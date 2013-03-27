#!/bin/bash

export PAPER_DIR=$HOME/dev/papers/eurompi/netpipe/src/

echo
echo "------------------------------------"
echo "Test Latency"
echo "------------------------------------"
$PAPER_DIR/gather-perf.pl -a $PAPER_DIR/ini/run-ft-lat.ini
$PAPER_DIR/gather-perf.pl -a $PAPER_DIR/ini/run-vanilla-lat.ini

echo
echo "------------------------------------"
echo "Test Bandwidth"
echo "------------------------------------"
$PAPER_DIR/gather-perf.pl -a $PAPER_DIR/ini/run-ft-bw.ini
$PAPER_DIR/gather-perf.pl -a $PAPER_DIR/ini/run-vanilla-bw.ini

exit 0
