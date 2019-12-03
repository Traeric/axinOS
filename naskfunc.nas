; naskfunc
; TAB=4

[FORMAT "WCOFF"]				; 制作目标文件的模式 这里是WCOFF
[INSTRSET "i486p"]              ; 允许给486cpu使用
[BITS 32]						; 设定成32位机器语言模式


; 制作目标文件信息

[FILE "naskfunc.nas"]			; 源文件名信息

	; 程序中包含的函数名
	GLOBAL	_io_hlt, _io_cli, _io_sti, _io_stihlt
	GLOBAL	_io_in8,  _io_in16,  _io_in32
	GLOBAL	_io_out8, _io_out16, _io_out32
	GLOBAL	_io_load_eflags, _io_store_eflags
	GLOBAL	_load_gdtr, _load_idtr
	GLOBAL	_load_cr0, _store_cr0
	GLOBAL	_load_tr
	GLOBAL	_asm_inthandler20, _asm_inthandler21
	GLOBAL	_asm_inthandler27, _asm_inthandler2c
	GLOBAL	_asm_inthandler0c, _asm_inthandler0d
	GLOBAL	_asm_end_app, _memtest_sub
	GLOBAL	_farjmp, _farcall
	GLOBAL	_asm_hrb_api, _start_app
	EXTERN	_inthandler20, _inthandler21
	EXTERN	_inthandler27, _inthandler2c
	EXTERN	_inthandler0c, _inthandler0d
	EXTERN	_hrb_api


; 实际的函数

[SECTION .text]		; 目标文件中写了这些之后再写程序

_io_hlt:	; void io_hlt(void);
	HLT
	RET   ; 类似于return的作用

; 这个函数的作用是将数据写到指定的地址中
_write_mem8:
	mov ecx, [esp + 4]   ; esp + 4里面放的是地址
	mov al, [esp + 8]  ; esp + 8里面放的是数据
	mov [ecx], al  ; 现在将数据写到地址中
	ret

_io_cli:	; void io_cli(void);
	CLI
	RET

_io_sti:	; void io_sti(void);
	STI
	RET

_io_stihlt:	; void io_stihlt(void);
	STI
	HLT
	RET

_io_in8:	; int io_in8(int port);
	MOV		EDX,[ESP+4]		; port
	MOV		EAX,0
	IN		AL,DX
	RET

_io_in16:	; int io_in16(int port);
	MOV		EDX,[ESP+4]		; port
	MOV		EAX,0
	IN		AX,DX
	RET

_io_in32:	; int io_in32(int port);
	MOV		EDX,[ESP+4]		; port
	IN		EAX,DX
	RET

_io_out8:	; void io_out8(int port, int data);
	MOV		EDX,[ESP+4]		; port
	MOV		AL,[ESP+8]		; data
	OUT		DX,AL
	RET

_io_out16:	; void io_out16(int port, int data);
	MOV		EDX,[ESP+4]		; port
	MOV		EAX,[ESP+8]		; data
	OUT		DX,AX
	RET

_io_out32:	; void io_out32(int port, int data);
	MOV		EDX,[ESP+4]		; port
	MOV		EAX,[ESP+8]		; data
	OUT		DX,EAX
	RET

_io_load_eflags:	; int io_load_eflags(void);
	; 这里的操作是先将EFLAGS中的值压入栈中 然后将压入栈中的数据弹出到EAX寄存器中
	PUSHFD		; PUSH EFLAGS 将EFLAGS中的值压入栈中
	POP		EAX
	RET

_io_store_eflags:	; void io_store_eflags(int eflags);
	; 这里的操作是先将EAX中的值压入栈中 然后将压入栈中的数据弹出到EFLAGS寄存器中
	MOV		EAX,[ESP+4]
	PUSH	EAX
	POPFD		; POP EFLAGS 将栈中的值弹出到EFLAGS
	RET
_load_gdtr:		; void load_gdtr(int limit, int addr);
	MOV		AX,[ESP+4]		; limit
	MOV		[ESP+6],AX
	LGDT	[ESP+6]
	RET

_load_idtr:		; void load_idtr(int limit, int addr);
	MOV		AX,[ESP+4]		; limit
	MOV		[ESP+6],AX
	LIDT	[ESP+6]
	RET
	
_asm_inthandler20:
	PUSH	ES
	PUSH	DS
	PUSHAD
	MOV		EAX,ESP
	PUSH	EAX
	MOV		AX,SS
	MOV		DS,AX
	MOV		ES,AX
	CALL	_inthandler20
	POP		EAX
	POPAD
	POP		DS
	POP		ES
	IRETD
	
_asm_inthandler21:
	PUSH	ES
	PUSH	DS
	PUSHAD
	MOV		EAX,ESP
	PUSH	EAX
	MOV		AX,SS
	MOV		DS,AX
	MOV		ES,AX
	CALL	_inthandler21
	POP		EAX
	POPAD     ; 将AX CX DX BX SP BP SI DI寄存器中的值全部压入到栈中
	POP		DS
	POP		ES
	IRETD

_asm_inthandler27:
	PUSH	ES
	PUSH	DS
	PUSHAD
	MOV		EAX,ESP
	PUSH	EAX
	MOV		AX,SS
	MOV		DS,AX
	MOV		ES,AX
	CALL	_inthandler27
	POP		EAX
	POPAD
	POP		DS
	POP		ES
	IRETD

