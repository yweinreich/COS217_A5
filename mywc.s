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

// give registers meaningful names
currentChar .req x1
charCount   .req x2
wordCount   .req x3
lineCount   .req x4


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
        str     w0, [x1]
        cmp     w0, EOF
        beq endWhileLoop

    // lCharCount++;
        adr     x0, lCharCount
        ldr     x2, [x0]
        // add .equ for incrementation?
        add     x2, x2, 1
        str     x2, [x0]

    // if (!isspace(iChar)) goto elseSpace;
        adr     x1, iChar
        ldr     w0, [x1]
        bl      isspace
        // result of isspace will overwrite iChar in w0
        cmp     w0, FALSE
        beq     elseSpace

    // if (!iInWord) goto endIfWord;
        adr     x3, iInWord
        ldr     w3, [x3]
        cmp     w3, FALSE
        beq     endIfWord

    // lWordCount++;
        adr     x0, lWordCount
        ldr     x4, [x0]
        add     x4, x4, 1
        str     x4, [x0]
    // iInWord = FALSE;
        mov     w3, FALSE
        adr     x0, iInWord
        str     w3, [x0]
    // goto endIfWord;
        b       endIfWord

elseSpace:

    // if (iInWord) goto endIfWord;
        cmp     w3, TRUE
        beq     endIfWord

    // iInWord = TRUE;
        mov     w3, TRUE
        adr     x0, iInWord
        str     w3, [x0]

endIfWord:

    // if (iChar != '\n') goto whileLoop;
        adr     x0, iChar
        ldr     w1, [x0]
        cmp     w1, '\n'
        bne     whileLoop

    // lLineCount++;
        adr     x0, lLineCount
        ldr     x6, [x0]
        add     x6, x6, 1
        str     x6, [x0]

    // goto whileLoop;
        b whileLoop

endWhileLoop:
    // if (!iInWord) goto endIfWord2;
        adr     x0, iInWord
        ldr     w3, [x0]
        cmp     w3, FALSE
        beq     endIfWord2

    // lWordCount++;
        adr     x0, lWordCount
        ldr     x4, [x0]
        add     x4, x4, 1
        str     x4, [x0]

endIfWord2:
    // printf("%7ld %7ld %7ld\n", lLineCount, lWordCount, lCharCount);
        adr     x0, printfFormatStr
        adr     x1, lLineCount
        ldr     x1, [x1]
        adr     x2, lWordCount
        ldr     x2, [x2]
        adr     x3, lCharCount
        ldr     x3, [x3]
        bl      printf
    
    // epilog and return 0;
        mov w0, 0
        ldr x30, [sp]
        add sp, sp, MAIN_STACK_BYTECOUNT
        ret

        .size main, (. -main)

