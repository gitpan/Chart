#>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>#
#  Chart::LinesPoints          #
#                              #
#  written by david bonner     #
#  dbonner@cs.bu.edu           #
#                              #
#  maintained by Chart group   #
#  Chart@wettzell.ifag.de      #
#                              #
#  theft is treason, citizen   #
#<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<#
# History:
#---------
# $RCSfile: LinesPoints.pm,v $ $Revision: 1.2 $ $Date: 2002/05/31 13:18:02 $
# $Author: dassing $
# $Log: LinesPoints.pm,v $
# Revision 1.2  2002/05/31 13:18:02  dassing
# Release 1.1
#
#=====================================================================

package Chart::LinesPoints;

use Chart::Base;
use GD;
use Carp;
use strict;

@Chart::LinesPoints::ISA = qw(Chart::Base);
$Chart::LinesPoints::VERSION = '1.0';


my $DEBUG = 0;

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
  
  # draw the lines
  printf "Limit: y_max: %7.2f, y_min: %7.2f\n",$self->{'curr_y_max'},$self->{'curr_y_min'}  if $DEBUG;
  for $i (1..$self->{'num_datasets'}) {
    # get the color for this dataset, and set the brush
    $color = $self->_color_role_to_index('dataset'.($i-1));
    $brush = $self->_prepare_brush ($color, 'line');
    $self->{'gd_obj'}->setBrush ($brush);

    # draw every line for this dataset
    for $j (1..$self->{'num_datapoints'}) {
      # don't try to draw anything if there's no data
      if (defined ($data->[$i][$j]) and defined ($data->[$i][$j-1])) {
	$x2 = $x1 + ($delta * ($j - 1));
	$x3 = $x1 + ($delta * $j);
	$y2 = $y1 - (($data->[$i][$j-1] - $mod) * $map);
	$y3 = $y1 - (($data->[$i][$j] - $mod) * $map);

	# draw the line
        printf "draw %7.2f,%7.2f --> %7.2f,%7.2f\n",$x2,$y2, $x3,$y3 if $DEBUG;
        if ( $y2 < $self->{'curr_y_min'} && $y3 < $self->{'curr_y_min'} ||
             $y2 > $self->{'curr_y_max'} && $y3 > $self->{'curr_y_max'} ) {
            # the line starts and ends outside the frame
            # do not draw any line
            print  "corrected: no draw\n" if $DEBUG;
            next;
        }
        if ( $y2 < $self->{'curr_y_min'} && $y3 >= $self->{'curr_y_min'} && $y3 <= $self->{'curr_y_max'}) {
           # the line starts outside y top line and ends inside the frame
           my $y4 = $self->{'curr_y_min'};
           my $deltax32 = $x3-$x2;
           my $deltay23 = $y2-$y3;
           if ( $deltay23 != 0 ) {
              my $x4 = -$deltax32/$deltay23*($y4-$y3)+$x3;
              $x2 = $x4;
              $y2 = $y4; 
           }
           printf  "corrected draw %7.2f,%7.2f --> %7.2f,%7.2f\n",$x2,$y2, $x3,$y3 if $DEBUG;
        }
        elsif ( $y3 < $self->{'curr_y_min'} && $y2 <= $self->{'curr_y_max'} && $y2 >= $self->{'curr_y_min'} ) {
           # the line starts inside the frame and ends outside the top y line
           my $y4 = $self->{'curr_y_min'};
           my $deltax32 = $x3-$x2;
           my $deltay32 = $y3-$y2;
           if ( $deltay32 != 0 ) {
              my $x4 =  ($y4-$y2)/$deltay32*$deltax32+$x2;
              $x3 = $x4;
              $y3 = $y4; 
           }
           printf  "corrected draw %7.2f,%7.2f --> %7.2f,%7.2f\n",$x2,$y2, $x3,$y3 if $DEBUG;
        }
        elsif ( $y2 <= $self->{'curr_y_max'} && $y2 >= $self->{'curr_y_min'} && $y3 > $self->{'curr_y_max'} ) {
           # the line starts inside the frame and below the bottom y line
           my $y4 = $self->{'curr_y_max'};
           my $x4 = ($x2-$x3)/$y3*$y2+$x3;
           $x3 = $x4;
           $y3 = $y4;
           printf  "corrected draw %7.2f,%7.2f --> %7.2f,%7.2f\n",$x2,$y2, $x3,$y3 if $DEBUG;
        } 
        elsif ( $y2 > $self->{'curr_y_max'} && $y3 <= $self->{'curr_y_max'} && $y3 >= $self->{'curr_y_min'} ) {
           # the line starts below the bottom y line and ends inside the frame
           my $y4 = $self->{'curr_y_max'};
           my $x4 = ($x2-$x3)/$y2*$y3+$x3;
           $x2 = $x4;
           $y2 = $y4;
           printf  "corrected draw %7.2f,%7.2f --> %7.2f,%7.2f\n",$x2,$y2, $x3,$y3 if $DEBUG;
        }
        elsif ( $y2 > $self->{'curr_y_max'} && $y3 < $self->{'curr_y_min'} ) {
           # the line starts below the bottom y line and ends outside the top y line
           my $y4 = $self->{'curr_y_max'};
           my $y5 = $self->{'curr_y_min'};
           my $x4 = ($y4-$y2)/($y3-$y2)*($x3-$x2)+$x2;   # (x4,y4) --> (x2,y2)
           my $x5 = ($y5-$y2)/($y3-$y2)*($x3-$x2)+$x2;   # (x5,y5) --> (x3,y3)
           $x2 = $x4;
           $y2 = $y4;
           $x3 = $x5;
           $y3 = $y5;
           printf  "corrected draw %7.2f,%7.2f --> %7.2f,%7.2f\n",$x2,$y2, $x3,$y3 if $DEBUG;
        }
        elsif ( $y2 < $self->{'curr_y_min'} && $y3 > $self->{'curr_y_max'} ) {
           # the line starts outside the top y line and ends below the bottom y line
           my $y4 = $self->{'curr_y_min'};
           my $y5 = $self->{'curr_y_max'};
           my $x4 = ($y4-$y2)/($y3-$y2)*($x3-$x2)+$x2;   # (x4,y4) --> (x2,y2)
           my $x5 = ($y5-$y2)/($y3-$y2)*($x3-$x2)+$x2;   # (x5,y5) --> (x3,y3)
           $x2 = $x4;
           $y2 = $y4;
           $x3 = $x5;
           $y3 = $y5;
           printf  "corrected draw %7.2f,%7.2f --> %7.2f,%7.2f\n",$x2,$y2, $x3,$y3 if $DEBUG;
        } 
	$self->{'gd_obj'}->line($x2, $y2, $x3, $y3, gdBrushed);
      }
    }

    # reset the brush for points
    $brush = $self->_prepare_brush ($color, 'point');
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
	# remember the imagemap data if they wanted it
	if ($self->{'imagemap'} =~ /^true$/i) {
	  $self->{'imagemap_data'}->[$i][$j] = [ $x2, $y2 ];
	}
      } else {
	if ($self->{'imagemap'} =~ /^true$/i) {
	  $self->{'imagemap_data'}->[$i][$j] = [ undef(), undef() ];
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
