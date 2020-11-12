#include <stdio.h>

// Convolution parameters
const int iprec = 2;                                // Input data precision
const int wprec = 2;                                // Weight precision
const int W = 10;                                   // Input width
const int H = 10;                                   // Input height
const int C = 2;                                    // Input channel blocks
const int Fw = 3;                                   // Filter kernel width
const int Fh = 3;                                   // Filter kernel height
const int Fc = 2;                                   // Number of filter blocks (i.e. number of output channel blocks)
const int Sw = 1;                                   // Filter horizontal (width) stride

// Tensors
int i_t[H][W][C][iprec];                            // Input tensor
int w_t[Fc][Fh][Fw][C][wprec];                      // Width tensor
int *i_tptr = (int*)i_t;                            // Input address pointer
int *w_tptr = (int*)w_t;                            // Weight address pointer

// Computed MVU parameters to program into CSRs
const int ilength0 = C*Fw-1;
const int ilength1 = Fh-1;
const int ilength2 = iprec*wprec-1;
const int ilength3 = ((W-Fw+1)/Sw - 1);
const int ijump0 = iprec*(C*(W-Fw) + 1);                    const char* i_jump0_str = "Move to next row";
const int ijump1 = -iprec*(C*(Fh-1)*W + Fw*C - 1);          const char* i_jump1_str = "Move back to start of window; bump zig-zag";
const int ijump2 = -iprec*(C*(Fh-1)*W + (Fw-Sw-1)*C + 1);   const char* i_jump2_str = "Move window to right by horizontal stride";
const int ijump3 = 0;                                       const char* i_jump3_str = "";
const int wlength0 = C*Fw*Fh-1;                             // Total size of a filter
const int wlength1 = 0;
const int wlength2 = 0;
const int wlength3 = 0;
const int wjump0 = -wprec*(C*Fw*Fh-1);                      // Move back to start of filter for next precision combo; Bump zig-zag
const int wjump1 = 0;
const int wjump2 = 0;
const int wjump3 = wjump0;
const int countdown = (C * Fw) * (Fh) * (iprec * wprec) * ((W-Fw+1)/Sw);

// Internal parameters
const int m = 10;
const int i_j0 = iprec;                                 // Move to next channel block and/or column
const int i_j1 = ijump0;
const int i_j2 = ijump1;
const int i_j3 = ijump2;
const int i_j4 = ijump3;
int i_zzoff = 0;
int w_zzoff = 0;
int cntdwn = countdown;
int cntup = 0;
int i_i0 = ilength0;
int i_i1 = ilength1;
int i_i2 = ilength2;
int i_i3 = ilength3;
int w_i0 = wlength0;
int w_i1 = wlength1;
int w_i2 = wlength2;
int w_i3 = wlength3;
const int w_j0 = wprec;                                 // Move to next channel block and/or column
const int w_j1 = wjump0;
const int w_j2 = wjump1;
const int w_j3 = wjump2;
const int w_j4 = wjump3;


void bumpZigZag()
{

}

int getNextInput()
{   
    if (i_i0 == 0 && i_i1 == 0 && i_i2 == 0 && i_i3 == 0)
    {
        i_i0 = ilength0;
        i_i1 = ilength1;
        i_i2 = ilength2;
        i_i3 = ilength3;
        i_tptr += i_j4;
        printf("\n==> i_j4: %s\n", i_jump3_str);
    }
    else if (i_i0 == 0 && i_i1 == 0 && i_i2 == 0)
    {
        i_i0 = ilength0;
        i_i1 = ilength1;
        i_i2 = ilength2;
        i_i3--;
        i_tptr += i_j3;
        printf("\n==> i_j3: %s\n", i_jump2_str);
    }
    else if (i_i0 == 0 && i_i1 == 0)
    {
        i_i0 = ilength0;
        i_i1 = ilength1;
        i_i2--;
        i_tptr += i_j2;
        printf("\n==> i_j2: %s\n", i_jump1_str);
    }
    else if (i_i0 == 0)
    {
        i_i0 = ilength0;
        i_i1--;
        i_tptr += i_j1;
        printf("\n");
    }
    else
    {
        i_i0--;
        i_tptr += i_j0;       
    }

    return *i_tptr;
}

int getNextWeight()
{
    if (w_i0 == 0 && w_i1 == 0 && w_i2 == 0 && w_i3 == 0)
    {
        w_i0 = wlength0;
        w_i1 = wlength1;
        w_i2 = wlength2;
        w_i3 = wlength3;
        w_tptr += w_j4;
        //printf("\n==> w_j4\n");
    }
    else if (w_i0 == 0 && w_i1 == 0 && w_i2 == 0)
    {
        w_i0 = wlength0;
        w_i1 = wlength1;
        w_i2 = wlength2;
        w_i3--;
        w_tptr += w_j3;
        //printf("\n==> w_j3\n");
    }
    else if (w_i0 == 0 && w_i1 == 0)
    {
        w_i0 = wlength0;
        w_i1 = wlength1;
        w_i2--;
        w_tptr += w_j2;
        //printf("\n==> w_j2\n");
    }
    else if (w_i0 == 0)
    {
        w_i0 = wlength0;
        w_i1--;
        w_tptr += w_j1;
        //printf("\n");
    }
    else
    {
        w_i0--;
        w_tptr += w_j0;       
    }

    return *w_tptr;
}


int main()
{


    // Initialize input tensor
    // The values are set such that each digit represents the position
    // in that dimension of the tensor. This makes reading the print
    // outs easier.
    for (int h=0; h < H; h++)
    {
        for (int w=0; w < W; w++)
        {
            for (int c=0; c < C; c++)
            {
                for (int p=0; p < iprec; p++)
                {
                    i_t[h][w][c][p] = h*m*m*m + w*m*m + c*m + p;
                    //printf("%4d,", i_t[h][w][c][p]);
                }
            }
        }
    }

    // Initialize weight tensor
    // The values are set such that each digit represents the position
    // in that dimension of the tensor. This makes reading the print
    // outs easier.
    for (int fc=0; fc < Fc; fc++)
    {
        for (int fh=0; fh < Fh; fh++)
        {
            for (int fw=0; fw < Fw; fw++)
            {
                for (int c=0; c < C; c++)
                {
                    for (int p=0; p < wprec; p++)
                    {
                        w_t[fc][fh][fw][c][p] = fc*m*m*m*m + fh*m*m*m + fw*m*m + c*m + p;
                        //printf("%5d,", w_t[fc][fh][fw][c][p]);
                    }
                }
                //printf("\n");
            }
        }       
    }

    // Do conv2d
    for (cntdwn = countdown; cntdwn > 0; cntdwn--)
    {
        printf("(%04d,%05d),", *i_tptr, *w_tptr);
        getNextInput();
        getNextWeight();
    }
    

    printf("\n\nFinal location: %d\n", *i_tptr);
    printf("Final cntdwn=%d, computed countdown=%d, cntup=%d\n", cntdwn, countdown, cntup);

    return 0;
}