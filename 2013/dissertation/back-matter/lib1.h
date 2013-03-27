#ifndef LIB1_H
#define LIB1_H

#include "mpi.h"

struct lib1_status {
    /* A flag to keep track of whether or not we should be recovering */
    int recovering;
    /* How many iterations are left in the operation */
    int iterations_left;
    /* The checksum values (only used on the checksum rank) */
    float *checksum;
    MPI_Comm lib1_comm_full;
    MPI_Comm lib1_comm;
    int checksum_rank;
};
typedef struct lib1_status lib1_status_t;

int lib1_init(MPI_Comm comm, lib1_status_t *status);

int lib1_recovery(float *v, int size_v, MPI_Comm comm, lib1_status_t *status, int correct);

int lib1_min_scale_vector(float *v, int size_v, int iterations, lib1_status_t *status);

int lib1_finalize(lib1_status_t *status);

#define LIB1_SUCCESS 0
#define LIB1_FAILURE 1
#define LIB1_UNRECOVERABLE 2

#endif
