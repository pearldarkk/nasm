%include 'func64.asm'

section .rodata
    popupmsg        db      'Finding netcat processes to kill: ', 0ah, 0
    procpath        db      '/proc', 0
    statusstr       db      '/status', 0
    ncproc          db      'nc', 0
    ncatproc        db      'ncat', 0
    socatproc       db      'socat', 0

section .data
    statusdir       db      '/proc/', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ; append 20 bytes

section .bss
    buf             resb    1024
    statusbuf       resb    50
    fd              resd    1
    statusfd        resd    1
    nread           resd    1
    pid             resd    1
    bpos            resd    1    
    dirent          resq    1   
    timer           resb    32      ; struct timer
    act             resb    152     ; struct sigaction

section .text
global _start
_start:
    mov     rbp, rsp
    call    sigact
    ; setup signal handler
    mov     qword [act], sigact             ; -> sa_handler
    mov     qword [act + 8], 4000000h       ; -> sa_flags
    mov     dword [act + 10h], restore      ; -> restores
    mov     rdi, 14
    mov     rsi, act
    mov     rdx, 0
    mov     r10d, 8
    mov     rax, 13             
    syscall                     ; rt_sigaction(SIGALRM, &act, NULL, 8)

    cmp     rax, 0
    jnz     .failedExit         ; if failed

    ; set timer
    mov     dword [timer + 10h], 5  ; 5 seconds
    mov     rax, qword [timer + 10h]
    mov     qword [timer], rax  ; timer.it_interval = timer.it_value
    mov     rdi, 0              ; ITIMER_REAL
    mov     rsi, timer
    mov     rdx, 0
    mov     rax, 38
    syscall                     ; setitimer(ITIMER_REAL, &timer, NULL)

    .endlessLoop:
    jmp     .endlessLoop

    mov     rdi, 0
    mov     rax, 60
    syscall

    .failedExit:
    mov     rdi, -1
    mov     rax, 60
    syscall

sigact:
    push    rbp
    mov     rbp, rsp
    push    rbx
    sub     rsp, 10h
    ; open /proc as directory with readonly privilege
    mov     rdi, procpath
    mov     rsi, 10000h     
    mov     rdx, 0
    mov     rax, 2
    syscall         ; open("/proc", O_DIRECTORY | O_RDONLY)

    cmp     eax, -1
    jnz     .beginKill
    mov     rdi, -1
    mov     rax, 60
    syscall             ; exit(-1)  

    .beginKill:
    mov     [rbp - 4], eax
    ; write promp info
    mov     rdi, 1
    mov     rsi, popupmsg
    mov     rdx, 36
    mov     rax, 1
    syscall

    .readProcess:
    mov     edi, [rbp - 4]
    mov     rsi, buf
    mov     rdx, 1024
    mov     rax, 78
    syscall                 ; getdents(fd, buf, 1024)

    cmp     eax, 0          ; finished reading /proc
    jz     .retProc

    mov     ecx, 0
    mov     [rbp - 0ch], ecx
    mov     [rbp - 8], eax
    .iterProcess:
    mov     ecx, [rbp - 0ch]
    cmp     ecx, [rbp - 8]
    jge     .readProcess
    mov     ebx, ecx        
    add     rbx, buf        ; rbx = (struct dirent) (buf + ecx)
    movzx   eax, word [rbx + 10h] ; eax = [rbx->d_reclen]
    add     ecx, eax        ; ecx += [rbx->d_reclen] next process
    mov     rdx, rbx        
    add     rdx, 12h        ; rdx = &d_name
    mov     [rbp - 0ch], ecx    ; save ecx before calling because ecx is not preserved across function calls
    mov     rdi, rdx
    call    atoi            ; atoi(&rbx->d_name)
    cmp     eax, 0          ; if is pid
    jz      .iterProcess
    mov     [rbp - 10h], eax
    ; create string of pid's status file path
    ; append pid to "/proc/"
    mov     rdx, rbx        
    add     rdx, 12h        ; rdx = &d_name
    mov     rdi, rdx
    call    strlencalc
    mov     ecx, eax
    mov     rsi, rdx
    mov     rdi, statusdir
    add     rdi, 6          ; rdi points to after '/' in "/proc/"
    rep     movsb           
    ; append '/status' to "/proc/<pid>"
    mov     ecx, 8
    mov     rsi, statusstr
    rep     movsb 

    ; open status file
    mov     rdi, statusdir
    mov     rsi, 0      ; O_RDONLY
    mov     rdx, 0
    mov     rax, 2
    syscall             ; open(statusdir, O_RDONLY)

    cmp     eax, -1
    jz      .iterProcess ; if cant open, check next process

    mov     rdi, rax
    mov     rsi, statusbuf
    mov     rdx, 50
    mov     rax, 0
    syscall             ; read(statusfd, statusbuf, 50) read 50 char from status file to statusbuf

    ; check if it is a netcat process
    ; == 'nc'?
    mov     rdi, statusbuf
    add     rdi, 6      ; points to after "Name: "
    mov     rsi, ncproc
    mov     rdx, 2
    call    strncmp
    cmp     eax, 0
    jz      .killProc
    ; == 'ncat' ?
    mov     rdi, statusbuf
    add     rdi, 6      ; points to after "Name: "
    mov     rsi, ncatproc
    mov     rdx, 4
    call    strncmp
    cmp     eax, 0
    jz      .killProc

    ; == 'socat' ?
    mov     rdi, statusbuf
    add     rdi, 6      ; points to after "Name: "
    mov     rsi, socatproc
    mov     rdx, 5
    call    strncmp
    cmp     eax, 0
    jz      .killProc
    jmp     .iterProcess

    .killProc:
    ; write name of process about to kill
    mov     rdi, rbx
    add     rdi, 12h        ; -> d_name
    call    strlencalc
    mov     rdx, rax
    mov     rdi, 1
    mov     rsi, rbx
    add     rsi, 12h        ; -> d_name
    call    println
    ; kill it
    mov     rdi, [rbp - 10h]
    mov     rsi, 9
    mov     rax, 62
    syscall             ; kill(pid, 9)
    jmp     .iterProcess

    .retProc:
    add     rsp, 10h
    pop     rbx
    mov     rsp, rbp
    pop     rbp
    ret

restore:
    mov     rax, 15
    syscall