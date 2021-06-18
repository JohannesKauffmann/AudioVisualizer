#include "altera_avalon_pio_regs.h"
#include "system.h"
#include "sys/alt_stdio.h"

#include <stdio.h>
#include <complex>

#include <math.h>

#define SAMPLE_SIZE 256

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

float calculateMagnitude(complex<float>* f, float* f2)
{
	float max = 0;
    for(int i = 0; i < SAMPLE_SIZE; i++)
    {
    	float tmp = sqrtf(pow(f[i].real(), 2) + pow(f[i].imag(), 2));
    	if (tmp > max)
    	{
    		max = tmp;
    	}
        f2[i] = tmp;
    }
    return max;
}



int main()
{
	printf("Hello!!\n");

	alt_u8 readRequest = 0;
	alt_u8 empty = 0;
	alt_32 aud_data = 0;

	complex<float> samples_f[SAMPLE_SIZE] = { 0 };
	alt_16 samples[SAMPLE_SIZE] = { 0 };
	float amplitudes[SAMPLE_SIZE] = { 0 };

	alt_u8 counter = 0;

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

//			if (local != 0 && local != 61440)
//			{
//				alt_printf("woat is det den\n");
//			}

			samples_f[counter] = (complex<float>) local;
			samples[counter] = local;
			counter++;

			readRequest = 0;
			IOWR_ALTERA_AVALON_PIO_DATA(PIO_FIFO_RDREQ_BASE, readRequest);
		}

		if (counter + 1 == SAMPLE_SIZE)
		{
			FFT(samples_f, (int) SAMPLE_SIZE, 1.0);

			float max = calculateMagnitude(samples_f, amplitudes);
			getal = (alt_u32) max;

			counter = 0;
//			getal = samples_f[0].real();
//			getal = samples[0];
		}
	}

	return (int) getal;
}
