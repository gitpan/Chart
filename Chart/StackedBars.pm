#>>>>>>>>>>>>>>>>>>>>>>>>>>>>>#
#  Chart::StackedBars         #
#                             #
#  written by david bonner    #
#  dbonner@cs.bu.edu          #
#                             #
#  maintained by peter clark  #
#  ninjaz@webexpress.com      #
#                             #
#  theft is treason, citizen  #
#<<<<<<<<<<<<<<<<<<<<<<<<<<<<<#

package Chart::StackedBars;

use Chart::Base;
use GD;
use Carp;
use strict;

@Chart::StackedBars::ISA = qw(Chart::Base);
$Chart::StackedBars::VERSION = 0.99;

#>>>>>>>>>>>>>>>>>>>>>>>>>>#
#  public methods go here  #
#<<<<<<<<<<<<<<<<<<<<<<<<<<#



#>>>>>>>>>>>>>>>>>>>>>>>>>>>#
#  private methods go here  #
#<<<<<<<<<<<<<<<<<<<<<<<<<<<#

## override check_data to make sure we don't get datasets with positive
## and negative values mixed
sub _check_data {
  my $self = shift;
  my $data = $self->{'dataref'};
  my $length = 0;
  my ($i, $j, $posneg);

  # remember the number of datasets
  $self->{'num_datasets'} = $#{$data};

  # remember the number of points in the largest dataset
  $self->{'num_datapoints'} = 0;
  for (0..$self->{'num_datasets'}) {
    if (scalar(@{$data->[$_]}) > $self->{'num_datapoints'}) {
      $self->{'num_datapoints'} = scalar(@{$data->[$_]});
    }
  }

  # make sure the datasets don't mix pos and neg values
  for $i (0..$self->{'num_datapoints'}-1) {
    $posneg = '';
    for $j (1..$self->{'num_datasets'}) {
      if ($data->[$j][$i] > 0) {
	if ($posneg eq 'neg') {
	  croak "The values for a Chart::StackedBars data point must either be all positive or all negative";
	}
	else {
	  $posneg = 'pos';
	}
      }
      elsif ($data->[$j][$i] < 0) {
	if ($posneg eq 'pos') {
	  croak "The values for a Chart::StackedBars data point must either be all positive or all negative";
	}
	else {
	  $posneg = 'neg';
	}
      }
    }
  }

  # find good min and max y-values for the plot
  $self->_find_y_scale;

  # find the longest x-tick label
  for (@{$data->[0]}) {
    if (length($_) > $length) {
      $length = length ($_);
    }
  }

  # now store it in the object
  $self->{'x_tick_label_length'} = $length;

  return;
}


## override _find_y_scale to account for stacked bars
sub _find_y_scale {
  my $self = shift;
  my $raw = $self->{'dataref'};
  my $data = [@{$raw->[1]}];
  my ($i, $j, $max, $min);
  my ($order, $mult, $tmp);
  my ($range, $delta, @dec, $y_ticks);
  my $labels = [];
  my $length = 0;

  # use realy weird max and min values
  $max = -999999999999;
  $min = 999999999999;

  # go through and stack them
  for $i (0..$self->{'num_datapoints'}-1) {
    for $j (2..$self->{'num_datasets'}) {
      $data->[$i] += $raw->[$j][$i];
    }
  }

  # get max and min values
  for $i (0..$self->{'num_datapoints'}-1) {
    if ($data->[$i] > $max) {
      $max = $data->[$i];
    }
    if ($data->[$i] < $min) {
      $min = $data->[$i];
    }
  }

  # calculate good max value
  if ($max < -10) {
    $tmp = -$max;
    $order = int((log $tmp) / (log 10));
    $mult = int ($tmp / (10 ** $order));
    $tmp = ($mult - 1) * (10 ** $order);
    $max = -$tmp;
  }
  elsif ($max < 0) {
    $max = 0;
  }
  elsif ($max > 10) {
    $order = int((log $max) / (log 10));
    $mult = int ($max / (10 ** $order));
    $max = ($mult + 1) * (10 ** $order);
  }
  elsif ($max >= 0) {
    $max = 10;
  }

  # now go for a good min
  if ($min < -10) {
    $tmp = -$min;
    $order = int((log $tmp) / (log 10));
    $mult = int ($tmp / (10 ** $order));
    $tmp = ($mult + 1) * (10 ** $order);
    $min = -$tmp;
  }
  elsif ($min < 0) {
    $min = -10;
  }
  elsif ($min > 10) {
    $order = int ((log $min) / (log 10));
    $mult = int ($min / (10 ** $order));
    $min = $mult * (10 ** $order);
  }
  elsif ($min >= 0) {
    $min = 0;
  }

  # make sure all-positive or all-negative charts get anchored at
  # zero so that we don't cut out some parts of the bars
  if (($max > 0) && ($min > 0)) {
    $min = 0;
  }
  if (($min < 0) && ($max < 0)) {
    $max = 0;
  }

  # put the appropriate in and max values into the object if necessary
  unless (defined ($self->{'max_val'})) {
    $self->{'max_val'} = $max;
  }
  unless (defined ($self->{'min_val'})) {
    $self->{'min_val'} = $min;
  }

  # generate the y_tick labels, store them in the object
  # figure out which one is going to be the longest
  $range = $self->{'max_val'} - $self->{'min_val'};
  $y_ticks = $self->{'y_ticks'} - 1;
  if ($self->{'integer_ticks_only'} =~ /^true$/i) {
    unless (($range % $y_ticks) == 0) {
      while (($range % $y_ticks) != 0) {
	$y_ticks++;
      }
      $self->{'y_ticks'} = $y_ticks + 1;
    }
  }
    
  $delta = $range / $y_ticks;
  for (0..$y_ticks) {
    $tmp = $self->{'min_val'} + ($delta * $_);
    @dec = split /\./, $tmp;
    if ($dec[1] && (length($dec[1]) > 3)) {
      $tmp = sprintf("%.3f", $tmp);
    }
    $labels->[$_] = $tmp;
    if (length($tmp) > $length) {
      $length = length($tmp);
    }
  }

  # store it in the object
  $self->{'y_tick_labels'} = $labels;
  $self->{'y_tick_label_length'} = $length;
 
  # and return
  return;
}


