#include "altera_avalon_pio_regs.h"
#include "system.h"
#include "sys/alt_stdio.h"

#include <stdio.h>
#include <complex>

#include <math.h>

#define SAMPLE_SIZE 1024

using namespace std;

#define M_PI 3.1415926535897932384

int log2(int N)    /*function to calculate the log2(.) of int numbers*/
{
  int k = N, i = 0;
  while(k) {
    k >>= 1;
    i++;
  }
  return i - 1;
}

int check(int n)    //checking if the number of element is a power of 2
{
  return n > 0 && (n & (n - 1)) == 0;
}

int reverse(int N, int n)    //calculating revers number
{
  int j, p = 0;
  for(j = 1; j <= log2(N); j++) {
    if(n & (1 << (log2(N) - j)))
      p |= 1 << (j - 1);
  }
  return p;
}

void ordina(complex<float>* f1, int N) //using the reverse order in the array
{
  complex<float> f2[SAMPLE_SIZE];
  for(int i = 0; i < N; i++)
    f2[i] = f1[reverse(N, i)];
  for(int j = 0; j < N; j++)
    f1[j] = f2[j];
}

void transform(complex<float>* f, int N) //
{
  ordina(f, N);    //first: reverse order
  complex<float> *W;
  W = (complex<float> *)malloc(N / 2 * sizeof(complex<float>));
  W[1] = polar(1., -2. * M_PI / N);
  W[0] = 1;
  for(int i = 2; i < N / 2; i++)
    W[i] = pow(W[1], i);
  int n = 1;
  int a = N / 2;
  for(int j = 0; j < log2(N); j++) {
    for(int i = 0; i < N; i++) {
      if(!(i & n)) {
        complex<float> temp = f[i];
        complex<float> Temp = W[(i * a) % (n * a)] * f[i + n];
        f[i] = temp + Temp;
        f[i + n] = temp - Temp;
      }
    }
    n *= 2;
    a = a / 2;
  }
  free(W);
}

void FFT(complex<float>* f, int N, double d)
{
  transform(f, N);
  for(int i = 0; i < N; i++)
    f[i] *= d; //multiplying by step
}

#define y 3.0457 //log 1,44025(x). Berekend middels z^19 = SAMPLE_SIZE / 2. z = 1,38865. Dus y * log(x) == log 1,38865(x)

void calculateMagnitude(complex<float>* f, float *decibels, alt_u8 *frequencyIndex, alt_u8 *chart_data, size_t length)
{
	alt_u8 counter = 0; 		// Keeps track of which horizontal square we are in. values >= 0, < 20.
	alt_8 max_db = INT8_MIN;	// Db values are negative from -80 to 0, so any value should be larger than int8_min.

    for (int i = 0; i < length; i++)
    {
    	float amplitude = sqrtf(pow(f[i].real(), 2) + pow(f[i].imag(), 2));
    	float calculated_db = 20 * (log10 (amplitude / 7500000));

    	if (calculated_db < -80)
    	{
    		decibels[i] = -80;
    	}
    	else
    	{
    		decibels[i] = calculated_db;
    	}
    	//power_db = 20 * log10(amp / amp_ref);

    	// Check if next value is in next horizontal square.
    	alt_u8 tmp_counter = frequencyIndex[i];

    	if (tmp_counter > counter)
    	{
    		counter = tmp_counter;
    		max_db = INT8_MIN; // Reset maximum db.
    	}

    	if (decibels[i] > max_db)
    	{
    		max_db = decibels[i];
    		chart_data[counter] = (48 - roundf( ((float) max_db / (float) -80) * (float) 48) );
    	}
    }
}

void calculateFrequencyIndex(alt_u8 *array, size_t length)
{
	for (int i = 0; i < length; i++)
	{
    	if (i < 2)
    	{
    		array[i] = i;
    	}
    	else
    	{
    		array[i] = (alt_u8) roundf( y * logf(i) );
    	}
	}
}

int main()
{
	printf("Hello!!\n");

	alt_u8 readRequest = 0;
	alt_u8 empty = 0;
	alt_32 aud_data = 0;

	complex<float> samples_f[SAMPLE_SIZE] = { 0 };
	float decibels[SAMPLE_SIZE / 2] = { 0 };
	alt_u8 frequencyIndex[SAMPLE_SIZE / 2] = { 0 };
	alt_u8 chart_data[20] = { 0 };

	calculateFrequencyIndex(frequencyIndex, SAMPLE_SIZE / 2);

	alt_u16 counter = 0;

	alt_u32 getal = 0;

	while (1)
	{
		empty = IORD_ALTERA_AVALON_PIO_DATA(PIO_FIFO_RDEMPTY_BASE);

		if (empty == 0)
		{
			readRequest = 1;
			IOWR_ALTERA_AVALON_PIO_DATA(PIO_FIFO_RDREQ_BASE, readRequest);

			aud_data = IORD_ALTERA_AVALON_PIO_DATA(PIO_FIFO_Q_BASE);

			alt_16 local = aud_data & 0x0000FFFF;

			samples_f[counter] = (complex<float>) local;
			counter++;

			readRequest = 0;
			IOWR_ALTERA_AVALON_PIO_DATA(PIO_FIFO_RDREQ_BASE, readRequest);
		}

		if (counter + 1 == SAMPLE_SIZE)
		{
			IOWR_ALTERA_AVALON_PIO_DATA(PIO_DATA_BACK_BASE, 1);
			FFT(samples_f, (int) SAMPLE_SIZE, 1.0);

			calculateMagnitude(samples_f, decibels, frequencyIndex, chart_data, SAMPLE_SIZE / 2);

			IOWR_ALTERA_AVALON_PIO_DATA(PIO_DATA_BACK_BASE, 0);

			counter = 0;
//			getal = samples_f[0].real();
			getal = decibels[0];
		}
	}

	return (int) getal + (int) decibels[0] + (int) samples_f[0].real() + (int) chart_data[0];
}
