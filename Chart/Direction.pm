#>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>#
#  Chart::Direction              #
#                                #
#  written by Chart Group        #
#                                #
#  maintained by the Chart Group #
#  Chart@wettzell.ifag.de        #
#                                #
#                                #
#<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<#

package Chart::Direction;

use Chart::Base 2.0;
use GD;
use Carp;
use strict;
use POSIX;

@Chart::Direction::ISA = qw(Chart::Base);
$Chart::Direction::VERSION = '2.1';

#>>>>>>>>>>>>>>>>>>>>>>>>>>#
#  public methods go here  #
#<<<<<<<<<<<<<<<<<<<<<<<<<<#



#>>>>>>>>>>>>>>>>>>>>>>>>>>>#
#  private methods go here  #
#<<<<<<<<<<<<<<<<<<<<<<<<<<<#

#we don't need a legend for this type.
sub _draw_legend {

    return 1;
}

# we use the find_y_scale methode to det the labels of the circles and the amount of them
sub _find_y_scale
{
	my $self = shift;

	# Predeclare vars.
	my ($d_min, $d_max);		# Dataset min & max.
	my ($p_min, $p_max);		# Plot min & max.
	my ($tickInterval, $tickCount, $skip);
	my @tickLabels;				# List of labels for each tick.
	my $maxtickLabelLen = 0;	# The length of the longest tick label.

	# Find the datatset minimum and maximum.
	($d_min, $d_max) = $self->_find_y_range();

	# Force the inclusion of zero if the user has requested it.
	if( $self->{'include_zero'} =~ m!^true$!i )
	{
		if( ($d_min * $d_max) > 0 )	# If both are non zero and of the same sign.
		{
			if( $d_min > 0 )	# If the whole scale is positive.
			{
				$d_min = 0;
			}
			else				# The scale is entirely negative.
			{
				$d_max = 0;
			}
		}
	}


	    # Allow the dataset range to be overidden by the user.
	    # f_min/max are booleans which indicate that the min & max should not be modified.
	    my $f_min = defined $self->{'min_val'};
	    $d_min = $self->{'min_val'} if $f_min;

	    my $f_max = defined $self->{'max_val'};
	    $d_max = $self->{'max_val'} if $f_max;

	    # Assert against the min is larger than the max.
	    if( $d_min > $d_max )
	    {
	     croak "The the specified 'min_val' & 'max_val' values are reversed (min > max: $d_min>$d_max)";
	     }

	     # Calculate the width of the dataset. (posibly modified by the user)
	     my $d_width = $d_max - $d_min;

	     # If the width of the range is zero, forcibly widen it
	     # (to avoid division by zero errors elsewhere in the code).
	     if( 0 == $d_width )
	         {
		$d_min--;
		$d_max++;
		$d_width = 2;
	          }

             # Descale the range by converting the dataset width into
             # a floating point exponent & mantisa pair.
             my( $rangeExponent, $rangeMantisa ) = $self->_sepFP( $d_width );
	     my $rangeMuliplier = 10 ** $rangeExponent;

	     # Find what tick
	     # to use & how many ticks to plot,
	     # round the plot min & max to suatable round numbers.
	     ($tickInterval, $tickCount, $p_min, $p_max)
		= $self->_calcTickInterval($d_min/$rangeMuliplier, $d_max/$rangeMuliplier,
				$f_min, $f_max,
				$self->{'min_circles'}+1, $self->{'max_circles'}+1);
	     # Restore the tickInterval etc to the correct scale
	     $_ *= $rangeMuliplier foreach($tickInterval, $p_min, $p_max);

	     #get teh precision for the labels
	     my $precision = $self->{'precision'};

	     # Now sort out an array of tick labels.
	     for( my $labelNum = $p_min; $labelNum<=$p_max; $labelNum+=$tickInterval )
	     {
		my $labelText;

		if( defined $self->{f_y_tick} )
		{
                        # Is _default_f_tick function used?
                        if ( $self->{f_y_tick} == \&Chart::Base::_default_f_tick ) {
			   $labelText = sprintf("%.".$precision."f", $labelNum);
                        } else {         print \&_default_f_tick;
			   $labelText = $self->{f_y_tick}->($labelNum);
                        }
		}
		else
		{
			$labelText = sprintf("%.".$precision."f", $labelNum);
		}
		#print "labelText = $labelText\n";
		push @tickLabels, $labelText;
		$maxtickLabelLen = length $labelText if $maxtickLabelLen < length $labelText;
	     }


	# Store the calculated data.
	$self->{'min_val'} = $p_min;
	$self->{'max_val'} = $p_max;
	$self->{'y_ticks'} = $tickCount;
	$self->{'y_tick_labels'} = \@tickLabels;
	$self->{'y_tick_label_length'} = $maxtickLabelLen;

	# and return.
	return 1;
}

