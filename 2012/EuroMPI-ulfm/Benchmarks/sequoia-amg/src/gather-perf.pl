#!/usr/bin/env perl

#
# Gather the data for the tests defined
#
use strict;
use Env qw(HOME PATH USER PWD MACH_SHORT_NAME ENVIRONMENT PBS_NODEFILE PBS_NNODES);
if( $MACH_SHORT_NAME =~ /jaguarpf/ ) {
    push(@INC, "/tmp/work/jjhursey/testing/lib");
    use lib "/tmp/work/jjhursey/testing/lib";
} else {
    push(@INC, $HOME."/dev/papers/eurompi/driver/lib");
    use lib $HOME."/dev/papers/eurompi/driver/lib";
}

use Class::Struct;
use POSIX;
use Time::HiRes qw(gettimeofday);

use FTDriver::Coremath;


###############################################################################
# Customize the following
###############################################################################
# Debug - Do not run commands
my $debug;


# Analysis only
my $analysis_only; # Cmd Line: -a


# Baseline run
my $baseline;

#
# AMG Parameters
#
my $global_rx = 6; # 6 defined by Test Problem Set guideline
my $global_ry = $global_rx;
my $global_rz = $global_rx;
my $global_solver = 4; # Can use Solver 3 or 4
my $global_iterations = 2; # Cmd Line: -i [ITERATIONS]

#
# Directory to store data
#
my $output_directory = $HOME."/dev/papers/eurompi/sequoia-amg/data";

#
# AMG Install Directory
#
my $amg_installdir;
if( $MACH_SHORT_NAME =~ /jaguarpf/ ) {
    $amg_installdir = "/tmp/work/jjhursey/testing/amg";
} elsif( $MACH_SHORT_NAME =~ /chester/ ) {
    $amg_installdir = "/tmp/work/jjhursey/testing/amg";
} else {
    $amg_installdir = $HOME."/dev/apps/AMG2006/test";
}

#
# Subdirectory for storing data
#
my $subdir;
if( $MACH_SHORT_NAME =~ /jaguarpf/ ) {
    $subdir = "jaguarpf";
}
elsif( $MACH_SHORT_NAME =~ /chester/ ) {
    $subdir = "chester";
} else {
    $subdir = "smoky";
}

#
# Prefix for test results
#
my $prefix;


#
# Number of nodes
#
my $num_nodes;
my $num_nodes_offset = 1; # Subtract 1 for --nolocal
if( $MACH_SHORT_NAME =~ /jaguarpf/ || $MACH_SHORT_NAME =~ /chester/) {
  if( defined($PBS_NNODES) ) {
    $num_nodes = $PBS_NNODES / 16;
  } else {
    $num_nodes = 1;
  }
}
elsif( defined($PBS_NODEFILE) ) {
  $num_nodes = get_pbs_num_nodes() - $num_nodes_offset;
}
else {
  $num_nodes = 1;
}


#
# Number of processes per node
#
my $num_procs_per_node;
if( $MACH_SHORT_NAME =~ /jaguarpf/ || $MACH_SHORT_NAME =~ /chester/ ) {
  $num_procs_per_node = 16;
}
elsif( defined($PBS_NODEFILE) ) {
  $num_procs_per_node = get_pbs_num_procs_per_node();
}
else {
  $num_procs_per_node = 16;
}


my $global_np_start_at = 8; # Cmd Line: -np MIN_NP
my $global_np_end_at = ($num_procs_per_node * $num_nodes); # Cmd Line: -max_np MAX_NP


#
# Cleanup Command
#
my $cleanup_cmd;
if( $MACH_SHORT_NAME =~ /jaguarpf/ || $MACH_SHORT_NAME =~ /chester/ ) {
  ; #Leave undefined
} else {
  $cleanup_cmd = "cleanup.pl amg2006 &> /dev/null";
}


###############################################################################
# Below this line be dragons, beware
###############################################################################

# Perform flush after each write to STDOUT
$| = 1;

