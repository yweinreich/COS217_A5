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
.equ oldx25, 56

// registers for parameters and local variables
LSUMLENGTH .req x19
LINDEX .req x20
ULSUM .req x21
ULCARRY .req x22
OSUM .req x23
OADDEND2 .req x24
OADDEND1 .req x25

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
    str     x30, [sp]

    // store current values of x19-x25
    str     x19, [sp, oldx19]
    str     x20, [sp, oldx20]
    str     x21, [sp, oldx21]
    str     x22, [sp, oldx22]
    str     x23, [sp, oldx23]
    str     x24, [sp, oldx24]
    str     x25, [sp, oldx25]

    // store parameters in the appropriate registers
    mov     OADDEND1, x0
    mov     OADDEND2, x1
    mov     OSUM, x2

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
    mov     LSUMLENGTH, x0

    // goto endLargerIf;
    b       endLargerIf

largerElse:
    // lLarger = lLength2;
    mov     LSUMLENGTH, x1

endLargerIf:

    // Clear oSum's array if necessary.
    // if (oSum->lLength <= lSumLength) goto endClearIf;
    // lLength is the first element of oSum (0 offset)
    ldr     x0, [OSUM]

    cmp     x0, LSUMLENGTH
    ble     endClearIf

    // memset(oSum->aulDigits, 0, MAX_DIGITS * sizeof(unsigned long));    
    add     x0, OSUM, AULDIGITS

    mov     x1, 0

    mov     x2, SIZEOFULONG
    mov     x3, MAX_DIGITS
    mul     x2, x2, x3

    bl      memset

endClearIf:

    // Perform the addition.
    // ulCarry = 0;
    mov     ULCARRY, 0

    // lIndex = 0;
    mov     LINDEX, 0

// if (lIndex >= lSumLength) goto endAdditionLoop;
    cmp     LINDEX, LSUMLENGTH
    bge     endAdditionLoop

additionLoop:
    // ulSum = ulCarry;
    mov     ULSUM, ULCARRY

    // ulCarry = 0;
    mov     ULCARRY, 0

    // ulSum += oAddend1->aulDigits[lIndex];
    add     x0, OADDEND1, AULDIGITS
    ldr     x0, [x0, LINDEX, lsl longByteShift]
    add     ULSUM, ULSUM, x0

    // Check for overflow.
    // if (ulSum >= oAddend1->aulDigits[lIndex]) goto endOverflowIf1;
    add     x0, OADDEND1, AULDIGITS
    ldr     x0, [x0, LINDEX, lsl longByteShift]
    cmp     ULSUM, x0
    bhs     endOverflowIf1

    // ulCarry = 1;
    mov     ULCARRY, 1

endOverflowIf1:
    // ulSum += oAddend2->aulDigits[lIndex];
    add     x0, OADDEND2, AULDIGITS
    ldr     x0, [x0, LINDEX, lsl longByteShift]
    add     ULSUM, ULSUM, x0

    // Check for overflow.
    // if (ulSum >= oAddend2->aulDigits[lIndex]) goto endOverflowIf2;
    add     x0, OADDEND2, AULDIGITS
    ldr     x0, [x0, LINDEX, lsl longByteShift]
    cmp     ULSUM, x0
    bhs     endOverflowIf2

    // ulCarry = 1;
    mov     ULCARRY, 1

endOverflowIf2:
    // oSum->aulDigits[lIndex] = ulSum;
    add     x0, OSUM, AULDIGITS
    str     ULSUM, [x0, LINDEX, lsl longByteShift]

    // lIndex++;
    add     LINDEX, LINDEX, 1

    // if (lIndex < lSumLength) goto additionLoop;
    cmp     LINDEX, LSUMLENGTH
    blt     additionLoop
 
endAdditionLoop:

    // Check for a carry out of the last "column" of the addition.
    // if (ulCarry != 1) goto endCarryIf;
    cmp     ULCARRY, 1
    bne     endCarryIf

    // if (lSumLength != MAX_DIGITS) goto endMaxIf;
    mov     x1, MAX_DIGITS
    cmp     LSUMLENGTH, x1
    bne     endMaxIf

    // return FALSE;
    mov     x0, FALSE

    // restore old values of x19-x25
    ldr     x19, [sp, oldx19]
    ldr     x20, [sp, oldx20]
    ldr     x21, [sp, oldx21]
    ldr     x22, [sp, oldx22]
    ldr     x23, [sp, oldx23]
    ldr     x24, [sp, oldx24]
    ldr     x25, [sp, oldx25]

    // epilog
    ldr     x30, [sp]
    add     sp, sp, ADD_STACK_BYTECOUNT
    ret

    .size BigInt_add, (. -BigInt_add)

endMaxIf:
    // oSum->aulDigits[lSumLength] = 1;
    add     x0, OSUM, AULDIGITS
    mov     x1, 1
    str     x1, [x0, LSUMLENGTH, lsl longByteShift]

    // lSumLength++;
    add     LSUMLENGTH, LSUMLENGTH, 1

endCarryIf:
    // Set the length of the sum.
    // oSum->lLength = lSumLength;
    // lLength is the first element of oSum (0 offset)
    str     LSUMLENGTH, [OSUM]

    // return TRUE;
    mov     x0, TRUE

    // restore old values of x19-x25
    ldr     x19, [sp, oldx19]
    ldr     x20, [sp, oldx20]
    ldr     x21, [sp, oldx21]
    ldr     x22, [sp, oldx22]
    ldr     x23, [sp, oldx23]
    ldr     x24, [sp, oldx24]
    ldr     x25, [sp, oldx25]

    // epilog
    ldr     x30, [sp]
    add     sp, sp, ADD_STACK_BYTECOUNT
    ret

    .size BigInt_add, (. -BigInt_add)
