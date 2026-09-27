BITS 64
GLOBAL _start

%define SYS_read      0
%define SYS_write     1
%define SYS_open      2
%define SYS_close     3
%define SYS_uname    63
%define SYS_sysinfo  99
%define SYS_exit     60
%define STDOUT        1

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
    cpu_label db "CPU          : "
    cpu_label_len equ $ - cpu_label
    memory_label db "Memory       : "
    memory_label_len equ $ - memory_label

    cpuinfo_path db "/proc/cpuinfo", 0
    model_key db "model name", 0
    unknown_text db "Unknown", 10
    unknown_text_len equ $ - unknown_text

    days_text db "d "
    days_text_len equ $ - days_text
    hours_text db "h "
    hours_text_len equ $ - hours_text
    mins_text db "m", 10
    mins_text_len equ $ - mins_text

    mib_text db " MiB / "
    mib_text_len equ $ - mib_text
    mib_end db " MiB", 10
    mib_end_len equ $ - mib_end
    newline db 10

SECTION .bss
    utsbuf resb 390
    sysinfo_buf resb 128
    cpu_buf resb 8192
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

    mov rsi, cpu_label
    mov rdx, cpu_label_len
    call print
    call print_cpu_model

    mov rax, SYS_sysinfo
    mov rdi, sysinfo_buf
    syscall
    test rax, rax
    js .exit_error

    mov rsi, memory_label
    mov rdx, memory_label_len
    call print

    ; Linux x86-64 struct sysinfo:
    ; totalram @ 32, freeram @ 40, bufferram @ 56, mem_unit @ 104.
    ; Display used as total - free - buffers.
    mov eax, dword [sysinfo_buf + 104]
    mov r8, rax
    mov rax, [sysinfo_buf + 32]
    imul rax, r8
    mov r9, rax
    mov rax, [sysinfo_buf + 40]
    imul rax, r8
    mov r10, rax
    mov rax, [sysinfo_buf + 56]
    imul rax, r8
    add r10, rax
    mov rax, r9
    sub rax, r10
    shr rax, 20
    call print_uint
    mov rsi, mib_text
    mov rdx, mib_text_len
    call print
    mov rax, r9
    shr rax, 20
    call print_uint
    mov rsi, mib_end
    mov rdx, mib_end_len
    call print

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

; Read /proc/cpuinfo and print the first model name value.
print_cpu_model:
    mov rax, SYS_open
    mov rdi, cpuinfo_path
    xor rsi, rsi
    xor rdx, rdx
    syscall
    test rax, rax
    js .unknown
    mov r12, rax

    mov rax, SYS_read
    mov rdi, r12
    mov rsi, cpu_buf
    mov rdx, 8191
    syscall
    test rax, rax
    jle .close_unknown
    mov r13, rax
    mov byte [cpu_buf + r13], 0

    mov rax, SYS_close
    mov rdi, r12
    syscall

    mov rsi, cpu_buf
    mov rcx, r13
.search:
    cmp rcx, 10
    jb .unknown
    cmp byte [rsi], 'm'
    jne .next
    cmp byte [rsi+1], 'o'
    jne .next
    cmp byte [rsi+2], 'd'
    jne .next
    cmp byte [rsi+3], 'e'
    jne .next
    cmp byte [rsi+4], 'l'
    jne .next
    cmp byte [rsi+5], ' '
    jne .next
    cmp byte [rsi+6], 'n'
    jne .next
    cmp byte [rsi+7], 'a'
    jne .next
    cmp byte [rsi+8], 'm'
    jne .next
    cmp byte [rsi+9], 'e'
    jne .next

.find_colon:
    cmp byte [rsi], 0
    je .unknown
    cmp byte [rsi], ':'
    je .value
    inc rsi
    jmp .find_colon
.value:
    inc rsi
.skip_space:
    cmp byte [rsi], ' '
    jne .print_value
    inc rsi
    jmp .skip_space
.print_value:
    mov rdi, rsi
    xor rdx, rdx
.value_len:
    cmp byte [rdi + rdx], 10
    je .have_len
    cmp byte [rdi + rdx], 0
    je .have_len
    inc rdx
    jmp .value_len
.have_len:
    mov rsi, rdi
    call print
    call print_newline
    ret

.next:
    inc rsi
    dec rcx
    jmp .search

.close_unknown:
    mov rax, SYS_close
    mov rdi, r12
    syscall
.unknown:
    mov rsi, unknown_text
    mov rdx, unknown_text_len
    jmp print

print:
    mov rax, SYS_write
    mov rdi, STDOUT
    syscall
    ret

print_newline:
    mov rsi, newline
    mov rdx, 1
    jmp print

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