# Calculates the tick  in normalised units.
sub _calcTickInterval
{       my $self = shift;
	my(
		$min, $max,		# The dataset min & max.
		$minF, $maxF,	# Indicates if those min/max are fixed.
		$minTicks, $maxTicks,	# The minimum & maximum number of ticks.
	) = @_;

	# Verify the supplied 'min_y_ticks' & 'max_y_ticks' are sensible.
	if( $minTicks < 2 )
	{
		print STDERR "Chart::Base : Incorrect value for 'min_circles', too small.\n";
		$minTicks = 2;
	}

	if( $maxTicks < 5*$minTicks  )
	{
		print STDERR "Chart::Base : Incorrect value for 'max_circles', too small.\n";
		$maxTicks = 5*$minTicks;
	}

	my $width = $max - $min;
	my @divisorList;

	for( my $baseMul = 1; ; $baseMul *= 10 )
	{
		TRY: foreach my $tryMul (1, 2, 5)
		{
			# Calc a fresh, smaller tick interval.
			my $divisor = $baseMul * $tryMul;

			# Count the number of ticks.
			my ($tickCount, $pMin, $pMax) = $self->_countTicks($min, $max, 1/$divisor);

			# Look a the number of ticks.
			if( $maxTicks < $tickCount )
			{
				# If it is to high, Backtrack.
				$divisor = pop @divisorList;
                                # just for security:
                                if ( !defined($divisor) || $divisor == 0 ) { $divisor = 1; }
				($tickCount, $pMin, $pMax) = $self->_countTicks($min, $max, 1/$divisor);
				print "\nChart::Base : Caution: Tick limit of $maxTicks exceeded. Backing of to an interval of ".1/$divisor." which plots $tickCount ticks\n";
				return(1/$divisor, $tickCount, $pMin, $pMax);
			}
			elsif( $minTicks > $tickCount )
			{
				# If it is to low, try again.
				next TRY;
			}
			else
			{
				# Store the divisor for possible later backtracking.
				push @divisorList, $divisor;

				# if the min or max is fixed, check they will fit in the interval.
				next TRY if( $minF && ( int ($min*$divisor) != ($min*$divisor) ) );
				next TRY if( $maxF && ( int ($max*$divisor) != ($max*$divisor) ) );

				# If everything passes the tests, return.
				return(1/$divisor, $tickCount, $pMin, $pMax)
			}
		}
	}
	die "can't happen!";
}

