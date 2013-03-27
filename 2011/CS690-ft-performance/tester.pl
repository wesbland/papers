#!/usr/bin/perl

$p = 0.9;
$procs = 1000000; # 1 million
$runtime = 7 * 24 * 60 * 60; # 1 week
$checkpoint_interval = 1 * 60 * 60; # 3 hours
$checkpoint_overhead = 5 * 60; # 5 minutes

#for ($mtbf = $r; $mtbf > 0; $mtbf -= 60) {
#    $result = system("./a.out $p $n $r $mtbf");
#}

for ($p = 1.0; $p > 0.999; $p -= 0.00001) {
    $result = system("./a.out $p $procs $checkpoint_interval $checkpoint_overhead $runtime");
}

print $result;