# Different metrics
# FOM : Figure of Merit
my $ANALYZE_AMG_SSTRUCT = "SStruct Interface";
my $ANALYZE_AMG_SETUP = "Setup phase times";
my $ANALYZE_AMG_SOLVE = "Solve phase times";
my $ANALYZE_AMG_FOM = "System Size ";

#
# Test Unit Structure
#
struct Test_Unit => {
                     name => '$',
                     mpirun => '$',

                     np => '$',

                     px => '$',
                     py => '$',
                     pz => '$',

                     rx => '$',
                     ry => '$',
                     rz => '$',

                     solver => '$',

                     iterations => '$',

                     output_base => '$',

                     k => '$',

                     sstruct_all_data => '@',
                     sstruct_min => '$',
                     sstruct_max => '$',
                     sstruct_std_dev => '$',
                     sstruct_avg => '$',
                     sstruct_k_means => '$',
                     sstruct_k_means_std_dev => '$',

                     setup_all_data => '@',
                     setup_min => '$',
                     setup_max => '$',
                     setup_std_dev => '$',
                     setup_avg => '$',
                     setup_k_means => '$',
                     setup_k_means_std_dev => '$',

                     solve_all_data => '@',
                     solve_min => '$',
                     solve_max => '$',
                     solve_std_dev => '$',
                     solve_avg => '$',
                     solve_k_means => '$',
                     solve_k_means_std_dev => '$',

                     fom_all_data => '@',
                     fom_min => '$',
                     fom_max => '$',
                     fom_std_dev => '$',
                     fom_avg => '$',
                     fom_k_means => '$',
                     fom_k_means_std_dev => '$',
};

my $ERROR_TIMEOUT_RTN = -9999;

my @all_tests = ();
my $cur_test;
my $cur_output_file;
my $cur_cmd;
my $sstruct_cur_data;
my $setup_cur_data;
my $solve_cur_data;
my $fom_cur_data;
my $i;

#####################
# Parse Args
#####################
if(0 != parse_args() ) {
  printf("Usage: ./gather-perf.pl [-i ITERATIONS] [-a] [-p PREFIX] [-np MIN_NP] [-max_np MAX_NP]\n");
  exit -1;
}


#####################
# Goto AMG directory
#####################
chdir($amg_installdir);
if( !-e "amg2006" ) {
  print "ERROR: Cannot find the AMG executable (NPmpi)\n";
  exit -1;
}


#####################
# Setup run
#####################
for($i = $global_np_start_at; $i <= $global_np_end_at; $i *= 2) {
  if( !defined($baseline) ) {
    $cur_test = create_test($i, "Scaling - Without FT", "--bind-to-core", "noft");
    push(@all_tests, $cur_test);

    $cur_test = create_test($i, "Scaling - With FT",    "--bind-to-core -am ft-enable-mpi", "ft");
    push(@all_tests, $cur_test);
  } else {
    $cur_test = create_test($i, "Scaling - Compiled Out", "--bind-to-core", "nocompileft");
    push(@all_tests, $cur_test);
  }
}


