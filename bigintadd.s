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
    sub     sp, sp LARGER_STACK_BYTECOUNT
    str     x30, [sp]

    // store lLength1 on the stack
    mov     x2, sp
    add     x2, x2, LLENGTH1
    str     x0, [x2]

    // store lLength1 on the stack
    mov     x3, sp
    add     x3, x3, LLENGTH2
    str     x1, [x3]

    // long lLarger;
    
    // if (lLength1 <= lLength2) goto largerElse;
    mov     x2, sp
    add     x2, x2, LLENGTH1
    ldr     x2, [x2]

    mov     x3, sp
    add     x3, x3, LLENGTH2
    str     x3, [x3]

    cmp     x2, x3
    ble     largerElse

    // lLarger = lLength1;
    // get lLength1
    mov     x2, sp
    add     x2, x2, LLENGTH1
    ldr     x2, [x2]
    // get stack address of lLarger
    mov     x4, sp
    add     x4, x4, LLARGER
    // store lLength1 in lLarger
    str     x2, [x4]   

    // goto endLargerIf;
    b       endLargerIf

largerElse:
    // lLarger = lLength2;
    // get lLength2
    mov     x3, sp
    add     x3, x3, LLENGTH2
    ldr     x3, [x3]
    // get stack address of lLarger
    mov     x4, sp
    add     x4, x4, LLARGER
    // store lLength2 in lLarger
    str     x3, [x4]   

endLargerIf:
    // return lLarger;
    mov     x4, sp
    add     x4, x4, LLARGER
    ldr     x4, [x4]
    mov     x0, x4

    // epilog
    ldr     x30, [sp]
    add     sp, sp, LARGER_STACK_BYTECOUNT
    ret

    .size BigInt_larger, (. - BigInt_larger)

/*--------------------------------------------------------------------*/

// must be a multiple of 16
.equ ADD_STACK_BYTECOUNT, 64

// stack pointer offsets for parameters and local variables
.equ 

/* Assign the sum of oAddend1 and oAddend2 to oSum.  oSum should be
   distinct from oAddend1 and oAddend2.  Return 0 (FALSE) if an
   overflow occurred, and 1 (TRUE) otherwise. */

int BigInt_add(BigInt_T oAddend1, BigInt_T oAddend2, BigInt_T oSum)
{
    unsigned long ulCarry;
    unsigned long ulSum;
    long lIndex;
    long lSumLength;

    /* Determine the larger length. */
    lSumLength = BigInt_larger(oAddend1->lLength, oAddend2->lLength);

    /* Clear oSum's array if necessary. */
    if (oSum->lLength <= lSumLength)
        goto endClearIf;
    memset(oSum->aulDigits, 0, MAX_DIGITS * sizeof(unsigned long));
endClearIf:

    /* Perform the addition. */
    ulCarry = 0;

    lIndex = 0;

additionLoop:
    if (lIndex >= lSumLength)
        goto endAdditionLoop;
    ulSum = ulCarry;
    ulCarry = 0;

    ulSum += oAddend1->aulDigits[lIndex];

    if (ulSum >= oAddend1->aulDigits[lIndex])
        goto endOverflowIf1; /* Check for overflow. */
    ulCarry = 1;

endOverflowIf1:
    ulSum += oAddend2->aulDigits[lIndex];

    if (ulSum >= oAddend2->aulDigits[lIndex])
        goto endOverflowIf2; /* Check for overflow. */
    ulCarry = 1;

endOverflowIf2:
    oSum->aulDigits[lIndex] = ulSum;

    lIndex++;
    goto additionLoop;

endAdditionLoop:

    /* Check for a carry out of the last "column" of the addition. */
    if (ulCarry != 1)
        goto endCarryIf;

    if (lSumLength != MAX_DIGITS)
        goto endMaxIf;
    return FALSE;

endMaxIf:
    oSum->aulDigits[lSumLength] = 1;
    lSumLength++;

endCarryIf:
    /* Set the length of the sum. */
    oSum->lLength = lSumLength;

    return TRUE;
}