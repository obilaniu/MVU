#include <stdio.h>

//
// General parameters
//
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
const int Pl = 0;                                   // Zero-padding in on the left in the width dimension
const int Pr = 0;                                   // Zero-padding in on the right in the width dimension
const int Pt = 0;                                   // Zero-padding in on the top in the height dimension
const int Pb = 0;                                   // Zero-padding in on the bottom in the height dimension


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
int ilength[4];
int ijump[4];
int wlength[4];
int wjump[4];
int countdown;
int bumpzigzag_on;
int loadshacc_on;
int ioffset;
int woffset;
int slength[4];
int sjump[4];
int blength[4];
int bjump[4];


// Internal parameters
int i_j[5];
int i_zzoff;
int w_zzoff;
int cntdwn;
int i_i[4];
int w_i[4];
int w_j[5];
int s_i[4];
int s_j[5];
int b_i[4];
int b_j[5];
int outaddr;

char* i_jump_str[4];
char* w_jump_str[4];
char* s_jump_str[4];
char* b_jump_str[4];


void assignInternalParams()
{
    i_j[0] = iprec;                                 // Move to next channel block and/or column
    i_j[1] = ijump[0];
    i_j[2] = ijump[1];
    i_j[3] = ijump[2];
    i_j[4] = ijump[3];
    i_zzoff = 0;
    w_zzoff = 0;
    cntdwn = countdown;
    i_i[0] = ilength[0];
    i_i[1] = ilength[1];
    i_i[2] = ilength[2];
    i_i[3] = ilength[3];
    w_i[0] = wlength[0];
    w_i[1] = wlength[1];
    w_i[2] = wlength[2];
    w_i[3] = wlength[3];
    w_j[0] = wprec;                                 // Move to next channel block and/or column
    w_j[1] = wjump[0];
    w_j[2] = wjump[1];
    w_j[3] = wjump[2];
    w_j[4] = wjump[3];
    outaddr = 0;
    w_tptr += woffset;
    i_tptr += ioffset;
    s_i[0] = slength[0];
    s_i[1] = slength[1];
    s_i[2] = slength[2];
    s_i[3] = slength[3];
    s_j[0] = 0;                                 
    s_j[1] = sjump[0];
    s_j[2] = sjump[1];
    s_j[3] = sjump[2];
    s_j[4] = sjump[3];
    b_i[0] = blength[0];
    b_i[1] = blength[1];
    b_i[2] = blength[2];
    b_i[3] = blength[3];
    b_j[0] = 0;                                 
    b_j[1] = bjump[0];
    b_j[2] = bjump[1];
    b_j[3] = bjump[2];
    b_j[4] = bjump[3];
    
}


int iw, id = 0;

void bumpZigZag(int curjump)
{
    if (curjump >= bumpzigzag_on)
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
    if (i[0] == 0 && i[1] == 0 && i[2] == 0 && i[3] == 0)
    {
        i[0] = length[0];
        i[1] = length[1];
        i[2] = length[2];
        i[3] = length[3];
        *tptr += j[4];
        printf("\n==> %s_j4: %s\n", tensorid, jump_str[3]);
        return 4;
    }
    else if (i[0] == 0 && i[1] == 0 && i[2] == 0)
    {
        i[0] = length[0];
        i[1] = length[1];
        i[2] = length[2];
        i[3]--;
        *tptr += j[3];
        printf("\n==> %s_j3: %s\n", tensorid, jump_str[2]);
        return 3;
    }
    else if (i[0] == 0 && i[1] == 0)
    {
        i[0] = length[0];
        i[1] = length[1];
        i[2]--;
        *tptr += j[2];
        printf("\n==> %s_j2: %s\n", tensorid, jump_str[1]);
        return 2;
    }
    else if (i[0] == 0)
    {
        i[0] = length[0];
        i[1]--;
        *tptr += j[1];
        printf("==> %s_j1: %s\n", tensorid, jump_str[0]);
        
        return 1;
    }
    else
    {
        i[0]--;
        *tptr += j[0];
        return 0;
    }  
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
    if ((1 << curjump) >= loadshacc_on)
    {
        return getNextAddr(s_i, slength, s_j, &s_tptr, "s", s_jump_str);
    }
    return -1;
}

int getNextBias(int curjump)
{
    if ((1 << curjump) >= loadshacc_on)
    {
        return getNextAddr(b_i, blength, b_j, &b_tptr, "b", b_jump_str);
    }
    return -1;
}


int genNextOutput(int curjump)
{
    if ((1 << curjump) >= loadshacc_on)
    {
        outaddr += oprec;
        printf("==> shacc load. Next output addr = %05d\n", outaddr);
    }
    return 0;
}


