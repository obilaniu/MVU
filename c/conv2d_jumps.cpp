#include <stdio.h>

//
// General parameters
//
#define NJUMPS 5
const int m = 10;                                   // Spacing between dimension blocks in generated tensors


//
// Convolution parameters
//


// Case 1: 3x3 conv, 10x10 feature map, 2 channel blocks in, 2 channel blocks out, 2x2 bits
const int iprec = 2;                                // Input data precision
const int wprec = 2;                                // Weight precision
const int oprec = 2;                                // Output precision
const int W = 10;                                   // Input width
const int H = 10;                                   // Input height
const int C = 2;                                    // Input channel blocks
const int Fw = 3;                                   // Filter kernel width
const int Fh = 3;                                   // Filter kernel height
const int Fc = 2;                                   // Number of filter set blocks (i.e. number of output channel blocks)
const int Sw = 1;                                   // Filter horizontal (width) stride
const int Pl = 1;                                   // Zero-padding in on the left in the width dimension
const int Pr = 1;                                   // Zero-padding in on the right in the width dimension
const int Pt = 1;                                   // Zero-padding in on the top in the height dimension
const int Pb = 1;                                   // Zero-padding in on the bottom in the height dimension


/*
// Case 1a: 3x3 conv, 10x10 feature map, 2 channel blocks in, 4 channel blocks out, 2x2 bits
const int iprec = 2;                                // Input data precision
const int wprec = 2;                                // Weight precision
const int oprec = 2;                                // Output precision
const int W = 8;                                   // Input width
const int H = 8;                                   // Input height
const int C = 2;                                    // Input channel blocks
const int Fw = 3;                                   // Filter kernel width
const int Fh = 3;                                   // Filter kernel height
const int Fc = 2;                                   // Number of filter set blocks (i.e. number of output channel blocks)
const int Sw = 1;                                   // Filter horizontal (width) stride
const int Pl = 0;                                   // Zero-padding in on the left in the width dimension
const int Pr = 0;                                   // Zero-padding in on the right in the width dimension
const int Pt = 0;                                   // Zero-padding in on the top in the height dimension
const int Pb = 0;                                   // Zero-padding in on the bottom in the height dimension
*/

// Case 2: 3x3 conv, 10x10 feature map, 2 channel blocks in, 2 channel blocks out, 1x1 bits 
/*
const int iprec = 1;                                // Input data precision
const int wprec = 1;                                // Weight precision
const int oprec = 1;                                // Output precision
const int W = 10;                                   // Input width
const int H = 10;                                   // Input height
const int C = 2;                                    // Input channel blocks
const int Fw = 3;                                   // Filter kernel width
const int Fh = 3;                                   // Filter kernel height
const int Fc = 2;                                   // Number of filter set blocks (i.e. number of output channel blocks)
const int Sw = 1;                                   // Filter horizontal (width) stride
const int Pw = 0;                                   // Zero-padding in width dimension
const int Ph = 0;                                   // Zero-padding in height dimension
*/

// Case 3: 3x3 conv, 2x2 upper left corner of feature map, 2 channel blocks in, 2 channel blocks out, 2x2 bits
/*
const int iprec = 2;                                // Input data precision
const int wprec = 2;                                // Weight precision
const int oprec = 2;                                // Output precision
const int W = 2;                                    // Input width
const int H = 2;                                    // Input height
const int C = 2;                                    // Input channel blocks
const int Fw = 3;                                   // Filter kernel width
const int Fh = 3;                                   // Filter kernel height
const int Fc = 2;                                   // Number of filter set blocks (i.e. number of output channel blocks)
const int Sw = 1;                                   // Filter horizontal (width) stride
const int Pw = 1;                                   // Zero-padding in width dimension
const int Ph = 1;                                   // Zero-padding in height dimension
*/

/*
// Case 4: 3x3 conv, 32x32 feature map, 2 channel blocks in, 2 channel blocks out, 8x8 bits
const int iprec = 8;                                // Input data precision
const int wprec = 8;                                // Weight precision
const int oprec = 8;                                // Output precision
const int W = 32;                                   // Input width
const int H = 32;                                   // Input height
const int C = 1;                                    // Input channel blocks
const int Fw = 3;                                   // Filter kernel width
const int Fh = 3;                                   // Filter kernel height
const int Fc = 1;                                   // Number of filter set blocks (i.e. number of output channel blocks)
const int Sw = 1;                                   // Filter horizontal (width) stride
const int Pl = 1;                                   // Zero-padding in on the left in the width dimension
const int Pr = 1;                                   // Zero-padding in on the right in the width dimension
const int Pt = 1;                                   // Zero-padding in on the top in the height dimension
const int Pb = 1;                                   // Zero-padding in on the bottom in the height dimension
*/

