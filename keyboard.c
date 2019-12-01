#include "bootpack.h"

// 处理键盘中断
struct FIFO8 keyfifo;

void inthandler21(int *esp)
{
	unsigned char data;
	/* 通知pic "IRQ-01已经受理完毕" */
	/* 也就是说告诉pic已经处理完了这个中断 继续监听键盘的中断 */
	/* 否则cpu就不会监视这个中断了 下次再按键盘就没有用了 */
	io_out8(PIC0_OCW2, 0x61);	
	data = io_in8(PORT_KEYDAT);
	
	// 为了加快中断执行 这里不处理信息 而是将数据暂时保存到缓冲区中 
	fifo8_put(&keyfifo, data);
	return;
}

#define PORT_KEYSTA				0x0064
#define KEYSTA_SEND_NOTREADY	0x02
#define KEYCMD_WRITE_MODE		0x60
#define KBC_MODE				0x47

void wait_KBC_sendready(void)
{
	/* 等待键盘控制电路准备完毕 */
	for (;;) {
		if ((io_in8(PORT_KEYSTA) & KEYSTA_SEND_NOTREADY) == 0) {
			break;
		}
	}
	return;
}

void init_keyboard(void)
{
	/* 初始化键盘控制电路 */
	wait_KBC_sendready();
	io_out8(PORT_KEYCMD, KEYCMD_WRITE_MODE);
	wait_KBC_sendready();
	io_out8(PORT_KEYDAT, KBC_MODE);
	return;
}

