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
.equ LARGER_STACK_BYTECOUNT, 32

// stack pointer offsets for parameters and local variables
.equ LLENGTH1, 8
.equ LLENGTH2, 16
.equ LLARGER, 24

// Return the larger of lLength1 and lLength2.
// static long BigInt_larger(long lLength1, long lLength2)
BigInt_larger:
    // prolog
    sub     sp, sp, LARGER_STACK_BYTECOUNT
    str     x30, [sp]

    // store lLength1 on the stack
    str     x0, [sp, LLENGTH1]

    // store lLength1 on the stack
    str     x1, [sp, LLENGTH2]

    // long lLarger;
    
    // if (lLength1 <= lLength2) goto largerElse;
    ldr     x2, [sp, LLENGTH1]
    ldr     x3, [sp, LLENGTH2]
    cmp     x2, x3
    ble     largerElse

    // lLarger = lLength1;
    ldr     x4, [sp, LLENGTH1]
    str     x4, [sp, LLARGER]

    // goto endLargerIf;
    b       endLargerIf

largerElse:
    // lLarger = lLength2;
    ldr     x3, [sp, LLENGTH2]
    str     x3, [sp, LLARGER]   

endLargerIf:
    // return lLarger;
    ldr     x0, [sp, LLARGER]

    // epilog
    ldr     x30, [sp]
    add     sp, sp, LARGER_STACK_BYTECOUNT
    ret

    .size BigInt_larger, (. - BigInt_larger)

/*--------------------------------------------------------------------*/

// must be a multiple of 16
.equ ADD_STACK_BYTECOUNT, 64

// parameter local variables stack offsets
.equ LSUMLENGTH, 8
.equ LINDEX, 16
.equ ULSUM, 24
.equ ULCARRY, 32
.equ OSUM, 40
.equ OADDEND2, 48
.equ OADDEND1, 56
.equ longByteShift, 3
.equ SIZEOFULONG, 8

// structure field offsets
.equ LLENGTH, 0
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

    // store oAddend1 on the stack
    str     x0, [sp, OADDEND1]

    // store oAddend2 on the stack
    str     x1, [sp, OADDEND2]

    // store oSum on the stack
    str     x2, [sp, OSUM]

//  unsigned long ulCarry;
//  unsigned long ulSum;
//  long lIndex;
//  long lSumLength;

    // Determine the larger length.
    // lSumLength = BigInt_larger(oAddend1->lLength, oAddend2->lLength);
    // get lLength from oAddend1, store in x0
    ldr     x0, [sp, OADDEND1]
    add     x0, x0, LLENGTH
    ldr     x0, [x0]

    // get lLength from oAddend2, store in x1
    ldr     x1, [sp, OADDEND2]
    add     x1, x1, LLENGTH
    ldr     x1, [x1]

    bl      BigInt_larger

    // store return value of BigInt_larger in lSumLength
    str     x0, [sp, LSUMLENGTH]

    // Clear oSum's array if necessary.
    // if (oSum->lLength <= lSumLength) goto endClearIf;
    ldr     x0, [sp, OSUM]
    add     x0, x0, LLENGTH
    ldr     x0, [x0]

    ldr     x1, [sp, LSUMLENGTH]

    cmp     x0, x1
    ble     endClearIf

    // memset(oSum->aulDigits, 0, MAX_DIGITS * sizeof(unsigned long));    
    ldr     x0, [sp, OSUM]
    add     x0, x0, AULDIGITS

    mov     x1, 0

    mov     x2, SIZEOFULONG
    mov     x3, MAX_DIGITS
    mul     x2, x2, x3

    bl      memset

endClearIf:

    // Perform the addition.
    // ulCarry = 0;
    mov     x0, 0
    str     x0, [sp, ULCARRY]

    // lIndex = 0;
    mov     x0, 0
    str     x0, [sp, LINDEX]