#this is where we draw the circles and the axes
sub _draw_y_ticks {
  my $self = shift;
  my $data = $self->{'dataref'};
  my $misccolor = $self->_color_role_to_index('misc');
  my $textcolor = $self->_color_role_to_index('text');
  my $background = $self->_color_role_to_index('background');
  my @labels = @{$self->{'y_tick_labels'}};
  my ($width, $height, $centerX, $centerY, $diameter);
  my ($pi, $font, $fontW, $fontH, $labelX, $labelY, $label_offset);
  my ($dia_delta, $dia, $x, $y, @label_degrees, $arc, $angle_interval);

  # set up initial constant values
  $pi = 3.14159265358979323846;
  $font = $self->{'legend_font'};
  $fontW = $self->{'legend_font'}->width;
  $fontH = $self->{'legend_font'}->height;
  $angle_interval = $self->{'angle_interval'};

  if ($self->{'grey_background'} =~ /^true$/i) {
      $background = $self->_color_role_to_index('grey_background');
  }
  # init the imagemap data field if they wanted it
  if ($self->{'imagemap'} =~ /^true$/i) {
    $self->{'imagemap_data'} = [];
  }

  # find width and height
  $width = $self->{'curr_x_max'} - $self->{'curr_x_min'};
  $height = $self->{'curr_y_max'} - $self->{'curr_y_min'};

  # find center point, from which the pie will be drawn around
  $centerX = int($width/2  + $self->{'curr_x_min'});
  $centerY = int($height/2 + $self->{'curr_y_min'});

  # always draw a circle, which means the diameter will be the smaller
  # of the width and height. let enougth space for the label.
  if ($width < $height) {
   $diameter = $width -110;
  }
  else {
    $diameter = $height -80 ;
  }

  #the difference between the diameter of two following circles;
  $dia_delta = ceil($diameter / ($self->{'y_ticks'}-1));

  #store the calculated data
  $self->{'centerX'} = $centerX;
  $self->{'centerY'} = $centerY;
  $self->{'diameter'} = $diameter;

  #draw the axes and its labels
  # set up an array of labels for the axes
  if ($angle_interval == 0) {
     @label_degrees = ( );
  }
  elsif ($angle_interval <= 5 && $angle_interval > 0) {
     @label_degrees = qw(180 175 170 165 160 155 150 145 140 135 130 125 120 115
     110 105 100 95 90 85 80 75 70 65 60 55 50 45 40 35 30 25 20 15 10 5 0 355 350
     345 340 335 330 325 320 315 310 305 300 295 290 285 280 275 270 265 260 255
     250 245 240 235 230 225 220 215 210 205 200 195 190 185);
     $angle_interval = 5;
  }
  elsif ($angle_interval <= 10 && $angle_interval > 5) {
     @label_degrees = qw(180 170 160 150 140 130 120 110 100 90 80 70 60 50 40
     30 20 10 0 350 340 330 320 310 300 290 280 270 260 250 240 230 220 210 200 190);
     $angle_interval = 10;
  }
  elsif ($angle_interval <= 15 && $angle_interval > 10) {
     @label_degrees = qw(180 165 150 135 120 105 90 75 60 45 30 15 0 345 330 315 300
     285 270 255 240 225 210 195);
     $angle_interval = 15;
  }
  elsif ($angle_interval <=20 && $angle_interval > 15) {
     @label_degrees = qw(180 160 140 120 100 80 60 40 20 0 340 320 300 280 260 240
     220 200);
     $angle_interval = 20;
  }
  elsif ($angle_interval <= 30 && $angle_interval > 20) {
     @label_degrees = qw(180 150 120 90 60 30 0 330 300 270 240 210);
     $angle_interval = 30;
  }
  elsif ($angle_interval <= 45 && $angle_interval > 30) {
     @label_degrees = qw(180 135 90 45 0 315 270 225);
     $angle_interval = 45;
  }
  elsif ($angle_interval <= 90 && $angle_interval > 45) {
     @label_degrees = qw(180 90 0 270);
     $angle_interval = 90;
  }
  else {
     carp "The angle_interval must be between 0 and 90!\nCorrected value: 30";
     @label_degrees = qw(180 150 120 90 60 30 0 330 300 270 240 210);
     $angle_interval = 30;
  }
  $arc = 0;
  foreach (@label_degrees)    {
      #calculated the coordinates of the end point of the line
      $x = sin ($arc)*($diameter/2+10) + $centerX;
      $y = cos  ($arc)*($diameter/2+10) + $centerY;
      #some ugly correcture
      if ($_ == '270') { $y++;}
      #draw the line
      $self->{'gd_obj'}->line($centerX, $centerY, $x, $y, $misccolor);
      #calculate the string point
      $x = sin ($arc)*($diameter/2+30) + $centerX-8;
      $y = cos  ($arc)*($diameter/2+28) + $centerY-6;
      #draw the labels
      $self->{'gd_obj'}->string($font, $x, $y, $_.'°', $textcolor);
      $arc += (($angle_interval)/360) *2*$pi;
  }
      
  #draw the circles
  $dia = 0;
  foreach (@labels) {
      $self->{'gd_obj'}->arc($centerX,$centerY,
                    $dia, $dia,
                    0, 360,
                    $misccolor);
      $dia += $dia_delta;
  }
  
  $self->{'gd_obj'}->filledRectangle($centerX-length($labels[0])/2*$fontW-2,
                                     $centerY+2,
                                     $centerX+2+$diameter/2,
                                     $centerY+$fontH+2,
                                     $background);
  #draw the labels of the circles
  $dia = 0;
  foreach (@labels) {
       $self->{'gd_obj'}->string($font, $centerX+$dia/2-length($_)/2*$fontW,
                                 $centerY+2, $_, $textcolor);
       $dia += $dia_delta;
  }
       
  

  return;
}

#We don't need x ticks, it's all done in _draw_y_ticks
sub _draw_x_ticks {
  my $self = shift;

  return;
}


