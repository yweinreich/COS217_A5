//--------------------------------------------------------------------
// bigintaddflat.c                                                    
// Author: Ariella and Jonathan                                       
//--------------------------------------------------------------------

// In lieu of a boolean data type.
//    FALSE
.equ FALSE, 0
//    TRUE
.equ TRUE, 1

//--------------------------------------------------------------------
    .section .rodota

//--------------------------------------------------------------------
    .section .data

//--------------------------------------------------------------------
    .section .bss

//--------------------------------------------------------------------
    .section .text

// must be a multiple of 16
.equ ADD_STACK_BYTECOUNT, 64

// stack offsets for old register values
.equ oldx19, 8
.equ oldx20, 16
.equ oldx21, 24
.equ oldx22, 32
.equ oldx23, 40
.equ oldx24, 48

// registers for parameters and local variables
// using caller saved registers so we don't need to save the values
LSUMLENGTH .req x19
LINDEX .req x20
ULSUM .req x21
OSUM .req x22
OADDEND2 .req x23
OADDEND1 .req x24
OA1DIGITS .req x9
OA2DIGITS .req x10
OSUMDIGITS .req x11

.equ longByteShift, 3
.equ SIZEOFULONG, 8

// structure field offsets
.equ AULDIGITS, 8

// enumerated constants
.equ MAX_DIGITS, 32768

// Assign the sum of oAddend1 and oAddend2 to oSum.  oSum should be
// distinct from oAddend1 and oAddend2.  Return 0 (FALSE) if an
// overflow occurred, and 1 (TRUE) otherwise.

// int BigInt_add(BigInt_T oAddend1, BigInt_T oAddend2, BigInt_T oSum)

    .global BigInt_add

BigInt_add:
    // prolog
    sub     sp, sp, ADD_STACK_BYTECOUNT
    prfm    PSTL1KEEP, [sp]
    str     x30, [sp]

    // store current values of x19-x24
    str     x24, [sp, oldx24]
    str     x23, [sp, oldx23]
    str     x22, [sp, oldx22]
    str     x21, [sp, oldx21]
    str     x20, [sp, oldx20]
    str     x19, [sp, oldx19]

    // store parameters in the appropriate registers
    add     OADDEND1, xzr, x0
    add     OADDEND2, xzr, x1
    add     OSUM, xzr, x2

//  unsigned long ulCarry;
//  unsigned long ulSum;
//  long lIndex;
//  long lSumLength;

    // Determine the larger length.
    // lSumLength = BigInt_larger(oAddend1->lLength, oAddend2->lLength);
    // lLength is the first element of oAddend1 (0 offset)
    ldr     x0, [OADDEND1]

    // lLength is the first element of oAddend2 (0 offset)
    ldr     x1, [OADDEND2]

    // if (lLength1 <= lLength2) goto largerElse;
    cmp     x0, x1
    ble     largerElse

    // lLarger = lLength1;
    add     LSUMLENGTH, xzr, x0

    // goto endLargerIf;
    b       endLargerIf

largerElse:
    // lLarger = lLength2;
    add     LSUMLENGTH, xzr, x1

endLargerIf:

    // Clear oSum's array if necessary.
    // if (oSum->lLength <= lSumLength) goto endClearIf;
    // lLength is the first element of oSum (0 offset)
    ldr     x0, [OSUM]

    cmp     x0, LSUMLENGTH
    ble     endClearIf

    // memset(oSum->aulDigits, 0, MAX_DIGITS * sizeof(unsigned long));    
    add     x0, OSUM, AULDIGITS

    // set x1 to 0
    eor     x1, x1, x1

    mov     x2, SIZEOFULONG
    mov     x3, MAX_DIGITS
    mul     x2, x2, x3

    bl      memset

endClearIf:

    // Perform the addition.

    // lIndex = 0;
    eor     LINDEX, LINDEX, LINDEX

// if (lIndex >= lSumLength) goto endNoCarry;
    cmp     LINDEX, LSUMLENGTH
    bge     endNoCarry

