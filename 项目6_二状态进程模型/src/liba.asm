; @Author: Jed
; @Description: 内核的汇编函数部分
; @Date: 2019-03-21
; @LastEditTime: 2019-03-23
BITS 16
%include "macro.asm"

[global clearScreen]
[global printInPos]
[global putchar_c]
[global getch]
[global powerOff]
[global reBoot]
[global getUsrProgNum]
[global getUsrProgName]
[global getUsrProgSize]
[global getUsrProgCylinder]
[global getUsrProgHead]
[global getUsrProgSector]
[global getUsrProgAddrSeg]
[global getUsrProgAddrOff]
[global loadAndRun]
[global loadProcessMem]
[global getDateYear]
[global getDateMonth]
[global getDateDay]
[global getDateHour]
[global getDateMinute]
[global getDateSecond]
[global syscaller]


clearScreen:                  ; 函数：清屏
    push ax
    mov ax, 0003h
    int 10h                   ; 中断调用，清屏
    pop ax
    retf

printInPos:                   ; 函数：在指定位置显示字符串
    pusha                     ; 保护现场（压栈16字节）
    mov si, sp                ; 由于代码中要用到bp，因此使用si来为参数寻址
    add si, 16+4              ; 首个参数的地址
    mov	ax, cs                ; 置其他段寄存器值与CS相同
    mov	ds, ax                ; 数据段
    mov	bp, [si]              ; BP=当前串的偏移地址
    mov	ax, ds                ; ES:BP = 串地址
    mov	es, ax                ; 置ES=DS
    mov	cx, [si+4]            ; CX = 串长（=9）
    mov	ax, 1301h             ; AH = 13h（功能号）、AL = 01h（光标置于串尾）
    mov	bx, 0007h             ; 页号为0(BH = 0) 黑底白字(BL = 07h)
    mov dh, [si+8]            ; 行号=0
    mov	dl, [si+12]           ; 列号=0
    int	10h                   ; BIOS的10h功能：显示一行字符
    popa                      ; 恢复现场（出栈16字节）
    retf

putchar_c:                    ; 函数：在光标处打印一个彩色字符
    pusha
    push ds
    push es
    mov bx, 0                 ; 页号=0
    mov ah, 03h               ; 功能号：获取光标位置
    int 10h                   ; dh=行，dl=列
    mov ax, cs
    mov ds, ax                ; ds = cs
    mov es, ax                ; es = cs
    mov bp, sp
    add bp, 20+4              ; 参数地址，es:bp指向要显示的字符
    mov cx, 1                 ; 显示1个字符
    mov ax, 1301h             ; AH = 13h（功能号）、AL = 01h（光标置于串尾）
    mov bh, 0                 ; 页号
    mov bl, [bp+4]            ; 颜色属性
    int 10h                   ; 显示字符串（1个字符）
    pop es
    pop ds
    popa
    retf

getch:                        ; 函数：读取一个字符到tempc（无回显）
    mov ah, 0                 ; 功能号
    int 16h                   ; 读取字符，al=读到的字符
    mov ah, 0                 ; 为返回值做准备
    retf

powerOff:                     ; 函数：强制关机
    mov ax, 2001H
    mov dx, 1004H
    out dx, ax

reBoot:
    int 19h

getUsrProgNum:
    mov al, [addr_upinfo]
    mov ah, 0
    retf

getUsrProgName:
    push bp
    push bx
    mov bp, sp
    add bp, 4+4
    mov al, [bp]              ; al=progid
    add al, -1                ; al=progid-1
    mov bl, 26                ; 每个用户程序的信息块大小为26字节
    mul bl                    ; ax = (progid-1) * 26
    add ax, 1                 ; ax = 1 + (progid-1) * 26
    add ax, 1                 ; 加上name在用户程序信息中的偏移
    add ax, addr_upinfo       ; 不用方括号，因为就是要访问字符串所在的地址
    pop bx
    pop bp
    retf

getUsrProgSize:
    push bp
    push bx
    mov bp, sp
    add bp, 4+4
    mov al, [bp]              ; al=progid
    add al, -1                ; al=progid-1
    mov bl, 26                ; 每个用户程序的信息块大小为26字节
    mul bl                    ; ax = (progid-1) * 26
    add ax, 1                 ; ax = 1 + (progid-1) * 26
    add ax, 17                ; 加上size在用户程序信息中的偏移
    mov bx, ax
    add bx, addr_upinfo
    mov ax, [bx]
    pop bx
    pop bp
    retf

getUsrProgCylinder:
    push bp
    push bx
    mov bp, sp
    add bp, 4+4
    mov al, [bp]              ; al=progid
    add al, -1                ; al=progid-1
    mov bl, 26                ; 每个用户程序的信息块大小为26字节
    mul bl                    ; ax = (progid-1) * 26
    add ax, 1                 ; ax = 1 + (progid-1) * 26
    add ax, 19                ; 加上cylinder在用户程序信息中的偏移
    mov bx, ax
    add bx, addr_upinfo
    mov al, [bx]
    mov ah, 0
    pop bx
    pop bp
    retf

