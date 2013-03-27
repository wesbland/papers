#!/bin/bash

export PAPER_DIR=$HOME/dev/papers/eurompi/netpipe/src/

echo
echo "------------------------------------"
echo "Test Latency"
echo "------------------------------------"
$PAPER_DIR/gather-perf.pl -a $PAPER_DIR/ini/run-ft-lat_disabled.jaguar.ini
$PAPER_DIR/gather-perf.pl -a $PAPER_DIR/ini/run-ft-lat_noprogress.jaguar.ini
$PAPER_DIR/gather-perf.pl -a $PAPER_DIR/ini/run-ft-lat_progress.jaguar.ini

echo
echo "------------------------------------"
echo "Test Bandwidth"
echo "------------------------------------"
$PAPER_DIR/gather-perf.pl -a $PAPER_DIR/ini/run-ft-bw_disabled.jaguar.ini
$PAPER_DIR/gather-perf.pl -a $PAPER_DIR/ini/run-ft-bw_noprogress.jaguar.ini
$PAPER_DIR/gather-perf.pl -a $PAPER_DIR/ini/run-ft-bw_progress.jaguar.ini

exit 0
