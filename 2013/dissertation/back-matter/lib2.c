#include <stdio.h>
#include <stdlib.h>
#include <math.h>

#include "mpi.h"
#include "mpi-ext.h"
#include "lib2.h"

int lib2_init(MPI_Comm comm, lib2_status_t *status) {
    int rank, size;

    status->recovering = 0;
    
    /* Duplicate the communicator to have seperation of failures between libraries */
    if (MPI_SUCCESS != MPI_Comm_dup(comm, &status->lib2_comm_full)) {
        /* Revoke the new communicator in case it was created somehow and return. We'll try again from scratch */
        OMPI_Comm_revoke(status->lib2_comm_full);
        
        return LIB2_UNRECOVERABLE;
    }

    MPI_Comm_rank(status->lib2_comm_full, &rank);
    MPI_Comm_size(status->lib2_comm_full, &size);

    status->checksum_rank = size - 1;

    if (status->checksum_rank == rank) {
        /* Duplicate the communicator to have seperation of failures between libraries */
        if (MPI_SUCCESS != MPI_Comm_split(status->lib2_comm_full, MPI_UNDEFINED, rank, &status->lib2_comm)) {
            /* Revoke all communicators and start from scratch */
            OMPI_Comm_revoke(status->lib2_comm);
            OMPI_Comm_revoke(status->lib2_comm_full);

            return LIB2_UNRECOVERABLE;
        }
    } else {
        if (MPI_SUCCESS != MPI_Comm_split(status->lib2_comm_full, 0, rank, &status->lib2_comm)) {
            OMPI_Comm_revoke(status->lib2_comm);
            OMPI_Comm_revoke(status->lib2_comm_full);

            return LIB2_UNRECOVERABLE;
        }
    }
    
    return LIB2_SUCCESS;
}

int lib2_recovery(float *result, int size_v, MPI_Comm comm, lib2_status_t *status, int correct) {
    int size, i, rank;
    float *checksums;

    /* Duplicate the communicator to have seperation of failures between libraries */
    if (MPI_SUCCESS != MPI_Comm_dup(comm, &status->lib2_comm_full)) {
        /* Revoke the new communicator in case it was created somehow and return. We'll try again from scratch */
        OMPI_Comm_revoke(status->lib2_comm_full);

        return LIB2_FAILURE;
    }

    MPI_Comm_size(status->lib2_comm_full, &size);
    MPI_Comm_rank(status->lib2_comm_full, &rank);

    status->checksum_rank = size -1;

    if (status->checksum_rank == rank) {
        /* Duplicate the communicator to have seperation of failures between libraries */
        if (MPI_SUCCESS != MPI_Comm_split(status->lib2_comm_full, MPI_UNDEFINED, rank, &status->lib2_comm)) {
            OMPI_Comm_revoke(status->lib2_comm);
            OMPI_Comm_revoke(status->lib2_comm_full);

            return LIB2_FAILURE;
        }
    } else {
        /* Duplicate the communicator to have seperation of failures between libraries */
        if (MPI_SUCCESS != MPI_Comm_split(status->lib2_comm_full, 0, rank, &status->lib2_comm)) {
            OMPI_Comm_revoke(status->lib2_comm);
            OMPI_Comm_revoke(status->lib2_comm_full);

            return LIB2_FAILURE;
        }
    }

    /* Determine whether there is anything to recover and inform the new process */
    if (MPI_SUCCESS != MPI_Bcast(&status->recovering, 1, MPI_INT, status->checksum_rank, status->lib2_comm_full)) {
        OMPI_Comm_revoke(status->lib2_comm_full);
        OMPI_Comm_revoke(status->lib2_comm);

        return LIB2_FAILURE;
    }

    /* Broadcast the ABFT checksum and whether or not we were done with the
     * operation */
    if (status->recovering) {
        if (status->checksum_rank != rank) {
            status->checksum = (float *) malloc(sizeof(float) * size_v);
        }

        if (MPI_SUCCESS != MPI_Bcast(&status->checksum, size_v, MPI_FLOAT, status->checksum_rank, status->lib2_comm)) {
            OMPI_Comm_revoke(status->lib2_comm_full);
            OMPI_Comm_revoke(status->lib2_comm);

            return LIB2_FAILURE;
        }

        if (rank != status->checksum_rank) {
            checksums = (float *) malloc(sizeof(float) * size_v);

            if (MPI_SUCCESS != MPI_Allreduce(result, checksums, size_v, MPI_FLOAT, MPI_SUM, status->lib2_comm)) {
                OMPI_Comm_revoke(status->lib2_comm_full);
                OMPI_Comm_revoke(status->lib2_comm);
                free(checksums);

                return LIB2_FAILURE;
            }

            if (!correct) {
                for (i = 0; i < size_v; i++) {
                    result[i] = status->checksum[i] - checksums[i];
                }
            }

            free(checksums);
        }

        if (MPI_SUCCESS != MPI_Bcast(&status->operation_done, 1, MPI_INT, status->checksum_rank, status->lib2_comm_full)) {
            OMPI_Comm_revoke(status->lib2_comm_full);
            OMPI_Comm_revoke(status->lib2_comm);

            return LIB2_FAILURE;
        }
    }

    return LIB2_SUCCESS;
}

int lib2_vector_add(float *v1,
                    float *v2,
                    int size_v,
                    float *result,
                    lib2_status_t *status) {
    int i, rank, size;
    float *temp;
    MPI_Status mpi_status;
    
    MPI_Comm_rank(status->lib2_comm_full, &rank);
    MPI_Comm_size(status->lib2_comm_full, &size);

    if (!status->recovering) {
        status->operation_done = 0;

        if (status->checksum_rank == rank) {
            status->checksum = (float *) calloc(size_v, sizeof(float));
        }
    } else {
        status->recovering = 0;

        if (status->operation_done) {
            return LIB2_SUCCESS;
        }
    }
    
    temp = (float *) malloc(sizeof(float) * size_v);

    if (status->checksum_rank == rank) {
        if (MPI_SUCCESS != MPI_Sendrecv(v1, size_v, MPI_FLOAT, (size-1-rank), 31337, temp, size_v, MPI_FLOAT, (size-1-rank), 31337, status->lib2_comm, &mpi_status)) {
            /* Perform recovery */
            status->recovering = 1;

            OMPI_Comm_revoke(status->lib2_comm);

            return LIB2_FAILURE;
        }

        for (i = 0; i < size_v; i++) {
            result[i] = temp[i] + v2[i];
        }
    }

    /* Update the checksum */
    if (MPI_SUCCESS != MPI_Reduce(result, status->checksum, size_v, MPI_FLOAT, MPI_SUM, status->checksum_rank, status->lib2_comm_full)) {
        status->recovering = 1;

        OMPI_Comm_revoke(status->lib2_comm);
        OMPI_Comm_revoke(status->lib2_comm_full);

        return LIB2_UNRECOVERABLE;
    }

    status->operation_done = 1;

    return LIB2_SUCCESS;
}

int lib2_finalize(lib2_status_t *status) {
    int ret, done = 1;

    /* Make sure everyone agrees that the operations were successful */
    if (MPI_SUCCESS != (ret = OMPI_Comm_agree(status->lib2_comm_full, &done))) {
        /* Fail out of this function, the recovering process will still need us to call the recovery function to send it the resulting checksum */
        status->recovering = 1;

        OMPI_Comm_revoke(status->lib2_comm);
        OMPI_Comm_revoke(status->lib2_comm_full);

        return LIB2_FAILURE;
    }
    
    free(status);

    return LIB2_SUCCESS;
}
