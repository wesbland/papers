#!/bin/bash

#PBS -S /bin/bash

#PBS -N OMPI_v_netpipe_smoky
#PBS -j oe
#PBS -l walltime=2:00:00,nodes=2:ppn=16
#PBS -l gres=widow2
#PBS -A csc725
# -q debug

#walltime=2:00:00,size=256
# 33 = 32 nodes = 512 procs
# 65 = 64 nodes = 1024 procs

#source $HOME/.bashrc

export PAPER_DIR=$HOME/dev/papers/eurompi/netpipe/src/

echo
echo "------------------------------------"
echo "Date (start)"
echo "------------------------------------"
date

echo
echo "------------------------------------"
echo "Setup Environment "
echo "------------------------------------"
#export OMPI_MCA_btl="^openib"
export OMPI_MCA_hwloc_base_mem_bind_failure_action=silent
#export OMPI_MCA_routed=rts
#export OMPI_MCA_errmgr_rts_hnp_priority=5000
#export OMPI_MCA_errmgr_rts_orted_priority=5000
#export OMPI_MCA_errmgr_rts_app_priority=5000
#export OMPI_MCA_ompi_ftmpi_enable=1
export OMPI_MCA_coll="basic,ftbasic"
# Use only 'basic' for the vanilla runs (selection error otherwise)
#export OMPI_MCA_coll="basic"

export OMPI_MCA_mpi_param_check=0
export OMPI_MCA_pml_ob1_unexpected_limit=256
export OMPI_MCA_coll_basic_crossover=2
export OMPI_MCA_coll_ftbasic_crossover=2
export OMPI_MCA_coll_ftbasic_progress_wait_inc=100000

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
cd ~/svn/testing/ompi-tests/NetPIPE-3.7.1/
pwd

echo
echo "------------------------------------"
echo "make the test "
echo "------------------------------------"
make clean mpi

echo
echo
echo
echo "------------------------------------"
echo "Test Latency"
echo "------------------------------------"
$PAPER_DIR/gather-perf.pl $PAPER_DIR/ini/run-ft-lat.ini
#$PAPER_DIR/gather-perf.pl $PAPER_DIR/ini/run-vanilla-lat.ini

echo
echo "------------------------------------"
echo "Test Bandwidth"
echo "------------------------------------"
$PAPER_DIR/gather-perf.pl $PAPER_DIR/ini/run-ft-bw.ini
#$PAPER_DIR/gather-perf.pl $PAPER_DIR/ini/run-vanilla-bw.ini

echo
echo "------------------------------------"
echo "Test Full Graph"
echo "------------------------------------"
$PAPER_DIR/gather-perf.pl $PAPER_DIR/ini/run-ft-full.ini
#$PAPER_DIR/gather-perf.pl $PAPER_DIR/ini/run-vanilla-full.ini

echo
echo "------------------------------------"
echo "Date (end)"
echo "------------------------------------"
date

exit 0
