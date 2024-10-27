org 0x7c00
BaseOfStack equ 0x7c00
BaseOfLoader equ 0x1000
OffsetOfLoader equ 0x00

RootDirSectors equ 14
SectorNumOfRootDirStart equ 19 ;根目录占用扇区数
SectorNumOfFAT1Start equ 1 ;FAT1起始扇区号 
SectorBalance equ 17

    jmp short Label_Start
    nop
    ;FAT12文件系统引导扇区结构
    BS_OEMName db 'myboot  '
    BPB_BytesPerSec dw 512
    BPB_SecPerClus db 1
    BPB_RavdSecCnt dw 1
    BPB_NumFATs db 2
    BPB_RootEntCnt dw 224
    BPB_TotSec16 dw 2880
    BPB_Media db 0xf0
    BPB_FATSz16 dw 9
    BPB_SecPerTrk dw 18
    BPB_NumHeads dw 2
    BPB_hiddSec dd 0
    BPB_TotSec32 dd 0
    BS_DrvNum db 0
    BS_Reserved1 db 0
    BS_BootSig db 0x29
    BS_VolID dd 0
    BS_VOlLab db 'boot loader'
    BS_FileSysType db 'FAT12   '

Label_Start:
    mov ax, cs
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, BaseOfStack
    ;clean screen
    mov ax, 0600h ;ah=06h滚动窗口功能号 al滚动列数，0为清屏
    mov bx, 0700h ;bh=07h白色
    mov cx, 0 ;滚动范围左上角
    mov dx, 0184fh ;滚动范围右下角
    int 10h
    ;set focus
    mov ax, 0200h ;ah=02h设定光标位置
    mov bx, 0000h
    mov dx, 0000h
    int 10h
    ;display in screen:start booting
    mov ax, 1301h ;ah=13h显示一行字符串
    mov bx, 000fh ;页码/字符属性
    mov dx, 0000h ;游标
    mov cx, 10 ;字符串长度
    push ax
    mov ax, ds
    mov es, ax
    pop ax
    mov bp, StartBootMessage
    int 10h
    ;reset软盘
    xor ah, ah ;清零操作
    xor dl, dl ;dl驱动器号
    int 13h

;search loader.bin
    mov word [SectorNo], SectorNumOfRootDirStart
Label_Search_In_Root_Dir_Begin:
    cmp word [RootDirSizeForLoop], 0
    jz Label_No_LoaderBin
    dec word [RootDirSizeForLoop]

    mov ax, 00h
    mov es, ax
    mov bx, 8000h
    mov ax, [SectorNo]
    mov cl, 1
    call Func_ReadOneSector

    mov si, LoaderFileName ;文件名入栈
    mov di, 8000h
    cld ;清楚directionflag
    mov dx, 10h ;每个扇区的目录项个数(512/32)=16

Label_Search_For_LoaderBin:
    cmp dx, 0 ;遍历目录项；
    jz Label_Goto_Next_Sector_In_Root_Dir
    dec dx
    mov cx, 11 ;目录项文件名长度

Label_Cmp_FileName:
    cmp cx, 0 ;cx中存储字符长度
    jz Label_FileName_Found
    dec cx
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
    mov si, LoaderFileName
    jmp Label_Search_For_LoaderBin

Label_Goto_Next_Sector_In_Root_Dir:
    add word [SectorNo], 1
    jmp Label_Search_In_Root_Dir_Begin

;找不到loader dpsplay on screen：error
Label_No_LoaderBin:
    mov ax, 1301h
    mov bx, 008ch
    mov dx, 0100h
    mov cx, 21
    push ax
    mov ax, ds
    mov es, ax
    pop ax
    mov bp, NoLoaderMessage
    int 10h
    jmp $
;找到loader
Label_FileName_Found:
    mov ax, RootDirSectors
    and di, 0ffe0h
    add di, 01ah
    mov cx, word [es:di]
    push cx
    add cx, ax
    add cx, SectorBalance
    mov ax, BaseOfLoader
    mov es, ax
    mov bx, OffsetOfLoader
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
    call Func_GetFATEntry
    cmp ax, 0fffh
    jz Label_File_Loaded
    push ax
    mov dx, RootDirSectors
    add ax, dx
    add ax, SectorBalance
    add bx, [BPB_BytesPerSec]
    jmp Label_Go_On_Loading_File

Label_File_Loaded:
    jmp BaseOfLoader:OffsetOfLoader 

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

RootDirSizeForLoop dw RootDirSectors ;14
SectorNo dw 0
Odd db 0

StartBootMessage: db "Start Boot"
NoLoaderMessage: db "Error:No loader found"
LoaderFileName: db "LOADER  BIN",0 ;8byte文件名，3byte扩展名

    ;fill zero until whole sector
    times 510 - ($ - $$) db 0 
    dw 0xaa55










