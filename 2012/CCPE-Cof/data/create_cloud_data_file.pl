#!/usr/bin/perl

$binomial_foldername = "binomial";
$linear_foldername = "linear";
$ranks = 16;
$runs = 20;

$filename_prefix = "$binomial_foldername\/binomial_low_run";
open OUTFILE, ">", "binomial_low.dat" or die $!;

for ($i = 0; $i < $ranks; $i++) {
    for ($j = 0; $j < $runs; $j++) {
        open FILE, "<", "$filename_prefix$j\/rank$i" or die $! .  " $filename_prefix$j\/rank$i";
        
        @lines = <FILE>;
        chomp(@lines);
        
        print OUTFILE "$i $lines[0]\n";
    }
}

$filename_prefix = "$binomial_foldername\/binomial_middle_run";
open OUTFILE, ">", "binomial_middle.dat";

for ($i = 0; $i < $ranks; $i++) {
    for ($j = 0; $j < $runs; $j++) {
        open FILE, "<", "$filename_prefix$j\/rank$i" or die $! .  " $filename_prefix$j\/rank$i";
        
        @lines = <FILE>;
        chomp(@lines);
        
        print OUTFILE "$i $lines[0]\n";
    }
}

$filename_prefix = "$binomial_foldername\/binomial_high_run";
open OUTFILE, ">", "binomial_high.dat";

for ($i = 0; $i < $ranks; $i++) {
    for ($j = 0; $j < $runs; $j++) {
        open FILE, "<", "$filename_prefix$j\/rank$i" or die $! .  " $filename_prefix$j\/rank$i";
        
        @lines = <FILE>;
        chomp(@lines);
        
        print OUTFILE "$i $lines[0]\n";
    }
}

$filename_prefix = "$linear_foldername\/linear_low_run";
open OUTFILE, ">", "linear_low.dat";

for ($i = 0; $i < $ranks; $i++) {
    for ($j = 0; $j < $runs; $j++) {
        open FILE, "<", "$filename_prefix$j\/rank$i" or die $! .  " $filename_prefix$j\/rank$i";
        
        @lines = <FILE>;
        chomp(@lines);
        
        print OUTFILE "$i $lines[0]\n";
    }
}

$filename_prefix = "$linear_foldername\/linear_middle_run";
open OUTFILE, ">", "linear_middle.dat";

for ($i = 0; $i < $ranks; $i++) {
    for ($j = 0; $j < $runs; $j++) {
        open FILE, "<", "$filename_prefix$j\/rank$i" or die $! .  " $filename_prefix$j\/rank$i";
        
        @lines = <FILE>;
        chomp(@lines);
        
        print OUTFILE "$i $lines[0]\n";
    }
}

$filename_prefix = "$linear_foldername\/linear_high_run";
open OUTFILE, ">", "linear_high.dat";

for ($i = 0; $i < $ranks; $i++) {
    for ($j = 0; $j < $runs; $j++) {
        open FILE, "<", "$filename_prefix$j\/rank$i" or die $! .  " $filename_prefix$j\/rank$i";
        
        @lines = <FILE>;
        chomp(@lines);
        
        print OUTFILE "$i $lines[0]";
    }
}

