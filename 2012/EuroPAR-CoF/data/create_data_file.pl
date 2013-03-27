#!/usr/bin/perl

$binomial_foldername = "binomial";
$linear_foldername = "linear";
$ranks = 16;
$runs = 20;

$filename_prefix = "$binomial_foldername\/binomial_low_run";
open OUTFILE, ">", "binomial_low.dat" or die $!;

for ($i = 0; $i < $ranks; $i++) {
    $stdev = 0;
    $mean = 0;
    $min = 9999999999;
    $max = 0;

    for ($j = 0; $j < $runs; $j++) {
        open FILE, "<", "$filename_prefix$j\/rank$i" or die $! .  " $filename_prefix$j\/rank$i";
        
        @lines = <FILE>;
        chomp(@lines);
        
        $mean += $lines[0];
        if ($lines[0] > $max) {$max = $lines[0];}
        if ($lines[0] < $min) {$min = $lines[0];}
    }
    
    $mean -= $max - $min;
    $mean /= $runs-2;

    for ($j = 0; $j < $runs; $j++) {
        open FILE, "<", "$filename_prefix$j\/rank$i" or die $! .  " $filename_prefix$j\/rank$i";
        
        @lines = <FILE>;
        chomp(@lines);

        if ($lines[0] == $min || $lines[0] == $max) {next;}
        
        $stdev += ($lines[0] - $mean) * ($lines[0] - $mean);
    }

    $stdev /= $runs-3;
    $stdev = sqrt($stdev);

    if ($mean != 0) {
        print OUTFILE "$i $mean $stdev\n";
    }
}

$filename_prefix = "$binomial_foldername\/binomial_middle_run";
open OUTFILE, ">", "binomial_middle.dat";

for ($i = 0; $i < $ranks; $i++) {
    $mean = 0;
    $stdev = 0;
    $min = 9999999999;
    $max = 0;

    for ($j = 0; $j < $runs; $j++) {
        open FILE, "<", "$filename_prefix$j\/rank$i" or die $! .  " $filename_prefix$j\/rank$i";
        
        @lines = <FILE>;
        chomp(@lines);
        
        $mean += $lines[0];
        if ($lines[0] > $max) {$max = $lines[0];}
        if ($lines[0] < $min) {$min = $lines[0];}
    }
    
    $mean -= $max - $min;
    $mean /= $runs-2;

    for ($j = 0; $j < $runs; $j++) {
        open FILE, "<", "$filename_prefix$j\/rank$i" or die $! .  " $filename_prefix$j\/rank$i";
        
        @lines = <FILE>;
        chomp(@lines);

        if ($lines[0] == $min || $lines[0] == $max) {next;}
        
        $stdev += ($lines[0] - $mean) * ($lines[0] - $mean);
    }

    $stdev /= $runs-3;
    $stdev = sqrt($stdev);
    
    if ($mean != 0) {
        print OUTFILE "$i $mean $stdev\n";
    }
}

$filename_prefix = "$binomial_foldername\/binomial_high_run";
open OUTFILE, ">", "binomial_high.dat";

for ($i = 0; $i < $ranks; $i++) {
    $mean = 0;
    $stdev = 0;
    $min = 9999999999;
    $max = 0;

    for ($j = 0; $j < $runs; $j++) {
        open FILE, "<", "$filename_prefix$j\/rank$i" or die $! .  " $filename_prefix$j\/rank$i";
        
        @lines = <FILE>;
        chomp(@lines);
        
        $mean += $lines[0];
        if ($lines[0] > $max) {$max = $lines[0];}
        if ($lines[0] < $min) {$min = $lines[0];}
    }

    $mean -= $max - $min;
    $mean /= $runs-2;

    for ($j = 0; $j < $runs; $j++) {
        open FILE, "<", "$filename_prefix$j\/rank$i" or die $! .  " $filename_prefix$j\/rank$i";
        
        @lines = <FILE>;
        chomp(@lines);

        if ($lines[0] == $min || $lines[0] == $max) {next;}
        
        $stdev += ($lines[0] - $mean) * ($lines[0] - $mean);
    }
    
    $stdev /= $runs-3;
    $stdev = sqrt($stdev);
    
    if ($mean != 0) {
        print OUTFILE "$i $mean $stdev\n";
    }
}

