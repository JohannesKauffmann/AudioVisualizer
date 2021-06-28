#include "altera_avalon_pio_regs.h"
#include "system.h"

#include "fft.h"

#include <math.h>
#include <stdio.h>
#include <string.h>

#define y 3.60672 //log 1,31951(x). Berekend middels z^20 = SAMPLE_SIZE / 2. z = 1,31951. Dus y * log(x) == log 1,31951(x)		//samplesize=512

#define AMPLITUDE_REFERENCE 3700000

void calculateChartData(complex<float>* f, float *decibels, alt_u8 *frequencyIndex, alt_u8 *chart_data, size_t length)
{
	alt_u8 counter = 0; 		// Keeps track of which horizontal square we are in. values >= 0, < 20.
	alt_8 max_db = INT8_MIN;	// Db values are negative from -80 to 0, so any value should be larger than int8_min.

    for (size_t i = 0; i < length; i++)
    {
    	// Calculate decibel from amplitude.
    	float amplitude = sqrtf(pow(f[i].real(), 2) + pow(f[i].imag(), 2));

    	//power_db = 20 * log10(amp / amp_ref);
    	float calculated_db = 20 * (log10 (amplitude / AMPLITUDE_REFERENCE));

    	if (calculated_db < -80)
    	{
    		decibels[i] = -80;
    	}
    	else
    	{
    		decibels[i] = calculated_db;
    	}

    	// Check if current index lies in next horizontal square.
    	alt_u8 tmp_counter = frequencyIndex[i];

    	if (tmp_counter > counter)
    	{
    		counter = tmp_counter;
    		max_db = INT8_MIN; // Reset maximum db.
    	}

    	// Take the maximum decibel for each horizontal square.
    	if (decibels[i] > max_db)
    	{
    		max_db = decibels[i];
    		chart_data[counter] = (48 - roundf( ((float) max_db / (float) -80) * (float) 48) );
    	}
    }
}

void initializeFrequencyIndex(alt_u8 *array, size_t length)
{
	// Fill the frequency index array with index values, logarithmically.
	for (size_t i = 0; i < length; i++)
	{
    	if (i < 2)
    	{
    		array[i] = i;
    	}
    	else
    	{
    		array[i] = (alt_u8) floorf( y * logf(i) ); //floorf alleen met z^20 ipv 19.
    	}
	}
}

int main()
{
	printf("Welcome to the AudioVisualiser!\n");

	alt_u16 counter = 0; // Keeps track of amount of samples read.

	complex<float> samples_f[SAMPLE_SIZE] = { 0 };	// Used to store results from the FFT.
	float decibels[SAMPLE_SIZE / 2] = { 0 };		// Stores calculated decibel values.
	alt_u8 frequencyIndex[SAMPLE_SIZE / 2] = { 0 };	// List with horizontal values between 0 and 19, spread logarithmically.
	alt_u8 chart_data[20] = { 0 };					// Stores vertical chart height values.

	// Initializes the frequencyIndex array with horizontal values between 0 and 19, spread logarithmically.
	initializeFrequencyIndex(frequencyIndex, SAMPLE_SIZE / 2);

	while (1)
	{
		alt_u8 empty = IORD_ALTERA_AVALON_PIO_DATA(PIO_FIFO_RDEMPTY_BASE);

		// Read from the FIFO if it's not empty.
		if (empty == 0)
		{
			// Assert the readrequest.
			IOWR_ALTERA_AVALON_PIO_DATA(PIO_FIFO_RDREQ_BASE, 1);

			// Read the left and right channel data from the FIFO.
			alt_32 aud_data = IORD_ALTERA_AVALON_PIO_DATA(PIO_FIFO_Q_BASE);

			// Only look at the right channel - for now - and store the data.
			alt_16 local = aud_data & 0x0000FFFF;

			samples_f[counter] = (complex<float>) local;
			counter++;

			// Deassert the readrequest.
			IOWR_ALTERA_AVALON_PIO_DATA(PIO_FIFO_RDREQ_BASE, 0);
		}

		// Check if we already have enough samples.
		if (counter + 1 == SAMPLE_SIZE)
		{
			// Indicate that data is about to be updated.
			IOWR_ALTERA_AVALON_PIO_DATA(PIO_DATA_BACK_BASE, 0);

			// Run the FFT over the current samples.
			FFT(samples_f, (int) SAMPLE_SIZE, 1.0);

			// Populate the chartdata from the FFT results and clear the results afterwards.
			calculateChartData(samples_f, decibels, frequencyIndex, chart_data, SAMPLE_SIZE / 2);
			memset(samples_f, 0, sizeof(complex<float>) * SAMPLE_SIZE);

			// Write the results to the on-chip RAM.
			for (int i = 0; i < 20; i++)
			{
				IOWR_ALTERA_AVALON_PIO_DATA(PIO_RAM_WRADDRESS_BASE, (alt_u8) i);
				IOWR_ALTERA_AVALON_PIO_DATA(PIO_RAM_DATA_BASE, chart_data[i]);
				IOWR_ALTERA_AVALON_PIO_DATA(PIO_RAM_WREN_BASE, 1);
				IOWR_ALTERA_AVALON_PIO_DATA(PIO_RAM_WREN_BASE, 0);
			}

			// Indicate that data is updated and reset the counter.
			IOWR_ALTERA_AVALON_PIO_DATA(PIO_DATA_BACK_BASE, 1);
			counter = 0;
		}
	}

	return (int) decibels[0] + (int) samples_f[0].real() + (int) chart_data[0]; // To prevent optimizing away variables.
}
