#!/bin/bash

#PBS -S /bin/bash

#PBS -N OMPI_v_frssj_smoky
#PBS -j oe
#PBS -l walltime=1:30:00,nodes=65:ppn=16
#PBS -l gres=widow2
#PBS -A csc725
# -q debug

#walltime=2:00:00,size=256
#  2 =  1 nodes =   16 procs
#  3 =  2 nodes =   32 procs
#  5 =  4 nodes =   64 procs
#  9 =  8 nodes =  124 procs
# 17 = 16 nodes =  256 procs
# 33 = 32 nodes =  512 procs
# 65 = 64 nodes = 1024 procs

#source $HOME/.bashrc

export PAPER_DIR=$HOME/dev/papers/eurompi/FaultRevokeShrinkSpawnJoin

echo
echo "------------------------------------"
echo "Date (start)"
echo "------------------------------------"
date

echo
echo "------------------------------------"
echo "Setup Environment "
echo "------------------------------------"
# openib is not well supported under FT conditions
export OMPI_MCA_btl="tcp,sm,self"
export OMPI_MCA_hwloc_base_mem_bind_failure_action=silent
#export OMPI_MCA_routed=rts
#export OMPI_MCA_errmgr_rts_hnp_priority=5000
#export OMPI_MCA_errmgr_rts_orted_priority=5000
#export OMPI_MCA_errmgr_rts_app_priority=5000
#export OMPI_MCA_ompi_ftmpi_enable=1
export OMPI_MCA_coll="basic,ftbasic"
export OMPI_MCA_mpi_param_check=0
export OMPI_MCA_pml_ob1_unexpected_limit=256
export OMPI_MCA_coll_basic_crossover=2
export OMPI_MCA_coll_ftbasic_crossover=2
export OMPI_MCA_coll_ftbasic_progress_wait_inc=100000
# Set xcast delay to 0
export OMPI_MCA_errmgr_hnp_stable_xcast_delay=0

echo
echo "------------------------------------"
echo "Compiler "
echo "------------------------------------"
mpicc --showme


echo
echo "------------------------------------"
echo "MPI "
echo "------------------------------------"
which mpirun


echo
echo "------------------------------------"
echo "ulimit "
echo "------------------------------------"
ulimit -s unlimited
ulimit -a


echo
echo "------------------------------------"
echo "Working Directory "
echo "------------------------------------"
cd $PAPER_DIR
pwd

echo
echo
echo
echo "------------------------------------"
echo "Run Test"
echo "------------------------------------"
$PAPER_DIR/gather-perf.pl -i 50

echo
echo "------------------------------------"
echo "Date (end)"
echo "------------------------------------"
date

exit 0