/*
// Case 5: 3x3 conv, 32x32 feature map, 1 channel blocks in, 1 channel blocks out, 2x2 bits = 2 bits
const int iprec = 2;                                // Input data precision
const int wprec = 2;                                // Weight precision
const int oprec = 2;                                // Output precision
const int W = 32;                                   // Input width
const int H = 32;                                   // Input height
const int C = 1;                                    // Input channel blocks
const int Fw = 3;                                   // Filter kernel width
const int Fh = 3;                                   // Filter kernel height
const int Fc = 1;                                   // Number of filter set blocks (i.e. number of output channel blocks)
const int Sw = 1;                                   // Filter horizontal (width) stride
const int Pl = 1;                                   // Zero-padding in on the left in the width dimension
const int Pr = 1;                                   // Zero-padding in on the right in the width dimension
const int Pt = 1;                                   // Zero-padding in on the top in the height dimension
const int Pb = 1;                                   // Zero-padding in on the bottom in the height dimension
*/


// Tensors
int i_t[H][W][C][iprec];                            // Input tensor
int w_t[Fc][Fh][Fw][C][wprec];                      // Filter weight tensor
int *i_tptr = (int*)i_t;                            // Input address pointer
int *w_tptr = (int*)w_t;                            // Weight address pointer
int s_t[Fc];                                        // Scaler array (for batch norm and scaled quantization)
int b_t[Fc];                                        // Bias array (for batch norm and conv/fc)
int *s_tptr = (int*)s_t;                            // Scaler address pointer
int *b_tptr = (int*)b_t;                            // Bias address pointer

// Computed MVU parameters to program into CSRs
int ilength[NJUMPS];                                     // note: there are only 4 elements, but creating 5 since index starts at 1
int ijump[NJUMPS];
int wlength[NJUMPS];
int wjump[NJUMPS];
int countdown;
int zigzag_step_sel;
int shacc_load_sel;
int ioffset;
int woffset;
int slength[NJUMPS];
int sjump[NJUMPS];
int blength[NJUMPS];
int bjump[NJUMPS];


// Internal parameters
int i_zzoff;
int w_zzoff;
int cntdwn;
int i_i[NJUMPS];
int i_j[NJUMPS];
int w_i[NJUMPS];
int w_j[NJUMPS];
int s_i[NJUMPS];
int s_j[NJUMPS];
int b_i[NJUMPS];
int b_j[NJUMPS];
int outaddr;

char* i_jump_str[5];
char* w_jump_str[5];
char* s_jump_str[5];
char* b_jump_str[5];


void assignInternalParams()
{
    for (int i=0; i < NJUMPS; i++)
    {
        i_j[i] = ijump[i];
        i_i[i] = ilength[i];
        w_i[i] = wlength[i];
        w_j[i] = wjump[i];
        s_i[i] = slength[i];
        s_j[i] = sjump[i];
        b_i[i] = blength[i];
        b_j[i] = bjump[i];
    }
    i_zzoff = 0;
    w_zzoff = 0;
    cntdwn = countdown;
    outaddr = 0;
    w_tptr += woffset;
    i_tptr += ioffset;   
}


int iw, id = 0;

void bumpZigZag(int curjump)
{
    if ((1 << curjump) & zigzag_step_sel)
    {
        int sh = (iw == 0) || (id == iprec-1);

        id++;
        iw--;

        if (sh)
        {
            iw += id+1;
            id = 0;

            if (iw >= iprec+wprec-1)
            {
                id = 0;
                iw = 0;
                sh = 0;
            }
            else if (iw >= wprec)
            {
                id = iw - wprec + 1;
                iw -= id;
            }
            else if (id >= iprec)
            {
                iw = id - iprec + 1;
                id -= iw;
            }
        }

        i_zzoff = id;
        w_zzoff = iw;
        printf("==> Bumped zig-zag: id=%2d, iw=%2d\n", id, iw);
    }
}


