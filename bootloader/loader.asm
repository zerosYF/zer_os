;检测硬件信息，处理器模式切换，向内核传递数据
org 10000h
    jmp Label_Start
%include "fat12.inc"

BaseOfKernelFile equ 0x00
OffsetOfKernelFile equ 0x100000

BaseTmpOfKernelAddr equ 0x00
OffsetTmpOfKernelFile equ 0x7E00

MemoryStructBufferAddr equ 0x7E00

[SECTION gdt]
LABEL_GDT: dd 0, 0
LABEL_DESC_CODE32: dd 0x0000FFFF,0x00CF9A00
LABEL_DESC_DATA32: dd 0x0000FFFF,0x00CF9200

GdtLen equ $ - LABEL_GDT
GdtPtr dw GdtLen - 1
dd LABEL_GDT

SelectorCode32 equ LABEL_DESC_CODE32 - LABEL_GDT
SelectorData32 equ LABEL_DESC_DATA32 - LABEL_GDT

[SECTION gdt64]
LABEL_GDT64: dq 0x0000000000000000
LABEL_DESC_CODE64: dq 0x0020980000000000
LABEL_DESC_DATA64: dq 0x0000920000000000

GdtLen64 equ $ - LABEL_GDT64
GdtPtr64 dw GdtLen64 - 1
dd LABEL_GDT64

SelectorCode64 equ LABEL_DESC_CODE64 - LABEL_GDT64
SelectorData64 equ LABEL_DESC_DATA64 - LABEL_GDT64

[SECTION .s16]
[BITS 16]
Label_Start:
    mov ax, cs
    mov ds, ax
    mov es, ax
    mov ax, 0x00
    mov ss, ax
    mov sp, 0x7c00
;display in screen
    mov ax, 1301h
    mov bx, 000fh
    mov dx, 0200h
    mov cx, 12
    push ax
    mov ax, ds
    mov es, ax
    pop ax
    mov bp, StartLoaderMessage
    int 10h

;open address A20 扩展内存空间，使得FS段寄存器在实模式下寻址能力超过1MB
    ;A20快速门
    push ax
    in al, 92h
    or al, 00000010b
    out 92h, al
    pop ax

    cli ;关闭外部中断
    ;加载保护模式结构
    db 0x66
    lgdt [GdtPtr]
    ;cr0第0位置1开启保护模式
    mov eax, cr0
    or eax, 1 
    mov cr0, eax
    ;fs段寄存器加载新数据段值
    mov ax, SelectorData32
    mov fs, ax
    ;退出保护模式
    mov eax, cr0
    and al, 11111110b
    mov cr0, eax
    sti ;开启中断
;重启floppy
    xor ah, ah
    xor dl, dl
    int 13h

;search kernel.bin文件
    mov word [SectorNo], SectorNumOfRootDirStart
Label_Search_In_Root_Dir_Begin:
    cmp word [RootDirSizeForLoop], 0 ;14个sector在rootdir中
    jz Label_No_LoaderBin
    dec word [RootDirSizeForLoop]

    mov ax, 00h
    mov es, ax
    mov bx, 8000h
    mov ax, [SectorNo]
    mov cl, 1
    call Func_ReadOneSector

    mov si, KernelFileName ;文件名入栈
    mov di, 8000h
    cld ;清除directionflag
    mov dx, 10h ;每个扇区的目录项个数(512/32)=16

;在某一个扇区中寻找文件
Label_Search_For_LoaderBin_In_One_Sector:
    cmp dx, 0 ;遍历目录项；
    jz Label_Goto_Next_Sector_In_Root_Dir
    dec dx
    mov cx, 11 ;目录项文件名长度

Label_Cmp_FileName:
    cmp cx, 0 ;cx中存储字符长度
    jz Label_FileName_Found
    dec cx
    ;字符对比
    lodsb
    cmp al, byte [es:di]
    jz Label_Go_On
    jmp Label_Different

Label_Go_On:
    inc di
    jmp Label_Cmp_FileName

Label_Different:
    and di, 0ffe0h ;清除di中低5位
    add di, 20h
    mov si, KernelFileName
    jmp Label_Search_For_LoaderBin_In_One_Sector

