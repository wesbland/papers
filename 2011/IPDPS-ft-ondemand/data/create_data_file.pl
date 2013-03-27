#!/usr/bin/perl

$filename_prefix = "binomial_dancer\/binomial_low_run";
open OUTFILE, ">", "binomial_low.dat" or die $!;

for ($i = 0; $i < 16; $i++) {
    $stdev = 0;
    $mean = 0;

    for ($j = 0; $j < 20; $j++) {
        open FILE, "<", "$filename_prefix$j\/rank$i" or die $! .  " $filename_prefix$j\/rank$i";
        
        @lines = <FILE>;
        chomp(@lines);
        
        $mean += $lines[0];
    }
    
    $mean /= 20;
    
    for ($j = 0; $j < 20; $j++) {
        open FILE, "<", "$filename_prefix$j\/rank$i" or die $! .  " $filename_prefix$j\/rank$i";
        
        @lines = <FILE>;
        chomp(@lines);
        
        $stdev += ($lines[0] - $mean) * ($lines[0] - $mean);
    }

    $stdev /= 19;
    $stdev = sqrt($stdev);

    if ($mean != 0) {
        print OUTFILE "$i $mean $stdev\n";
    }
}

$filename_prefix = "binomial_dancer\/binomial_middle_run";
open OUTFILE, ">", "binomial_middle.dat";

for ($i = 0; $i < 16; $i++) {
    $mean = 0;
    $stdev = 0;

    for ($j = 0; $j < 20; $j++) {
        open FILE, "<", "$filename_prefix$j\/rank$i" or die $! .  " $filename_prefix$j\/rank$i";
        
        @lines = <FILE>;
        chomp(@lines);
        
        $mean += $lines[0];
    }
    
    $mean /= 20;

    for ($j = 0; $j < 20; $j++) {
        open FILE, "<", "$filename_prefix$j\/rank$i" or die $! .  " $filename_prefix$j\/rank$i";
        
        @lines = <FILE>;
        chomp(@lines);
        
        $stdev += ($lines[0] - $mean) * ($lines[0] - $mean);
    }

    $stdev /= 19;
    $stdev = sqrt($stdev);
    
    if ($mean != 0) {
        print OUTFILE "$i $mean $stdev\n";
    }
}

$filename_prefix = "binomial_dancer\/binomial_high_run";
open OUTFILE, ">", "binomial_high.dat";

for ($i = 0; $i < 16; $i++) {
    $mean = 0;
    $stdev = 0;

    for ($j = 0; $j < 20; $j++) {
        open FILE, "<", "$filename_prefix$j\/rank$i" or die $! .  " $filename_prefix$j\/rank$i";
        
        @lines = <FILE>;
        chomp(@lines);
        
        $mean += $lines[0];
    }
    
    $mean /= 20;

    for ($j = 0; $j < 20; $j++) {
        open FILE, "<", "$filename_prefix$j\/rank$i" or die $! .  " $filename_prefix$j\/rank$i";
        
        @lines = <FILE>;
        chomp(@lines);
        
        $stdev += ($lines[0] - $mean) * ($lines[0] - $mean);
    }
    
    $stdev /= 19;
    $stdev = sqrt($stdev);
    
    if ($mean != 0) {
        print OUTFILE "$i $mean $stdev\n";
    }
}

$filename_prefix = "linear_dancer\/linear_low_run";
open OUTFILE, ">", "linear_low.dat";

for ($i = 0; $i < 16; $i++) {
    $mean = 0;
    $stdev = 0;

    for ($j = 0; $j < 20; $j++) {
        open FILE, "<", "$filename_prefix$j\/rank$i" or die $! .  " $filename_prefix$j\/rank$i";
        
        @lines = <FILE>;
        chomp(@lines);
        
        $mean += $lines[0];
    }
    
    $mean /= 20;
    
    for ($j = 0; $j < 20; $j++) {
        open FILE, "<", "$filename_prefix$j\/rank$i" or die $! .  " $filename_prefix$j\/rank$i";
        
        @lines = <FILE>;
        chomp(@lines);
        
        $stdev += ($lines[0] - $mean) * ($lines[0] - $mean);
    }
    
    $stdev /= 19;
    $stdev = sqrt($stdev);
    
    if ($mean != 0) {
        print OUTFILE "$i $mean $stdev\n";
    }
}

$filename_prefix = "linear_dancer\/linear_middle_run";
open OUTFILE, ">", "linear_middle.dat";

for ($i = 0; $i < 16; $i++) {
    $mean = 0;
    $stdev = 0;

    for ($j = 0; $j < 20; $j++) {
        open FILE, "<", "$filename_prefix$j\/rank$i" or die $! .  " $filename_prefix$j\/rank$i";
        
        @lines = <FILE>;
        chomp(@lines);
        
        $mean += $lines[0];
    }
    
    $mean /= 20;
    
    for ($j = 0; $j < 20; $j++) {
        open FILE, "<", "$filename_prefix$j\/rank$i" or die $! .  " $filename_prefix$j\/rank$i";
        
        @lines = <FILE>;
        chomp(@lines);
        
        $stdev += ($lines[0] - $mean) * ($lines[0] - $mean);
    }
    
    $stdev /= 19;
    $stdev = sqrt($stdev);
    
    if ($mean != 0) {
        print OUTFILE "$i $mean $stdev\n";
    }
}

$filename_prefix = "linear_dancer\/linear_high_run";
open OUTFILE, ">", "linear_high.dat";

for ($i = 0; $i < 16; $i++) {
    $mean = 0;
    $stdev = 0;

    for ($j = 0; $j < 20; $j++) {
        open FILE, "<", "$filename_prefix$j\/rank$i" or die $! .  " $filename_prefix$j\/rank$i";
        
        @lines = <FILE>;
        chomp(@lines);
        
        $mean += $lines[0];
    }
    
    $mean /= 20;
    
    for ($j = 0; $j < 20; $j++) {
        open FILE, "<", "$filename_prefix$j\/rank$i" or die $! .  " $filename_prefix$j\/rank$i";
        
        @lines = <FILE>;
        chomp(@lines);
        
        $stdev += ($lines[0] - $mean) * ($lines[0] - $mean);
    }
    
    $stdev /= 19;
    $stdev = sqrt($stdev);
    
    if ($mean != 0) {
        print OUTFILE "$i $mean $stdev\n";
    }
}