#####################
# Foreach MPI Run
#####################
foreach $cur_test (@all_tests) {
  if( !defined($analysis_only) ) {
    display_test($cur_test);
  }

  #####################
  # Run the mpirun N times
  # Collect output in N'versioned files
  #####################
  if( !defined($analysis_only) ) {
    printf("\t----- Running Tests\n\t");
    for($i = 0; $i < $cur_test->iterations; ++$i ) {
      if( defined($debug) ) {
        printf("\t----- %3d of %3d - Running\n", $i, $cur_test->iterations);
      } else {
        if( $i != 0 && 0 == ($i % 5) ) {
          if( 0 == ($i % 25) ) {
            print "\n\t.";
          } else {
            print " .";
          }
        } else {
          print ".";
        }
      }

      $cur_output_file = get_output_filename($cur_test->output_base, $i);
      #print "\t\t $i : $cur_output_file\n";

      if( -e $cur_output_file ) {
        run_command("rm $cur_output_file");
      }

      $cur_cmd = $cur_test->mpirun ." &>".$cur_output_file;
      run_command($cur_cmd);

      # Cleanup
      if(defined($cleanup_cmd) ) {
        run_command($cleanup_cmd);
      }
    }
    if( !defined($debug) ) {
      print "\n";
    }
  }

  if( defined($debug) ) {
    next;
  }
  #####################
  # Extract the data
  #####################
  if( !defined($analysis_only) ) {
    printf("\t----- Collecting Data\n");
  }
  for($i = 0; $i < $cur_test->iterations; ++$i ) {
    #printf("\t----- %3d of %3d - Collecting\n", $i, $cur_test->iterations);

    $cur_output_file = get_output_filename($cur_test->output_base, $i);
    ($sstruct_cur_data, $setup_cur_data, $solve_cur_data, $fom_cur_data) = extract_data($cur_output_file);
    #printf("Data: %11.6f %11.6f %11.6f %11.6f\n", $sstruct_cur_data, $setup_cur_data, $solve_cur_data, $fom_cur_data);

    push(@{$cur_test->sstruct_all_data}, $sstruct_cur_data);
    push(@{$cur_test->setup_all_data}, $setup_cur_data);
    push(@{$cur_test->solve_all_data}, $solve_cur_data);
    push(@{$cur_test->fom_all_data}, $fom_cur_data);
  }
  #printf("\n");

  #####################
  # Analyze all of the output
  # {Min, Max, Avg., Mean, K-means Avg}
  #####################
  if( !defined($analysis_only) ) {
    printf("\t----- Analyzing Data\n");
  }

  $cur_test->k( floor($cur_test->iterations / 5) );
  set_avg_k($cur_test->k);

  # SStruct
  $cur_test->sstruct_min(     calc_min(@{$cur_test->sstruct_all_data}) );
  $cur_test->sstruct_max(     calc_max(@{$cur_test->sstruct_all_data}) );
  $cur_test->sstruct_std_dev( calc_std_dev(@{$cur_test->sstruct_all_data}) );
  $cur_test->sstruct_avg(     calc_avg(@{$cur_test->sstruct_all_data}) );
  $cur_test->sstruct_k_means( calc_avg_k(@{$cur_test->sstruct_all_data}) );
  $cur_test->sstruct_k_means_std_dev( calc_std_dev_k(@{$cur_test->sstruct_all_data}) );

  # Setup
  $cur_test->setup_min(     calc_min(@{$cur_test->setup_all_data}) );
  $cur_test->setup_max(     calc_max(@{$cur_test->setup_all_data}) );
  $cur_test->setup_std_dev( calc_std_dev(@{$cur_test->setup_all_data}) );
  $cur_test->setup_avg(     calc_avg(@{$cur_test->setup_all_data}) );
  $cur_test->setup_k_means( calc_avg_k(@{$cur_test->setup_all_data}) );
  $cur_test->setup_k_means_std_dev( calc_std_dev_k(@{$cur_test->setup_all_data}) );

  # Solve
  $cur_test->solve_min(     calc_min(@{$cur_test->solve_all_data}) );
  $cur_test->solve_max(     calc_max(@{$cur_test->solve_all_data}) );
  $cur_test->solve_std_dev( calc_std_dev(@{$cur_test->solve_all_data}) );
  $cur_test->solve_avg(     calc_avg(@{$cur_test->solve_all_data}) );
  $cur_test->solve_k_means( calc_avg_k(@{$cur_test->solve_all_data}) );
  $cur_test->solve_k_means_std_dev( calc_std_dev_k(@{$cur_test->solve_all_data}) );

  # Fom
  $cur_test->fom_min(     calc_min(@{$cur_test->fom_all_data}) );
  $cur_test->fom_max(     calc_max(@{$cur_test->fom_all_data}) );
  $cur_test->fom_std_dev( calc_std_dev(@{$cur_test->fom_all_data}) );
  $cur_test->fom_avg(     calc_avg(@{$cur_test->fom_all_data}) );
  $cur_test->fom_k_means( calc_avg_k(@{$cur_test->fom_all_data}) );
  $cur_test->fom_k_means_std_dev( calc_std_dev_k(@{$cur_test->fom_all_data}) );

  if( !defined($analysis_only) ) {
    printf("\n");
  }
}