/*
 Computes parameters for 2-D convolution for one output row 
 on interior of input map (VALID in TF lingo)
*/
void setConv2dlineValid()
{
    // Scheme 1: Compute all output pixels for a single line, but only the first output channel block
    // -note that this would require adding in jumps to the output address to skip over the locations
    //  for the next output channel blocks
    // -subsequent conv2dline operations would need to be executed to fill in the remaining output
    //  channel blocks
    /*
    ilength0 = C*Fw-1;
    ilength1 = Fh-1;
    ilength2 = iprec*wprec-1;
    ilength3 = ((W-Fw+1)/Sw - 1);
    ijump0 = iprec*(C*(W-Fw) + 1);                    i_jump0_str = "Move to next row";
    ijump1 = -iprec*(C*(Fh-1)*W + Fw*C - 1);          i_jump1_str = "Move back to start of window; bump zig-zag";
    ijump2 = -iprec*(C*(Fh-1)*W + (Fw-Sw-1)*C + 1);   i_jump2_str = "Move window to right by horizontal stride";
    ijump3 = 0;                                       i_jump3_str = "";
    wlength0 = C*Fw*Fh-1;                             // Total size of a filter
    wlength1 = 0;
    wlength2 = 0;
    wlength3 = 0;
    wjump0 = -wprec*(C*Fw*Fh-1);                      // Move back to start of filter for next precision combo; Bump zig-zag
    wjump1 = 0;
    wjump2 = 0;
    wjump3 = wjump0;
    countdown = (C * Fw) * (Fh) * (iprec * wprec) * ((W-Fw+1)/Sw);
    */

    // Scheme 2: Compute all of the output pixels for a single line including all output channel blocks
    ilength[0] = C*Fw-1;                                                          // Width of filter window X number of input channel blocks
    ilength[1] = Fh-1;                                                            // Height of filter
    ilength[2] = iprec*wprec*Fc-1;                                                // Number of bit combos X filter sets
    ilength[3] = 0;
    ijump[0] = iprec*(C*(W-Fw) + 1);                                              i_jump_str[0] = (char*)"Move to next row";
    ijump[1] = -iprec*(C*(Fh-1)*W + Fw*C - 1);                                    i_jump_str[1] = (char*)"Move back to start of window";
    ijump[2] = -iprec*(C*(Fh-1)*W + (Fw-Sw-1)*C + 1);                             i_jump_str[2] = (char*)"Move window to right by horizontal stride";
    ijump[3] = ijump[2];                                                          i_jump_str[3] = (char*)"Move window to right by horizontal stride";
    wlength[0] = C*Fw*Fh-1;                                                       // Total size of one filter block
    wlength[1] = iprec*wprec-1;                                                   // Number of bit combos
    wlength[2] = Fc-1;                                                            // Number of filter blocks
    wlength[3] = 0;
    wjump[0] = -wprec*(C*Fw*Fh-1);                                                w_jump_str[0] = (char*)"Move back to start of filter for next precision combo";
    wjump[1] = wprec;                                                             w_jump_str[1] = (char*)"Move to next filter set block";
    wjump[2] = -wprec*(C*Fw*Fh*Fc-1);                                             w_jump_str[2] = (char*)"Move back to start of first filter set block for next window";
    wjump[3] = wjump[2];                                                          w_jump_str[3] = (char*)"Move back to start of first filter set block for next window";
    countdown = (C * Fw) * (Fh) * (iprec * wprec) * (Fc) * ((W-Fw+1)/Sw);
    bumpzigzag_on = 1;
    loadshacc_on = 1 << 2;
    woffset = 0;                                                                  // Filter pointer offset
    slength[0] = 0;                                                               // Don't need this inner loop
    slength[1] = 0;                                                               // Don't need this inner loop
    slength[2] = 0;                                                               // Don't need this inner loop. NOTE: this is length0 in the HW
    slength[3] = Fc-1;                                                            // NOTE: this is length1 in the HW
    sjump[0] = 0;                                                                 s_jump_str[0] = (char *)"";
    sjump[1] = 0;                                                                 s_jump_str[1] = (char *)"";
    sjump[2] = 1;                                                                 s_jump_str[2] = (char*)"Move to next channel block";          // NOTE: this is jump/stride 0 in the HW
    sjump[3] = -Fc+1;                                                             s_jump_str[3] = (char*)"Move back to first channel block";    // NOTE: this is jump/stride 1 in the HW
    blength[0] = 0;                                                               // Don't need this inner loop
    blength[1] = 0;                                                               // Don't need this inner loop
    blength[2] = 0;                                                               // Don't need this inner loop
    blength[3] = Fc-1;                                                            // NOTE: this is length1 in the HW
    bjump[0] = 0;                                                                 b_jump_str[0] = (char*)"";
    bjump[1] = 0;                                                                 b_jump_str[1] = (char*)"";
    bjump[2] = 1;                                                                 b_jump_str[2] = (char*)"Move to next channel block";          // NOTE: this is jump/stride 0 in the HW
    bjump[3] = -Fc+1;                                                             b_jump_str[3] = (char*)"Move back to first channel block";    // NOTE: this is jump/stride 1 in the HW
}


