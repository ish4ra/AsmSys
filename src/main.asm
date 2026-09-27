BITS 64
GLOBAL _start

%define SYS_read       0
%define SYS_write      1
%define SYS_open       2
%define SYS_close      3
%define SYS_statfs   137
%define SYS_uname     63
%define SYS_sysinfo   99
%define SYS_exit      60
%define STDOUT         1

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
    disk_label db "Disk /       : "
    disk_label_len equ $ - disk_label

    cpuinfo_path db "/proc/cpuinfo", 0
    root_path db "/", 0
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
    gib_text db " GiB / "
    gib_text_len equ $ - gib_text
    gib_end db " GiB", 10
    gib_end_len equ $ - gib_end
    newline db 10

    opt_cpu db "--cpu",0
    opt_memory db "--memory",0
    opt_disk db "--disk",0
    opt_all db "--all",0
    opt_help db "--help",0
    opt_help_short db "-h",0
    help_text db "Usage: asmsys [OPTION]",10,10
              db "  --cpu       Show CPU information",10
              db "  --memory    Show memory information",10
              db "  --disk      Show root filesystem usage",10
              db "  --all       Show all system information",10
              db "  --help, -h  Show this help",10
    help_text_len equ $ - help_text
    invalid_text db "asmsys: unknown option",10
    invalid_text_len equ $ - invalid_text

SECTION .bss
    utsbuf resb 390
    sysinfo_buf resb 128
    statfs_buf resb 120
    cpu_buf resb 8192
    numbuf resb 32

SECTION .text
_start:
    mov r14, [rsp]
    cmp r14, 1
    je show_all
    cmp r14, 2
    jne invalid_option
    mov r15, [rsp+16]

    mov rdi,r15
    mov rsi,opt_cpu
    call streq
    test rax,rax
    jnz only_cpu
    mov rdi,r15
    mov rsi,opt_memory
    call streq
    test rax,rax
    jnz only_memory
    mov rdi,r15
    mov rsi,opt_disk
    call streq
    test rax,rax
    jnz only_disk
    mov rdi,r15
    mov rsi,opt_all
    call streq
    test rax,rax
    jnz show_all
    mov rdi,r15
    mov rsi,opt_help
    call streq
    test rax,rax
    jnz show_help
    mov rdi,r15
    mov rsi,opt_help_short
    call streq
    test rax,rax
    jnz show_help
    jmp invalid_option

show_help:
    mov rsi,help_text
    mov rdx,help_text_len
    call print
    xor rdi,rdi
    jmp exit

invalid_option:
    mov rsi,invalid_text
    mov rdx,invalid_text_len
    call print
    mov rdi,2
    jmp exit

only_cpu:
    call show_cpu
    xor rdi,rdi
    jmp exit
only_memory:
    call load_sysinfo
    test rax,rax
    js exit_error
    call show_memory
    xor rdi,rdi
    jmp exit
only_disk:
    call show_disk
    test rax,rax
    js exit_error
    xor rdi,rdi
    jmp exit

show_all:
    mov rsi,title
    mov rdx,title_len
    call print
    mov rax,SYS_uname
    mov rdi,utsbuf
    syscall
    test rax,rax
    js exit_error

    mov rsi,hostname_label
    mov rdx,hostname_label_len
    call print
    lea rsi,[utsbuf+65]
    call print_cstr
    call print_newline

    mov rsi,kernel_label
    mov rdx,kernel_label_len
    call print
    lea rsi,[utsbuf+130]
    call print_cstr
    call print_newline

    mov rsi,arch_label
    mov rdx,arch_label_len
    call print
    lea rsi,[utsbuf+260]
    call print_cstr
    call print_newline

    call show_cpu
    call load_sysinfo
    test rax,rax
    js exit_error
    call show_memory
    call show_uptime
    call show_disk
    test rax,rax
    js exit_error
    xor rdi,rdi
    jmp exit

load_sysinfo:
    mov rax,SYS_sysinfo
    mov rdi,sysinfo_buf
    syscall
    ret

show_cpu:
    mov rsi,cpu_label
    mov rdx,cpu_label_len
    call print
    call print_cpu_model
    ret

show_memory:
    mov rsi,memory_label
    mov rdx,memory_label_len
    call print
    mov eax,dword [sysinfo_buf+104]
    mov r8,rax
    mov r9,[sysinfo_buf+32]
    imul r9,r8
    mov r10,[sysinfo_buf+40]
    imul r10,r8
    mov rax,[sysinfo_buf+56]
    imul rax,r8
    add r10,rax
    mov rax,r9
    sub rax,r10
    shr rax,20
    call print_uint
    mov rsi,mib_text
    mov rdx,mib_text_len
    call print
    mov rax,r9
    shr rax,20
    call print_uint
    mov rsi,mib_end
    mov rdx,mib_end_len
    call print
    ret

