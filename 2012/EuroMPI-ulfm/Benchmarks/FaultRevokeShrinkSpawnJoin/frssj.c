#include <stdio.h>
#include <unistd.h>
#include <stdlib.h>
#include <assert.h>
#include <limits.h>
#include <signal.h>

#include <mpi.h>
#include <mpi-ext.h>

#define TIMING_VERBOSE 0

static int victim = 0;
static int verbose = 0;
static int nb_runs = 10;

static void process_arguments(int argc, char *argv[])
{
    int my_rank, world_size;
    int ch;

    MPI_Comm_rank(MPI_COMM_WORLD, &my_rank);
    MPI_Comm_size(MPI_COMM_WORLD, &world_size);

    if( my_rank == 0 ) {
        while( (ch = getopt(argc, argv, "Vv:n:h")) != -1 ) {
            switch(ch) {
            case 'V':
                verbose = 1;
                break;
            case 'v':
                victim = atoi(optarg) % world_size;
                if( victim < 0 )
                    victim = 0;
                break;
            case 'n':
                nb_runs = atoi(optarg);
                if( nb_runs <= 0 )
                    nb_runs = 1;
                break;
            case 'h':
                fprintf(stderr, 
                        "Usage: %s options\n"
                        "  where options are:\n"
                        "   -V       enable verbose mode. Displays what hosts run what ranks\n"
                        "   -v <N>   choose the rank of the victim (%% world size). Default: %d\n"
                        "   -n <N>   choose the number of iterations. Default: %d\n"
                        "\n",
                        argv[0], victim, nb_runs);
                MPI_Abort(MPI_COMM_WORLD, 0);
            }
        }
        if( verbose ) {
            fprintf(stderr, 
                    "#Victim: %d\n"
                    "#nb_runs: %d\n", victim, nb_runs);
        }
    }
    MPI_Bcast(&victim,  1, MPI_INT, 0, MPI_COMM_WORLD);
    MPI_Bcast(&verbose, 1, MPI_INT, 0, MPI_COMM_WORLD);
    MPI_Bcast(&nb_runs, 1, MPI_INT, 0, MPI_COMM_WORLD);
}

#define FAILURE_DETECTED 0
#define COMM_REVOKED     1
#define COMM_SHRINKED    2
#define COMM_SPAWNED     3
#define ROLLBACK_DONE    4
#define COMM_MERGED      5
#define NBMEASURES       6

static void benchmark(char *argv[], MPI_Comm loc_wworld)
{
    double timing[NBMEASURES], start;
    double *alltimes = NULL;
    int size_of_shrinked, rank_in_shrinked;
    int rank_in_kid;
    int my_rank, world_size;
    int rc, r, err, i;
    MPI_Comm kid, shrinked;
    char hostname[MPI_MAX_PROCESSOR_NAME];
    int len;

    for( ; nb_runs > 0; nb_runs--) {
        MPI_Comm_size(loc_wworld, &world_size);
        MPI_Comm_rank(loc_wworld, &my_rank);

        if( verbose ) {
            for( r = 0; r < world_size; r++ ) {
                if( r == my_rank ) {
                    MPI_Get_processor_name(hostname, &len);
                    gethostname(hostname, MPI_MAX_PROCESSOR_NAME);
                    fprintf(stderr, "#rank %d runs on %s (runs left %d)\n", 
                            my_rank, hostname, nb_runs);
                }
                MPI_Barrier(loc_wworld);
            }
        }

        /******************************************************
         * Enter benchmark
         ******************************************************/
#if TIMING_VERBOSE == 1
        if( 0 == my_rank ) {
            printf("Stage: Start benchmark (%3d)\n", nb_runs);
        }
#endif
        MPI_Barrier(loc_wworld);
        start = MPI_Wtime();


        /******************************************************
         * Time: Failure Detection
         ******************************************************/
#if TIMING_VERBOSE == 1
        if( 0 == my_rank ) {
            printf("\tStage: Failure Detection\n");
        }
#endif
        if( my_rank != victim ) {
            /* Wait for a failure */
            rc = MPI_Barrier(loc_wworld);
        } else {
            /* Simulate a failure */
            raise(9);
        }
        timing[FAILURE_DETECTED] = MPI_Wtime();
        assert( rc != MPI_SUCCESS );


        /******************************************************
         * Time: Revoke
         ******************************************************/
#if TIMING_VERBOSE == 1
        if( 0 == my_rank ) {
            printf("\tStage: Revoke\n");
        }
#endif
        OMPI_Comm_revoke(loc_wworld);
        timing[COMM_REVOKED] = MPI_Wtime();


        /******************************************************
         * Time: Shrink
         * JJH: Why is the 'free' in the timing segment for 'shrink'?
         ******************************************************/
#if TIMING_VERBOSE == 1
        if( 0 == my_rank ) {
            printf("\tStage: Shrink\n");
        }
#endif
        rc = OMPI_Comm_shrink(loc_wworld, &shrinked);
        MPI_Comm_free(&loc_wworld);
        timing[COMM_SHRINKED] = MPI_Wtime();
        assert(rc == MPI_SUCCESS);


        /******************************************************
         * Time: Spawn
         ******************************************************/
#if TIMING_VERBOSE == 1
        if( 0 == my_rank ) {
            printf("\tStage: Spawn\n");
        }
#endif
        rc = MPI_Comm_spawn(argv[0], NULL, 1, MPI_INFO_NULL, 0, shrinked, &kid, &err);
        timing[COMM_SPAWNED] = MPI_Wtime();
        assert( MPI_SUCCESS == rc );
        assert( 0 == err );


        /******************************************************
         * Time: Sync with spawned process - Rollback
         ******************************************************/
#if TIMING_VERBOSE == 1
        if( 0 == my_rank ) {
            printf("\tStage: Rollback\n");
        }
#endif
        MPI_Comm_rank(kid, &rank_in_kid);
        if( 0 == rank_in_kid ) {
            MPI_Send( &victim, 1, MPI_INT, 0, 0, kid );
            MPI_Send( &verbose, 1, MPI_INT, 0, 0, kid );
            MPI_Send( &nb_runs, 1, MPI_INT, 0, 0, kid );
        }
        timing[ROLLBACK_DONE] = MPI_Wtime();


        /******************************************************
         * Time: Merge with spawned process
         * JJH: Why is the 'free' in the timing segment for 'intercomm_merge'?
         ******************************************************/
#if TIMING_VERBOSE == 1
        if( 0 == my_rank ) {
            printf("\tStage: Intercomm_merge\n");
        }
#endif
        rc = MPI_Intercomm_merge( kid, 0, &loc_wworld );
        MPI_Comm_free(&kid);
        timing[COMM_MERGED] = MPI_Wtime();
        assert( MPI_SUCCESS == 0 );


        /******************************************************
         * Gather and Display the Time from all surviving processes
         ******************************************************/
#if TIMING_VERBOSE == 1
        if( 0 == my_rank ) {
            printf("\tStage: Gather/Display\n");
        }
#endif
        MPI_Comm_size(shrinked, &size_of_shrinked);
        //assert( size_of_shrinked == world_size - 1 );
        MPI_Comm_rank(shrinked, &rank_in_shrinked);

        for( i = NBMEASURES-1; i > 0; i--) {
            timing[i] -= timing[i-1];
        }
        timing[0] -= start;

        if( 0 == rank_in_shrinked ) {
            alltimes = (double*)malloc(size_of_shrinked * NBMEASURES * sizeof(double));
        } else {
            alltimes = NULL;
        }

        MPI_Gather(timing, NBMEASURES, MPI_DOUBLE, alltimes, NBMEASURES, MPI_DOUBLE, 0, shrinked);
        if( 0 == rank_in_shrinked ) {
            for( r = 0; r < size_of_shrinked; r++ ) {
                if( 0 == r ) {
                    printf("#RUN   RANK   FAILURE_DETECTED  COMM_REVOKED   COMM_SHRINKED COMM_SPAWNED ROLLBACK_DONE COMM_MERGED\n");
                }
                printf("%3d  %3d  %#13.10g  %#13.10g  %#13.10g  %#13.10g  %#13.10g  %#13.10g\n",
                       nb_runs, r, 
                       alltimes[r*NBMEASURES+FAILURE_DETECTED], 
                       alltimes[r*NBMEASURES+COMM_REVOKED], 
                       alltimes[r*NBMEASURES+COMM_SHRINKED],
                       alltimes[r*NBMEASURES+COMM_SPAWNED],
                       alltimes[r*NBMEASURES+ROLLBACK_DONE],
                       alltimes[r*NBMEASURES+COMM_MERGED]);                       
                if( size_of_shrinked - 1 == r ) {
                    printf("\n\n");
                }
            }
            free(alltimes);
        }

#if TIMING_VERBOSE == 1
        if( 0 == my_rank || 0 == 0) {
            usleep(100000);
            printf("Stage: End   Benchmark (Rank %3d) (%3d)\n", my_rank, nb_runs);
            usleep(100000);
        }
#endif

        MPI_Barrier(shrinked);
        /* End of display section */
        MPI_Comm_free(&shrinked);        
    }

    if( verbose ) {
        printf("Stage: Finished Benchmark (Rank %3d)\n", my_rank);
    }
}

static void spawned_app(MPI_Comm parent, MPI_Comm *wworld)
{
    /* Entering Fault-Tolerant Section */
    MPI_Comm_set_errhandler(MPI_COMM_WORLD, MPI_ERRORS_RETURN);
    MPI_Comm_set_errhandler(parent, MPI_ERRORS_RETURN);

#if TIMING_VERBOSE == 1
    printf("\tStage: Spawned Process: Rolling in\n");
#endif

    MPI_Recv( &victim,  1, MPI_INT, 0, 0, parent, MPI_STATUS_IGNORE );
    MPI_Recv( &verbose, 1, MPI_INT, 0, 0, parent, MPI_STATUS_IGNORE );
    MPI_Recv( &nb_runs, 1, MPI_INT, 0, 0, parent, MPI_STATUS_IGNORE );

    nb_runs--; /* Need to decrement what we receive by 1 */

#if TIMING_VERBOSE == 1
    printf("\tStage: Spawned Process: Merging\n");
#endif

    MPI_Intercomm_merge( parent, 1, wworld );

#if TIMING_VERBOSE == 1
    printf("\tStage: Spawned Process: Rejoining World\n");
#endif
}


int main(int argc, char *argv[])
{
    MPI_Comm parent, wworld, loc_wworld;

    MPI_Init(&argc, &argv);

    MPI_Comm_set_errhandler(MPI_COMM_WORLD, MPI_ERRORS_RETURN);

    MPI_Comm_get_parent(&parent);
    if( parent == MPI_COMM_NULL ) {
        process_arguments(argc, argv);
#if 0
        MPI_Comm_dup(MPI_COMM_WORLD, &wworld);
#else
        /* A warmup step
         * So the MPI library has time to setup structures before the timing loop
         */
        MPI_Comm_dup(MPI_COMM_WORLD, &loc_wworld);
        OMPI_Comm_revoke(loc_wworld);
        OMPI_Comm_shrink(loc_wworld, &wworld);
#endif
    } else {
        spawned_app(parent, &wworld);
    }

    benchmark(argv, wworld);

    MPI_Finalize();

    return 0;
}
