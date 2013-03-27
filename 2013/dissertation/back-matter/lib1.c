#include <stdio.h>
#include <stdlib.h>
#include <math.h>

#include "mpi.h"
#include "mpi-ext.h"
#include "lib1.h"

int lib1_init(MPI_Comm comm, lib1_status_t *status) {
    int rank, size;
    
    status->recovering = 0;
    
    /* Duplicate the communicator to have seperation of failures between libraries */
    if (MPI_SUCCESS != MPI_Comm_dup(comm, &status->lib1_comm_full)) {
        /* Revoke the new communicator in case it was created somehow and return. We'll try again from scratch */
        OMPI_Comm_revoke(status->lib1_comm_full);
        
        return LIB1_UNRECOVERABLE;
    }
    
    
    MPI_Comm_rank(status->lib1_comm_full, &rank);
    MPI_Comm_size(status->lib1_comm_full, &size);
    
    status->checksum_rank = size - 1;

    if (status->checksum_rank == rank) {
        /* Duplicate the communicator to have seperation of failures between libraries */
        if (MPI_SUCCESS != MPI_Comm_split(status->lib1_comm_full, MPI_UNDEFINED, rank, &status->lib1_comm)) {
            /* Revoke the new communicator in case it was created somehow and return. We'll try again from scratch */
            OMPI_Comm_revoke(status->lib1_comm);
            OMPI_Comm_revoke(status->lib1_comm_full);
            
            return LIB1_UNRECOVERABLE;
        }
    } else {
        /* Duplicate the communicator to have seperation of failures between libraries */
        if (MPI_SUCCESS != MPI_Comm_split(status->lib1_comm_full, 0, rank, &status->lib1_comm)) {
            /* Revoke the new communicator in case it was created somehow and return. We'll try again from scratch */
            OMPI_Comm_revoke(status->lib1_comm);
            OMPI_Comm_revoke(status->lib1_comm_full);
            
            return LIB1_UNRECOVERABLE;
        }
    }
   
    return LIB1_SUCCESS;
}

int lib1_recovery(float *v, int size_v, MPI_Comm comm, lib1_status_t *status, int correct) {
    int ret, size, rank, i;
    float *checksums;

    /* Duplicate the communicator to have seperation of failures between libraries */
    if (MPI_SUCCESS != MPI_Comm_dup(comm, &status->lib1_comm_full)) {
        /* Revoke the new communicator in case it was created somehow and return. We'll try again from scratch */
        OMPI_Comm_revoke(status->lib1_comm);

        return LIB1_FAILURE;
    }

    MPI_Comm_size(status->lib1_comm_full, &size);
    MPI_Comm_rank(status->lib1_comm_full, &rank);

    status->checksum_rank = size - 1;

    if (status->checksum_rank == rank) {
        /* Duplicate the communicator to have seperation of failures between libraries */
        if (MPI_SUCCESS != MPI_Comm_split(status->lib1_comm_full, MPI_UNDEFINED, rank, &status->lib1_comm)) {
            /* Revoke the new communicator in case it was created somehow and return. We'll try again from scratch */
            OMPI_Comm_revoke(status->lib1_comm);
            OMPI_Comm_revoke(status->lib1_comm_full);
            
            return LIB1_FAILURE;
        }
    } else {
        /* Duplicate the communicator to have seperation of failures between libraries */
        if (MPI_SUCCESS != MPI_Comm_split(status->lib1_comm_full, 0, rank, &status->lib1_comm)) {
            /* Revoke the new communicator in case it was created somehow and return. We'll try again from scratch */
            OMPI_Comm_revoke(status->lib1_comm);
            OMPI_Comm_revoke(status->lib1_comm_full);
            
            return LIB1_FAILURE;
        }
    }

    /* Determine whether there is anything to recover and inform the new process */
    if (MPI_SUCCESS != MPI_Bcast(&status->recovering, 1, MPI_INT, status->checksum_rank, status->lib1_comm_full)) {
        OMPI_Comm_revoke(status->lib1_comm_full);
        OMPI_Comm_revoke(status->lib1_comm);
        
        return LIB1_FAILURE;
    }

    /* Broadcast the ABFT checksum and iterations remaining and use them to recover */
    if (status->recovering) {
        if (status->checksum_rank != rank) {
            status->checksum = (float *) malloc(sizeof(float) * size_v);
        }

        if (MPI_SUCCESS != MPI_Bcast(&status->checksum, size_v, MPI_FLOAT, status->checksum_rank, status->lib1_comm_full)) {
            OMPI_Comm_revoke(status->lib1_comm_full);
            OMPI_Comm_revoke(status->lib1_comm);

            return LIB1_FAILURE;
        }

        if (rank != status->checksum_rank) {
            checksums = (float *) malloc(sizeof(float) * size_v);

            if (MPI_SUCCESS != (ret = MPI_Allreduce(v, checksums, size_v, MPI_FLOAT, MPI_SUM, status->lib1_comm))) {
                OMPI_Comm_revoke(status->lib1_comm_full);
                OMPI_Comm_revoke(status->lib1_comm);

                free(checksums);
                return LIB1_FAILURE;
            }

            if (!correct) {
                for (i = 0; i < size_v; i++) {
                    v[i] = status->checksum[i] - checksums[i];
                }
            }

            free(checksums);
        }

        if (MPI_SUCCESS != MPI_Bcast(&status->iterations_left, 1, MPI_INT, status->checksum_rank, status->lib1_comm_full)) {
            OMPI_Comm_revoke(status->lib1_comm_full);
            OMPI_Comm_revoke(status->lib1_comm);

            return LIB1_FAILURE;
        }
    }

    return LIB1_SUCCESS;
}