int getNextAddr(int *i, int *length, int *j, int **tptr, const char* tensorid, char** jump_str)
{
    int jump = -1;

    // Figure out which jump to take
    if (i[1] == 0 && i[2] == 0 && i[3] == 0 && i[4] == 0)
    {
        i[4] = length[4];
        i[3] = length[3];
        i[2] = length[2];
        i[1] = length[1];
        *tptr += j[0];
        jump = 0;
    }
    else if (i[2] == 0 && i[3] == 0 && i[4] == 0)
    {
        i[4] = length[4];
        i[3] = length[3];
        i[2] = length[2];
        i[1]--;
        *tptr += j[1];
        jump = 1;
    }
    else if (i[3] == 0 && i[4] == 0)
    {
        i[4] = length[4];
        i[3] = length[3];
        i[2]--;
        *tptr += j[2];
        jump = 2;
    }
    else if (i[4] == 0)
    {
        i[4] = length[4];
        i[3]--;
        *tptr += j[3];
        jump = 3;
    }
    else
    {
        i[4]--;
        *tptr += j[4];     
        jump = 4;
    }

    // Print out jump if there is a message
    if (jump_str[jump] != NULL)
        printf("==> %s_j[%d]: %s", tensorid, jump, jump_str[jump]);  

    return jump;
}

int getNextInput()
{
    return getNextAddr(i_i, ilength, i_j, &i_tptr, "i", i_jump_str);
}

int getNextWeight()
{
    return getNextAddr(w_i, wlength, w_j, &w_tptr, "w", w_jump_str);
}

int getNextScaler(int curjump)
{
    if ((1 << curjump) & shacc_load_sel)
    {
        return getNextAddr(s_i, slength, s_j, &s_tptr, "s", s_jump_str);
    }
    return -1;
}

int getNextBias(int curjump)
{
    if ((1 << curjump) & shacc_load_sel)
    {
        return getNextAddr(b_i, blength, b_j, &b_tptr, "b", b_jump_str);
    }
    return -1;
}


int genNextOutput(int curjump)
{
    if ((1 << curjump) & shacc_load_sel)
    {
        outaddr += oprec;
        printf("==> shacc load. Next output addr = %05d\n", outaddr);
        return 1;
    }
    return 0;
}