if( !defined($analysis_only) ) {
  printf("\n");
}
print "-"x70 . "\n";
print "-"x30 . " All Data " . "-"x30 . "\n";

foreach $cur_test (@all_tests) {
  printf("%5s %10s %10s %10s %10s %3s %10s %10s\n",
         "NP", "Min", "Max", "Average", "Std.Dev.", "K", "K Means", "K Std.Dev.");
  display_data($cur_test);
}
print "-"x70 . "\n";

exit 0;


sub display_test() {
  my $loc_cur_test = shift(@_);

  if( !defined($debug) ) {
    return display_test_brief($loc_cur_test);
  }

  print "-"x10 . " " . $loc_cur_test->name . "\n";
  print "\t np         : " . $loc_cur_test->np . "\n";
  print "\t Px,Py,Pz   : " . $loc_cur_test->px . ", " . $loc_cur_test->py . ", " . $loc_cur_test->pz . "\n";
  print "\t Rx,Ry,Rz   : " . $loc_cur_test->rx . ", " . $loc_cur_test->ry . ", " . $loc_cur_test->rz . "\n";
  print "\t iterations : " . $loc_cur_test->iterations . "\n";
  print "\t output     : " . $loc_cur_test->output_base . "\n";
  print "\t mpirun     : " . $loc_cur_test->mpirun . "\n";

  return 0;
}

sub display_test_brief() {
  my $loc_cur_test = shift(@_);

  print "-"x70 . "\n";
  print "-"x10 . " " . $loc_cur_test->name . " : ".$loc_cur_test->output_base."\n";
  printf("\t np(%4d)\titer(%3d)\tP(%2d,%2d,%2d)\tR(%2d,%2d,%2d)\n",
         $loc_cur_test->np,
         $loc_cur_test->iterations,
         $loc_cur_test->px, $loc_cur_test->py, $loc_cur_test->pz,
         $loc_cur_test->rx, $loc_cur_test->ry, $loc_cur_test->rz);

  return 0;
}

sub run_command() {
  my $loc_cmd = shift(@_);
  my $loc_timeout = shift(@_);
  my $rtn;

  if( defined($debug) ) {
    print "Run: $loc_cmd\n";
    if( defined($loc_timeout) ) {
      print "\t Timeout : $loc_timeout\n";
    }
    return 0;
  }

  if( !defined($loc_timeout) ) {
    return system($loc_cmd);
  }

  eval {
    local $SIG{ALRM} = sub { die "alarm\n" }; # NB: \n required
    alarm $loc_timeout;
    $rtn = system($loc_cmd);
    alarm 0;
  };
  if( $@ ) {
    if( $@ eq "alarm\n" ) {
      if( $rtn == 0 ) {
        return $ERROR_TIMEOUT_RTN;
      }
    }
  }

  return $rtn;
}

sub get_output_filename() {
  my $fname = shift(@_);
  my $itr = shift(@_);
  my $str;

  $str = ($output_directory ."/");
  if( defined($subdir) ) {
      $str .= ($subdir ."/");
  }
  $str .= ($fname ."--$itr.data");
  return ($str);
}