getUsrProgHead:
    push bp
    push bx
    mov bp, sp
    add bp, 4+4
    mov al, [bp]              ; al=progid
    add al, -1                ; al=progid-1
    mov bl, 26                ; 每个用户程序的信息块大小为26字节
    mul bl                    ; ax = (progid-1) * 26
    add ax, 1                 ; ax = 1 + (progid-1) * 26
    add ax, 20                ; 加上head在用户程序信息中的偏移
    mov bx, ax
    add bx, addr_upinfo
    mov al, [bx]
    mov ah, 0
    pop bx
    pop bp
    retf

getUsrProgSector:
    push bp
    push bx
    mov bp, sp
    add bp, 4+4
    mov al, [bp]              ; al=progid
    add al, -1                ; al=progid-1
    mov bl, 26                ; 每个用户程序的信息块大小为26字节
    mul bl                    ; ax = (progid-1) * 26
    add ax, 1                 ; ax = 1 + (progid-1) * 26
    add ax, 21                ; 加上sector在用户程序信息中的偏移
    mov bx, ax
    add bx, addr_upinfo
    mov al, [bx]
    mov ah, 0
    pop bx
    pop bp
    retf

getUsrProgAddrSeg:
    push bp
    push bx
    mov bp, sp
    add bp, 4+4
    mov al, [bp]              ; al=progid
    add al, -1                ; al=progid-1
    mov bl, 26                ; 每个用户程序的信息块大小为26字节
    mul bl                    ; ax = (progid-1) * 26
    add ax, 1                 ; ax = 1 + (progid-1) * 26
    add ax, 22                ; 加上addr在用户程序信息中的偏移
    mov bx, ax
    add bx, addr_upinfo
    mov ax, [bx]
    pop bx
    pop bp
    retf

getUsrProgAddrOff:
    push bp
    push bx
    mov bp, sp
    add bp, 4+4
    mov al, [bp]              ; al=progid
    add al, -1                ; al=progid-1
    mov bl, 26                ; 每个用户程序的信息块大小为26字节
    mul bl                    ; ax = (progid-1) * 26
    add ax, 1                 ; ax = 1 + (progid-1) * 26
    add ax, 24                ; 加上addr在用户程序信息中的偏移
    mov bx, ax
    add bx, addr_upinfo
    mov ax, [bx]
    pop bx
    pop bp
    retf

loadAndRun:                   ; 函数：从软盘中读取扇区到内存并运行用户程序
    pusha
    mov bp, sp
    add bp, 16+4              ; 参数地址
    LOAD_TO_MEM [bp+12], [bp], [bp+4], [bp+8], [bp+16], [bp+20]
    call dword pushCsIp       ; 用此技巧来手动压栈CS、IP
    pushCsIp:
    mov si, sp                ; si指向栈顶
    mov word[si], afterrun    ; 修改栈中IP的值，这样用户程序返回回来后就可以继续执行了
    push word[bp+16]          ; 用户程序的段地址CS
    push word[bp+20]          ; 用户程序的偏移量IP
    retf                      ; 段间跳转
    afterrun:
    popa
    retf


getDateYear:                  ; 函数：从CMOS获取当前年份
    mov al, 9
    out 70h, al
    in al, 71h
    mov ah, 0
    retf

getDateMonth:                 ; 函数：从CMOS获取当前月份
    mov al, 8
    out 70h, al
    in al, 71h
    mov ah, 0
    retf

getDateDay:                   ; 函数：从CMOS获取当前日期
    mov al, 7
    out 70h, al
    in al, 71h
    mov ah, 0
    retf

getDateHour:                  ; 函数：从CMOS获取当前小时
    mov al, 4
    out 70h, al
    in al, 71h
    mov ah, 0
    retf

getDateMinute:                ; 函数：从CMOS获取当前分钟
    mov al, 2
    out 70h, al
    in al, 71h
    mov ah, 0
    retf

getDateSecond:                ; 函数：从CMOS获取当前秒钟
    mov al, 0
    out 70h, al
    in al, 71h
    mov ah, 0
    retf

[extern sys_showOuch]
[extern sys_toUpper]
[extern sys_toLower]
[extern sys_atoi]
[extern sys_itoa]
[extern sys_printInPos]
syscaller:
    push ds
    push si                   ; 用si作为内部临时寄存器
    mov si, cs
    mov ds, si                ; ds = cs
    mov si, ax
    shr si, 8                 ; si = 功能号
    add si, si                ; si = 2 * 功能号
    call [sys_table+si]       ; 系统调用函数
    pop si
    pop ds
    iret                      ; int 21h中断返回
    sys_table:                ; 存放功能号与系统调用函数映射的表
        dw sys_showOuch, sys_toUpper, sys_toLower
        dw sys_atoi, sys_itoa, sys_printInPos

loadProcessMem:
    pusha
    mov bp, sp
    add bp, 16+4              ; 参数地址
    LOAD_TO_MEM [bp+12], [bp], [bp+4], [bp+8], [bp+16], [bp+20]

    
    popa
    retf



global Timer
global timer_flag