/*
 Computes parameters of a 2-D convolution for outputing a single line (or pixels) of the given length.

 Can handle padded top/bottom edges, left/right edges, and corners. NOTE: assumes that the 
 input feature map is large enough and the filter small enough that both the top/bottom and left/right
 edges are not covered at the same time, e.g. filter covers top edge but not bottom edge simulatneously.

 Parameters
 ----------
 Fw:     Filter/kernel width
 Fh:     Filter/kernel height
 Ow:     Output width in pixels (set to 1 when doing left/right edges/corners)
 Pt,Pb:  Top/bottom padding
 Pl,Pr:  Left/right padding     
*/
void setConv2dline(int Fw, int Fh, int Ow, int Pt=0, int Pb=0, int Pl=0, int Pr=0)
{
    // The filter height used here will be corrected by the padding amount
    int Fh_corr = Fh - Pt - Pb;
    int wrow_corr = 0;

    // Filter width will be corrected by the padding amount
    int Fw_corr = Fw - Pl - Pr;
    int wcol_corr = 0;

    // Initialize the address offsets for the input and weights
    ioffset = 0;
    woffset = 0;

    // Account for top/bottom padding
    if (Pt)
    {
        // Compute increased jump to skip rows in the filter not used when there is padding
        wrow_corr = wprec*C*Fw*Pt;

        // Set the weight base address to skip same number of rows in the weights as the padding
        woffset += wrow_corr;
    }
    else if (Pb)
    {
        // Compute extra jump to skip rows in the filter not used when there is padding
        wrow_corr = wprec*C*Fw*Pb;

        // No initial weight row skip is needed at the bottom edge

        // Set input offset to skip to bottom edge
        ioffset += iprec*C*(H-Fh_corr)*W;
    }

    // Account for left/right padding
    if (Pl)
    {
        // Compute increased jump to skip columns in the filter not used when there is padding
        wcol_corr = wprec*C*Pl;

        // Set the weight base address to skip the first columns in the weights the cover the padding
        woffset += wcol_corr;
    }
    else if (Pr)
    {
        // Compute increased jump to skip columns in the filter not used when there is padding
        wcol_corr = wprec*C*Pr;

        // Set the input offset to skip to the right edge of the input feature map
        ioffset += iprec*C*(W-Fw_corr);

        // No weight address offset needed here
    }
    
    ilength[4] = 0;
    ilength[3] = C*Fw_corr-1;                                                   // Width of filter window X number of input channel blocks
    ilength[2] = Fh_corr-1;                                                     // Height of filter
    ilength[1] = iprec*wprec*Fc-1;                                              // Number of bit combos X filter sets
    ijump[4] = 0;                                                               i_jump_str[4] = NULL;                   // not needed
    ijump[3] = iprec;                                                           i_jump_str[3] = NULL;                   // Move to next channel block/pixel
    ijump[2] = iprec*(C*(W-Fw_corr) + 1);                                       i_jump_str[2] = (char*)"Move to next row\n";
    ijump[1] = -iprec*(C*(Fh_corr-1)*W + Fw_corr*C - 1);                        i_jump_str[1] = (char*)"Move back to start of window\n";
    ijump[0] = -iprec*(C*(Fh_corr-1)*W + (Fw_corr-Sw-1)*C + 1);                 i_jump_str[0] = (char*)"Move window to right by horizontal stride\n";
    wlength[4] = C*Fw_corr-1;                                                   // Filter width
    wlength[3] = Fh_corr-1;                                                     // Filter height
    wlength[2] = iprec*wprec-1;                                                 // Number of bit combos
    wlength[1] = Fc-1;                                                          // Number of filter blocks
    wjump[4] = wprec;                                                           w_jump_str[4] = NULL;                   // Filter width
    wjump[3] = wprec + wcol_corr;                                               w_jump_str[3] = (char*)"Move to next filter row\n";
    wjump[2] = -wprec*(C*Fw*Fh_corr-1) + wcol_corr;                             w_jump_str[2] = (char*)"Move back to start of filter for next precision combo\n";
    wjump[1] = wprec + wrow_corr + wcol_corr;                                   w_jump_str[1] = (char*)"Move to next filter set block\n";
    wjump[0] = -wprec*(C*Fw*Fh*Fc-1) + wrow_corr + wcol_corr;                   w_jump_str[0] = (char*)"Move back to start of first filter set block for next window\n";
    countdown = (C * Fw_corr) * (Fh_corr) * (iprec * wprec) * (Fc) * (Ow);
    zigzag_step_sel = 0x7;                                                      // Step the zig-zag address generator on weight jump 2, 1, or 0
    shacc_load_sel = 0x3;                                                       // Load shift/accumulator on weight jump 0 and 1
    slength[4] = 0;                                                             // Don't need this inner loop
    slength[3] = 0;                                                             // Don't need this inner loop
    slength[2] = 0;                                                             // Don't need this inner loop. NOTE: this is length0 in the HW
    slength[1] = Fc-1;                                                          // NOTE: this is length1 in the HW
    sjump[4] = 0;                                                               s_jump_str[4] = (char *)"";
    sjump[3] = 0;                                                               s_jump_str[3] = (char *)"";
    sjump[2] = 0;                                                               s_jump_str[2] = (char *)"";
    sjump[1] = 1;                                                               s_jump_str[1] = (char*)"Move to next output channel block";          // NOTE: this is jump/stride 0 in the HW
    sjump[0] = -Fc+1;                                                           s_jump_str[0] = (char*)"Move back to first output channel block";    // NOTE: this is jump/stride 1 in the HW
    blength[4] = 0;                                                             // Don't need this inner loop
    blength[3] = 0;                                                             // Don't need this inner loop
    blength[2] = 0;                                                             // Don't need this inner loop
    blength[1] = Fc-1;                                                          // NOTE: this is length1 in the HW
    bjump[4] = 0;                                                               b_jump_str[4] = (char*)"";
    bjump[3] = 0;                                                               b_jump_str[3] = (char*)"";
    bjump[2] = 0;                                                               b_jump_str[2] = (char*)"";
    bjump[1] = 1;                                                               b_jump_str[1] = (char*)"Move to next output channel block";          // NOTE: this is jump/stride 0 in the HW
    bjump[0] = -Fc+1;                                                           b_jump_str[0] = (char*)"Move back to first output channel block";    // NOTE: this is jump/stride 1 in the HW    
}



