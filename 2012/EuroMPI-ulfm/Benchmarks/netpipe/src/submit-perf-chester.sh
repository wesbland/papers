#!/bin/bash

#PBS -S /bin/bash

#PBS -N OMPI_v_netpipe_chester
#PBS -j oe
#PBS -l walltime=2:00:00,size=32
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
export XTPE_INFO_MESSAGE_OFF=1
#export OMPIDEVEL=/tmp/work/jjhursey/local/ompi/devel-ft-static/gnu/
export OMPIDEVEL=/tmp/work/jjhursey/local/ompi/devel-ft-static-opt/gnu/
export PATH=$OMPIDEVEL/bin:$PATH
export LD_LIBRARY_PATH=$OMPIDEVEL/lib:$LD_LIBRARY_PATH
resId=`exec bash $OMPIDEVEL/share/openmpi/ras-alps-command.sh`
export OMPI_ALPS_RESID=$resId

#export OMPI_MCA_orte_tmpdir_base=/tmp/scratch
export OMPI_MCA_orte_tmpdir_base=/tmp/work/jjhursey/tmp/
export OMPI_MCA_shmem_mmap_enable_nfs_warning=0
#export OMPI_MCA_orte_local_tmpdir_base=/tmp/work/jjhursey/tmp/
#export OMPI_MCA_orte_remote_tmpdir_base=/tmp/

export OMPI_MCA_btl="self,ugni,sm"
export OMPI_MCA_hwloc_base_mem_bind_failure_action=silent
export OMPI_MCA_routed=rts
export OMPI_MCA_errmgr_rts_hnp_priority=5000
export OMPI_MCA_errmgr_rts_orted_priority=5000
export OMPI_MCA_errmgr_rts_app_priority=5000
export OMPI_MCA_ompi_ftmpi_enable=1
export OMPI_MCA_coll="basic,ftbasic"
export OMPI_MCA_mpi_param_check=0
export OMPI_MCA_pml_ob1_unexpected_limit=256
export OMPI_MCA_coll_basic_crossover=2
export OMPI_MCA_coll_ftbasic_crossover=2
export OMPI_MCA_coll_ftbasic_progress_wait_inc=100000

# echo
# echo "------------------------------------"
# echo "Modules "
# echo "------------------------------------"
# module list
# module unload PrgEnv-cray
# module unload PrgEnv-pgi
# module load PrgEnv-gnu
# echo "------------"
# module list

echo
echo "------------------------------------"
echo "Compiler "
echo "------------------------------------"
which cc
cc --version -v
echo
echo MPICC
echo
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
cd /tmp/work/$USER/testing/NetPIPE-3.7.1/
pwd

echo
echo "------------------------------------"
echo "make the test "
echo "------------------------------------"
#make clean mpi

echo
echo
echo
echo "------------------------------------"
echo "Test Latency"
echo "------------------------------------"
export OMPI_MCA_ompi_ftmpi_enable=0
export OMPI_MCA_coll_ftbasic_agreement_progress=0
$PAPER_DIR/gather-perf.pl $PAPER_DIR/ini/run-ft-lat_disabled.jaguar.ini
export OMPI_MCA_ompi_ftmpi_enable=1
export OMPI_MCA_coll_ftbasic_agreement_progress=0
$PAPER_DIR/gather-perf.pl $PAPER_DIR/ini/run-ft-lat_noprogress.jaguar.ini
export OMPI_MCA_ompi_ftmpi_enable=1
export OMPI_MCA_coll_ftbasic_agreement_progress=1
$PAPER_DIR/gather-perf.pl $PAPER_DIR/ini/run-ft-lat_progress.jaguar.ini

echo
echo "------------------------------------"
echo "Test Bandwidth"
echo "------------------------------------"
export OMPI_MCA_ompi_ftmpi_enable=0
export OMPI_MCA_coll_ftbasic_agreement_progress=0
$PAPER_DIR/gather-perf.pl $PAPER_DIR/ini/run-ft-bw_disabled.jaguar.ini
export OMPI_MCA_ompi_ftmpi_enable=1
export OMPI_MCA_coll_ftbasic_agreement_progress=0
$PAPER_DIR/gather-perf.pl $PAPER_DIR/ini/run-ft-bw_noprogress.jaguar.ini
export OMPI_MCA_ompi_ftmpi_enable=1
export OMPI_MCA_coll_ftbasic_agreement_progress=1
$PAPER_DIR/gather-perf.pl $PAPER_DIR/ini/run-ft-bw_progress.jaguar.ini

echo
echo "------------------------------------"
echo "Test Full Graph"
echo "------------------------------------"
export OMPI_MCA_ompi_ftmpi_enable=0
export OMPI_MCA_coll_ftbasic_agreement_progress=0
$PAPER_DIR/gather-perf.pl $PAPER_DIR/ini/run-ft-full_disabled.jaguar.ini
export OMPI_MCA_ompi_ftmpi_enable=1
export OMPI_MCA_coll_ftbasic_agreement_progress=0
$PAPER_DIR/gather-perf.pl $PAPER_DIR/ini/run-ft-full_noprogress.jaguar.ini
export OMPI_MCA_ompi_ftmpi_enable=1
export OMPI_MCA_coll_ftbasic_agreement_progress=1
$PAPER_DIR/gather-perf.pl $PAPER_DIR/ini/run-ft-full_progress.jaguar.ini

echo
echo "------------------------------------"
echo "Date (end)"
echo "------------------------------------"
date

exit 0
