; hello-os
; TAB=4
CYLS EQU 10   ; �����ȡ��������
	org 0x8c00  ; ָ��װ�ص�ַ
; ��������Ǳ�׼��FAT12��ʽ����ר�õĴ���
	jmp entry
	db 0x90
	db "HELLOIPL"		; �����������ƿ����������ַ�����8�ֽڣ�
	dw 512				; ÿ��������sector���Ĵ�С��������521�ֽڣ�
	db 1				; �أ�cluster���Ĵ�С������Ϊ1��������
	dw 1				; FAT����ʼλ�ã�һ��ӵ�һ��������ʼ��
	db 2				; FAT�ĸ���������Ϊ2��
	dw 224				; ��Ŀ¼�Ĵ�С��һ�����ó�224�
	dw 2880			; �ô��̵Ĵ�С��������2280������Ҳ����һ�����̵Ĵ�С1440KB��
	db 0xf0			; ���̵����ࣨ������0xf0��
	dw 9				; FAT�ĳ��ȣ�������9������
	dw 18				; 1���ŵ���track���м���������������18��
	dw 2				; ��ͷ����������2��
	dd 0				; ��ʹ�÷�����������0
	dd 2880			; ��дһ�δ��̴�С
	db 0, 0, 0x29		; ���岻�� �̶�
	dd 0xffffffff		; �������ǣ��������
	db "HELLO-OS   "	; �������ƣ�11�ֽڣ�
	db "FAT12   "		; ���̸�ʽ���ƣ�8�ֽڣ�
	resb 18				; �ȿճ�18�ֽ�
		

; ��������
entry:
	mov	ax, 0			; ��ʼ���Ĵ���
	mov	ss, ax        
	mov	sp, 0x7c00
	mov ds, ax
	
	mov ax, 0x0820    ; 0x8000 ~ 0x8200����װ���������Ĵ���
	mov es, ax
	mov ch, 0			; ����0
	mov dh, 0			; ��ͷ0
	mov cl, 2			; ����2  ����1��������

readNextSector:     ; ��ת�������ȡ��һ������������
	mov si, 0    ; ���ڼ���
retry:
	mov ah, 0x02			; AH=0x02 : ��ʾ���� ��bios�ж���
	mov al, 1			; ��ȡ1������
	mov bx, 0
	mov dl, 0x00			; A������
	int	0x13			; ���ô���bios
	jnc nextSector       ; û���� �Ͷ�ȡ��һ������������
	
	; ��ȡ���� ���¶�ȡ�����������¶�ȡ���������
	inc si
	; ��si���бȽϣ������ʱѭ����5��(���ߴ���5��)������ת��error����ӡ������ʾ
	cmp si, 5
	jae error     ; si >= 5ʱ��ת
	; ��ȡ���� ����ϵͳ��λ ׼����һ�ζ�ȡ
	mov ax, 0x00
	mov dl, 0x00   ; A������
	int 0x13    ; ����������
	jmp retry
nextSector:
	; ��es�ĵ�ַ��ox20��Ҳ��������ƶ�512�ֽڣ���Ϊes�Ƕε�ַ�Ĵ�����0x20Ҳ����ʮ���Ƶ�32��
	; ���ڶε�ַ��Ҫ��16����ô�������ƶ��ĵ�ַ���� 32 * 16 = 512 Ҳ����һ�������Ĵ�С
	mov ax, es
	add ax, 0x20
	mov es, ax
	
	add cl, 1   ; cl��һ��ʾ��ȡ��һ������
	; ���cl <= 18�ͼ�����ȡ��������ڱ�ʾ�Ѿ���ȡ��18�����������ü�����ȡ�ˡ���Ϊһ������ֻ��18������
	cmp cl, 18
	jbe readNextSector
	
	; ��������˵���Ѿ���ȡ��18�������� ��ô��������ȡ��һ���18������
	mov cl, 1    ; ��һ�������1��ʼ��ȡ
	inc dh        ; ��ͷҲҪ������һ��
	; �����ж���һ���Ƿ��Ѿ���ȡ��
	cmp dh, 2
	jb readNextSector   ; dh < 2����ת��ȡ����
	
	; ��������˵����һ���18������Ҳ�Ѿ���ȡ���� Ҳ����˵һ������������Ѿ������ˣ���������ȡ��һ�����������
	mov dh, 0    ; ��ͷ����Ϊ��������Ĵ�ͷ
	inc ch     ; �����1 ��ʾ��ȡ��һ������
	; �����ж��Ƿ��Ѿ�������10���� ���û����ת������ȡ����������
	cmp ch, CYLS
	jb readNextSector
	; ���������ʾ�Ѿ�������ָ�����ݶ����ض��ڴ����ˣ���ô�������Ϳ���ȥ����ϵͳװ�����ڴ��еĵ�ִַ�в���ϵͳ��������
	mov ds:[0x0ff0], ch   ; ���߲���ϵͳ����װ�����ݵĽ�����ַ
	jmp 0xc200
	
fin:
	hlt					; ��cpuֹͣ �ȴ�ָ�� 
	jmp	fin				; ����ѭ��

error:
	mov si, msg  ; ��siָ������Ҫ��ʾ�����ݵ�ַ

putloop:
	mov al, ds:[si]   ; һ��һ������Ҫ��ʾ���ַ�
	inc	si			; si��һ
	cmp	al, 0    ; ����ַ�ȫ����ʾ���ˣ���ִ��jeָ������ѭ������cpuִ��hltָ������
	je fin
	mov	ah, 0x0e			; ��ʾҪ��ʾһ������
	mov	bx, 15			; ָ��������ʾ����ɫ
	int	0x10			; ����bios�ṩ�ĺ��� ������õĺ��������ǿ����Կ�
	jmp	putloop

		
; �����Լ���ʾ����Ϣ
msg:
	db	0x0a, 0x0a		; ��������
	db	"hello, this is axin operation system"   ; Ҫ��ʾ����Ϣ
	db	0x0a			; ����
	db	0      ; ����cmp�������ж�

	resb 0x7dfe-$		; ������510�ֽ�ǰ���������Ϊ0

	db 0x55, 0xaa   ; cpu������������ֽ���ʾ���������ж�ǰ��ĳ���ʱ��ִ��

