#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#include "lib1.h"
#include "lib2.h"

#include "mpi.h"
#include "mpi-ext.h"

void repair(float *v1, float *v2, float *result, int size_v, MPI_Comm broken, MPI_Comm* repaired);

char *filename;
enum progression {
    START,
    INIT_LIB1_V1,
    INIT_LIB1_V2,
    INIT_LIB2,
    SCALE1,
    SCALE2,
    ADD
};
enum progression alg_status = START;
lib1_status_t lib1_status1, lib1_status2;
lib2_status_t lib2_status;

int main(int argc, char **argv) {
    FILE *input;
    int rank, size;
    MPI_Comm parent, *world, *repair_comm;
    float *vector1, *vector2, *result, *final_total;
    int size_vector, temp, ret, old_rank;
    char *buffer, *next;
    int i, done;
    MPI_Status mpi_status;

    if (argc < 3) {
        fprintf(stderr, "Usage: ./vector_math vector1_file vector2_file\n");
        exit(1);
    }
    
    world = (MPI_Comm *) malloc(sizeof(MPI_Comm));

    filename = strdup(argv[1]);

    buffer = (char *) malloc(sizeof(char) * 1024);
    
    input = fopen(argv[1], "r");
    buffer = fgets(buffer, 1024, input);
    
    /* We don't do a ton of error checking here. Don't let the line length overflow the buffer. You can use as many lines as you like. Seperate floats by whitespace. */
    size_vector = (int) strtol(buffer, &next, 10);
    if (size_vector == 0 && buffer == next) {
        fprintf(stderr, "Invalid input file\n");
        exit(1);
    }
    buffer = next;
    vector1 = (float *) calloc(size_vector, sizeof(float));
    for (i = 0; i < size_vector; i++) {
        vector1[i] = (float) strtod(buffer, &next);
        if (buffer == next || NULL == next) {
            buffer = fgets(buffer, 1024, input);
            if (NULL == next) {
                i--;
            }
        } else {
            buffer = next;
        }
    }

    result = (float *) malloc(sizeof(float) * size_vector);
    final_total = (float *) malloc(sizeof(float) * size_vector);
    
    input = fopen(argv[2], "r");
    buffer = fgets(buffer, 1024, input);
    
    /* We don't do a ton of error checking here. Don't let the line length overflow the buffer. You can use as many lines as you like. Seperate floats by whitespace. */
    temp = (int) strtol(buffer, &next, 10);
    if (temp == 0 && buffer == next) {
        fprintf(stderr, "Invalid input file\n");
        exit(1);
    }
    
    if (temp != size_vector) {
        fprintf(stderr, "Vectors should be the same size\n");
        exit(1);
    }
    buffer = next;
    
    vector2 = (float *) calloc(size_vector, sizeof(float));
    for (i = 0; i < size_vector; i++) {
        vector2[i] = (float) strtod(buffer, &next);
        if (buffer == next || NULL == next) {
            buffer = fgets(buffer, 1024, input);
            if (NULL == next) {
                i--;
            }
        } else {
            buffer = next;
        }
    }
    
    MPI_Init(&argc, &argv);
    
    MPI_Comm_get_parent(&parent);
    
    /* This is not an original process, perform recovery */
    if (MPI_COMM_NULL != parent) {
        /* For now, abort if there is an error. Trying to handle all of the cases for failure during startup is unnecessarily complicated. Just abort the new processes and start over if there's a problem. */
        MPI_Comm_set_errhandler(parent, MPI_ERRORS_ARE_FATAL);

        /* Join the rest of the processes */
        repair_comm = (MPI_Comm *) malloc(sizeof(MPI_Comm));
        MPI_Intercomm_merge(parent, true, repair_comm);
        
        MPI_Comm_free(&parent);

        MPI_Recv(&old_rank, 1, MPI_INT, 0, 31337, *repair_comm, &mpi_status);

        MPI_Comm_split(*repair_comm, 0, old_rank, world);

        MPI_Comm_rank(*world, &rank);
        MPI_Comm_size(*world, &size);

        size_vector /= (size - 1);

        /* Now we will start recovering from failures as we have one big world again and it is possible to reason about the status of the comm. */
        MPI_Comm_set_errhandler(*world, MPI_ERRORS_RETURN);
        
        /* Figure out where we were before we died */
        if (MPI_SUCCESS != (ret = MPI_Allreduce(&alg_status, &alg_status, 1, MPI_INT, MPI_MAX, *world))) {
            /* Perform recovery */
            OMPI_Comm_revoke(*world);
            repair(vector1, vector2, result, size_vector, *world, world);
        }

        /* Perform ABFT recovery */
        if (INIT_LIB1_V1 >= alg_status) {
            if (MPI_SUCCESS != (ret = lib1_recovery(vector1, size_vector, *world, &lib1_status1, 0))) {
                /* Failure during the library, perform recovery */
                OMPI_Comm_revoke(*world);
                repair(vector1, vector2, result, size_vector, *world, world);
            }
        } else {
            if (MPI_SUCCESS != (ret = lib1_init(*world, &lib1_status1))) {
                /* Failure during the library, perform recovery */
                OMPI_Comm_revoke(*world);
                repair(vector1, vector2, result, size_vector, *world, world);
            }
            alg_status = INIT_LIB1_V1;
        }

        /* Perform ABFT recovery */
        if (INIT_LIB1_V2 >= alg_status) {
            if (MPI_SUCCESS != (ret = lib1_recovery(vector2, size_vector, *world, &lib1_status2, 0))) {
                /* Failure during the library, perform recovery */
                OMPI_Comm_revoke(*world);
                repair(vector1, vector2, result, size_vector, *world, world);
            }
        } else {
            if (MPI_SUCCESS != (ret = lib1_init(*world, &lib1_status2))) {
                /* Failure during the library, perform recovery */
                OMPI_Comm_revoke(*world);
                repair(vector1, vector2, result, size_vector, *world, world);
            }
            alg_status = INIT_LIB1_V2;
        }

        if (INIT_LIB2 >= alg_status) {
            if (MPI_SUCCESS != (ret = lib2_recovery(result, size_vector, *world, &lib2_status, 0))) {
                /* Failure during the library, perform recovery */
                OMPI_Comm_revoke(*world);
                repair(vector1, vector2, result, size_vector, *world, world);
            }
        } else {
            if (MPI_SUCCESS != (ret = lib2_init(*world, &lib2_status))) {
                /* Failure during the library, perform recovery */
                OMPI_Comm_revoke(*world);
                repair(vector1, vector2, result, size_vector, *world, world);
            }
            alg_status = INIT_LIB2;
        }
    } else {
        /* Set the errhandler for MCW so it gets propagated to all other communicators */
        MPI_Comm_set_errhandler(MPI_COMM_WORLD, MPI_ERRORS_RETURN);

        if (MPI_SUCCESS != (ret = MPI_Comm_dup(MPI_COMM_WORLD, world))) {
            /* Perform recovery */
            if (MPI_ERR_PROC_FAILED == ret) {
                OMPI_Comm_revoke(MPI_COMM_WORLD);
                repair(vector1, vector2, result, size_vector, MPI_COMM_WORLD, world);
            } else if (MPI_ERR_REVOKED == ret) {
                repair(vector1, vector2, result, size_vector, MPI_COMM_WORLD, world);
            }
        }

        if (LIB1_SUCCESS != (ret = lib1_init(*world, &lib1_status1))) {
            /* Failure during the library, perform recovery */
            OMPI_Comm_revoke(*world);
            repair(vector1, vector2, result, size_vector, *world, world);
        }
        
        alg_status = INIT_LIB1_V1;

        if (LIB1_SUCCESS != (ret = lib1_init(*world, &lib1_status2))) {
            /* Failure during the library, perform recovery */
            OMPI_Comm_revoke(*world);
            repair(vector1, vector2, result, size_vector, *world, world);
        }
        
        alg_status = INIT_LIB1_V2;

        if (LIB2_SUCCESS != (ret = lib2_init(*world, &lib2_status))) {
            /* Failure during the library, perform recovery */
            OMPI_Comm_revoke(*world);
            repair(vector1, vector2, result, size_vector, *world, world);
        }
        
        alg_status = INIT_LIB2;

        MPI_Comm_rank(*world, &rank);
        MPI_Comm_size(*world, &size);

        if (0 != size_vector % (size-1)) {
            fprintf(stderr, "Invalid job size. The size of the vector needs to be divisible by the number of processes in the job - 1 (for checksums).\n");
            exit(1);
        }

        /* Arbitraily divide up the vector to make sure everyone doesn't have the same values. This is only an example after all... */
        size_vector /= (size - 1);

        vector1 = &vector1[rank * size_vector];
        vector2 = &vector2[rank * size_vector];
    }

    fprintf(stdout, "Vectors loaded...\n");
    for (i = 0; i < size_vector; i++) {
        fprintf(stdout, "[%d] %f\t%f\n", rank, vector1[i], vector2[i]);
    }
    sleep(1);
#endif

    if (SCALE1 >= alg_status) {
        if (LIB1_SUCCESS != (ret = lib1_min_scale_vector(vector1, size_vector, 1000, &lib1_status1))) {
            /* Failure during the library, perform recovery */
            repair_comm = (MPI_Comm *) malloc(sizeof(MPI_Comm));
    
            done = 0;
    
            /* Revoke and repair the old communicator */
            OMPI_Comm_revoke(*world);
            repair(vector1, vector2, result, size_vector, *world, repair_comm);
            MPI_Comm_free(world);
            free(world);
            world = repair_comm;
        }
        
        alg_status = SCALE1;
    }
    
    if (SCALE2 >= alg_status) {
        if (LIB1_SUCCESS != (ret = lib1_min_scale_vector(vector2, size_vector, 1000, &lib1_status2))) {
            /* Failure during the library, perform recovery */
            repair_comm = (MPI_Comm *) malloc(sizeof(MPI_Comm));
    
            done = 0;
    
            /* Revoke and repair the old communicator */
            OMPI_Comm_revoke(*world);
            repair(vector1, vector2, result, size_vector, *world, repair_comm);
            MPI_Comm_free(world);
            free(world);
            world = repair_comm;
        }
    
        alg_status = SCALE2;
    }

    if (ADD >= alg_status) {
        if (LIB2_SUCCESS != (ret = lib2_vector_add(vector1, vector2, size_vector, result, &lib2_status))) {
            /* Failure during the library, perform recovery */
            repair_comm = (MPI_Comm *) malloc(sizeof(MPI_Comm));
    
            done = 0;
    
            /* Revoke and repair the old communicator */
            OMPI_Comm_revoke(*world);
            repair(vector1, vector2, result, size_vector, *world, repair_comm);
            MPI_Comm_free(world);
            free(world);
            world = repair_comm;
        }
        
        alg_status = ADD;
    }
    
    if (0 == rank) {
        final_total = (float *) malloc(sizeof(float) * size_vector * size);
    }
    if (MPI_SUCCESS != (ret = MPI_Gather(result, size_vector, MPI_FLOAT, final_total, size_vector, MPI_FLOAT, 0, *world))) {
        /* Perform recovery */
        OMPI_Comm_revoke(*world);
        repair(vector1, vector2, result, size_vector, *world, repair_comm);
        MPI_Comm_free(world);
        free(world);
        world = repair_comm;
    }
    
    if (0 == rank) {
        fprintf(stdout, "\n---Result---\n");
        for (i = 0; i < size_vector * size; i++) {
            fprintf(stdout, "%f\n", final_total[i]);
        }
    }

    MPI_Finalize();

    return 0;
}

void repair(float *v1, float *v2, float *result, int size_v, MPI_Comm broken, MPI_Comm *repaired) {
    MPI_Comm temp, temp_intercomm, temp_intracomm, *recursive_repair;
    int ret, *errcodes, procs_needed, old_rank, i, new_rank, old_group_size;
    int *temp_ranks, *failed_ranks, *new_ranks;
    MPI_Group old_group, failed_group, new_group;
    enum progression best_status;

    /* Get the needed data about the broken communicator */
    MPI_Comm_size(broken, &old_group_size);
    MPI_Comm_group(broken, &old_group);
    MPI_Comm_rank(broken, &old_rank);
    OMPI_Comm_failure_ack(broken);
    OMPI_Comm_failure_get_acked(broken, &failed_group);
    MPI_Group_size(failed_group, &procs_needed);
    errcodes = (int *) malloc(sizeof(int) * procs_needed);
    
    /* Figure out ranks of the processes which had failed */
    temp_ranks = (int *) malloc(sizeof(int) * old_group_size);
    failed_ranks = (int *) malloc(sizeof(int) * old_group_size);
    for (i = 0; i < old_group_size; i++) {
        temp_ranks[i] = i;
    }
    MPI_Group_translate_ranks(failed_group, procs_needed, temp_ranks, old_group, failed_ranks);
    MPI_Group_free(&old_group);
    MPI_Group_free(&failed_group);

    /* Shrink the broken communicator to remove failed procs */
    OMPI_Comm_shrink(broken, &temp);

    /* Spawn the new process(es) */
    if (MPI_SUCCESS != (ret =
        MPI_Comm_spawn("./vector_math ", NULL, procs_needed, MPI_INFO_NULL, 0, temp, &temp_intercomm, errcodes))) {
        free(temp_ranks);
        free(failed_ranks);
        free(errcodes);
        MPI_Comm_free(&temp);
        if (MPI_ERR_PROC_FAILED == ret) {
            OMPI_Comm_revoke(temp);
            return repair(v1, v2, result, size_v, broken, repaired);
        } else if (MPI_ERR_REVOKED == ret) {
            return repair(v1, v2, result, size_v, broken, repaired);
        } else {
            fprintf(stderr, "Unknown error with MPI_COMM_SPAWN: %d\n", ret);
            exit(1);
        }
    }
    free(errcodes);
    MPI_Comm_free(&temp);

    /* Merge the new processes into a new communicator */
    if (MPI_SUCCESS != (ret = MPI_Intercomm_merge(temp_intercomm, 0, &temp_intracomm))) {
        free(temp_ranks);
        free(failed_ranks);
        MPI_Comm_free(&temp_intercomm);
        if (MPI_ERR_PROC_FAILED == ret) {
            /* Start the recovery over again if there is a failure. */
            OMPI_Comm_revoke(temp_intercomm);
            return repair(v1, v2, result, size_v, broken, repaired);
        } else if (MPI_ERR_REVOKED == ret) {
            /* Start the recovery over again if there is a failure. */
            OMPI_Comm_revoke(temp_intercomm);
            return repair(v1, v2, result, size_v, broken, repaired);
        } else {
            fprintf(stderr, "Unknown error with MPI_COMM_SPAWN: %d\n", ret);
            exit(1);
        }
    }
    MPI_Comm_free(&temp_intercomm);

    /* Tell the new processes what their old ranks were */
    MPI_Comm_rank(temp_intracomm, &new_rank);
    if (0 == new_rank) {
        MPI_Comm_group(temp_intracomm, &new_group);
        new_ranks = (int *) malloc(sizeof(int) * procs_needed);
        MPI_Group_translate_ranks(new_group, procs_needed, temp_ranks, new_group, new_ranks);
        MPI_Group_free(&new_group);

        for (i = 0; i < procs_needed; i++) {
            if (MPI_SUCCESS != (ret =
                MPI_Send(&failed_ranks[i], 1, MPI_INT, new_ranks[i], 31337, temp_intracomm))) {
                free(temp_ranks);
                free(failed_ranks);
                free(new_ranks);
                if (MPI_ERR_PROC_FAILED == ret) {
                    /* Start the recovery over again if there is a failure. */
                    OMPI_Comm_revoke(temp_intercomm);
                    return repair(v1, v2, result, size_v, broken, repaired);
                } else if (MPI_ERR_REVOKED == ret) {
                    /* Start the recovery over again if there is a failure. */
                    OMPI_Comm_revoke(temp_intercomm);
                    return repair(v1, v2, result, size_v, broken, repaired);
                } else {
                    fprintf(stderr, "Unknown error with MPI_SEND: %d\n", ret);
                    exit(1);
                }
            }
        }
    }
    free(temp_ranks);
    free(failed_ranks);
    free(new_ranks);

    /* Everyone move to their old position in the recovered communicator */
    if (MPI_SUCCESS != (ret = MPI_Comm_split(temp_intracomm, 0, old_rank, repaired))) {
        if (MPI_ERR_PROC_FAILED == ret) {
            /* Start the recovery over again if there is a failure. */
            OMPI_Comm_revoke(temp_intercomm);
            return repair(v1, v2, result, size_v, broken, repaired);
        } else if (MPI_ERR_REVOKED == ret) {
            /* Start the recovery over again if there is a failure. */
            OMPI_Comm_revoke(temp_intercomm);
            return repair(v1, v2, result, size_v, broken, repaired);
        } else {
            fprintf(stderr, "Unknown error with MPI_COMM_SPLIT: %d\n", ret);
            exit(1);
        }
    }

    /* If someone has reached this point, we should recover lib1 */
    if (INIT_LIB1_V1 >= best_status) {
        if (LIB1_SUCCESS != lib1_recovery(v1, size_v, *repaired, &lib1_status1, (INIT_LIB1_V1 >= alg_status))) {
            recursive_repair = (MPI_Comm *) malloc(sizeof(MPI_Comm));
            OMPI_Comm_revoke(*repaired);
            return repair(v1, v2, result, size_v, *repaired, repaired);
        }
    }

    /* If someone has reached this point, we should recover lib1 */
    if (INIT_LIB1_V2 >= best_status) {
        if (LIB1_SUCCESS != lib1_recovery(v1, size_v, *repaired, &lib1_status2, (INIT_LIB1_V2 >= alg_status))) {
            recursive_repair = (MPI_Comm *) malloc(sizeof(MPI_Comm));
            OMPI_Comm_revoke(*repaired);
            return repair(v1, v2, result, size_v, *repaired, repaired);
        }
    }

    /* If someone has reached this point, we should recover lib1 */
    if (INIT_LIB2 >= best_status) {
        if (LIB2_SUCCESS != lib2_recovery(result, size_v, *repaired, &lib2_status, (INIT_LIB2 >= alg_status))) {
            recursive_repair = (MPI_Comm *) malloc(sizeof(MPI_Comm));
            OMPI_Comm_revoke(*repaired);
            return repair(v1, v2, result, size_v, *repaired, repaired);
        }
    }

    alg_status = best_status;
}