$filename_prefix = "$linear_foldername\/linear_low_run";
open OUTFILE, ">", "linear_low.dat";

for ($i = 0; $i < $ranks; $i++) {
    $mean = 0;
    $stdev = 0;
    $min = 9999999999;
    $max = 0;

    for ($j = 0; $j < $runs; $j++) {
        open FILE, "<", "$filename_prefix$j\/rank$i" or die $! .  " $filename_prefix$j\/rank$i";
        
        @lines = <FILE>;
        chomp(@lines);
        
        $mean += $lines[0];
        if ($lines[0] > $max) {$max = $lines[0];}
        if ($lines[0] < $min) {$min = $lines[0];}
    }
    
    $mean -= $max - $min;
    $mean /= $runs-2;
    
    for ($j = 0; $j < $runs; $j++) {
        open FILE, "<", "$filename_prefix$j\/rank$i" or die $! .  " $filename_prefix$j\/rank$i";
        
        @lines = <FILE>;
        chomp(@lines);
        
        if ($lines[0] == $min || $lines[0] == $max) {next;}
        
        $stdev += ($lines[0] - $mean) * ($lines[0] - $mean);
    }
    
    $stdev /= $runs-3;
    $stdev = sqrt($stdev);
    
    if ($mean != 0) {
        print OUTFILE "$i $mean $stdev\n";
    }
}

$filename_prefix = "$linear_foldername\/linear_middle_run";
open OUTFILE, ">", "linear_middle.dat";

for ($i = 0; $i < $ranks; $i++) {
    $mean = 0;
    $stdev = 0;
    $min = 9999999999;
    $max = 0;

    for ($j = 0; $j < $runs; $j++) {
        open FILE, "<", "$filename_prefix$j\/rank$i" or die $! .  " $filename_prefix$j\/rank$i";
        
        @lines = <FILE>;
        chomp(@lines);
        
        $mean += $lines[0];
        if ($lines[0] > $max) {$max = $lines[0];}
        if ($lines[0] < $min) {$min = $lines[0];}
    }
    
    $mean -= $max - $min;
    $mean /= $runs-2;
    
    for ($j = 0; $j < $runs; $j++) {
        open FILE, "<", "$filename_prefix$j\/rank$i" or die $! .  " $filename_prefix$j\/rank$i";
        
        @lines = <FILE>;
        chomp(@lines);
        
        if ($lines[0] == $min || $lines[0] == $max) {next;}
        
        $stdev += ($lines[0] - $mean) * ($lines[0] - $mean);
    }
    
    $stdev /= $runs-3;
    $stdev = sqrt($stdev);
    
    if ($mean != 0) {
        print OUTFILE "$i $mean $stdev\n";
    }
}

$filename_prefix = "$linear_foldername\/linear_high_run";
open OUTFILE, ">", "linear_high.dat";

for ($i = 0; $i < $ranks; $i++) {
    $mean = 0;
    $stdev = 0;
    $min = 9999999999;
    $max = 0;

    for ($j = 0; $j < $runs; $j++) {
        open FILE, "<", "$filename_prefix$j\/rank$i" or die $! .  " $filename_prefix$j\/rank$i";
        
        @lines = <FILE>;
        chomp(@lines);
        
        $mean += $lines[0];
        if ($lines[0] > $max) {$max = $lines[0];}
        if ($lines[0] < $min) {$min = $lines[0];}
    }
    
    $mean -= $max - $min;
    $mean /= $runs-2;
    
    for ($j = 0; $j < $runs; $j++) {
        open FILE, "<", "$filename_prefix$j\/rank$i" or die $! .  " $filename_prefix$j\/rank$i";
        
        @lines = <FILE>;
        chomp(@lines);
        
        if ($lines[0] == $min || $lines[0] == $max) {next;}
        
        $stdev += ($lines[0] - $mean) * ($lines[0] - $mean);
    }
    
    $stdev /= $runs-3;
    $stdev = sqrt($stdev);
    
    if ($mean != 0) {
        print OUTFILE "$i $mean $stdev\n";
    }
}