sub extract_data() {
  my $fname  = shift(@_);
  my $line;
  my $loc_sstruct_data = 0;
  my $loc_setup_data = 0;
  my $loc_solve_data = 0;
  my $loc_fom_data = 0;
  my $type;
  my $val;

  if( !open(DATAFILE, "<$fname") ) {
    print "ERROR: Cannot open the file specified! ($fname)\n";
    exit -1;
  }

  while($line = <DATAFILE> ) {
    chomp($line);

    if( $line =~ /$ANALYZE_AMG_SSTRUCT/ ) {
      $type = $ANALYZE_AMG_SSTRUCT;
    }
    elsif( $line =~ /$ANALYZE_AMG_SETUP/ ) {
      $type = $ANALYZE_AMG_SETUP;
    }
    elsif( $line =~ /$ANALYZE_AMG_SOLVE/ ) {
      $type = $ANALYZE_AMG_SOLVE;
    }
    elsif( $line =~ /$ANALYZE_AMG_FOM/ ) {
      $type = $ANALYZE_AMG_FOM;
      $line = $';
      $line =~ /\d+.\d+e\+\d+/;
      $val = $&;

      $loc_fom_data = $val;
    }
    elsif( $line =~ /wall clock time\s*=\s*/ ) {  # or /cpu clock time\s*=\s*/
      $line = $';
      $line =~ /\d*.\d*/;
      $val = $&;

      if( $type eq $ANALYZE_AMG_SSTRUCT ) {
        $loc_sstruct_data = $val;
      }
      elsif( $type eq $ANALYZE_AMG_SETUP ) {
        $loc_setup_data = $val;
      }
      elsif( $type eq $ANALYZE_AMG_SOLVE ) {
        $loc_solve_data = $val;
      }
    }
    else {
      #print "L: $line\n";
    }
  }

  close(DATAFILE);

  return ($loc_sstruct_data, $loc_setup_data, $loc_solve_data, $loc_fom_data);
}

sub display_data() {
  my $cur_test = shift(@_);

  printf("%5d %10.4f %10.4f %10.4f %10.4f %3d %10.4f %10.4f - %20s - SStruct\n",
         $cur_test->np,
         $cur_test->sstruct_min,
         $cur_test->sstruct_max,
         $cur_test->sstruct_avg,
         $cur_test->sstruct_std_dev,
         $cur_test->k,
         $cur_test->sstruct_k_means,
         $cur_test->sstruct_k_means_std_dev,
         $cur_test->name
        );

  printf("%5d %10.4f %10.4f %10.4f %10.4f %3d %10.4f %10.4f - %20s - Setup\n",
         $cur_test->np,
         $cur_test->setup_min,
         $cur_test->setup_max,
         $cur_test->setup_avg,
         $cur_test->setup_std_dev,
         $cur_test->k,
         $cur_test->setup_k_means,
         $cur_test->setup_k_means_std_dev,
         $cur_test->name
        );

  printf("%5d %10.4f %10.4f %10.4f %10.4f %3d %10.4f %10.4f - %20s - Solve\n",
         $cur_test->np,
         $cur_test->solve_min,
         $cur_test->solve_max,
         $cur_test->solve_avg,
         $cur_test->solve_std_dev,
         $cur_test->k,
         $cur_test->solve_k_means,
         $cur_test->solve_k_means_std_dev,
         $cur_test->name
        );

  printf("%5d %10.4f %10.4f %10.4f %10.4f %3d %10.4f %10.4f - %20s - FOM (e+07)\n",
         $cur_test->np,
         $cur_test->fom_min / 10000000,
         $cur_test->fom_max / 10000000,
         $cur_test->fom_avg / 10000000,
         $cur_test->fom_std_dev / 10000000,
         $cur_test->k,
         $cur_test->fom_k_means / 10000000,
         $cur_test->fom_k_means_std_dev / 10000000,
         $cur_test->name
        );

  return 0;
}