Label_Goto_Next_Sector_In_Root_Dir:
    add word [SectorNo], 1
    jmp Label_Search_In_Root_Dir_Begin

;找不到kernel dpsplay on screen：error
Label_No_LoaderBin:
    mov ax, 1301h
    mov bx, 008ch
    mov dx, 0300h
    mov cx, 21
    push ax
    mov ax, ds
    mov es, ax
    pop ax
    mov bp, NoKernelMessage
    int 10h
    jmp $
;找到kernel.bin,读取到临时转存空间
Label_FileName_Found:
    mov ax, RootDirSectors
    and di, 0ffe0h
    add di, 01ah
    mov cx, word [es:di]
    push cx
    add cx, ax
    add cx, SectorBalance
    mov eax, BaseTmpOfKernelAddr
    mov es, eax
    mov bx, OffsetTmpOfKernelFile
    mov ax, cx

Label_Go_On_Loading_File:
    push ax
    push bx
    mov ah, 0eh
    mov al, '.'
    mov bl, 0fh
    int 10h
    pop bx
    pop ax
    
    mov cl, 1
    call Func_ReadOneSector
    pop ax

    push cx
    push eax
    push fs
    push edi
    push ds
    push esi

    mov cx, 200h
    mov ax, BaseOfKernelFile
    mov fs, ax
    mov edi, dword [OffsetOfKernelFileCount]

    mov ax, BaseTmpOfKernelAddr
    mov ds, ax
    mov esi, OffsetTmpOfKernelFile

Label_Mov_Kernel:
    mov al, byte [ds:esi]
    mov byte [fs:edi], al
    inc esi
    inc edi
    loop Label_Mov_Kernel ;逐字节读取
    mov eax, 0x1000
    mov ds, eax
    mov dword [OffsetOfKernelFileCount], edi

    pop esi
    pop ds
    pop edi
    pop fs
    pop eax
    pop cx

    call Func_GetFATEntry
    cmp ax, 0fffh
    jz Label_File_Loaded
    push ax
    mov dx, RootDirSectors
    add ax, dx
    add ax, SectorBalance
    jmp Label_Go_On_Loading_File

Label_File_Loaded:
    mov ax, 0b800h
    mov gs, ax
    mov ah, 0fh
    mov al, 'X'
    mov [gs:((80 * 0 + 39) * 2)], ax ;屏幕0行，39列
    ;jmp $
;已将内核程序从floppy加载到内存中
;关闭软驱
KillMotor:
    push dx
    mov dx, 03f2h
    mov al, 0
    out dx, al
    pop dx

;get memory address size type
    mov ax, 1301h
    mov bx, 000fh
    mov dx, 0400h
    mov cx, 24
    push ax
    mov ax, ds
    mov es, ax
    pop ax
    mov bp, StartGetMemStructMessage
    int 10h

    mov ebx, 0
    mov ax, 0x00
    mov es, ax
    mov di, MemoryStructBufferAddr

Label_Get_Mem_Struct:
    mov	eax, 0x0E820
	mov	ecx, 20
	mov	edx, 0x534D4150
	int	15h
	jc	Label_Get_Mem_Fail
	add	di,	20

	cmp	ebx, 0
	jne	Label_Get_Mem_Struct
	jmp	Label_Get_Mem_OK

Label_Get_Mem_Fail:
	mov	ax,	1301h
	mov	bx,	008Ch
	mov	dx,	0500h
	mov	cx,	23
	push ax
	mov	ax,	ds
	mov	es,	ax
	pop	ax
	mov	bp,	GetMemErrMessage
	int	10h
	jmp	$

Label_Get_Mem_OK:
    mov ax, 1301h
    mov bx, 000fh
    mov dx, 0600h
    mov cx, 29
    push ax
    mov ax, ds
    mov es, ax
    pop ax
    mov bp, GetMemOKMessage
    int 10h

;get SVGA information
    mov ax, 1301h
    mov bx, 000fh
    mov dx, 0800h
    mov cx, 23
    push ax
    mov ax, ds
    mov es, ax
    pop ax
    mov bp, StartGetSVGA_VBEInfoMessage
    int 10h

    mov ax, 0x00
    mov es, ax
    mov di, 0x8000
    mov ax, 4f00h

    int 10h

    cmp ax, 004fh
    jz .KO

