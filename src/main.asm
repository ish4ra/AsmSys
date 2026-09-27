BITS 64
GLOBAL _start

%define SYS_write    1
%define SYS_uname   63
%define SYS_sysinfo 99
%define SYS_exit    60
%define STDOUT       1

SECTION .data
    title db "AsmSys", 10
    title_len equ $ - title

    hostname_label db "Hostname     : "
    hostname_label_len equ $ - hostname_label
    kernel_label db "Kernel       : "
    kernel_label_len equ $ - kernel_label
    arch_label db "Architecture : "
    arch_label_len equ $ - arch_label
    uptime_label db "Uptime       : "
    uptime_label_len equ $ - uptime_label

    days_text db "d "
    days_text_len equ $ - days_text
    hours_text db "h "
    hours_text_len equ $ - hours_text
    mins_text db "m", 10
    mins_text_len equ $ - mins_text
    newline db 10

SECTION .bss
    ; struct utsname contains six 65-byte character arrays on Linux.
    utsbuf resb 390
    ; struct sysinfo is larger than the fields used here. 128 bytes is ample
    ; for the x86-64 Linux layout.
    sysinfo_buf resb 128
    numbuf resb 32

SECTION .text

_start:
    mov rsi, title
    mov rdx, title_len
    call print

    mov rax, SYS_uname
    mov rdi, utsbuf
    syscall
    test rax, rax
    js .exit_error

    mov rsi, hostname_label
    mov rdx, hostname_label_len
    call print
    lea rsi, [utsbuf + 65]
    call print_cstr
    call print_newline

    mov rsi, kernel_label
    mov rdx, kernel_label_len
    call print
    lea rsi, [utsbuf + 130]
    call print_cstr
    call print_newline

    mov rsi, arch_label
    mov rdx, arch_label_len
    call print
    lea rsi, [utsbuf + 260]
    call print_cstr
    call print_newline

    mov rax, SYS_sysinfo
    mov rdi, sysinfo_buf
    syscall
    test rax, rax
    js .exit_error

    mov rsi, uptime_label
    mov rdx, uptime_label_len
    call print

    mov rax, [sysinfo_buf]
    xor rdx, rdx
    mov rcx, 86400
    div rcx
    push rdx
    call print_uint
    mov rsi, days_text
    mov rdx, days_text_len
    call print

    pop rax
    xor rdx, rdx
    mov rcx, 3600
    div rcx
    push rdx
    call print_uint
    mov rsi, hours_text
    mov rdx, hours_text_len
    call print

    pop rax
    xor rdx, rdx
    mov rcx, 60
    div rcx
    call print_uint
    mov rsi, mins_text
    mov rdx, mins_text_len
    call print

    xor rdi, rdi
    jmp .exit

.exit_error:
    mov rdi, 1
.exit:
    mov rax, SYS_exit
    syscall

; write(STDOUT, rsi, rdx)
print:
    mov rax, SYS_write
    mov rdi, STDOUT
    syscall
    ret

print_newline:
    mov rsi, newline
    mov rdx, 1
    jmp print

; Print a zero-terminated string at RSI.
print_cstr:
    push rsi
    xor rdx, rdx
.count:
    cmp byte [rsi + rdx], 0
    je .ready
    inc rdx
    jmp .count
.ready:
    pop rsi
    jmp print

; Print unsigned integer in RAX.
print_uint:
    lea rsi, [numbuf + 31]
    xor rcx, rcx
    mov rbx, 10
.convert:
    xor rdx, rdx
    div rbx
    add dl, '0'
    dec rsi
    mov [rsi], dl
    inc rcx
    test rax, rax
    jnz .convert
    mov rdx, rcx
    jmp print
