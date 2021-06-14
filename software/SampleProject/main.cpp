#include "altera_avalon_pio_regs.h"
#include "system.h"

#include <stdio.h>
//#include <unistd.h>
//#include "sys/alt_stdio.h"

int main()
{
	printf("Hello!!\n");

	alt_u8 readRequest = 0;
	alt_u8 empty = 0;
	alt_u32 aud_data = 0;

	while (1)
	{
		 IOWR_ALTERA_AVALON_PIO_DATA(PIO_DATA_BACK_BASE, aud_data);

		empty = IORD_ALTERA_AVALON_PIO_DATA(PIO_FIFO_RDEMPTY_BASE);

		if (empty == 1)
		{
//			printf("empty!\n");
//			alt_putstr("empty\n");
		}
		else
		{
//			printf("not empty!\n");
//			alt_putstr("not empty!\n");

			readRequest = 1;
			IOWR_ALTERA_AVALON_PIO_DATA(PIO_FIFO_RDREQ_BASE, readRequest);

			aud_data = IORD_ALTERA_AVALON_PIO_DATA(PIO_FIFO_Q_BASE);
//			printf("data: %ld\n", aud_data);
//			alt_printf("data!\n");

			readRequest = 0;
			IOWR_ALTERA_AVALON_PIO_DATA(PIO_FIFO_RDREQ_BASE, readRequest);
		}
	}

	return 0;
}
