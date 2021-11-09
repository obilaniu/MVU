#include <stdio.h>
#include <unistd.h>

//
// General parameters
//
#define NJUMPS 5
const int m = 10;                                   // Spacing between dimension blocks in generated tensors


// Prints out help on use of the command line
void printHelp()
{
	printf("Usage:\n");
	printf("  conv2d_jumps [-p] [-h]\n");
	printf("Options:\n");
	printf("  -p           Print out only the job parameters; do no simulate.\n");
	printf("  -h           Print help (this message)\n");
	return;
}


//
// Convolution parameters
//

/*
// Case 1: 3x3 conv, 10x10 feature map, 128 channels in, 128 channels out, 2x2 bits
const int iprec = 2;                                // Input data precision
const int wprec = 2;                                // Weight precision
const int oprec = 2;                                // Output precision
const int W = 10;                                   // Input width
const int H = 10;                                   // Input height
const int Ci = 128;                                 // Input channels
const int Fw = 3;                                   // Filter kernel width
const int Fh = 3;                                   // Filter kernel height
const int Co = 128;                                 // Number of output channels
const int Sw = 1;                                   // Filter horizontal (width) stride
const int Pl = 0;                                   // Zero-padding in on the left in the width dimension
const int Pr = 0;                                   // Zero-padding in on the right in the width dimension
const int Pt = 0;                                   // Zero-padding in on the top in the height dimension
const int Pb = 0;                                   // Zero-padding in on the bottom in the height dimension
*/

/*
// Case 1a: 3x3 conv, 10x10 feature map, 128 channels in, 256 channels out, 2x2 bits
const int iprec = 2;                                // Input data precision
const int wprec = 2;                                // Weight precision
const int oprec = 2;                                // Output precision
const int W = 10;                                   // Input width
const int H = 10;                                   // Input height
const int Ci = 128;                                 // Input channel 
const int Fw = 3;                                   // Filter kernel width
const int Fh = 3;                                   // Filter kernel height
const int Co = 256;                                 // Number of output channels
const int Sw = 1;                                   // Filter horizontal (width) stride
const int Pl = 0;                                   // Zero-padding in on the left in the width dimension
const int Pr = 0;                                   // Zero-padding in on the right in the width dimension
const int Pt = 0;                                   // Zero-padding in on the top in the height dimension
const int Pb = 0;                                   // Zero-padding in on the bottom in the height dimension
*/

// Case 2: 3x3 conv, 10x10 feature map, 128 channels in, 128 channels out, 1x1 bits 
/*
const int iprec = 1;                                // Input data precision
const int wprec = 1;                                // Weight precision
const int oprec = 1;                                // Output precision
const int W = 10;                                   // Input width
const int H = 10;                                   // Input height
const int Ci = 128;                                 // Input channels
const int Fw = 3;                                   // Filter kernel width
const int Fh = 3;                                   // Filter kernel height
const int Co = 128;                                 // Number of output channels
const int Sw = 1;                                   // Filter horizontal (width) stride
const int Pw = 0;                                   // Zero-padding in width dimension
const int Ph = 0;                                   // Zero-padding in height dimension
*/

// Case 3: 3x3 conv, 2x2 upper left corner of feature map, 128 channels in, 128 channels out, 2x2 bits
/*
const int iprec = 2;                                // Input data precision
const int wprec = 2;                                // Weight precision
const int oprec = 2;                                // Output precision
const int W = 2;                                    // Input width
const int H = 2;                                    // Input height
const int Ci = 128;                                 // Input channel blocks
const int Fw = 3;                                   // Filter kernel width
const int Fh = 3;                                   // Filter kernel height
const int Co = 128;                                 // Number of filter set blocks (i.e. number of output channel blocks)
const int Sw = 1;                                   // Filter horizontal (width) stride
const int Pw = 1;                                   // Zero-padding in width dimension
const int Ph = 1;                                   // Zero-padding in height dimension
*/

/*
// Case 4: 3x3 conv, 32x32 feature map, 64 channels in, 64 channels out, 8x8 bits
const int iprec = 8;                                // Input data precision
const int wprec = 8;                                // Weight precision
const int oprec = 8;                                // Output precision
const int W = 32;                                   // Input width
const int H = 32;                                   // Input height
const int Ci = 64;                                  // Input channel blocks
const int Fw = 3;                                   // Filter kernel width
const int Fh = 3;                                   // Filter kernel height
const int Co = 64;                                  // Number of filter set blocks (i.e. number of output channel blocks)
const int Sw = 1;                                   // Filter horizontal (width) stride
const int Pl = 1;                                   // Zero-padding in on the left in the width dimension
const int Pr = 1;                                   // Zero-padding in on the right in the width dimension
const int Pt = 1;                                   // Zero-padding in on the top in the height dimension
const int Pb = 1;                                   // Zero-padding in on the bottom in the height dimension
*/