## finally get around to plotting the data
sub _draw_data {
  my $self = shift;
  my $data = $self->{'dataref'};
  my $misccolor = $self->_color_role_to_index('misc');
  my $textcolor = $self->_color_role_to_index('text');
  my $background = $self->_color_role_to_index('background');
  my ($width, $height, $centerX, $centerY, $diameter);
  my ($mod, $map, $i, $brush, $color, $x, $y, $winkel, $first_x, $first_y );
  my ($arrow_x, $arrow_y, $m);

  my $pi = 3.14159265358979323846;
  my $len = 10;
  my $alpha = 1;
  my $last_x = undef;
  my $last_y = undef;

  # init the imagemap data field if they wanted it
  if ($self->{'imagemap'} =~ /^true$/i) {
    $self->{'imagemap_data'} = [];
  }

  # find width and height
  $width = $self->{'curr_x_max'} - $self->{'curr_x_min'};
  $height = $self->{'curr_y_max'} - $self->{'curr_y_min'};
  
  # get the base values
  #if ($self->{'min_val'} >= 0) {
      $mod = $self->{'min_val'};
  #}
  $centerX = $self->{'centerX'};
  $centerY = $self->{'centerY'};
  $diameter = $self->{'diameter'};
  $map = $diameter/2/($self->{'max_val'} - $self->{'min_val'});
  

  $color = $self->_color_role_to_index('dataset0');
  $brush = $self->_prepare_brush ($color, 'point');
  $self->{'gd_obj'}->setBrush ($brush);

  # draw every line for this dataset
  for $i (0..$self->{'num_datapoints'}) {
      # don't try to draw anything if there's no data
      if (defined ($data->[1][$i]) && $data->[1][$i] <= $self->{'max_val'}
          &&  $data->[1][$i] >= $self->{'min_val'}) {
        #calculate the point
        $winkel = (180 - ($data->[0][$i] % 360)) /360 * 2*$pi;
        $x = ceil($centerX + sin ($winkel) * ($data->[1][$i] - $mod) * $map);
        $y = ceil($centerY + cos ($winkel) * ($data->[1][$i] - $mod) * $map);

        if ($self->{'point'} =~ /^true$/i) {
          $brush = $self->_prepare_brush ($color, 'point');
          $self->{'gd_obj'}->setBrush ($brush);
          #draw the point
          $self->{'gd_obj'}->line($x+1, $y, $x, $y, gdBrushed);
        }
        if ($self->{'line'} =~ /^true$/i) {
          $brush = $self->_prepare_brush ($color, 'line');
          $self->{'gd_obj'}->setBrush ($brush);
          #draw the line
          if (defined $last_x) {
             $self->{'gd_obj'}->line($x, $y, $last_x, $last_y, gdBrushed);
          }
          else {
             $first_x = $x;
             $first_y = $y;
          }
 #         #draw the last line to the first point
 #         if ($i == $self->{'num_datapoints'}-1 )   {
 #            $self->{'gd_obj'}->line($x, $y, $first_x, $first_y, gdBrushed);
 #         }
        }
        if ($self->{'arrow'} =~ /^true$/i) {
          $brush = $self->_prepare_brush ($color, 'line');
          $self->{'gd_obj'}->setBrush ($brush);
          #draw the arrow
          if ($data->[1][$i] > $self->{'min_val'}) {
            $self->{'gd_obj'}->line($x, $y, $centerX, $centerY, gdBrushed);

            $arrow_x =  $x - cos($winkel-$alpha )*$len;
            $arrow_y = $y + sin($winkel-$alpha)*$len;
            $self->{'gd_obj'}->line($x, $y, $arrow_x, $arrow_y, gdBrushed);

            $arrow_x = $x + sin($pi/2-$winkel-$alpha )*$len;
            $arrow_y = $y - cos($pi/2-$winkel-$alpha)*$len;
            $self->{'gd_obj'}->line($x, $y, $arrow_x, $arrow_y, gdBrushed);

            
          }
        }

        $last_x = $x;
        $last_y = $y;
        
        
	# store the imagemap data if they asked for it
	if ($self->{'imagemap'} =~ /^true$/i) {
	  $self->{'imagemap_data'}->[1][$i] = [$x, $y ];
 	}
      } else {
	if ($self->{'imagemap'} =~ /^true$/i) {
	  $self->{'imagemap_data'}->[1][$i] = [ undef(), undef() ];

        }
      }
    }
    #draw the last line to the first point
    if ($self->{'line'} =~ /^true$/i) {
      $self->{'gd_obj'}->line($x, $y, $first_x, $first_y, gdBrushed);
    }
  
   $self->{'gd_obj'}->rectangle ($self->{'curr_x_min'},
                                $self->{'curr_y_min'},
                                $self->{'curr_x_max'},
                                $self->{'curr_y_max'},
                                $misccolor);

  return;

}


##  set the gdBrush object to trick GD into drawing fat lines
sub _prepare_brush {
  my $self = shift;
  my $color = shift;
  my $type = shift;
  my ($radius, @rgb, $brush, $white, $newcolor);

  # get the rgb values for the desired color
  @rgb = $self->{'gd_obj'}->rgb($color);

  # get the appropriate brush size
  if ($type eq 'line') {
    $radius = $self->{'brush_size'}/2;
  }
  elsif ($type eq 'point') {
    $radius = $self->{'pt_size'}/2;
  }

  # create the new image
  $brush = GD::Image->new ($radius*2, $radius*2);

  # get the colors, make the background transparent
  $white = $brush->colorAllocate (255,255,255);
  $newcolor = $brush->colorAllocate (@rgb);
  $brush->transparent ($white);

  # draw the circle
  $brush->arc ($radius-1, $radius-1, $radius, $radius, 0, 360, $newcolor);

  # fill it if we're using lines
  $brush->fill ($radius-1, $radius-1, $newcolor);

  # set the new image as the main object's brush
  return $brush;
}


## be a good module and return 1
1;
