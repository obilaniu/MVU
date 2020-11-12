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
const int ilength3 = ((W-Fw+1)/Sw - 1); //Fc-1;
const int ijump0 = iprec*(C*(W-Fw) + 1);                  // Move to next row
const int ijump1 = -iprec*(C*(Fh-1)*W + Fw*C - 1);        // Move back to start of window; bump zig-zag
const int ijump2 = -iprec*(C*(Fh-1)*W + (Fw-Sw)*C + 1);   // Move window to right by horizontal stride
const int ijump3 = 0;
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


int getNextInput()
{   
    if (i_i0 == 0 && i_i1 == 0 && i_i2 == 0 && i_i3 == 0)
    {
        i_i0 = ilength0;
        i_i1 = ilength1;
        i_i2 = ilength2;
        i_i3 = ilength3;
        i_tptr += i_j4;
        printf("\n");
    }
    else if (i_i0 == 0 && i_i1 == 0 && i_i2 == 0)
    {
        i_i0 = ilength0;
        i_i1 = ilength1;
        i_i2 = ilength2;
        i_i3--;
        i_tptr += i_j3;
        printf("\n");
    }
    else if (i_i0 == 0 && i_i1 == 0)
    {
        i_i0 = ilength0;
        i_i1 = ilength1;
        i_i2--;
        i_tptr += i_j2;
        printf("\n");
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
    
    
/*
    for (int l3=ilength3; l3 >= 0; l3--)
    {
        for (int l2=ilength2; l2 >= 0; l2--)
        {
            for (int l1=ilength1; l1 >= 0; l1--)
            {
                for (int l0=ilength0; l0 >= 0; l0--)
                {
                    printf("%4d,", *i_tptr+i_zzoff);
                    i_tptr += i_j0;
                    cntdwn--;
                    cntup++;
                }
                if (l1 != 0) 
                {
                    printf("\nNext row\n");
                    i_tptr += i_j1;
                }
            }
            if (l2 != 0) 
            {
                printf("\nReturn to filter window start; Bump zig-zag\n");
                i_tptr += i_j2;
            }
        }
        if (l3 != 0)
        {
            printf("\nShift window to right by stride\n");
            i_tptr += i_j3;
        }
    }
    */
    return *i_tptr;
}

int getNextWeight()
{
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
        /*
        for (int l3=ilength3; l3 >= 0; l3--)
        {
            for (int l2=ilength2; l2 >= 0; l2--)
            {
                for (int l1=ilength1; l1 >= 0; l1--)
                {
                    for (int l0=ilength0; l0 >= 0; l0--)
                    {
                        printf("%4d,", *i_tptr+i_zzoff);
                        i_tptr += i_j0;
                        cntdwn--;
                        cntup++;
                    }
                    if (l1 != 0) 
                    {
                        printf("\nNext row\n");
                        i_tptr += i_j1;
                    }
                }
                if (l2 != 0) 
                {
                    printf("\nReturn to filter window start; Bump zig-zag\n");
                    i_tptr += i_j2;
                }
            }
            if (l3 != 0)
            {
                printf("\nShift window to right by stride\n");
                i_tptr += i_j3;
            }
        }
        */
        printf("%4d,", *i_tptr);
        getNextInput();
    }
    

    printf("\n\nFinal location: %d\n", *i_tptr);
    printf("Final cntdwn=%d, computed countdown=%d, cntup=%d\n", cntdwn, countdown, cntup);

    return 0;
}