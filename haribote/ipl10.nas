; hello-os
; TAB=4
CYLS EQU 10   ; 定义读取的柱面数
	org 0x8c00  ; 指明装载地址
; 以下这段是标准的FAT12格式软盘专用的代码
	jmp entry
	db 0x90
	db "HELLOIPL"		; 启动区的名称可以是任意字符串（8字节）
	dw 512				; 每个扇区（sector）的大小（必须是521字节）
	db 1				; 簇（cluster）的大小（必须为1个扇区）
	dw 1				; FAT的起始位置（一般从第一个扇区开始）
	db 2				; FAT的个数（必须为2）
	dw 224				; 根目录的大小（一般设置成224项）
	dw 2880			; 该磁盘的大小（必须是2280扇区，也就是一个软盘的大小1440KB）
	db 0xf0			; 磁盘的种类（必须是0xf0）
	dw 9				; FAT的长度（必须是9扇区）
	dw 18				; 1个磁道（track）有几个扇区（必须是18）
	dw 2				; 磁头数（必须是2）
	dd 0				; 不使用分区，必须是0
	dd 2880			; 重写一次磁盘大小
	db 0, 0, 0x29		; 意义不明 固定
	dd 0xffffffff		; （可能是）卷标号码
	db "HELLO-OS   "	; 磁盘名称（11字节）
	db "FAT12   "		; 磁盘格式名称（8字节）
	resb 18				; 先空出18字节
		

; 程序主体
entry:
	mov	ax, 0			; 初始化寄存器
	mov	ss, ax        
	mov	sp, 0x7c00
	mov ds, ax
	
	mov ax, 0x0820    ; 0x8000 ~ 0x8200用于装载启动区的代码
	mov es, ax
	mov ch, 0			; 柱面0
	mov dh, 0			; 磁头0
	mov cl, 2			; 扇区2  扇区1是启动区

readNextSector:     ; 跳转到这里读取下一个扇区的内容
	mov si, 0    ; 用于计数
retry:
	mov ah, 0x02			; AH=0x02 : 表示读盘 在bios中定义
	mov al, 1			; 读取1个扇区
	mov bx, 0
	mov dl, 0x00			; A驱动器
	int	0x13			; 调用磁盘bios
	jnc nextSector       ; 没出错 就读取下一个扇区的内容
	
	; 读取出错 重新读取，下面是重新读取的相关配置
	inc si
	; 对si进行比较，如果此时循环了5次(或者大于5次)，就跳转到error处打印错误提示
	cmp si, 5
	jae error     ; si >= 5时跳转
	; 读取错误 进行系统复位 准备下一次读取
	mov ax, 0x00
	mov dl, 0x00   ; A驱动器
	int 0x13    ; 重置驱动器
	jmp retry
nextSector:
	; 将es的地址加ox20，也就是向后移动512字节，因为es是段地址寄存器，0x20也就是十进制的32，
	; 由于段地址需要乘16，那么这次向后移动的地址就是 32 * 16 = 512 也就是一个扇区的大小
	mov ax, es
	add ax, 0x20
	mov es, ax
	
	add cl, 1   ; cl加一表示读取下一个扇区
	; 如果cl <= 18就继续读取，如果大于表示已经读取了18个扇区，不用继续读取了。因为一个柱面只有18个扇区
	cmp cl, 18
	jbe readNextSector
	
	; 来到这里说明已经读取完18个扇区了 那么接下来读取另一面的18个扇区
	mov cl, 1    ; 另一面从扇区1开始读取
	inc dh        ; 磁头也要换成另一面
	; 这里判断另一面是否已经读取完
	cmp dh, 2
	jb readNextSector   ; dh < 2就跳转读取扇区
	
	; 来到这里说明另一面的18个扇区也已经读取完了 也就是说一个柱面的内容已经读完了，接下来读取下一个柱面的内容
	mov dh, 0    ; 磁头设置为软盘上面的磁头
	inc ch     ; 柱面加1 表示读取下一个柱面
	; 这里判断是否已经读完了10柱面 如果没有跳转继续读取扇区的内容
	cmp ch, CYLS
	jb readNextSector
	; 来到这里表示已经将软盘指定内容都加载都内存中了，那么接下来就可以去操作系统装载在内存中的地址执行操作系统的内容了
	mov ds:[0x0ff0], ch   ; 告诉操作系统磁盘装载内容的结束地址
	jmp 0xc200
	
fin:
	hlt					; 让cpu停止 等待指令 
	jmp	fin				; 无限循环

error:
	mov si, msg  ; 将si指向我们要显示的数据地址

putloop:
	mov al, ds:[si]   ; 一个一个加载要显示的字符
	inc	si			; si加一
	cmp	al, 0    ; 如果字符全部显示完了，就执行je指令跳出循环，让cpu执行hlt指令休眠
	je fin
	mov	ah, 0x0e			; 表示要显示一个文字
	mov	bx, 15			; 指定字体显示的颜色
	int	0x10			; 调用bios提供的函数 这里调用的函数功能是控制显卡
	jmp	putloop

		
; 我们自己显示的信息
msg:
	db	0x0a, 0x0a		; 换行两次
	db	"hello, this is axin operation system"   ; 要显示的信息
	db	0x0a			; 换行
	db	0      ; 用于cmp的条件判断

	resb 0x7dfe-$		; 将程序510字节前的内容填充为0

	db 0x55, 0xaa   ; cpu会根据这两个字节显示的数据来判断前面的程序时候执行