;失败
    mov ax, 1301h
    mov bx, 008ch
    mov dx, 0900h
    mov cx, 23
    push ax
    mov ax, ds
    mov es, ax
    pop ax
    mov bp, GetSVGA_VBEInfoErrMessage
    int 10h

    jmp $

.KO:
    mov ax, 1301h
    mov bx, 000fh
    mov dx, 0a00h
    mov cx, 29
    push ax
    mov ax, ds
    mov es, ax
    pop ax
    mov bp, GetSVGA_VBEInfoOKMessage
    int 10h

;get SVGA mode info
    mov ax, 1301h
    mov bx, 000fh
    mov dx, 0c00h
    mov cx, 24
    push ax
    mov ax, ds
    mov es, ax
    pop ax
    mov bp, StartGetSVGAModeInfoMessage
    int 10h

    mov ax, 0x00
    mov es, ax
    mov si, 0x800e

    mov esi, dword [es:si]
    mov edi, 0x8200

Label_SVGA_Mode_Info_Get:
    mov cx, word [es:esi]
;diplay SVGA mode information
    push ax

    mov ax, 00h
    mov al, ch
    call Label_DisplayAL

    mov	ax,	00h
	mov	al,	cl	
	call Label_DisplayAL

    pop ax

    cmp cx, 0ffffh
    jz Label_SVGA_Mode_Info_Finish

    mov ax, 4f01h
    int 10h

    cmp ax, 004fh
    jnz Label_SVGA_Mode_Info_Fail

    add esi, 2
    add edi, 0x100

    jmp Label_SVGA_Mode_Info_Get

Label_SVGA_Mode_Info_Fail:
    mov ax, 1301h
    mov bx, 008ch
    mov dx, 0d00h
    mov cx, 24
    push ax
    mov ax, ds
    mov es, ax
    pop ax
    mov bp, GetSVGAModeInfoErrMessage
    int 10h

Label_Set_SVGA_Mode_VESA_VBE_FAIL:
    jmp $

Label_SVGA_Mode_Info_Finish:
    mov	ax,	1301h
	mov	bx,	000Fh
	mov	dx,	0E00h
	mov	cx,	30
	push ax
	mov	ax,	ds
	mov	es,	ax
	pop	ax
	mov	bp,	GetSVGAModeInfoOKMessage
	int	10h

    ;jmp $

;set SVGA mode(VESA VBE)
    mov ax, 4f02h
    mov bx, 4180h
    int 10h
    cmp ax, 004fh
    jnz Label_Set_SVGA_Mode_VESA_VBE_FAIL
    ;jmp $
;模式转换 实模式->保护模式->长模式
;INIT IDT GDT goto protect mode
    cli     ;关中断
    lgdt [GdtPtr] ;将GDT基地址和长度加载到GDTR寄存器
    lidt [IDT_POINTER]

    mov eax, cr0 ;执行cr0 pe标志位开启分页
    or eax, 1
    mov cr0, eax
    jmp dword SelectorCode32:GO_TO_TMP_Protect

[SECTION .s32]
[BITS 32]
GO_TO_TMP_Protect:
    mov ax, 0x10
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov ss, ax
    mov esp, 7e00h
    call support_long_mode
    test eax, eax
    jz no_support
;init 临时页表
    mov	dword [0x90000], 0x91007
	mov	dword [0x90800], 0x91007		
	mov	dword [0x91000], 0x92007
	mov	dword [0x92000], 0x000083
	mov	dword [0x92008], 0x200083
	mov	dword [0x92010], 0x400083
	mov	dword [0x92018], 0x600083
	mov	dword [0x92020], 0x800083
	mov	dword [0x92028], 0xa00083
;load GDTR
    lgdt [GdtPtr64]
    mov ax, 0x10
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    mov esp, 7e00h
;open PAE
    mov eax, cr4
    bts eax, 5
    mov cr4, eax
;load cr3
    mov eax, 0x90000
    mov cr3, eax
;enable long mode
    mov ecx, 0c0000080h ;IA32-EFER
    rdmsr
    bts eax, 8
    wrmsr
