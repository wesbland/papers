#ifndef LIB2_H
#define LIB2_H

#include "mpi.h"

struct lib2_status {
    int recovering;
    int operation_done;
    float *checksum;
    MPI_Comm lib2_comm;
    MPI_Comm lib2_comm_full;
    int checksum_rank;
};
typedef struct lib2_status lib2_status_t;

int lib2_init(MPI_Comm comm, lib2_status_t *status);

int lib2_recovery(float *result,
                  int size_v, 
                  MPI_Comm comm,
                  lib2_status_t *status, 
                  int correct);

int lib2_vector_add(float *v1, 
                    float *v2, 
                    int size_v, 
                    float *result,
                    lib2_status_t *status);
                         
int lib2_finalize(lib2_status_t *status);

#define LIB2_SUCCESS 0
#define LIB2_FAILURE 1
#define LIB2_UNRECOVERABLE 2

#endif
