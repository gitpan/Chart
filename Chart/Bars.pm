#>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>#
#  Chart::Bars                   #
#                                #
#  written by david bonner       #
#  dbonner@cs.bu.edu             #
#                                #
#  maintained by the Chart Group #
#  Chart@wettzell.ifag.de        #
#                                #
#                                #
#  theft is treason, citizen     #
#<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<#

package Chart::Bars;

use Chart::Base 2.0;
use GD;
use Carp;
use strict;

@Chart::Bars::ISA = qw(Chart::Base);
$Chart::Bars::VERSION = '2.1';

#>>>>>>>>>>>>>>>>>>>>>>>>>>#
#  public methods go here  #
#<<<<<<<<<<<<<<<<<<<<<<<<<<#



#>>>>>>>>>>>>>>>>>>>>>>>>>>>#
#  private methods go here  #
#<<<<<<<<<<<<<<<<<<<<<<<<<<<#

## finally get around to plotting the data
sub _draw_data {
  my $self = shift;
  my $data = $self->{'dataref'};
  my $misccolor = $self->_color_role_to_index('misc');
  my ($x1, $x2, $x3, $y1, $y2, $y3);
  my ($width, $height, $delta1, $delta2, $map, $mod, $cut, $pink);
  my ($i, $j, $color);

  # init the imagemap data field if they wanted it
  if ($self->{'imagemap'} =~ /^true$/i) {
    $self->{'imagemap_data'} = [];
  }

  # find both delta values ($delta1 for stepping between different
  # datapoint names, $delta2 for setpping between datasets for that
  # point) and the mapping constant
  $width = $self->{'curr_x_max'} - $self->{'curr_x_min'};
  $height = $self->{'curr_y_max'} - $self->{'curr_y_min'};
  $delta1 = $width / $self->{'num_datapoints'};
  $map = $height / ($self->{'max_val'} - $self->{'min_val'});
  if ($self->{'spaced_bars'} =~ /^true$/i) {
    $delta2 = $delta1 / ($self->{'num_datasets'} + 2);
  }
  else {
    $delta2 = $delta1 / $self->{'num_datasets'};
  }

  # get the base x-y values
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
  
  # draw the bars
  for $i (1..$self->{'num_datasets'}) {
    # get the color for this dataset
    $color = $self->_color_role_to_index('dataset'.($i-1));

    # draw every bar for this dataset
    for $j (0..$self->{'num_datapoints'}) {
      # don't try to draw anything if there's no data
      if (defined ($data->[$i][$j])) {
	# find the bounds of the rectangle
        if ($self->{'spaced_bars'} =~ /^true$/i) {
          $x2 = $x1 + ($j * $delta1) + ($i * $delta2);
	}
	else {
	  $x2 = $x1 + ($j * $delta1) + (($i - 1) * $delta2);
	}
	$y2 = $y1;
	$x3 = $x2 + $delta2;
	$y3 = $y1 - (($data->[$i][$j] - $mod) * $map);

        #cut the bars off, if needed
        if ($data->[$i][$j] > $self->{'max_val'}) {
           $y3 = $y1 - (($self->{'max_val'} - $mod ) * $map) ;
           $cut = 1;
        }
        elsif  ($data->[$i][$j] < $self->{'min_val'}) {
           $y3 = $y1 - (($self->{'min_val'} - $mod ) * $map) ;
           $cut = 1;
        }
        else {
           #$y3 = $y1 + (($data->[$i][$j] - $mod) * $map);
           $cut = 0;
        }
        
	# draw the bar
	## y2 and y3 are reversed in some cases because GD's fill
	## algorithm is lame
	if ($data->[$i][$j] > 0) {
	  $self->{'gd_obj'}->filledRectangle ($x2, $y3, $x3, $y2, $color);
	  if ($self->{'imagemap'} =~ /^true$/i) {
	    $self->{'imagemap_data'}->[$i][$j] = [$x2, $y3, $x3, $y2];
	  }
	}
	else {
	  $self->{'gd_obj'}->filledRectangle ($x2, $y2, $x3, $y3, $color);
	  if ($self->{'imagemap'} =~ /^true$/i) {
	    $self->{'imagemap_data'}->[$i][$j] = [$x2, $y2, $x3, $y3];
	  }
	}

        # now outline it. outline red if the bar had been cut off
        unless ($cut){
	  $self->{'gd_obj'}->rectangle ($x2, $y3, $x3, $y2, $misccolor);
        }
        else {
          $pink = $self->{'gd_obj'}->colorAllocate(255,0,255);
          $self->{'gd_obj'}->rectangle ($x2, $y3, $x3, $y2, $pink);
        }

       } else {
	  if ($self->{'imagemap'} =~ /^true$/i) {
            $self->{'imagemap_data'}->[$i][$j] = [undef(), undef(), undef(), undef()];
          }
      }
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
