BITS 64
GLOBAL _start

SECTION .data
    banner db "AsmSys", 10
           db "Lightweight x86-64 Linux system information tool", 10, 10
    banner_len equ $ - banner

    label_arch db "Architecture : x86-64", 10
    label_arch_len equ $ - label_arch

    label_runtime db "Runtime      : Linux syscalls", 10
    label_runtime_len equ $ - label_runtime

    label_lang db "Language     : NASM Assembly", 10
    label_lang_len equ $ - label_lang

SECTION .text
_start:
    mov rax, 1
    mov rdi, 1
    mov rsi, banner
    mov rdx, banner_len
    syscall

    mov rax, 1
    mov rdi, 1
    mov rsi, label_arch
    mov rdx, label_arch_len
    syscall

    mov rax, 1
    mov rdi, 1
    mov rsi, label_runtime
    mov rdx, label_runtime_len
    syscall

    mov rax, 1
    mov rdi, 1
    mov rsi, label_lang
    mov rdx, label_lang_len
    syscall

    mov rax, 60
    xor rdi, rdi
    syscall
