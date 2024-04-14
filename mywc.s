// In lieu of a boolean data type.
// FALSE
    .equ FALSE, 0
// TRUE
    .equ TRUE, 1
// EOF
    .equ EOF, -1

//--------------------------------------------------------------------
    .section .rodata
printfFormatStr:
        .string "%7ld %7ld %7ld\n"

//--------------------------------------------------------------------

    .section .data
// static long lLineCount = 0;
lLineCount:
    .skip   8
// static long lWordCount = 0;
lWordCount:
    .skip   8
// static long lCharCount = 0;
lCharCount:
    .skip 8
// static int iInWord = FALSE;
iInWord:
    .skip 4

//--------------------------------------------------------------------

    .section .bss
// static int iChar;          
iChar:
    .skip 4

//--------------------------------------------------------------------

    .section .text

//--------------------------------------------------------------------
// Write to stdout counts of how many lines, words, and characters
// are in stdin. A word is a sequence of non-whitespace characters.
// Whitespace is defined by the isspace() function. Return 0.
//--------------------------------------------------------------------

// must be multiple of 16, don't ask
.equ MAIN_STACK_BYTECOUNT, 16

.global main

// int main(void)
main:
        // prolog
        sub     sp, sp, MAIN_STACK_BYTECOUNT
        str     x30, [sp]

whileLoop:
    // if ((iChar = getchar()) == EOF) goto endWhileLoop;
        bl      getchar
        adr     x1, iChar
        ldr     w0, [x1]
        cmp     [x1], EOF
        beq endWhileLoop

    // lCharCount++;
        adr     x2, lCharCount
        ldr     x2, [x2]
        // add .equ for incrementation?
        add     x2, x2, 1

    // if (!isspace(iChar)) goto elseSpace;
        adr     x0, iChar
        ldr     w0, [x0]
        bl      isspace
        cmp     w0, FALSE
        beq     elseSpace

    // if (!iInWord) goto endIfWord;
        adr     x3, iInWord
        ldr     w3, [x3]
        cmp     w3, FALSE
        beq     endIfWord

    // lWordCount++;
        adr     x4, lWordCount
        ldr     x4, [x4]
        add     x4, x4, 1
    // iInWord = FALSE;
        mov     w3, FALSE
    // goto endIfWord;
        b       endIfWord

    elseSpace:

        if (iInWord)
            goto endIfWord;
        iInWord = TRUE;

        endIfWord:

        if (iChar != '\n')
            goto whileLoop;
        lLineCount++;

        goto whileLoop;

        endWhileLoop:
        if (!iInWord)
            goto endIfWord2;
        lWordCount++;

        endIfWord2:
        printf("%7ld %7ld %7ld\n", lLineCount, lWordCount, lCharCount);
        return 0;