int lib1_min_scale_vector(float *v,
                          int size_v,
                          int iterations,
                          lib1_status_t *status) {
    float local_min, global_min;
    int i, ret, rank, size;
    
    MPI_Comm_rank(status->lib1_comm_full, &rank);
    MPI_Comm_size(status->lib1_comm_full, &size);

    if (!status->recovering) {
        status->iterations_left = iterations;

        if (status->checksum_rank == rank) {
            status->checksum = (float *) malloc(sizeof(float) * size_v);
        }
        
        /* Calculate the initial checksum */
        if (MPI_SUCCESS != (ret = MPI_Reduce(v, status->checksum, size_v, MPI_FLOAT, MPI_SUM, status->checksum_rank, status->lib1_comm_full))) {
            OMPI_Comm_revoke(status->lib1_comm);
            OMPI_Comm_revoke(status->lib1_comm_full);
            
            /* We can't recover from this error as we haven't created the checksum yet */
            return LIB1_UNRECOVERABLE;
        }

    } else {
        status->recovering = 0;

        if (0 == status->iterations_left) {
            return LIB1_SUCCESS;
        }
    }

    for (;status->iterations_left > 0; status->iterations_left--) {
        if (status->checksum_rank == rank) {
            /* Calculate the min among the local values */
            local_min = v[0];
            for(i = 1; i < size_v; i++) {
                if (local_min > v[i]) {
                    local_min = v[i];
                }
            }
    
            /* Calculate the min among all processes */
            if (MPI_SUCCESS != (ret = MPI_Allreduce(&local_min, &global_min, 1, MPI_FLOAT, MPI_MIN, status->lib1_comm))) {
                /* Perform recovery */
                status->recovering = 1;
    
                /* Revoke the internal communicator and return. */
                OMPI_Comm_revoke(status->lib1_comm);
                OMPI_Comm_revoke(status->lib1_comm_full);
    
                return LIB1_FAILURE;
            }
    
            /* Update the checksum */
            if (0 == rank) {
                if (MPI_SUCCESS != (ret = MPI_Send(&global_min, 1, MPI_FLOAT, status->checksum_rank, 0, status->lib1_comm_full))) {
                    status->recovering = 1;
                    OMPI_Comm_revoke(status->lib1_comm);
                    OMPI_Comm_revoke(status->lib1_comm_full);

                    return LIB1_FAILURE;
                }
            }
    
            /* Scale the local vector */
            for (i = 0; i < size_v; i++) {
                v[i] *= global_min;
            }
        } else {
            if (MPI_SUCCESS != (ret = MPI_Recv(&global_min, 1, MPI_FLOAT, 0, 0, status->lib1_comm_full, MPI_STATUS_IGNORE))) {
                status->recovering = 1;

                OMPI_Comm_revoke(status->lib1_comm);
                OMPI_Comm_revoke(status->lib1_comm_full);

                return LIB1_FAILURE;
            }

            for (i = 0; i < size_v; i++) {
                status->checksum[i] *= global_min;
            }
        }
    }
    
    return LIB1_SUCCESS;
}

int lib1_finalize(lib1_status_t *status) {
    int done = 1, ret;

    /* Make sure everyone agrees that the operations were successful */
    if (MPI_SUCCESS != (ret = OMPI_Comm_agree(status->lib1_comm_full, &done))) {
        /* Fail out of this function, the recovering process will still need us to call the recovery function to send it the resulting checksum */
        status->recovering = 1;

        OMPI_Comm_revoke(status->lib1_comm);
        OMPI_Comm_revoke(status->lib1_comm_full);

        return LIB1_FAILURE;
    }
    
    free(status);

    return LIB1_SUCCESS;
}