;open PE and paging
    mov eax, cr0
    bts eax, 0
    bts eax, 31
    mov cr0, eax
    jmp SelectorCode64:OffsetOfKernelFile
    ;jmp $

;test support long mode or not
support_long_mode:
    mov eax, 0x80000000
    cpuid
    cmp eax, 0x80000001
    setnb al
    jb support_long_mode_done
    mov eax, 0x80000001
    cpuid
    bt edx, 29
    setc al
support_long_mode_done:
    movzx eax, al
    ret
no_support:
    jmp $

[SECTION .s16lib]
[BITS 16]
;软盘读sector
;参数：ax=待读取的磁盘起始扇区号 cl=读入的扇区数量 es:bx目标缓冲区起始地址
Func_ReadOneSector:
    push bp
    mov bp, sp
    sub esp, 2 ;开辟两个字节栈空间
    mov byte [bp - 2], cl ;cl存入
    push bx
    mov bl, [BPB_SecPerTrk]
    div bl ;LBA扇区号/每磁道扇区数
    inc ah ;道内的起始扇区号；
    mov cl, ah ;cl扇区号
    mov dh, al ;dh目标磁道号
    shr al, 1
    mov ch, al ;ch磁道号低8位
    and dh, 1
    pop bx
    mov dl, [BS_DrvNum] ;驱动器号
Label_Go_On_Reading:
    mov ah, 2 
    mov al, byte [bp - 2] ;al读入扇区数
    int 13h ;读取磁盘扇区
    jc Label_Go_On_Reading
    add esp, 2
    pop bp
    ret

Func_GetFATEntry:
    push es
    push bx
    push ax
    mov ax, 00
    mov es, ax
    pop ax
    mov byte [Odd], 0
    mov bx, 3
    mul bx
    mov bx, 2
    div bx
    cmp dx, 0
    jz Label_Even
    mov byte [Odd], 1

Label_Even:
    xor dx, dx
    mov bx, [BPB_BytesPerSec]
    div bx
    push dx
    mov bx, 8000h
    add ax, SectorNumOfFAT1Start
    mov cl, 2
    call Func_ReadOneSector

    pop dx
    add bx, dx
    mov ax, [es:bx]
    cmp byte [Odd], 1
    jnz Label_Even_2
    shr ax, 4

Label_Even_2:
    and ax, 0fffh
    pop bx
    pop es
    ret

; display num in al
;显示16进制数值
Label_DisplayAL:
    push ecx
    push edx
    push edi
    mov edi, [DisplayPosition] ;游标位置
    mov ah, 0fh ;字体颜色
    mov dl, al
    shr al, 4
    mov ecx, 2
.begin:
    and al, 0fh
    cmp al, 9
    ja .1
    add al, '0'
    jmp .2
.1:
    sub al, 0ah
    add al, 'A'
.2:
    mov [gs:edi], ax
    add edi, 2
    mov al, dl
    loop .begin
    mov [DisplayPosition], edi
    pop edi
    pop edx
    pop ecx

    ret

IDT:
    times 0x50 dq 0
IDT_END:

IDT_POINTER:
    dw IDT_END - IDT - 1
    dd IDT

RootDirSizeForLoop dw RootDirSectors
SectorNo dw 0
Odd db 0

OffsetOfKernelFileCount dd OffsetOfKernelFile
DisplayPosition dd 0

StartLoaderMessage: db "Start Loader"
NoKernelMessage: db "Error no kernel found"
KernelFileName: db "KERNEL  BIN",0

StartGetMemStructMessage: db "Start Get Memory Struct."
GetMemOKMessage: db "Get Memory Struct SUCCESSFUL!"
GetMemErrMessage: db "Get Memory Struct ERROR"

StartGetSVGA_VBEInfoMessage: db "Start Get SVGA VBE Info"
GetSVGA_VBEInfoOKMessage: db "Get SVGA VBE Info SUCCESSFUL!"
GetSVGA_VBEInfoErrMessage: db "Get SVGA VBE Info ERROR"

StartGetSVGAModeInfoMessage: db	"Start Get SVGA Mode Info"
GetSVGAModeInfoOKMessage: db "Get SVGA Mode Info SUCCESSFUL!"
GetSVGAModeInfoErrMessage: db "Get SVGA Mode Info ERROR"