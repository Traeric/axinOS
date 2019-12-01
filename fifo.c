#include "bootpack.h"

#define FLAGS_OVERRUN		0x0001

/* ���n��FIFO?�t�� */
void fifo8_init(struct FIFO8 *fifo, int size, unsigned char *buf)
{
	fifo->size = size;
	fifo->buf = buf;
	fifo->free = size; /* ?�t��召 */
	fifo->flags = 0;
	fifo->p = 0; /* ���꘢�����ʓ��ʒu */
	fifo->q = 0; /* ���꘢����?�o�ʒu */
	return;
}

/* ��FIFO?�t��?��������ۑ� */
int fifo8_put(struct FIFO8 *fifo, unsigned char data)
{
	if (fifo->free == 0) {
		/* ��]�v�L�� ��o */
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

/* ��FIFO�擾�꘢���� */
int fifo8_get(struct FIFO8 *fifo)
{
	int data;
	if (fifo->free == fifo->size) {
		/* �@��?�t��?�� �ԉ�-1 */
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

/* ?���?�����I������ */
int fifo8_status(struct FIFO8 *fifo)
{
	return fifo->size - fifo->free;
}
