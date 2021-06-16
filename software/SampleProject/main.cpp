#include "altera_avalon_pio_regs.h"
#include "system.h"

#include <stdio.h>
#include <string.h>
//#include <unistd.h>
#include "sys/alt_stdio.h"

//#include "fft.h"













#include <complex>
#define MAX 1024

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
  complex<float> f2[MAX];
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

//int main()
//{
//  int n;
//  do {
//    cout << "specify array dimension (MUST be power of 2)" << endl;
//    cin >> n;
//  } while(!check(n));
//  double d;
//  cout << "specify sampling step" << endl; //just write 1 in order to have the same results of matlab fft(.)
//  cin >> d;
//  complex<float> vec[MAX];
//  cout << "specify the array" << endl;
//  for(int i = 0; i < n; i++) {
//    cout << "specify element number: " << i << endl;
//    cin >> vec[i];
//  }
//  FFT(vec, n, d);
//  cout << "...printing the FFT of the array specified" << endl;
//  for(int j = 0; j < n; j++)
//    cout << vec[j] << endl;
//  return 0;
//}















const alt_u16 sample_size = 1024;

int main()
{
	printf("Hello!!\n");

	alt_u8 readRequest = 0;
	alt_u8 empty = 0;
	alt_u32 aud_data = 0;

	alt_u16 sample_cnt = 0;
//	float *samples = new float[sample_size];// { 0 };
//	memset(samples, 0, (unsigned int)(sample_size * sizeof(float)));
	complex<float> samples[sample_size] = { 0 };

	complex<float> x;

	while (1)
	{
		IOWR_ALTERA_AVALON_PIO_DATA(PIO_DATA_BACK_BASE, aud_data);

		if ((sample_cnt + 1) == sample_size)
		{
			// Got 1024 samples!
//			float *tmp = new float[sample_size];
			complex<float> tmp[sample_size] = { 0 };
			memcpy(tmp, samples, (unsigned int) sample_size * sizeof(complex<float>));
			x = tmp[0];

			FFT(tmp, (int) sample_size, 1.0);

//			float *delete_me = ComplexFFT(tmp, (unsigned long int) sample_size, 96000, 1);
//			delete[] delete_me;
//			delete[] tmp;

			sample_cnt = 0;
		}
		else
		{
			// Read data until 1024 samples.
			empty = IORD_ALTERA_AVALON_PIO_DATA(PIO_FIFO_RDEMPTY_BASE);

			if (empty == 1)
			{

			}
			else
			{
				readRequest = 1;
				IOWR_ALTERA_AVALON_PIO_DATA(PIO_FIFO_RDREQ_BASE, readRequest);

				// Read FIFO
				aud_data = IORD_ALTERA_AVALON_PIO_DATA(PIO_FIFO_Q_BASE);

				// Convert read value to 16 bits.
				alt_u16 left_data = (aud_data & 0xFFFF0000) >> 16;

				// Store as float.
				samples[sample_cnt] = (complex<float>) left_data;
				sample_cnt++;

				readRequest = 0;
				IOWR_ALTERA_AVALON_PIO_DATA(PIO_FIFO_RDREQ_BASE, readRequest);
			}
		}
	}

	return (int) x.real();
}