sub create_test() {
  my $np = shift(@_);
  my $name = shift(@_);
  my $mca = shift(@_);
  my $file_prefix = shift(@_);
  my $loc_test;

  if( defined($prefix) ) {
    $file_prefix = $prefix ."-". $file_prefix;
  }

  $loc_test = Test_Unit->new();

  if(       8 == $np ) {
    $loc_test->px(2);
    $loc_test->py(2);
    $loc_test->pz(2);
  }
  elsif(   16 == $np ) {
    $loc_test->px(4);
    $loc_test->py(2);
    $loc_test->pz(2);
  }
  elsif(   32 == $np ) {
    $loc_test->px(4);
    $loc_test->py(4);
    $loc_test->pz(2);
  }
  elsif(   64 == $np ) {
    $loc_test->px(4);
    $loc_test->py(4);
    $loc_test->pz(4);
  }
  elsif(  128 == $np ) {
    $loc_test->px(8);
    $loc_test->py(4);
    $loc_test->pz(4);
  }
  elsif(  256 == $np ) {
    $loc_test->px(8);
    $loc_test->py(8);
    $loc_test->pz(4);
  }
  elsif(  512 == $np ) {
    $loc_test->px(8);
    $loc_test->py(8);
    $loc_test->pz(8);
  }
  elsif(  1024 == $np ) {
    $loc_test->px(16);
    $loc_test->py(8);
    $loc_test->pz(8);
  }
  else {
    printf("ERROR: Too many processes! (Nodes: $num_nodes, Procs/node: $num_procs_per_node)\n");
    exit -1;
  }

  $loc_test->name($name);
  $loc_test->np($np);

  $loc_test->rx($global_rx);
  $loc_test->ry($global_ry);
  $loc_test->rz($global_rz);

  $loc_test->solver($global_solver);

  $loc_test->iterations($global_iterations);

  $loc_test->k(0); # Set automaticly during analysis

  $loc_test->output_base($file_prefix."-");
  if( defined($prefix) ) {
    $loc_test->output_base($loc_test->output_base . $prefix."_");
  }
  $loc_test->output_base($loc_test->output_base . "NP_".$loc_test->np."-S_".$loc_test->solver);

  $loc_test->mpirun("mpirun --nolocal ".
                    $mca.
                    " -np ".$loc_test->np.
                    " amg2006 ".
                    " -P ".$loc_test->px." ".$loc_test->py." ".$loc_test->pz.
                    " -r ".$loc_test->rx." ".$loc_test->ry." ".$loc_test->rz.
                    " -solver ".$loc_test->solver);

  return $loc_test
}

sub parse_args() {
  my $argc = scalar(@ARGV);
  my $i;

  for($i = 0; $i < $argc; ++$i) {
    if( $ARGV[$i] =~ /^-a/ ) {
      $analysis_only = 12;
    }
    elsif( $ARGV[$i] =~ /^-b/ ) {
      $baseline = 12;
    }
    elsif( $ARGV[$i] =~ /^-max_np/ ) {
      ++$i;
      if( $i >= $argc ) {
        print "Error: Must supply an argument to [-max_np MAX_NP]\n";
        return -1;
      }
      $global_np_end_at = $ARGV[$i] + 0;
      if( $global_np_end_at < 0 ) {
        print "Error: Must supply a positive argument to [-max_np MAX_NP] not (".$ARGV[$i].")\n";
        return -1;
      }
    }
    elsif( $ARGV[$i] =~ /^-np/ ) {
      ++$i;
      if( $i >= $argc ) {
        print "Error: Must supply an argument to [-np MIN_NP]\n";
        return -1;
      }
      $global_np_start_at = $ARGV[$i] + 0;
      if( $global_np_start_at < 0 ) {
        print "Error: Must supply a positive argument to [-np MIN_NP] not (".$ARGV[$i].")\n";
        return -1;
      }
    }
    elsif( $ARGV[$i] =~ /^-i/ ) {
      ++$i;
      if( $i >= $argc ) {
        print "Error: Must supply an argument to [-i ITERATIONS]\n";
        return -1;
      }
      $global_iterations = $ARGV[$i] + 0;
    }
    elsif( $ARGV[$i] =~ /^-p/ ) {
      ++$i;
      if( $i >= $argc ) {
        print "Error: Must supply an argument to [-p PREFIX]\n";
        return -1;
      }
      $prefix = $ARGV[$i];
    }
  }

  return 0;
}

sub get_pbs_num_nodes() {
  my $value;

  if( !defined($PBS_NODEFILE) ) {
    return 0;
  }

  $value = `cat $PBS_NODEFILE | sort -u | wc -l`;
  chomp($value);

  return ($value + 0);
}

sub get_pbs_num_procs_per_node() {
  my $value;

  if( !defined($PBS_NODEFILE) ) {
    return 0;
  }

  $value = `cat $PBS_NODEFILE | wc -l`;
  chomp($value);

  $value = $value / ($num_nodes + $num_nodes_offset);

  return ($value + 0);
}