int main()
{
    w_tptr += woffset;

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

    // Initialize the scaler tensor
    for (int fc=0; fc < Fc; fc++)
    {
        s_t[fc] = fc;
    }

    // Initialize the bias tensor
    for (int fc=0; fc < Fc; fc++)
    {
        b_t[fc] = fc;
    }

    int Ow_line_valid = (W-Fw+1)/Sw;

    // Compute parameters for convolution
    //setConv2dline(Fw, Fh, 1, Pt, 0, Pl, 0);        // top left corner
    //setConv2dline(Fw, Fh, Ow_line_valid, Pt, 0, 0, 0);        // Top edge
    //setConv2dline(Fw, Fh, 1, Pt, 0, 0, Pr);        // top right corner
    //setConv2dline(Fw, Fh, 1, 0, 0, Pl, 0);        // Left edge
    //setConv2dline(Fw, Fh, (W-Fw+1)/Sw);                       // Inner
    //setConv2dline(Fw, Fh, 1, 0, 0, 0, Pr);        // right edge
    //setConv2dline(Fw, Fh, 1, 0, Pb, Pl, 0);        // bottom left corner
    //setConv2dline(Fw, Fh, Ow_line_valid, 0, Pb, 0, 0);        // Bottom row
    setConv2dline(Fw, Fh, 1, 0, Pb, 0, Pr);        // bottom left corner
    assignInternalParams();

    // Print out the computed parameters
    printf("==Computed Parameters==\n");
    printf("ilength[4]=%10d, ilength[3]=%10d, ilength[2]=%10d, ilength[1]=%10d\n", ilength[4], ilength[3], ilength[2], ilength[1]);
    printf("ijump[4]  =%10d, ijump[3]  =%10d, ijump[2]  =%10d, ijump[1]  =%10d, ijump[0]  =%10d\n", ijump[4], ijump[3], ijump[2], ijump[1], ijump[0]);
    printf("wlength[4]=%10d, wlength[3]=%10d, wlength[2]=%10d, wlength[1]=%10d\n", wlength[4], wlength[3], wlength[2], wlength[1]);
    printf("wjump[4]  =%10d, wjump[3]  =%10d, wjump[2]  =%10d, wjump[1]  =%10d, wjump[0]  =%10d\n", wjump[4], wjump[3], wjump[2], wjump[1], wjump[0]);
    printf("slength[4]=%10d, slength[3]=%10d, slength[2]=%10d, slength[1]=%10d\n", slength[4], slength[3], slength[2], slength[1]);
    printf("sjump[4]  =%10d, sjump[3]  =%10d, sjump[2]  =%10d, sjump[1]  =%10d, sjump[0]  =%10d\n", sjump[4], sjump[3], sjump[2], sjump[1], sjump[0]);
    printf("blength[4]=%10d, blength[3]=%10d, blength[2]=%10d, blength[1]=%10d\n", blength[4], blength[3], blength[2], blength[1]);
    printf("bjump[4]  =%10d, bjump[3]  =%10d, bjump[2]  =%10d, bjump[1]  =%10d, bjump[0]  =%10d\n", bjump[4], bjump[3], bjump[2], bjump[1], bjump[0]);
    printf("ioffset=%d, woffset=%d, countdown=%d\n", ioffset, woffset, countdown);
    printf("\n");

    // Do the operation
    int w_whichjump = 0;
    int i_whichjump = 0;
    for (cntdwn = countdown; cntdwn > 0; cntdwn--)
    {
        printf("(%04d,%05d),", *(i_tptr+id), *(w_tptr+iw));
        i_whichjump = getNextInput();
        w_whichjump = getNextWeight();
        bumpZigZag(w_whichjump);
        genNextOutput(w_whichjump);
        if (getNextScaler(w_whichjump) >= 0)
            printf("==> s_tptr: %04d\n", *(s_tptr));
        if (getNextBias(w_whichjump) >= 0)
            printf("==> b_tptr: %04d\n", *(b_tptr));
    }
    

    printf("\n\nFinal locations: i_tptr=%d, w_tptr=%d, s_ptr=%d, b_tptr=%d\n", *i_tptr, *w_tptr, *s_tptr, *b_tptr);

    return 0;
}