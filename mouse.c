#include "bootpack.h"

// 处理鼠标中断
struct FIFO8 mousefifo;

void inthandler2c(int *esp)
{
	unsigned char data;
	io_out8(PIC1_OCW2, 0x64);	/* 通知IRQ-12已经处理了中断 请继续监听 这个实际上是通知从pic */
	io_out8(PIC0_OCW2, 0x62);	/* 通知IRQ-02 这个是通知主pic 因为主pic通过IRQ-02监听从pic */
	data = io_in8(PORT_KEYDAT);
	fifo8_put(&mousefifo, data);
	return;
}

#define KEYCMD_SENDTO_MOUSE		0xd4
#define MOUSECMD_ENABLE			0xf4

void enable_mouse(struct MOUSE_DEC *mdec)
{
	/* 激活鼠标 */
	wait_KBC_sendready();
	io_out8(PORT_KEYCMD, KEYCMD_SENDTO_MOUSE);
	wait_KBC_sendready();
	io_out8(PORT_KEYDAT, MOUSECMD_ENABLE);
	mdec -> phase = 0;  // 进入到等待鼠标0xfa状态 鼠标开始连接时会有一个中断 会发送0xfa 要排除掉这个数据
	return; /* 如果顺利的话鼠标会产生一个中断给cpu一个ACK 返回数据(0xfa) */
}

int mouse_decode(struct MOUSE_DEC *mdec, unsigned char dat)
{	
	if (mdec->phase == 0) {
		/* 等待鼠标0xfa状态 */
		if (dat == 0xfa) {
			mdec->phase = 1;
		}
		return 0;
	}
	if (mdec->phase == 1) {
		/* 等待鼠标的第一个字节 */
		if ((dat & 0xc8) == 0x08) {
			/* 如果第一字节正确就写入 */
			mdec->buf[0] = dat;
			mdec->phase = 2;
		}
		return 0;
	}
	if (mdec->phase == 2) {
		/* 等待鼠标的第二个字节 */
		mdec->buf[1] = dat;
		mdec->phase = 3;
		return 0;
	}
	if (mdec->phase == 3) {
		/* 等待鼠标的第三个字节 */
		mdec->buf[2] = dat;
		mdec->phase = 1;
		mdec->btn = mdec->buf[0] & 0x07;
		mdec->x = mdec->buf[1];
		mdec->y = mdec->buf[2];
		if ((mdec->buf[0] & 0x10) != 0) {
			mdec->x |= 0xffffff00;
		}
		if ((mdec->buf[0] & 0x20) != 0) {
			mdec->y |= 0xffffff00;
		}
		mdec->y = - mdec->y; /* 鼠标的y方向与画面符号相反 */
		return 1;
	}
	return -1; /* 出错返回-1 */
}
