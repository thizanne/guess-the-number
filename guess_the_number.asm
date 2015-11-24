bits 64

global _start

section .rodata
        MsgChooseSecret db "Choose a secret number : "
        LenChooseSecret equ $-MsgChooseSecret

        MsgTryNumber db "Guess the secret number... "
        LenTryNumber equ $-MsgTryNumber

        MsgGreater db "The secret number is greater !", 10
        LenGreater equ $-MsgGreater

        MsgLesser db "The secret number is lesser !", 10
        LenLesser equ $-MsgLesser

        MsgWin db "Success ! Number of tries: "
        LenWin equ $-MsgWin

        MsgTooManyDigits db "The maximal number of digits is 64.", 10
        LenTooManyDigits equ $-MsgTooManyDigits

        MsgNotADigit db "You must enter a valid integer number.", 10
        LenNotADigit equ $-MsgNotADigit

section .text
_start:
        mov rax, 1              ; sys_write
        mov rsi, MsgChooseSecret
        mov rdx, LenChooseSecret
        mov rdi, 1              ; stdout
        syscall

        sub rsp, 65
        mov rsi, rsp
        call getString

        mov rsi, rsp
        lea rcx, [rdi - 1]      ; don't forget the \n at the end
        call strToInteger

        xor r14, r14            ; r14 will hold the number of tries
        mov r15, rdi            ; r15 will hold the secret number

.gameLoop:
        mov rax, 1              ; sys_write
        mov rsi, MsgTryNumber
        mov rdx, LenTryNumber
        mov rdi, 1              ; stdout
        syscall

        add r14, 1              ; one more try

        sub rsp, 65
        mov rsi, rsp
        call getString

        mov rsi, rsp
        lea rcx, [rdi - 1]
        call strToInteger

        cmp r15, rdi
        jg .greater
        jl .lesser

        mov rsi, MsgWin         ; if we didn't jump, it's a win
        mov rdx, LenWin
        jmp .writeMessage

.greater:
        mov rsi, MsgGreater
        mov rdx, LenGreater
        jmp .writeMessage

.lesser:
        mov rsi, MsgLesser
        mov rdx, LenLesser
        jmp .writeMessage

.writeMessage:
        mov rax, 1              ; sys_write
        mov rdi, 1              ; stdout
        syscall

        jne .gameLoop

        mov rsi, r14
        call printRsi

        sub rsp, 1
        mov byte [rsp], `\n`
        mov rsi, rsp
        mov rdx, 1
        mov rax, 1              ; rax not preserved by syscall
        mov rdi, 1              ; stdout
        syscall

        xor rdi, rdi
        mov rax, 60             ; exit
        syscall

printRsi:
        push rbp
        mov rbp, rsp
        mov rax, rsi
        mov r10, 10            ; for the division

.fillLoop:
        xor rdx, rdx            ; for division
        div r10
        xor dl, 0x30            ; convert to ascii
        sub rsp, 1
        mov [rsp], dl
        cmp rax, 0
        jnz .fillLoop

        mov rax, 1              ; sys_write
        mov rsi, rsp            ; input buffer
        mov rdx, rbp
        sub rdx, rsp            ; size
        mov rdi, 1              ; stdout
        syscall

        leave
        ret

getString:
;; address expected in rsi
;; returns in rdi the number of bytes read
        xor rax, rax            ; sys.read
        xor rdi, rdi            ; stdin
        ; mov rsi, rsi          ; dest is actually already rsi
        mov rdx, 65             ; max length
        syscall

        add rsi, rax
        sub rsi, 1
        cmp byte [rsi], `\n`    ; is the last char read a \n ?
        jnz errorTooManyDigits

        mov rdi, rax            ; return in rdi

        ret

strToInteger:
;; address to string expected in rsi
;; length of string expected in rcx
;; puts in rdi the corresponding number
        xor rdi, rdi            ; accumulator initialisation

.conversionLoop:
        xor rax, rax
        mov al, [rsi]
        xor rax, 0x30           ; get ASCII value

        cmp rax, 9
        jg errorNotADigit

        cmp rax, 0
        jl errorNotADigit

        mov r10, rdi
        lea rdi, [rdi * 8]      ; mul rdi by 10
        lea rdi, [rdi + r10 * 2]

        add rdi, rax
        inc rsi
        loop .conversionLoop

        ret

errorTooManyDigits:
        push 0
        xor rdi, rdi            ; stdin
        mov rsi, rsp            ; dest
        mov rdx, 1              ; length

.flushStdinLoop:
        xor rax, rax            ; sys.read
        syscall

        cmp byte [rsp], `\n`
        jnz .flushStdinLoop

        mov rax, 1              ; sys.write
        mov rsi, MsgTooManyDigits
        mov rdx, LenTooManyDigits
        mov rdi, 2              ; stderr
        syscall

        mov rdi, 1
        mov rax, 60
        syscall

errorNotADigit:
        mov rax, 1              ; sys.write
        mov rsi, MsgNotADigit
        mov rdx, LenNotADigit
        mov rdi, 2              ; stderr
        syscall

        mov rdi, 1
        mov rax, 60
        syscall
