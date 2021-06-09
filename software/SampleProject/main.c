#include "altera_avalon_pio_regs.h"
#include "system.h"
#include <stdio.h>
#include <unistd.h>

int main()
{
	printf("Hello!!\n");

	alt_u8 readRequest = 0;
	alt_u8 empty = 0;
	alt_u32 aud_data = 0;

	while (1)
	{
		empty = IORD_ALTERA_AVALON_PIO_DATA(PIO_FIFO_RDEMPTY_BASE);

		if (empty == 1)
		{
			printf("empty!\n");
		}
		else
		{
			printf("not empty!\n");

			readRequest = 1;
			IOWR_ALTERA_AVALON_PIO_DATA(PIO_FIFO_RDREQ_BASE, readRequest);

			aud_data = IORD_ALTERA_AVALON_PIO_DATA(PIO_FIFO_Q_BASE);

			if (aud_data != 0)
			{
				printf("data: 0x%08lx\n", aud_data);
			}

			readRequest = 0;
			IOWR_ALTERA_AVALON_PIO_DATA(PIO_FIFO_RDREQ_BASE, readRequest);
		}

		usleep(500 * 1000);
	}

	return 0;
}