Timer:
    cli
    cmp word[cs:timer_flag], 0
    je QuitTimer

    push ss
    push gs
    push fs
    push es
    push ds
    push di
    push si
    push bp
    push sp
    push bx
    push dx
    push cx
    push ax
    call pcbSave
    add sp, 16+2              ; 丢弃参数

    call pcbSchedule

pcbRestart:                   ; 不是函数
    mov si, pcb_table
    mov ax, 34
    mul word[cs:current_process_id]
    add si, ax

    mov ax, [cs:si+0]
    mov cx, [cs:si+2]
    mov dx, [cs:si+4]
    mov bx, [cs:si+6]
    mov sp, [cs:si+8]
    mov bp, [cs:si+10]
    mov di, [cs:si+14]
    mov ds, [cs:si+16]
    mov es, [cs:si+18]
    mov fs, [cs:si+20]
    mov gs, [cs:si+22]
    mov ss, [cs:si+24]
    add sp, 11*2

    push word[cs:si+30]       ; flags
    push word[cs:si+28]       ; cs
    push word[cs:si+26]       ; ip

    push word[cs:si+12]       ; 恢复si
    pop si

QuitTimer:
    push ax
    mov al, 20h
    out 20h, al
    out 0A0h, al
    pop ax
    sti
    iret

    timer_flag dw 0
    current_process_id dw 0

%macro ProcessControlBlock 2
    dw 0                      ; ax，偏移量=+0
    dw 0                      ; cx，偏移量=+2
    dw 0                      ; dx，偏移量=+4
    dw 0                      ; bx，偏移量=+6
    dw 0FE00h                 ; sp，偏移量=+8
    dw 0                      ; bp，偏移量=+10
    dw 0                      ; si，偏移量=+12
    dw 0                      ; di，偏移量=+14
    dw %1                     ; ds，偏移量=+16
    dw %1                     ; es，偏移量=+18
    dw %1                     ; fs，偏移量=+20
    dw 0B800h                 ; gs，偏移量=+22
    dw %1                     ; ss，偏移量=+24
    dw 0                      ; ip，偏移量=+26
    dw %1                     ; cs，偏移量=+28
    dw 512                    ; flags，偏移量=+30
    db 0                      ; id，进程ID，偏移量=+32
    db %2                      ; state，{0:新建态; 1:就绪态; 2:运行态}，偏移量=+33
%endmacro

pcb_table:
pcb_0: ProcessControlBlock 0, 0
pcb_1: ProcessControlBlock 1000h, 1
pcb_2: ProcessControlBlock 2000h, 1
pcb_3: ProcessControlBlock 0, 0
pcb_4: ProcessControlBlock 0, 0
pcb_5: ProcessControlBlock 0, 0
pcb_6: ProcessControlBlock 0, 0
pcb_7: ProcessControlBlock 0, 0

pcbSave:
    pusha
    mov bp, sp
    add bp, 16+2
    mov di, pcb_table

    mov ax, 34
    mul word[cs:current_process_id]
    add di, ax

    mov ax, [bp]
    mov [cs:di], ax
    mov ax, [bp+2]
    mov [cs:di+2], ax
    mov ax, [bp+4]
    mov [cs:di+4], ax
    mov ax, [bp+6]
    mov [cs:di+6], ax
    mov ax, [bp+8]
    mov [cs:di+8], ax
    mov ax, [bp+10]
    mov [cs:di+10], ax
    mov ax, [bp+12]
    mov [cs:di+12], ax
    mov ax, [bp+14]
    mov [cs:di+14], ax
    mov ax, [bp+16]
    mov [cs:di+16], ax
    mov ax, [bp+18]
    mov [cs:di+18], ax
    mov ax, [bp+20]
    mov [cs:di+20], ax
    mov ax, [bp+22]
    mov [cs:di+22], ax
    mov ax, [bp+24]
    mov [cs:di+24], ax
    mov ax, [bp+26]
    mov [cs:di+26], ax
    mov ax, [bp+28]
    mov [cs:di+28], ax
    mov ax, [bp+30]
    mov [cs:di+30], ax

    popa
    ret

pcbSchedule:
    pusha
    inc word[cs:current_process_id]
    cmp word[cs:current_process_id], 3
    jnz byebye
    mov word[cs:current_process_id], 1
    byebye:
    ; mov si, pcb_table
    ; mov ax, 34
    ; mul word[cs:current_process_id]
    ; add si, ax                ; si指向当前PCB的首地址
    ; mov word[cs:si+33], 1     ; 设置state为就绪态
    ; try_next_pcb:
    ;     inc word[cs:current_process_id]
    ;     add si, 34            ; si指向下一PCB的首地址
    ;     cmp word[cs:current_process_id], 7
    ;     jna pcb_not_exceed    ; 若id递增到8，则将其恢复为1
    ;     mov word[cs:current_process_id], 1
    ;     ret
    ;     mov si, pcb_table
    ;     add si, 34
    ;     pcb_not_exceed:
    ;     cmp word[cs:si+33], 1 ; 如果下一进程处于就绪态
    ;     jne try_next_pcb      ; 调度完毕
    ; mov word[cs:si+33], 2     ; 设置为运行态
    popa
    ret



global debug_int48h
debug_int48h:
int 48h
retf