#!/bin/sh

N=50
#N=20
#N=5

for NP in 8 16 32 64 128 256 512 1024; do 
   if [ -e data/smoky-NP_${NP}-N_${N}.data ] ; then 
      python time_alt.py data/smoky-NP_${NP}-N_${N}.data ${NP} ${N} | \
      gawk 'BEGIN {printf("'$NP' ")} $1=="0" { for(i = 2; i < 8; i++) { printf("%f ", $i); } } END {printf("\n")}'
   fi
done | tee scalability.dat
