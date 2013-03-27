#
# Josh Hursey
# May 10, 2012
#
package FTDriver::Coremath;

use strict;
use warnings;
use vars qw($VERSION);

require Exporter;

our @ISA    = qw(Exporter);
our @EXPORT = qw( calc_avg calc_avg_k calc_avg_wo_max calc_avg_wo_min
                  calc_std_dev calc_std_dev_k
                  set_avg_k
                  get_avg_k
                  calc_min calc_max);
our $VERSION = 1.0;

#####################################
# Local Vars with accessors
#####################################
our $avg_k_var;

sub get_avg_k() {
    return $avg_k_var;
}

sub set_avg_k($) {
    $avg_k_var = shift(@_);
    return get_avg_k();
}

sub sanity_check(@) {
  my @input = @_;
  my $i;

  if( 0 >= scalar(@input) ) {
    return -1;
  }

  foreach $i (@input) {
    if( !defined($i) ) {
      #print "Error: CoreMath: Undefined reference in the input!\n";;
      return -2;
    }
  }

  return 0;
}

#####################################
# Calculate Minimum
#####################################
sub calc_min(@) {
  my @input = @_;
  my $val;
  my $i;

  if( 0 != sanity_check(@input) ) {
    return 0;
  }

  $val = $input[0];
  for( $i = 0; $i < scalar(@input); ++$i) {
    if( $val > $input[$i] ) {
      $val = $input[$i];
    }
  }

  return $val;
}

#####################################
# Calculate Maximum
#####################################
sub calc_max(@) {
  my @input = @_;
  my $val;
  my $i;

  if( 0 != sanity_check(@input) ) {
    return 0;
  }

  $val = $input[0];
  for( $i = 0; $i < scalar(@input); ++$i) {
    if( $val < $input[$i] ) {
      $val = $input[$i];
    }
  }

  return $val;
}

#####################################
# Calculate standard deviation of values
#####################################
sub calc_std_dev(@) {
  my @input = @_;
  my $std = 0;
  my $mean = 0;
  my $iters;
  my $i;
  my $total_i;

  if( 0 != sanity_check(@input) ) {
    return 0;
  }

  @input = sort(@input);
  $iters = scalar(@input);

  $mean    = calc_avg(@input);
  $total_i = scalar(@input);
  if( $total_i - 1 <= 0 ) {
    return 0;
  }

  $std     = 0;
  for($i = 0; $i < $iters; ++$i) {
    $std += ($input[$i] - $mean) * ($input[$i] - $mean);
  }
  $std = sqrt($std / ($total_i-1.0));

  return $std;
}

sub calc_std_dev_k(@) {
  my @input = @_;
  my $std = 0;
  my $mean = 0;
  my $iters;
  my $i;
  my $total_i;

  if( 0 != sanity_check(@input) ) {
    return 0;
  }

  @input = sort(@input);
  $iters = scalar(@input);

  $mean    = calc_avg_k(@input);
  $total_i = scalar(@input) - 2*$avg_k_var;
  if( $total_i - 1 <= 0 ) {
    return 0;
  }

  $std     = 0;
  for($i = $avg_k_var; $i < $iters-$avg_k_var; ++$i) {
    $std += ($input[$i] - $mean) * ($input[$i] - $mean);
  }
  $std = sqrt($std / ($total_i-1.0));

  return $std;
}

#####################################
# Calculate average
# - [May prune first/last K values]
#####################################
sub calc_avg(@) {
  my @input = @_;
  my $output = 0;
  my $iters;
  my $i;

  if( 0 != sanity_check(@input) ) {
    return 0;
  }

  @input = sort(@input);
  $iters = scalar(@input);

  for($i = 0; $i < $iters; ++$i) {
    $output += $input[$i];
  }

  $i = scalar(@input);
  if( $i == 0 ) {
    return 0;
  }
  $output = ($output / $i);

  return $output;
}

sub calc_avg_wo_max(@) {
  my @input = @_;
  my $output = 0;
  my $iters;
  my $i;
  my $max;
  my $passed = 0;

  if( 0 != sanity_check(@input) ) {
    return 0;
  }

  $max = calc_max(@input);

  @input = sort(@input);
  $iters = scalar(@input);

  for($i = 0; $i < $iters; ++$i) {
    if( $input[$i] != $max ) {
      $output += $input[$i];
    } else {
      if( $passed == 1 ) {
        $output += $input[$i];
      } else {
        $passed = 1;
      }
    }
  }

  $i = scalar(@input) - 1;
  if( $i == 0 ) {
    return 0;
  }
  $output = ($output / $i);

  return $output;
}

sub calc_avg_wo_min(@) {
  my @input = @_;
  my $output = 0;
  my $iters;
  my $i;
  my $min;
  my $passed = 0;

  if( 0 != sanity_check(@input) ) {
    return 0;
  }

  $min = calc_min(@input);

  @input = sort(@input);
  $iters = scalar(@input);

  for($i = 0; $i < $iters; ++$i) {
    if( $input[$i] != $min ) {
      $output += $input[$i];
    } else {
      if( $passed == 1 ) {
        $output += $input[$i];
      } else {
        $passed = 1;
      }
    }
  }

  $i = scalar(@input) - 1;
  if( $i == 0 ) {
    return 0;
  }
  $output = ($output / $i);

  return $output;
}

sub calc_avg_k(@) {
  my @input = @_;
  my $output = 0;
  my $iters;
  my $i;

  if( 0 != sanity_check(@input) ) {
    return 0;
  }

  @input = sort(@input);
  $iters = scalar(@input);

  for($i = $avg_k_var; $i < $iters-$avg_k_var; ++$i) {
    $output += $input[$i];
  }

  $i = scalar(@input) - 2*$avg_k_var;
  $output = ($output / $i);

  return $output;
}

1;

__END__