// Case 5: 3x3 conv, 32x32 feature map, 1 channel blocks in, 1 channel blocks out, 2x2 bits, with left/right padding of 1
const int iprec = 2;                                // Input data precision
const int wprec = 4;                                // Weight precision
const int oprec = 2;                                // Output precision
const int W = 32+2;                                 // Input width (with padding of 1)
const int H = 32;                                   // Input height
const int Ci = 64;                                  // Input channels
const int Fw = 3;                                   // Filter kernel width
const int Fh = 3;                                   // Filter kernel height
const int Co = 64;                                  // Number of filter set blocks (i.e. number of output channel blocks)
const int Sw = 1;                                   // Filter horizontal (width) stride
const int Pl = 0;                                   // Zero-padding in on the left in the width dimension
const int Pr = 0;                                   // Zero-padding in on the right in the width dimension
const int Pt = 0;                                   // Zero-padding in on the top in the height dimension
const int Pb = 0;                                   // Zero-padding in on the bottom in the height dimension

// Tensors
const int C = Ci/64;
const int Fc = Co/64;
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
    for (int i; i < NJUMPS; i++)
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
    /*
    s_i[0] = slength[0];
    s_i[1] = slength[1];
    s_i[2] = slength[2];
    s_i[3] = slength[3];
    s_i[3] = slength[3];
    s_j[0] = sjump[0];
    s_j[1] = sjump[1];
    s_j[2] = sjump[2];
    s_j[3] = sjump[3];
    s_j[4] = sjump[4];
    b_i[0] = blength[0];
    b_i[1] = blength[1];
    b_i[2] = blength[2];
    b_i[3] = blength[3];
    b_j[0] = bjump[0];
    b_j[1] = bjump[1];
    b_j[2] = bjump[2];
    b_j[3] = bjump[3];
    b_j[4] = bjump[4];
    */
    
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
 Computes parameters for 2-D convolution for one output row 
 on interior of input map (VALID in TF lingo)
*/
void setConv2dlineValid()
{
    // Scheme 1: Compute all of the output pixels for a single line including all output channel blocks
    ilength[4] = 0;
    ilength[3] = C*Fw-1;                                                        // Width of filter window X number of input channel blocks
    ilength[2] = Fh-1;                                                          // Height of filter
    ilength[1] = iprec*wprec*Fc-1;                                              // Number of bit combos X filter sets
    ijump[4] = 0;                                                               i_jump_str[4] = NULL;                   // not needed
    ijump[3] = iprec;                                                           i_jump_str[3] = NULL;                   // Move to next channel block/pixel
    ijump[2] = iprec*(C*(W-Fw) + 1);                                            i_jump_str[2] = (char*)"Move to next row\n";
    ijump[1] = -iprec*(C*(Fh-1)*W + Fw*C - 1);                                  i_jump_str[1] = (char*)"Move back to start of window\n";
    ijump[0] = -iprec*(C*(Fh-1)*W + (Fw-Sw-1)*C + 1);                           i_jump_str[0] = (char*)"Move window to right by horizontal stride\n";
    wlength[4] = 0;                                                             // not needed
    wlength[3] = C*Fw*Fh-1;                                                     // Total size of one filter block
    wlength[2] = iprec*wprec-1;                                                 // Number of bit combos
    wlength[1] = Fc-1;                                                          // Number of filter blocks
    wjump[4] = 0;                                                               w_jump_str[4] = NULL;                   // not needed
    wjump[3] = wprec;                                                           w_jump_str[3] = NULL;                   // Move to next channel block/pixel
    wjump[2] = -wprec*(C*Fw*Fh-1);                                              w_jump_str[2] = (char*)"Move back to start of filter for next precision combo\n";
    wjump[1] = wprec;                                                           w_jump_str[1] = (char*)"Move to next filter set block\n";
    wjump[0] = -wprec*(C*Fw*Fh*Fc-1);                                           w_jump_str[0] = (char*)"Move back to start of first filter set block for next window\n";
    countdown = (C * Fw) * (Fh) * (iprec * wprec) * (Fc) * ((W-Fw+1)/Sw);
    zigzag_step_sel = 0x7;                                                      // Step the zig-zag address generator on weight jump 2, 1, or 0
    shacc_load_sel = 0x3;                                                       // Load shift/accumulator on weight jump 0 and 1
    woffset = 0;                                                                // Filter pointer offset
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


/*
 Computes parameters to do the convolution in the corner/edge of an input feature map
 when there is "virtual" padding (i.e. no actual zeros in memory). Needed where the output 
 feature map is the same size as the input feature map in width and height (i.e. SAME in TF lingo)
 Pl and Pr are mutully exclusive, as are Pt and Pb. Set the one not being used to 0.
*/
/*
void setConv2dlineEdgePadding(int Pl, int Pr, int Pt, int Pb)
{/*
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
        zigzag_step_sel = 2;
        shacc_load_sel = 1 << 3;       
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
        zigzag_step_sel = 2;
        shacc_load_sel = 1 << 3;   
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
        zigzag_step_sel = 2;
        shacc_load_sel = 1 << 3;    
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


int main(int argc, char *argv[])
{   
    int param_only = 0;
    int option;

    // Get command line options
    while((option = getopt(argc, argv, "ph")) != -1)
    {
        switch(option)
        {
            case 'p':
                param_only = 1;
                break;
            case 'h':
                printHelp();
                break;
        }
    }

    if (Ci % 64 != 0)
        printf("WARNING: number of input channels Ci=%d is not a even multiple of 64!", Ci);
    if (Co % 64 != 0)
        printf("WARNING: number of input channels Co=%d is not a even multiple of 64!", Co);

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


    // If the -p flag is set, end here
    if (param_only)
        return 0;

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