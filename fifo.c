#include "bootpack.h"

#define FLAGS_OVERRUN		0x0001

/* n»FIFO?tæ */
void fifo8_init(struct FIFO8 *fifo, int size, unsigned char *buf)
{
	fifo->size = size;
	fifo->buf = buf;
	fifo->free = size; /* ?tæå¬ */
	fifo->flags = 0;
	fifo->p = 0; /* ºê¢ÊüÊu */
	fifo->q = 0; /* ºê¢?oÊu */
	return;
}

/* üFIFO?tæ?óÛ¶ */
int fifo8_put(struct FIFO8 *fifo, unsigned char data)
{
	if (fifo->free == 0) {
		/* ó]vL¹ ìo */
		fifo->flags |= FLAGS_OVERRUN;
		return -1;
	}
	fifo->buf[fifo->p] = data;
	fifo->p++;
	if (fifo->p == fifo->size) {
		fifo->p = 0;
	}
	fifo->free--;
	return 0;
}

/* ¸FIFOæ¾ê¢ */
int fifo8_get(struct FIFO8 *fifo)
{
	int data;
	if (fifo->free == fifo->size) {
		/* @Ê?tæ?ó Ôñ-1 */
		return -1;
	}
	data = fifo->buf[fifo->q];
	fifo->q++;
	if (fifo->q == fifo->size) {
		fifo->q = 0;
	}
	fifo->free++;
	return data;
}

/* ?æß?¶üIð */
int fifo8_status(struct FIFO8 *fifo)
{
	return fifo->size - fifo->free;
}
