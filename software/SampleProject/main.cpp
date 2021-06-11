#include "altera_avalon_pio_regs.h"
#include "system.h"

#include <stdio.h>
#include <unistd.h>

#include <complex>

#include "fft.h"

#define MAX 200
#define M_PI 3.1415926535897932384

using namespace std;

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
			printf("data: %ld\n", aud_data);

			readRequest = 0;
			IOWR_ALTERA_AVALON_PIO_DATA(PIO_FIFO_RDREQ_BASE, readRequest);
		}
	}

	return 0;
}