/*
 Computes parameters to do the convolution in the corner/edge of an input feature map
 when there is "virtual" padding (i.e. no actual zeros in memory). Needed where the output 
 feature map is the same size as the input feature map in width and height (i.e. SAME in TF lingo)
 Pl and Pr are mutully exclusive, as are Pt and Pb. Set the one not being used to 0.
*/
/*
void setConv2dlineEdgePadding(int Pl, int Pr, int Pt, int Pb)
{
    // Upper left corner
    if (Pt > 0 && Pl > 0)
    {
        printf("=Upper left corner=\n");
        woffset = wprec*C*(Pt*Fw + Pl);                                             // Start on weight tile within in the first filter block
        ioffset = 0;
        ilength0 = C*(Fw-Pl)-1;                                                     // Width of filter window X number of input channel blocks
        ilength1 = Fh-Pt-1;                                                         // Height of filter
        ilength2 = iprec*wprec*Fc-1;                                                // Number of bit combos X number of filter sets
        ilength3 = 0;                                                               // Not needed. Countdown will terminate.
        ijump0 = iprec*(C*(W-Fw+Pl) + 1);                                           i_jump0_str = (char*)"Move to next row";
        ijump1 = -iprec*(C*(Fh-Pt-1)*W + (Fw-Pl)*C - 1);                            i_jump1_str = (char*)"Move back to start of window";
        ijump2 = ijump1;                                                            i_jump2_str = i_jump1_str;
        ijump3 = ijump1;                                                            i_jump3_str = i_jump1_str;
        wlength0 = C*(Fw-Pl)-1;                                                     // One subset of the columns of the filter
        wlength1 = Fh-Pt-1;                                                         // Subset of the rows of the filter
        wlength2 = iprec*wprec-1;                                                   // Number of bit combos
        wlength3 = Fc-1;                                                            // Number of filter sets, but don't really need since countdown will terminate
        wjump0 = wprec*(C*Pl+1);                                                    w_jump0_str = (char*)"Jump to next row of filter set";
        wjump1 = -wprec*(C*Fw*Fh - 1) + woffset;                                    w_jump1_str = (char*)"Move back to start of filter for next bit combo";
        wjump2 = wprec + woffset;                                                   w_jump2_str = (char*)"Move to next filter set block";
        wjump3 = 0;                                                                 w_jump3_str = (char*)"Not needed!";
        countdown = (C * (Fw-Pl)) * (Fh-Pt) * (iprec * wprec) * (Fc);
        bumpzigzag_on = 2;
        loadshacc_on = 1 << 3;       
    }
    // Upper right corner
    else if (Pt > 0 && Pr > 0)
    {
        printf("=Upper right corner=\n");
        woffset = wprec*C*Pt*Fw;                                                    // Start on correct row of first filter block
        ioffset = iprec*(C*(W-Fw+Pr));                                              // Start on right edge of input feature map
        ilength0 = C*(Fw-Pr)-1;                                                     // Width of filter window X number of input channel blocks
        ilength1 = Fh-Pt-1;                                                         // Height of filter
        ilength2 = iprec*wprec*Fc-1;                                                // Number of bit combos X number of filter sets
        ilength3 = 0;                                                               // Not needed. Countdown will terminate.
        ijump0 = iprec*(C*(W-Fw+Pr) + 1);                                           i_jump0_str = (char*)"Move to next row";
        ijump1 = -iprec*(C*(Fh-Pt-1)*W + (Fw-Pr)*C - 1);                            i_jump1_str = (char*)"Move back to start of window";
        ijump2 = ijump1;                                                            i_jump2_str = i_jump1_str;
        ijump3 = ijump1;                                                            i_jump3_str = i_jump1_str;
        wlength0 = C*(Fw-Pr)-1;                                                     // One subset of the columns of the filter
        wlength1 = Fh-Pt-1;                                                         // Subset of the rows of the filter
        wlength2 = iprec*wprec-1;                                                   // Number of bit combos
        wlength3 = Fc-1;                                                            // Number of filter sets, but don't really need since countdown will terminate
        wjump0 = wprec*(C*Pr+1);                                                    w_jump0_str = (char*)"Jump to next row of filter set";
        wjump1 = -wprec*(C*Fw*Fh - 1) + wprec*C*Pr + woffset;                       w_jump1_str = (char*)"Move back to start of filter for next bit combo";
        wjump2 = wprec*(C*Pr + 1) + woffset;                                        w_jump2_str = (char*)"Move to next filter set block";
        wjump3 = 0;                                                                 w_jump3_str = (char*)"Not needed!";
        countdown = (C * (Fw-Pr)) * (Fh-Pt) * (iprec * wprec) * (Fc);
        bumpzigzag_on = 2;
        loadshacc_on = 1 << 3;   
    }
    // Lower left corner
    // 
    else if (Pb > 0 && Pl > 0)
    {
        printf("=Lower left corner=\n");
        woffset = wprec*C*Pl;                                                       // Start on weight tile within in the first filter block
        ioffset = iprec*C*W*(H-1-Pb);                                               // Input row position near bottom edge
        ilength0 = C*(Fw-Pl)-1;                                                     // Width of filter window X number of input channel blocks
        ilength1 = Fh-Pb-1;                                                         // Height of filter
        ilength2 = iprec*wprec*Fc-1;                                                // Number of bit combos X number of filter sets
        ilength3 = 0;                                                               // Not needed. Countdown will terminate.
        ijump0 = iprec*(C*(W-Fw+Pl) + 1);                                           i_jump0_str = (char*)"Move to next row";
        ijump1 = -iprec*(C*(Fh-Pb-1)*W + (Fw-Pl)*C - 1);                            i_jump1_str = (char*)"Move back to start of window";
        ijump2 = ijump1;                                                            i_jump2_str = i_jump1_str;
        ijump3 = ijump1;                                                            i_jump3_str = i_jump1_str;
        wlength0 = C*(Fw-Pl)-1;                                                     // One subset of the columns of the filter
        wlength1 = Fh-Pb-1;                                                         // Subset of the rows of the filter
        wlength2 = iprec*wprec-1;                                                   // Number of bit combos
        wlength3 = Fc-1;                                                            // Number of filter sets, but don't really need since countdown will terminate
        wjump0 = wprec*(C*Pl+1);                                                    w_jump0_str = (char*)"Jump to next row of filter set";
        wjump1 = -wprec*(C*Fw*(Fh-Pb) - 1) + woffset;                               w_jump1_str = (char*)"Move back to start of filter for next bit combo";
        wjump2 = wprec*(C*Fw + 1) + woffset;                                        w_jump2_str = (char*)"Move to next filter set block";
        wjump3 = 0;                                                                 w_jump3_str = (char*)"Not needed!";
        countdown = (C * (Fw-Pl)) * (Fh-Pb) * (iprec * wprec) * (Fc);
        bumpzigzag_on = 2;
        loadshacc_on = 1 << 3;    
    }
    // Lower right corner
    else if (Pb > 0 && Pr > 0)
    {

    }
    // Left edge
    else if (Pl > 0)
    {

    }
    // Right edge
    else if (Pr)
    {

    }
    else
    {
        printf("Error! Not a valid padding config!\n");
    }
    
        
}
*/


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


    // Compute parameters for convolution
    //setConv2dlineEdgePadding(1, 0, 1, 0);           // Upper-left corner
    setConv2dlineValid();                           // Inner
    //setConv2dlineEdgePadding(1, 0, 0, 1);           // Lower-left corner
    assignInternalParams();

    // Print out the computed parameters
    printf("==Computed Parameters==\n");
    printf("ilength0=%10d, ilength1=%10d, ilength2=%10d, ilength3=%10d\n", ilength[0], ilength[1], ilength[2], ilength[3]);
    printf("ijump0  =%10d, ijump1  =%10d, ijump2  =%10d, ijump3  =%10d\n", ijump[0], ijump[1], ijump[2], ijump[3]);
    printf("wlength0=%10d, wlength1=%10d, wlength2=%10d, wlength3=%10d\n", wlength[0], wlength[1], wlength[2], wlength[3]);
    printf("wjump0  =%10d, wjump1  =%10d, wjump2  =%10d, wjump3  =%10d\n", wjump[0], wjump[1], wjump[2], wjump[3]);
    printf("slength0=%10d, slength1=%10d, slength2=%10d, slength3=%10d\n", slength[0], slength[1], slength[2], slength[3]);
    printf("sjump0  =%10d, sjump1  =%10d, sjump2  =%10d, sjump3  =%10d\n", sjump[0], sjump[1], sjump[2], sjump[3]);
    printf("blength0=%10d, blength1=%10d, blength2=%10d, blength3=%10d\n", blength[0], blength[1], blength[2], blength[3]);
    printf("bjump0  =%10d, bjump1  =%10d, bjump2  =%10d, bjump3  =%10d\n", bjump[0], bjump[1], bjump[2], bjump[3]);
    printf("ioffset=%d, woffset=%d, countdown=%d\n", ioffset, woffset, countdown);
    printf("\n");

    // Do the operation
    int w_whichjump = 0;
    int i_whichjump = 0;
    for (cntdwn = countdown; cntdwn > 0; cntdwn--)
    {
        printf("(%04d,%05d),", *(i_tptr), *(w_tptr));
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