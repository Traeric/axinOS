; haribote-os boot asm
; TAB=4
[INSTRSET "i486p"]

VBEMODE	EQU		0x105			; 1024 x  768 x 8bit

BOTPAK	EQU		0x00280000		; bootpackのロード先
DSKCAC	EQU		0x00100000		; ディスクキャッシュの場所
DSKCAC0	EQU		0x00008000		; ディスクキャッシュの場所（リアルモード）

; BOOT_INFO的信息
CYLS	EQU		0x0ff0			; 设定启动区
LEDS	EQU		0x0ff1
VMODE	EQU		0x0ff2			; 关于颜色数目的设定 颜色的位数
SCRNX	EQU		0x0ff4			; 分辨率x
SCRNY	EQU		0x0ff6			; 分辨率y
VRAM	EQU		0x0ff8			; 图像缓冲区的开始地址

		ORG		0xc200			; 这个程序将要被装载到内存的地方

; 画面的设定
; 确定VUE是否存在
		MOV		AX,0x9000
		MOV		ES,AX
		MOV		DI,0
		MOV		AX,0x4f00
		INT		0x10
		CMP		AX,0x004f
		JNE		scrn320

; 检查VBE的版本是否在2以上

		MOV		AX,[ES:DI+4]
		CMP		AX,0x0200
		JB		scrn320			; if (AX < 0x0200) goto scrn320

; 查看画面模式0x105是否能够使用

		MOV		CX,VBEMODE
		MOV		AX,0x4f01
		INT		0x10
		CMP		AX,0x004f
		JNE		scrn320

; 画面模式信息的确认
		CMP		BYTE [ES:DI+0x19],8
		JNE		scrn320
		CMP		BYTE [ES:DI+0x1b],4
		JNE		scrn320
		MOV		AX,[ES:DI+0x00]
		AND		AX,0x0080
		JZ		scrn320			; 模式属性的bit是0 所以放弃

; 画面模式切换

		MOV		BX,VBEMODE+0x4000
		MOV		AX,0x4f02
		INT		0x10
		MOV		BYTE [VMODE],8	; VBE显卡 640 x 480 x 8位彩色
		MOV		AX,[ES:DI+0x12]
		MOV		[SCRNX],AX
		MOV		AX,[ES:DI+0x14]
		MOV		[SCRNY],AX
		MOV		EAX,[ES:DI+0x28]
		MOV		[VRAM],EAX
		JMP		keystatus

scrn320:
		MOV		AL,0x13			; VGA显卡 320 x 200 x 8位彩色
		MOV		AH,0x00
		INT		0x10
		MOV		BYTE [VMODE],8	; 记录画面模式
		MOV		WORD [SCRNX],320
		MOV		WORD [SCRNY],200
		MOV		DWORD [VRAM],0x000a0000

; 用bios获取键盘上各种指示灯的状态
keystatus:
		MOV		AH,0x02
		INT		0x16 			; keyboard BIOS
		MOV		[LEDS],AL

; PIC关闭一切中断
; 根据AT兼容机的规格 如果要初始化PIC
; 必须在CLI之前执行 否则有时会挂起
; 随后进行pic的初始化

		MOV		AL,0xff
		OUT		0x21,AL
		NOP						; 如果连续执行OUT指令 有些机种会无法执行  什么都不做 让cpu休息一个时钟的时间
		OUT		0xa1,AL

		CLI						; 禁止CPU级别的中断

; 为了能让cpu能够访问1MB以上的内存空间 设定A20GATE

		CALL	waitkbdout
		MOV		AL,0xd1
		OUT		0x64,AL
		CALL	waitkbdout
		MOV		AL,0xdf			; enable A20
		OUT		0x60,AL
		CALL	waitkbdout

; 切换到保护模式

[INSTRSET "i486p"]				; 想要使用486指令的叙述

		LGDT	[GDTR0]			; 设定临时的GDT
		MOV		EAX,CR0
		AND		EAX,0x7fffffff	; 设置bit31为0 为了禁止分页
		OR		EAX,0x00000001	; 设置bit0为1 为了切换到保护状态
		MOV		CR0,EAX
		JMP		pipelineflush
pipelineflush:
		MOV		AX,1*8			;  可读写的段  32bit
		MOV		DS,AX
		MOV		ES,AX
		MOV		FS,AX
		MOV		GS,AX
		MOV		SS,AX

; bootpack的转送

		MOV		ESI,bootpack	; 转送源
		MOV		EDI,BOTPAK		; 转送目的地
		MOV		ECX,512*1024/4
		CALL	memcpy

; 磁盘数据最终转送到它本来的位置去

; 首先从启动扇区开始

		MOV		ESI,0x7c00		; 转送源
		MOV		EDI,DSKCAC		; 转送目的地
		MOV		ECX,512/4
		CALL	memcpy

; 所有剩下的

		MOV		ESI,DSKCAC0+512	; 转送源
		MOV		EDI,DSKCAC+512	; 转送目的地
		MOV		ECX,0
		MOV		CL,BYTE [CYLS]
		IMUL	ECX,512*18*2/4	; 从柱面数变换为字节数 / 4
		SUB		ECX,512/4		; 减去IPL
		CALL	memcpy

; 必须由asmhead完成的工作已经全部完成 后面交给bootpack做

; bootpack的启动

		MOV		EBX,BOTPAK
		MOV		ECX,[EBX+16]
		ADD		ECX,3			; ECX += 3;
		SHR		ECX,2			; ECX /= 4;
		JZ		skip			; 没有要转送的东西时
		MOV		ESI,[EBX+20]	; 转送源
		ADD		ESI,EBX
		MOV		EDI,[EBX+12]	; 转送目的地
		CALL	memcpy
skip:
		MOV		ESP,[EBX+12]	; 栈初始值
		JMP		DWORD 2*8:0x0000001b

waitkbdout:
		IN		 AL,0x64
		AND		 AL,0x02
		JNZ		waitkbdout		; AND的结果如果不是0 就跳转到waitkbdout
		RET

memcpy:
		MOV		EAX,[ESI]
		ADD		ESI,4
		MOV		[EDI],EAX
		ADD		EDI,4
		SUB		ECX,1
		JNZ		memcpy			; 如果内存没有复制完就继续复制
		RET


		ALIGNB	16  ; 一直添加DB 0 直到填充的总地址能够被16整除
GDT0:
		RESB	8				; NULL selector
		DW		0xffff,0x0000,0x9200,0x00cf	; 可以读写的段(segment)32bit
		DW		0xffff,0x0000,0x9a28,0x0047	; 可以执行的段(segment)32bit(bootpack用)

		DW		0
GDTR0:
		DW		8*3-1
		DD		GDT0

		ALIGNB	16
bootpack:
