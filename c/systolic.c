/* Includes */
#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <time.h>


/* Data Structure Forward Declaration & Typedef */
struct SYSTOLIC;
struct PE;
typedef struct SYSTOLIC SYSTOLIC;
typedef struct PE       PE;


/* Data Structure Definition */
struct SYSTOLIC{
	int       injecting, ejecting;
	
	uint32_t* pA[32];
	uint32_t* pB[32];
	uint32_t* pC[32];
	uint32_t  delayA[32][32];
	uint32_t  delayB[32][32];
	uint32_t  delayC[32][32];
	
	PE        lattice[32][32];
};

struct PE{
	uint32_t A;/* Data */
	uint32_t B;/* Weight */
	uint32_t C;/* Accumulator */
};



/* Systolic Array Functions */

/**
 * @brief Initialize/Reset the array to all-clear
 */

void sysaInit(SYSTOLIC* array){
	memset(array, 0, sizeof(*array));
}

/**
 * @brief Begin injecting matrices A and B.
 * 
 * Assumes default strides and offsets, but should be programmable instead.
 */

void sysaBeginInject(SYSTOLIC* array, int32_t* A, int32_t* B){
	int i;
	
	array->injecting = 1;
	
	for(int i=0;i<32;i++){
		array->pA = A + 40*i;
		array->pB = B + i;
	}
}

/**
 * @brief Begin ejecting matrix C.
 * 
 * Also assumes default strides and offsets, which should be programmable instead.
 */

void sysaBeginEject(SYSTOLIC* array, int32_t* C){
	int i;
	
	array->ejecting = 1;
	
	for(int i=0;i<32;i++){
		array->pC = C + 32*i;
	}
}

/**
 * @brief Stop injecting input matrices.
 * 
 * In practice, halt running the linear AGU programs, and instead inject 0s.
 */

void sysaStopInject(SYSTOLIC* array){
	array->injecting = 0;
}

/**
 * @brief Stop ejecting output matrix.
 * 
 * In practice, halt running the linear AGU program and write out nothing.
 */

void sysaStopEject(SYSTOLIC* array){
	array->ejecting = 0;
}

/**
 * @brief Perform one clock tick in the systolic array's operation.
 */

void sysaTick(SYSTOLIC* array){
	int i,j;
	
	if(array->injecting){
		for(i=0;i<32;i++){
			array->lattice[i][0].A = array->delayA[i][0];
			array->lattice[0][i].B = array->delayB[0][i];
			array->delayB[31][i] = *array->pA[i];
			array->delayB[i][31] = *array->pB[i];
			array->pA[i] += 1;
			array->pB[i] += 40;
		}
		memmove(array->delayA, array->delayA- 1, sizeof(array->delayA)-4);
		memmove(array->delayB, array->delayB-32, sizeof(array->delayB)-4*32);
	}else{
		for(i=0;i<32;i++){
			array->lattice[i][0].A = 0;
			array->lattice[0][i].B = 0;
		}
	}
	
	/* Do math in each PE */
	for(i=0;i<32;i++){
		for(j=0;j<32;j++){
			array->lattice[i][j].C += array->lattice[i][j].A*array->lattice[i][j].B;
		}
	}
	/* Data moves East */
	for(i=31;i>=0;i--){
		for(j=30;j>=0;j--){
			array->lattice[i][j].A = array->lattice[i][j+1].A;
		}
	}
	/* Weights move South */
	for(i=30;i>=0;i--){
		for(j=31;j>=0;j--){
			array->lattice[i][j].B = array->lattice[i+1][j].B;
		}
	}
	
	if(array->ejecting){
		for(i=0;i<32;i++){
			array->delayA[i][0] = array->lattice[i][0].C;
		}
		memmove(array->delayC, array->delayC-1, sizeof(array->delayC)-4);
	}else{
		for(i=0;i<32;i++){
			array->lattice[i][0].C = 0;
		}
	}
}



/* Main */
int main(int argc, char* argv[]){
	int32_t  A[32][40], B[40][32], C[32][32], D[32][32];
	int      i, j, k;
	int      seedVal, mismatch = 0;
	SYSTOLIC array;
	
	/* PRNG seed */
	seedVal = time();
	seed(seedVal);
	printf("Seeding with value \'%d\'\n", seedVal);
	
	/* Random init */
	for(i=0;i<32;i++){
		for(j=0;j<40;j++){
			A[i][j] = rand()%3 - 1;
			B[j][i] = rand()%3 - 1;
		}
	}
	
	/* Compute ground truth matrix multiplication. */
	for(i=0;i<32;i++){
		for(j=0;j<32;j++){
			C[i][j] = 0;
			for(k=0;k<40;k++){
				C[i][j] += A[i][k]*B[k][j];
			}
		}
	}
	
	
	/* Simulate Systolic Array */
	sysaInit(&array);
	
	/**
	 * Pump data into Systolic Array, then extract it.
	 */
	
	sysaBeginInject(&array, A, B);
	for(i=0;i<40;i++){
		sysaTick(&array);
	}
	sysaStopInject(&array);
	sysaBeginEject(&array, D);
	for(i=0;i<64;i++){
		sysaTick(&array);
	}
	sysaStopEject(&array);
	
	/* Check for mismatch */
	for(i=0;i<32;i++){
		for(j=0;j<32;j++){
			if(C[i][j] != D[i][j]){
				mismatch++;
				printf("Mismatch at (%2d, %2d): %d != %d!\n", i,j,
				       C[i][j], D[i][j]);
			}
		}
	}
	if(!mismatch){
		printf("Test passed\n");
	}else{
		printf("Test failed\n");
	}
	
	return 0;
}