## finally get around to plotting the data
sub _draw_data {
  my $self = shift;
  my $raw = $self->{'dataref'};
  my $data = [];
  my $misccolor = $self->{'color_table'}{'misc'};
  my ($width, $height, $delta, $map, $mod);
  my ($x1, $y1, $x2, $y2, $x3, $y3, $i, $j, $color);

  # init the imagemap data field if they want it
  if ($self->{'imagemap'} =~ /^true$/i) {
    $self->{'imagemap_data'} = [];
  }

  # width and height of remaining area, delta for width of bars, mapping value
  $width = $self->{'curr_x_max'} - $self->{'curr_x_min'};
  if ($self->{'spaced_bars'} =~ /^true$/i) {
    $delta = $width / ($self->{'num_datapoints'} * 2);
  }
  else {
    $delta = $width / $self->{'num_datapoints'};
  }
  $height = $self->{'curr_y_max'} - $self->{'curr_y_min'};
  $map = $height / ($self->{'max_val'} - $self->{'min_val'});

  # get the base x and y values
  $x1 = $self->{'curr_x_min'};
  if ($self->{'min_val'} >= 0) {
    $y1 = $self->{'curr_y_max'};
    $mod = $self->{'min_val'};
  }
  elsif ($self->{'max_val'} <= 0) {
    $y1 = $self->{'curr_y_min'};
    $mod = $self->{'max_val'};
  }
  else {
    $y1 = $self->{'curr_y_min'} + ($map * $self->{'max_val'});
    $mod = 0;
    $self->{'gd_obj'}->line ($self->{'curr_x_min'}, $y1,
                             $self->{'curr_x_max'}, $y1,
			     $misccolor);
  }

  # create another copy of the data, but stacked
  $data->[1] = [@{$raw->[1]}];
  for $i (0..$self->{'num_datapoints'}-1) {
    for $j (2..$self->{'num_datasets'}) {
      $data->[$j][$i] = $data->[$j-1][$i] + $raw->[$j][$i];
    }
  }
     
  # draw the damn bars
  for $i (0..$self->{'num_datapoints'}-1) {
    # init the y values for this datapoint
    $y2 = $y1;
    
    for $j (1..$self->{'num_datasets'}) {
      # get the color
      $color = $self->{'color_table'}{'dataset'.($j-1)};
      
      # set up the geometry for the bar
      if ($self->{'spaced_bars'} =~ /^true$/i) {
        $x2 = $x1 + (2 * $i * $delta) + ($delta / 2);
	$x3 = $x2 + $delta;
      }
      else {
        $x2 = $x1 + ($i * $delta);
        $x3 = $x2 + $delta;
      }
      $y3 = $y1 - (($data->[$j][$i] - $mod) * $map);

      # draw the bar
      ## y2 and y3 are reversed in some cases because GD's fill
      ## algorithm is lame
      if ($data->[$j][$i] > 0) {
        $self->{'gd_obj'}->filledRectangle ($x2, $y3, $x3, $y2, $color);
	if ($self->{'imagemap'} =~ /^true$/i) {
	  $self->{'imagemap_data'}->[$j][$i] = [ $x2, $y3, $x3, $y2 ];
	}
      }
      else {
        $self->{'gd_obj'}->filledRectangle ($x2, $y2, $x3, $y3, $color);
	if ($self->{'imagemap'} =~ /^true$/i) {
	  $self->{'imagemap_data'}->[$j][$i] = [ $x2, $y2, $x3, $y3 ];
	}
      }

      # now outline it
      $self->{'gd_obj'}->rectangle ($x2, $y2, $x3, $y3, $misccolor);

      # now bootstrap the y values
      $y2 = $y3;
    }
  }


  # and finaly box it off 
  $self->{'gd_obj'}->rectangle ($self->{'curr_x_min'},
  				$self->{'curr_y_min'},
				$self->{'curr_x_max'},
				$self->{'curr_y_max'},
				$misccolor);
  return;
}

## be a good module and return 1
1;
