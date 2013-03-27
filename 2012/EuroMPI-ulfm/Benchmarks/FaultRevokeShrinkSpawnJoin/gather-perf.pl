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

###############################################################################
# Customize the following
###############################################################################
# Debug - Do not run commands
my $debug;

#
# Directory to store data
#
my $output_directory = $HOME."/dev/papers/eurompi/FaultRevokeShrinkSpawnJoin/data";

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

my $global_iterations = 10;

my $prefix;

#
# Cleanup Command
#
my $cleanup_cmd;
if( $MACH_SHORT_NAME =~ /jaguarpf/ || $MACH_SHORT_NAME =~ /chester/ ) {
  ; #Leave undefined
} else {
  $cleanup_cmd = "cleanup.pl frssj &> /dev/null";
}

###############################################################################
# Below this line be dragons, beware
###############################################################################
my $i;
my $ERROR_TIMEOUT_RTN = -9999;
my $cmd;
my $output_file;

my $output_filter = " 2>&1 | grep -v comm_revoke";

# Perform flush after each write to STDOUT
$| = 1;

#####################
# Parse Args
#####################
if(0 != parse_args() ) {
  printf("Usage: ./gather-perf.pl [-i ITERATIONS] [-a] [-p PREFIX] [-np MIN_NP] [-max_np MAX_NP]\n");
  exit -1;
}

#####################
# Run all tests
#####################
print "-"x70 . "\n";
for($i = $global_np_start_at; $i <= $global_np_end_at; $i *= 2) {
  if( defined($debug) ) {
    print "-"x70 . "\n";
  }
  printf("Running: NP = %3d, N = %3d\n", $i, $global_iterations);

  #$cmd = "mpirun --nolocal -np $i -am ft-enable-mpi frssj -v 1 -n $global_iterations " . $output_filter;
  $cmd = "mpirun --nolocal -np $i -am ft-enable-mpi frssj -v ".($i-1)." -n $global_iterations " . $output_filter;
  #print "Command: [$cmd]\n";
  $output_file = $output_directory . "/smoky-NP_".$i."-N_".$global_iterations.".data";
  #print "Output: [$output_file]\n";

  $cmd = $cmd . " > $output_file";
  run_command($cmd);
  run_command($cleanup_cmd);

  if( defined($debug) ) {
    print "\n";
  }
}
print "-"x70 . "\n";

exit 0;

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

sub parse_args() {
  my $argc = scalar(@ARGV);
  my $i;

  for($i = 0; $i < $argc; ++$i) {
    if( $ARGV[$i] =~ /^-max_np/ ) {
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
