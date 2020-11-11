#include <stdio.h>



int main()
{
    const int iprec = 2;
    const int wprec = 2;
    const int W = 10;
    const int H = 10;
    const int C = 2;
    const int Fw = 3;
    const int Fh = 3;
    const int Sw = 1;
    int i_t[H][W][C][iprec];
    int f[Fh][Fw][C];
    int *i_tptr = (int*)i_t;
    const int m = 10;
    const int i_j0 = iprec;                           // Move to next channel block and/or column
    const int i_j1 = iprec*(C*(W-Fw));                // Move to next row
    const int i_j2 = -iprec*(C*(Fh-1)*W + Fw*C);      // Move back to start of window; bump zig-zag
    const int i_j3 = -iprec*(C*(Fh-1)*W + (Fw-Sw)*C); // Move window to right by horizontal stride
    const int i_j4 = 0;
    const int ilength0 = C*Fw-1;
    const int ilength1 = Fh-1;
    const int ilength2 = iprec*wprec-1;
    const int ilength3 = (W-Fw+1)/Sw-1;
    int i_zzoff = 0;
    int w_zzoff = 0;
    const int countdown = (C * Fw) * (Fh) * (iprec * wprec) * ((W-Fw+1)/Sw);
    int cntdwn = countdown;
    int cntup = 0;

    // Initialize input tensor
    for (int h=0; h < H; h++)
    {
        for (int w=0; w < W; w++)
        {
            for (int c=0; c < C; c++)
            {
                for (int p=0; p < iprec; p++)
                {
                    i_t[h][w][c][p] = h*m*m*m + w*m*m + c*m + p;
                    //printf("%4d,", t[h][w][c][p]);
                }
            }
        }
    }

    // Do conv2d
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
    printf("\n\nFinal location: %d\n", *i_tptr);
    printf("Final cntdwn=%d, computed countdown=%d, cntup=%d\n", cntdwn, countdown, cntup);

    return 0;
}