// optimize loop by storing these values in registers
    add     OA1DIGITS, OADDEND1, AULDIGITS
    add     OA2DIGITS, OADDEND2, AULDIGITS
    add     OSUMDIGITS, OSUM, AULDIGITS
    mov     x12, 1

additionLoop:
    // ulSum = ulCarry;
    eor     ULSUM, ULSUM, ULSUM
    b       noCarry

yesCarry:
    add     ULSUM, xzr, x12

noCarry:
    // ulSum += oAddend1->aulDigits[lIndex];
    ldr     x0, [OA1DIGITS, LINDEX, lsl longByteShift]
    adcs    ULSUM, ULSUM, x0

    // Automatically notes overflow with carry flag

endOverflowIf1:
    // ulSum += oAddend2->aulDigits[lIndex];
    ldr     x0, [OA2DIGITS, LINDEX, lsl longByteShift]
    // if the carry flag is already set to 1, branch to regular addition
    // to avoid overwriting it
    bcs     add2NoFlag
    adcs    ULSUM, ULSUM, x0

    // Automatically notes overflow with carry flag

    b       endOverflowIf2

add2NoFlag:
    add     ULSUM, ULSUM, x0

endOverflowIf2:
    // oSum->aulDigits[lIndex] = ulSum;
    str     ULSUM, [OSUMDIGITS, LINDEX, lsl longByteShift]

    // lIndex++;
    add     LINDEX, LINDEX, x12

    bcc     carry0
    // do comparisons and branch knowing that carry = 1
    // if (lIndex < lSumLength) goto additionLoop;
    cmp     LINDEX, LSUMLENGTH
    blt     yesCarry
    b       endWithCarry

carry0:
    // do comparisons and branch knowing that carry = 0
    // if (lIndex < lSumLength) goto additionLoop;
    cmp     LINDEX, LSUMLENGTH
    blt     additionLoop
    prfm    PSTL1KEEP, [OSUM]
    b       endNoCarry

endWithCarry:
    // if (lSumLength != MAX_DIGITS) goto endMaxIf;
    prfm    PLDL1KEEP, [sp, oldx19]
    sub     x1, LSUMLENGTH, MAX_DIGITS
    cbnz    x1, endMaxIf

    // return FALSE;
    // FALSE = 0
    eor     x0, x0, x0

    // restore old values of x19-x24
    ldr     x19, [sp, oldx19]
    ldr     x20, [sp, oldx20]
    ldr     x21, [sp, oldx21]
    ldr     x22, [sp, oldx22]
    ldr     x23, [sp, oldx23]
    ldr     x24, [sp, oldx24]

    // epilog
    prfm    PLDL1STRM, [sp]
    ldr     x30, [sp]
    add     sp, sp, ADD_STACK_BYTECOUNT
    ret

    .size BigInt_add, (. -BigInt_add)

endMaxIf:
    // oSum->aulDigits[lSumLength] = 1;
    add     x0, OSUM, AULDIGITS
    str     x12, [x0, LSUMLENGTH, lsl longByteShift]

    // lSumLength++;
    add     LSUMLENGTH, LSUMLENGTH, x12

endNoCarry:
    // Set the length of the sum.
    // oSum->lLength = lSumLength;
    // lLength is the first element of oSum (0 offset)
    str     LSUMLENGTH, [OSUM]

    // return TRUE;
    // x12 = 1 = TRUE
    orr     x0, xzr, x12

    // restore old values of x19-x25
    ldr     x19, [sp, oldx19]
    ldr     x20, [sp, oldx20]
    ldr     x21, [sp, oldx21]
    ldr     x22, [sp, oldx22]
    ldr     x23, [sp, oldx23]
    ldr     x24, [sp, oldx24]

    // epilog
    prfm    PLDL1STRM, [sp]
    ldr     x30, [sp]
    add     sp, sp, ADD_STACK_BYTECOUNT
    ret

    .size BigInt_add, (. -BigInt_add)
