#>>>>>>>>>>>>>>>>>>>>>>>>>>>>>#
#  Chart::Points              #
#                             #
#  written by david bonner    #
#  dbonner@cs.bu.edu          #
#                             #
#  maintained by Chart Group  #
#  Chart@wettzell.ifag.de     #
#                             #
#  theft is treason, citizen  #
#<<<<<<<<<<<<<<<<<<<<<<<<<<<<<#
# History:
#---------
# $RCSfile: Points.pm,v $ $Revision: 1.2 $ $Date: 2002/05/31 13:18:02 $
# $Author: dassing $
# $Log: Points.pm,v $
# Revision 1.2  2002/05/31 13:18:02  dassing
# Release 1.1
#
#=====================================================================

package Chart::Points;

use Chart::Base;
use GD;
use Carp;
use strict;

@Chart::Points::ISA = qw(Chart::Base);
$Chart::Points::VERSION = '1.0';

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
  my ($x1, $x2, $x3, $y1, $y2, $y3, $mod);
  my ($width, $height, $delta, $map);
  my ($i, $j, $color, $brush);

  # init the imagemap data field if they want it
  if ($self->{'imagemap'} =~ /^true$/i) {
    $self->{'imagemap_data'} = [];
  }

  # find the delta value between data points, as well
  # as the mapping constant
  $width = $self->{'curr_x_max'} - $self->{'curr_x_min'};
  $height = $self->{'curr_y_max'} - $self->{'curr_y_min'};
  $delta = $width / $self->{'num_datapoints'};
  $map = $height / ($self->{'max_val'} - $self->{'min_val'});

  # get the base x-y values
  $x1 = $self->{'curr_x_min'} + ($delta / 2);
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
  
  # draw the points
  for $i (1..$self->{'num_datasets'}) {
    # get the color for this dataset, and set the brush
    $color = $self->_color_role_to_index('dataset'.($i-1));
    $brush = $self->_prepare_brush ($color);
    $self->{'gd_obj'}->setBrush ($brush);

    # draw every point for this dataset
    for $j (0..$self->{'num_datapoints'}) {
      # don't try to draw anything if there's no data
      if (defined ($data->[$i][$j])) {
	$x2 = $x1 + ($delta * $j);
	$x3 = $x2;
	$y2 = $y1 - (($data->[$i][$j] - $mod) * $map);
	$y3 = $y2;

	# draw the point
        if ( $y2 >= $self->{'curr_y_min'} && $y2 <= $self->{'curr_y_max'} &&
             $y3 >= $self->{'curr_y_min'} && $y3 <= $self->{'curr_y_max'} ) {
	   $self->{'gd_obj'}->line($x2, $y2, $x3, $y3, gdBrushed);
        }
	# store the imagemap data if they asked for it
	if ($self->{'imagemap'} =~ /^true$/i) {
	  $self->{'imagemap_data'}->[$i][$j] = [ $x2, $y2 ];
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


##  set the gdBrush object to have nice circular points
sub _prepare_brush {
  my $self = shift;
  my $color = shift;
  my $radius = $self->{'pt_size'}/2;
  my (@rgb, $brush, $white, $newcolor);

  # get the rgb values for the desired color
  @rgb = $self->{'gd_obj'}->rgb($color);

  # create the new image
  $brush = GD::Image->new ($radius*2, $radius*2);

  # get the colors, make the background transparent
  $white = $brush->colorAllocate (255,255,255);
  $newcolor = $brush->colorAllocate (@rgb);
  $brush->transparent ($white);

  # draw the circle
  $brush->arc ($radius-1, $radius-1, $radius, $radius, 0, 360, $newcolor);

  # and fill it
  $brush->fill ($radius-1, $radius-1, $newcolor);

  # set the new image as the main object's brush
  return $brush;
}

## be a good module and return 1
1;
