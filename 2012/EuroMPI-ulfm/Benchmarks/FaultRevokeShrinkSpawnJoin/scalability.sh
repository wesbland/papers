#!/bin/sh

N=50

for NP in 8 16 32 64 128 256 512 1024; do 
   ./time.py data/smoky-NP_${NP}-N_${N}.data ${NP} ${N} | gawk 'BEGIN {printf("'$NP' ")} $1=="0" { for(i = 2; i < 8; i++) { printf("%f ", $i); } } END {printf("\n")}'
done 
