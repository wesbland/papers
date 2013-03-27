#!/usr/bin/env perl

#
# Gather the data for the tests defined
#
use strict;
use Env qw(HOME PATH USER PWD MACH_SHORT_NAME SLURM_NNODES ENVIRONMENT);
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
# Directory to store data
my $output_directory = $HOME."/dev/papers/eurompi/netpipe/data";

# Netpipe Install Directory
my $netpipe_installdir;
if( $MACH_SHORT_NAME =~ /jaguarpf/ ) {
    $netpipe_installdir = "/tmp/work/jjhursey/testing/NetPIPE-3.7.1";
} elsif( $MACH_SHORT_NAME =~ /chester/ ) {
    $netpipe_installdir = "/tmp/work/jjhursey/testing/NetPIPE-3.7.1";
} else {
    $netpipe_installdir = $HOME."/svn/testing/ompi-tests/NetPIPE-3.7.1/";
}

my $subdir;
if( $MACH_SHORT_NAME =~ /jaguarpf/ ) {
    $subdir = "jaguarpf";
}
elsif( $MACH_SHORT_NAME =~ /chester/ ) {
    $subdir = "chester";
} else {
    $subdir = "smoky";
}

# Analyze the data only, no new runs
my $analysis_only;

# Debug - Do not run commands
my $debug;


###############################################################################
# Below this line be dragons, beware
###############################################################################
#
# Defines for INI File
#
my $KEY_TEST_NAME = "test_name";
my $KEY_MPIRUN    = "mpirun";
my $KEY_ITER      = "iterations";
my $KEY_OUTPUT    = "output";
my $KEY_ANALYZE   = "analyze";
my $KEY_ANALYZE_VALUE   = "analyze_value";
my $ANALYZE_NETPIPE_LATENCY = "netpipe_latency";
my $ANALYZE_NETPIPE_BANDWIDTH = "netpipe_bandwidth";

# Perform flush after each write to STDOUT
$| = 1;

#
# Test Unit Structure
#
struct Test_Unit => {
                     name => '$',
                     mpirun => '$',
                     iterations => '$',
                     output_base => '$',
                     analysis_type => '$',
                     analysis_value => '$',
                     all_data => '@',
                     min => '$',
                     max => '$',
                     std_dev => '$',
                     avg => '$',
                     k_means => '$',
                     k_means_std_dev => '$',
                     k => '$',
};

my $ERROR_TIMEOUT_RTN = -9999;

my $input_ini_file;
my @all_tests = ();
my $cur_test;

#####################
# Parse Args
#####################
if(0 != parse_args() ) {
  exit -1;
}

#####################
# Read the configuration file
#####################
if( ! -e $input_ini_file ) {
  print "ERROR: Cannot find the ini file specified! ($input_ini_file)\n";
  exit -1;
}
process_ini_file();

#####################
# Goto Netpipe directory
#####################
chdir($netpipe_installdir);
if( !-e "NPmpi" ) {
  print "ERROR: Cannot find the Netpipe executable (NPmpi)\n";
  exit -1;
}

#####################
# Foreach MPI Run
#####################
my $cur_output_file;
my $cur_cmd;
my $cur_data;
my $i;

foreach $cur_test (@all_tests) {
  if( !defined($analysis_only) ) {
    print "-"x10 . " " . $cur_test->name . "\n";
    print "-"x70 . "\n";
  }

  #display_test($cur_test);

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
    }
    if( !defined($debug) ) {
      print "\n";
    }
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
    $cur_data = extract_data($cur_output_file, $cur_test->analysis_type, $cur_test->analysis_value);
    #printf("\t Data : $cur_data\n");
    push(@{$cur_test->all_data}, $cur_data);
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
  $cur_test->min(     calc_min(@{$cur_test->all_data}) );
  $cur_test->max(     calc_max(@{$cur_test->all_data}) );
  $cur_test->std_dev( calc_std_dev(@{$cur_test->all_data}) );
  $cur_test->avg(     calc_avg(@{$cur_test->all_data}) );
  $cur_test->k_means( calc_avg_k(@{$cur_test->all_data}) );
  $cur_test->k_means_std_dev( calc_std_dev_k(@{$cur_test->all_data}) );

  if( !defined($analysis_only) ) {
    printf("\n");
  }
}

if( !defined($analysis_only) ) {
  printf("\n");
}
print "-"x70 . "\n";
print "-"x30 . " All Data " . "-"x30 . "\n";

my $last_analysis = "";
foreach $cur_test (@all_tests) {
  if( !($cur_test->analysis_type eq $last_analysis) ) {
    $last_analysis = $cur_test->analysis_type;

    print "\n";
    if( $cur_test->analysis_type eq $ANALYZE_NETPIPE_LATENCY ) {
      printf("----> Analysis: NetPIPE Latency   - %10d bytes (usec)\n", $cur_test->analysis_value);
    }
    elsif( $cur_test->analysis_type eq $ANALYZE_NETPIPE_BANDWIDTH ) {
      printf("----> Analysis: NetPIPE Bandwidth - %10s bytes (Mbps)\n", $cur_test->analysis_value);
    }
    printf("%5s %10s %10s %10s %10s %3s %10s %10s\n",
           "Iters", "Min", "Max", "Average", "Std.Dev.", "K", "K Means", "K Std.Dev.");
  }
  display_data($cur_test);
}
print "-"x70 . "\n";

exit 0;

