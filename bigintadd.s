/*--------------------------------------------------------------------*/
/* bigintaddflat.c                                                    */
/* Author: Ariella and Jonathan                                       */
/*--------------------------------------------------------------------*/

#include "bigint.h"
#include "bigintprivate.h"
#include <string.h>
#include <assert.h>

/* In lieu of a boolean data type. */
enum
{
    FALSE,
    TRUE
};

/*--------------------------------------------------------------------*/

/* Return the larger of lLength1 and lLength2. */

static long BigInt_larger(long lLength1, long lLength2)
{
    long lLarger;
    if (lLength1 <= lLength2)
        goto largerElse;
    lLarger = lLength1;
    goto endLargerIf;

largerElse:
    lLarger = lLength2;
endLargerIf:
    return lLarger;
}

/*--------------------------------------------------------------------*/

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