show_uptime:
    mov rsi,uptime_label
    mov rdx,uptime_label_len
    call print
    mov rax,[sysinfo_buf]
    xor rdx,rdx
    mov rcx,86400
    div rcx
    push rdx
    call print_uint
    mov rsi,days_text
    mov rdx,days_text_len
    call print
    pop rax
    xor rdx,rdx
    mov rcx,3600
    div rcx
    push rdx
    call print_uint
    mov rsi,hours_text
    mov rdx,hours_text_len
    call print
    pop rax
    xor rdx,rdx
    mov rcx,60
    div rcx
    call print_uint
    mov rsi,mins_text
    mov rdx,mins_text_len
    call print
    ret

show_disk:
    mov rax,SYS_statfs
    mov rdi,root_path
    mov rsi,statfs_buf
    syscall
    test rax,rax
    js .done
    push rax
    mov rsi,disk_label
    mov rdx,disk_label_len
    call print
    ; statfs: f_bsize @ 8, f_blocks @ 16, f_bfree @ 24, f_bavail @ 32
    mov r8,[statfs_buf+8]
    mov r9,[statfs_buf+16]
    imul r9,r8
    mov r10,[statfs_buf+24]
    imul r10,r8
    mov rax,r9
    sub rax,r10
    shr rax,30
    call print_uint
    mov rsi,gib_text
    mov rdx,gib_text_len
    call print
    mov rax,r9
    shr rax,30
    call print_uint
    mov rsi,gib_end
    mov rdx,gib_end_len
    call print
    pop rax
.done:
    ret

print_cpu_model:
    mov rax,SYS_open
    mov rdi,cpuinfo_path
    xor rsi,rsi
    xor rdx,rdx
    syscall
    test rax,rax
    js .unknown
    mov r12,rax
    mov rax,SYS_read
    mov rdi,r12
    mov rsi,cpu_buf
    mov rdx,8191
    syscall
    test rax,rax
    jle .close_unknown
    mov r13,rax
    mov byte [cpu_buf+r13],0
    mov rax,SYS_close
    mov rdi,r12
    syscall
    mov rsi,cpu_buf
    mov rcx,r13
.search:
    cmp rcx,10
    jb .unknown
    cmp dword [rsi],"mode"
    jne .next
    cmp dword [rsi+4],"l na"
    jne .next
    cmp word [rsi+8],"me"
    jne .next
.find_colon:
    cmp byte [rsi],0
    je .unknown
    cmp byte [rsi],':'
    je .value
    inc rsi
    jmp .find_colon
.value:
    inc rsi
.skip:
    cmp byte [rsi],' '
    jne .print
    inc rsi
    jmp .skip
.print:
    mov rdi,rsi
    xor rdx,rdx
.len:
    cmp byte [rdi+rdx],10
    je .ready
    cmp byte [rdi+rdx],0
    je .ready
    inc rdx
    jmp .len
.ready:
    mov rsi,rdi
    call print
    call print_newline
    ret
.next:
    inc rsi
    dec rcx
    jmp .search
.close_unknown:
    mov rax,SYS_close
    mov rdi,r12
    syscall
.unknown:
    mov rsi,unknown_text
    mov rdx,unknown_text_len
    jmp print

streq:
.loop:
    mov al,[rdi]
    cmp al,[rsi]
    jne .no
    test al,al
    je .yes
    inc rdi
    inc rsi
    jmp .loop
.yes:
    mov rax,1
    ret
.no:
    xor rax,rax
    ret

print:
    mov rax,SYS_write
    mov rdi,STDOUT
    syscall
    ret
print_newline:
    mov rsi,newline
    mov rdx,1
    jmp print
print_cstr:
    push rsi
    xor rdx,rdx
.count:
    cmp byte [rsi+rdx],0
    je .ready
    inc rdx
    jmp .count
.ready:
    pop rsi
    jmp print
print_uint:
    lea rsi,[numbuf+31]
    xor rcx,rcx
    mov rbx,10
.convert:
    xor rdx,rdx
    div rbx
    add dl,'0'
    dec rsi
    mov [rsi],dl
    inc rcx
    test rax,rax
    jnz .convert
    mov rdx,rcx
    jmp print

exit_error:
    mov rdi,1
exit:
    mov rax,SYS_exit
    syscall