sub process_ini_file() {
  my $line;
  my $processing;
  my $cur_key;
  my $cur_value;
  my $cur_test_unit;

  if( !open(INIFILE, "<$input_ini_file") ) {
    print "ERROR: Cannot open the ini file specified! ($input_ini_file)\n";
    exit -1;
  }

  $processing = 0;
  while($line = <INIFILE> ) {
    chomp($line);

    #
    # Skip Comments
    #
    if($line =~ /#/ ) {
      next;
    }

    #
    # Skip empty lines
    #
    if($line =~ /^\s*$/ ) {
      next;
    }

    $line =~ s/\s*$//;
    if( $line =~ /\\$/ ) {
      chop($line);
    }

    #
    # Find an '='
    #
    if($line =~ /=/ ) {
      $processing = 1;
      $cur_key = $`;
      $cur_value = $';

      # Strip off the start and end extra spaces
      $cur_key =~ s/^\s*//;
      $cur_key =~ s/\s*$//;
      $cur_value =~ s/^\s*//;
      $cur_value =~ s/\s*$//;

      if($cur_key =~ /$KEY_TEST_NAME/ ) {
        $cur_test_unit = Test_Unit->new();
        $cur_test_unit->name($cur_value);
        push(@all_tests, $cur_test_unit);
      }
      elsif($cur_key =~ /$KEY_MPIRUN/ ) {
        $cur_test_unit->mpirun($cur_value);
      }
      elsif($cur_key =~ /$KEY_ITER/ ) {
        $cur_test_unit->iterations($cur_value);
      }
      elsif($cur_key =~ /$KEY_OUTPUT/ ) {
        $cur_test_unit->output_base($cur_value);
      }
      elsif($cur_key =~ /$KEY_ANALYZE_VALUE/ ) {
        $cur_test_unit->analysis_value($cur_value);
      }
      elsif($cur_key =~ /$KEY_ANALYZE/ ) {
        $cur_test_unit->analysis_type($cur_value);
      }
    }
    elsif( $processing == 1 ) {
      $cur_value .= $line;

      if($cur_key =~ /$KEY_TEST_NAME/ ) {
        $cur_test_unit->name($cur_value);
      }
      elsif($cur_key =~ /$KEY_MPIRUN/ ) {
        $cur_test_unit->mpirun($cur_value);
      }
      elsif($cur_key =~ /$KEY_ITER/ ) {
        $cur_test_unit->iterations($cur_value);
      }
      elsif($cur_key =~ /$KEY_OUTPUT/ ) {
        $cur_test_unit->output_base($cur_value);
      }
      elsif($cur_key =~ /$KEY_ANALYZE_VALUE/ ) {
        $cur_test_unit->analysis_value($cur_value);
      }
      elsif($cur_key =~ /$KEY_ANALYZE/ ) {
        $cur_test_unit->analysis_type($cur_value);
      }
    }
  }

  close(INIFILE);

  return 0;
}

sub display_test() {
  my $loc_cur_test = shift(@_);

  print "-"x10 . " " . $loc_cur_test->name . "\n";
  print "\t mpirun     : " . $loc_cur_test->mpirun . "\n";
  print "\t iterations : " . $loc_cur_test->iterations . "\n";
  print "\t output     : " . $loc_cur_test->output_base . "\n";

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
  my $a_type = shift(@_);
  my $a_value = shift(@_);
  my $line;

  if( !defined($a_type) ) {
    print "ERROR: Unknown type of analysis\n";
    exit -1;
  }

  if( !open(DATAFILE, "<$fname") ) {
    print "ERROR: Cannot open the ini file specified! ($fname)\n";
    exit -1;
  }

  while($line = <DATAFILE> ) {
    chomp($line);

    if( $a_type eq $ANALYZE_NETPIPE_LATENCY ) {
      if( $line =~ /$a_value bytes/ ) {
        # Grab the Latency
        $line =~ /\d*.\d* usec/;
        $line = $&;
        $line =~ /\d*.\d*/;
        $line = $&;

        return $line;
      }
    }
    elsif( $a_type eq $ANALYZE_NETPIPE_BANDWIDTH ) {
      if( $line =~ /$a_value bytes/ ) {
        # Grab the Bandwidth
        $line =~ /\d*.\d* Mbps/;
        $line = $&;
        $line =~ /\d*.\d*/;
        $line = $&;

        return $line;
      }
    }
  }

  close(DATAFILE);

  return 0;
}

sub display_data() {
  my $cur_test = shift(@_);

  if( $cur_test->analysis_type eq $ANALYZE_NETPIPE_LATENCY ) {
    printf("%5d %10.4f %10.4f %10.4f %10.4f %3d %10.4f %10.4f - %20s\n",
           $cur_test->iterations,
           $cur_test->min,
           $cur_test->max,
           $cur_test->avg,
           $cur_test->std_dev,
           $cur_test->k,
           $cur_test->k_means,
           $cur_test->k_means_std_dev,
           $cur_test->name
          );
  }
  elsif( $cur_test->analysis_type eq $ANALYZE_NETPIPE_BANDWIDTH ) {
    printf("%5d %10.2f %10.2f %10.2f %10.2f %3d %10.2f %10.2f - %20s\n",
           $cur_test->iterations,
           $cur_test->min,
           $cur_test->max,
           $cur_test->avg,
           $cur_test->std_dev,
           $cur_test->k,
           $cur_test->k_means,
           $cur_test->k_means_std_dev,
           $cur_test->name
          );
  }

  return 0;
}

sub parse_args() {
  my $argc = scalar(@ARGV);
  my $i;

  if( $argc <= 0 ) {
    print "ERROR: Supply an ini file to process!\n";
    exit -1;
  }

  for($i = 0; $i < $argc; ++$i) {
    if( $ARGV[$i] =~ /^-a/ ) {
      $analysis_only = 12;
    }
    else {
      $input_ini_file = $ARGV[$i];
    }
  }

  return 0;
}