_asm_inthandler2c:
	PUSH	ES
	PUSH	DS
	PUSHAD
	MOV		EAX,ESP
	PUSH	EAX
	MOV		AX,SS
	MOV		DS,AX
	MOV		ES,AX
	CALL	_inthandler2c
	POP		EAX
	POPAD
	POP		DS
	POP		ES
	IRETD

_asm_inthandler0c:
	STI
	PUSH	ES
	PUSH	DS
	PUSHAD
	MOV		EAX,ESP
	PUSH	EAX
	MOV		AX,SS
	MOV		DS,AX
	MOV		ES,AX
	CALL	_inthandler0c
	CMP		EAX,0
	JNE		asm_end_app
	POP		EAX
	POPAD
	POP		DS
	POP		ES
	ADD		ESP,4
	IRETD

_asm_inthandler0d:
		STI
		PUSH	ES
		PUSH	DS
		PUSHAD
		MOV		EAX,ESP
		PUSH	EAX
		MOV		AX,SS
		MOV		DS,AX
		MOV		ES,AX
		CALL	_inthandler0d
		CMP		EAX,0		; ここだけ違う
		JNE		asm_end_app		; ここだけ違う
		POP		EAX
		POPAD
		POP		DS
		POP		ES
		ADD		ESP,4			; INT 0x0d では、これが必要
		IRETD

_load_cr0:		; int load_cr0(void);
	MOV		EAX,CR0
	RET

_store_cr0:		; void store_cr0(int cr0);
	MOV		EAX,[ESP+4]
	MOV		CR0,EAX
	RET

_memtest_sub:	; unsigned int memtest_sub(unsigned int start, unsigned int end)
	PUSH	EDI						; （EBX, ESI, EDI も使いたいので）
	PUSH	ESI
	PUSH	EBX
	MOV		ESI,0xaa55aa55			; pat0 = 0xaa55aa55;
	MOV		EDI,0x55aa55aa			; pat1 = 0x55aa55aa;
	MOV		EAX,[ESP+12+4]			; i = start;
mts_loop:
	MOV		EBX,EAX
	ADD		EBX,0xffc				; p = i + 0xffc;
	MOV		EDX,[EBX]				; old = *p;
	MOV		[EBX],ESI				; *p = pat0;
	XOR		DWORD [EBX],0xffffffff	; *p ^= 0xffffffff;
	CMP		EDI,[EBX]				; if (*p != pat1) goto fin;
	JNE		mts_fin
	XOR		DWORD [EBX],0xffffffff	; *p ^= 0xffffffff;
	CMP		ESI,[EBX]				; if (*p != pat0) goto fin;
	JNE		mts_fin
	MOV		[EBX],EDX				; *p = old;
	ADD		EAX,0x1000				; i += 0x1000;
	CMP		EAX,[ESP+12+8]			; if (i <= end) goto mts_loop;
	JBE		mts_loop
	POP		EBX
	POP		ESI
	POP		EDI
	RET
mts_fin:
	MOV		[EBX],EDX				; *p = old;
	POP		EBX
	POP		ESI
	POP		EDI
	RET
	
; 切换到指定的任务 JMP跳到GDT中指定的任务编号段地址
_farjmp:		; void farjmp(int eip, int cs);
	JMP		FAR	[ESP+4]				; eip, cs
	RET

_farcall:		; void farcall(int eip, int cs);
	CALL	FAR	[ESP+4]				; eip, cs
	RET


; 向TR寄存器中写入值 TR寄存其中保存的是当前的任务在GDT中的编号 用于切换多任务使用
_load_tr:		; void load_tr(int tr);
	LTR		[ESP+4]			; tr
	RET


_asm_hrb_api:
		STI
		PUSH	DS
		PUSH	ES
		PUSHAD		; 保存寄存器的值
		PUSHAD		; 用于向hrb_api传值  因为栈中的数据弹出去就没没了 因此需要存两遍
		MOV		AX,SS
		MOV		DS,AX		; OS用のセグメントをDSとESにも入れる
		MOV		ES,AX
		CALL	_hrb_api
		CMP		EAX,0		; EAXが0でなければアプリ終了処理
		JNE		asm_end_app
		ADD		ESP,32
		POPAD
		POP		ES
		POP		DS
		IRETD
_asm_end_app:
;	EAX为tss.esp0的地址
		MOV		ESP,[EAX]
		MOV		DWORD [EAX+4],0
		POPAD
		RET					; 返回cmd_app

_start_app:		; void start_app(int eip, int cs, int esp, int ds, int *tss_esp0);
		PUSHAD		; 32ビットレジスタを全部保存しておく
		MOV		EAX,[ESP+36]	; アプリ用のEIP
		MOV		ECX,[ESP+40]	; アプリ用のCS
		MOV		EDX,[ESP+44]	; アプリ用のESP
		MOV		EBX,[ESP+48]	; アプリ用のDS/SS
		MOV		EBP,[ESP+52]	; tss.esp0の番地
		MOV		[EBP  ],ESP		; OS用のESPを保存
		MOV		[EBP+4],SS		; OS用のSSを保存
		MOV		ES,BX
		MOV		DS,BX
		MOV		FS,BX
		MOV		GS,BX
;	以下はRETFでアプリに行かせるためのスタック調整
		OR		ECX,3			; アプリ用のセグメント番号に3をORする
		OR		EBX,3			; アプリ用のセグメント番号に3をORする
		PUSH	EBX				; アプリのSS
		PUSH	EDX				; アプリのESP
		PUSH	ECX				; アプリのCS
		PUSH	EAX				; アプリのEIP
		RETF
;	アプリが終了してもここには来ない