additionLoop:
    // if (lIndex >= lSumLength) goto endAdditionLoop;
    ldr     x0, [sp, LINDEX]
    ldr     x1, [sp, LSUMLENGTH]
    cmp     x0, x1
    bge     endAdditionLoop

    // ulSum = ulCarry;
    ldr     x2, [sp, ULCARRY]
    str     x2, [sp, ULSUM]

    // ulCarry = 0;
    mov     x0, 0
    str     x0, [sp, ULCARRY]

    // ulSum += oAddend1->aulDigits[lIndex];
    ldr     x0, [sp, ULSUM]
    ldr     x1, [sp, OADDEND1]
    add     x1, x1, AULDIGITS
    ldr     x2, [sp, LINDEX]
    ldr     x1, [x1, x2, lsl longByteShift]
    add     x0, x0, x1
    str     x0, [sp, ULSUM]

    // Check for overflow.
    // if (ulSum >= oAddend1->aulDigits[lIndex]) goto endOverflowIf1;
    ldr     x0, [sp, ULSUM]
    ldr     x1, [sp, OADDEND1]
    add     x1, x1, AULDIGITS
    ldr     x2, [sp, LINDEX]
    ldr     x1, [x1, x2, lsl longByteShift]
    cmp     x0, x1
    bhs     endOverflowIf1

    // ulCarry = 1;
    mov     x0, 1
    str     x0, [sp, ULCARRY]

endOverflowIf1:
    // ulSum += oAddend2->aulDigits[lIndex];
    ldr     x0, [sp, ULSUM]
    ldr     x1, [sp, OADDEND1]
    add     x1, x1, AULDIGITS
    ldr     x2, [sp, LINDEX]
    ldr     x1, [x1, x2, lsl longByteShift]
    add     x0, x0, x1
    str     x0, [sp, ULSUM]

    // Check for overflow.
    // if (ulSum >= oAddend2->aulDigits[lIndex]) goto endOverflowIf2;
    ldr     x0, [sp, ULSUM]
    ldr     x1, [sp, OADDEND2]
    add     x1, x1, AULDIGITS
    ldr     x2, [sp, LINDEX]
    ldr     x1, [x1, x2, lsl longByteShift]
    cmp     x0, x1
    bhs     endOverflowIf2

    // ulCarry = 1;
    mov     x0, 1
    str     x0, [sp, ULCARRY]

endOverflowIf2:
    // oSum->aulDigits[lIndex] = ulSum;
    ldr     x0, [sp, OSUM]
    add     x0, x0, AULDIGITS
    ldr     x1, [sp, LINDEX]
    ldr     x2, [sp, ULSUM]
    str     x2, [x0, x1, lsl longByteShift]

    // lIndex++;
    ldr     x0, [sp, LINDEX]
    mov     x1, 1
    add     x0, x0, x1
    str     x0, [sp, LINDEX]

    // goto additionLoop;
    b       additionLoop

endAdditionLoop:

    // Check for a carry out of the last "column" of the addition.
    // if (ulCarry != 1) goto endCarryIf;
    ldr     x0, [sp, ULCARRY]
    mov     x1, 1
    cmp     x0, x1
    bne     endCarryIf

    // if (lSumLength != MAX_DIGITS) goto endMaxIf;
    ldr     x0, [sp, LSUMLENGTH]
    ldr     x1, MAX_DIGITS
    cmp     x0, x1
    bne     endMaxIf

    // return FALSE;
    mov     x0, FALSE
    ldr     x30, [sp]
    add     sp, sp, ADD_STACK_BYTECOUNT
    ret

    .size BigInt_add, (. -BigInt_add)


endMaxIf:
    // oSum->aulDigits[lSumLength] = 1;
    ldr     x0, [sp, OSUM]
    add     x0, x0, AULDIGITS
    ldr     x1, [sp, LSUMLENGTH]    
    mov     x2, 1
    str     x2, [x0, x1, lsl longByteShift]

    // lSumLength++;
    ldr     x0, [sp, LSUMLENGTH]
    mov     x1, 1
    add     x0, x0, x1
    str     x0, [sp, LSUMLENGTH]

endCarryIf:
    // Set the length of the sum.
    // oSum->lLength = lSumLength;
    ldr     x0, [sp, OSUM]
    add     x0, x0, LLENGTH
    ldr     x1, [sp, LSUMLENGTH]
    str     x1, [x0]

    // return TRUE;
    mov     x0, TRUE
    ldr     x30, [sp]
    add     sp, sp, ADD_STACK_BYTECOUNT
    ret

    .size BigInt_add, (. -BigInt_add)
