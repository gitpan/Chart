#============================#
#                            #
#  Chart::Pie		     #
#  written by davidb bonner  #
#  dbonner@cs.bu.edu         #
#                            #
#============================#

package Chart::Pie;

use Chart::Base;
use GD;
use Carp;
use strict;

@Chart::Pie::ISA = qw ( Chart::Base );

#==================#
#  public methods  #
#==================#



#===================#
#  private methods  #
#===================#

sub draw_legend {
    my $obj = shift;
    my $dataref = $obj->{'data'};
    my (@labels, $legend_w, $legend_h, $color);
    my ($w, $h) = (gdSmallFont->width, gdSmallFont->height);
    my $black = $obj->get_color ('black');
    my $max_len = 0;
    my $ref = $obj->find_proportions ($dataref);

    #==========================#
    #  prepare list of labels  #
    #==========================#
    
    @labels = @{$dataref->[0]};

    for (0..$#labels) {
	my $tmp  = sprintf "%.1f", ($dataref->[1][$_] / $obj->{'sum'}) * 100;
	$labels[$_] = "$labels[$_] - $tmp\%";
	my $str_len = length ($labels[$_]);
	if ($str_len > $max_len) {
	    $max_len = $str_len;
	}
    }

    #===============#
    #  draw legend  #
    #===============#

    $legend_h = ($#labels + 1) * ($h + 2 * $obj->{'text_space'});
    $legend_w = ($max_len * $w) + 3 * $obj->{'text_space'};
    $obj->{'x_max'} -= $legend_w + 2 * $obj->{'text_space'};
    
    $obj->{'im'}->rectangle ($obj->{'x_max'} + 2 * $obj->{'text_space'},
			     $obj->{'y_min'},
			     $obj->{'x_max'} + 2 * $obj->{'text_space'} 
			         + $legend_w,
			     $obj->{'y_min'} + $legend_h,
			     $black);
    
    for (0..$#labels) {
	$color = $obj->data_color($_);

	$obj->{'im'}->string (gdSmallFont,
			      $obj->{'x_max'} + 7 
			          + ($max_len - length ($labels[$_])) * $w,
			      $obj->{'y_min'} + $obj->{'text_space'} 
			          + $_ * ($h + 2 * $obj->{'text_space'}),
			      $labels[$_],
			      $color);
    }
    
}

sub draw_data {
    my $obj = shift;
    my $dataref = $obj->{'data'};
    my $black = $obj->get_color ('black');
    my $circle = new GD::Polygon;
    my $poly = new GD::Polygon;
    my $pi = atan2 (1,1) * 4;
    my @labels = @{$dataref->[0]};
    my ($w, $h) = (gdSmallFont->width, gdSmallFont->height); 
    my ($cx, $cy, $r);
    my ($ref, $angle, $tmp);

    if ($#{$dataref} != 1) {
	croak "Only one data set supported for pie graphs";
    }

    ($cx, $cy) = ($obj->{'x_min'} + ($obj->{'x_max'} - $obj->{'x_min'}) / 2,
		  $obj->{'y_min'} + ($obj->{'y_max'} - $obj->{'y_min'}) / 2);
    $r = ($cx - $obj->{'x_min'} > $cy - $obj->{'y_min'})  
	    ? ($obj->{'y_max'} - $obj->{'y_min'}) / 2
	    : ($obj->{'x_max'} - $obj->{'x_min'}) / 2;

    $ref = $obj->find_proportions ($dataref);
    
    for (0..360) {
	$angle = ($_ / 360) * 2 * $pi;
	$circle->addPt ($r * cos ($angle) + $cx, 
			$obj->{'y_max'} + $obj->{'y_min'}
			  - ($r * sin ($angle) + $cy));
    }

    $obj->{'im'}->polygon ($circle, $black);

    $angle = 0;
    for (0..$#{$ref}) {
	$obj->{'im'}->line ($cx, $cy,
			    $r * cos ($angle) + $cx, 
			    $obj->{'y_max'} + $obj->{'y_min'} 
			      - ($r * sin ($angle) + $cy),
			    $black);
	$angle += ($ref->[$_] / $obj->{'sum'}) * 2 * $pi;
    }

    $angle = 0;
    for (0..$#{$ref}) {
	$tmp = ($ref->[$_] / $obj->{'sum'}) * $pi;
	$obj->{'im'}->fillToBorder ($cx + cos ($tmp + $angle) * ($r/2),
				    $obj->{'y_max'} + $obj->{'y_min'} 
				      - ($cy + sin ($tmp + $angle) * ($r/2)),
				    $black,
				    $obj->data_color ($_));
	$obj->{'im'}->string (gdSmallFont,
			      $cx + cos ($tmp + $angle) * ($r/2) 
			        - (length ($labels[$_]) * $w) / 2,
			      $obj->{'y_max'} + $obj->{'y_min'} 
			        - ($cy + sin ($tmp + $angle) * ($r/2) + $h/2),
			      $labels[$_],
			      $black);
	$angle += ($ref->[$_] / $obj->{'sum'}) * 2 * $pi;
    }

    $angle = 0;
    for (0..$#{$ref}) {
	$obj->{'im'}->line ($cx, $cy,
			    $r * cos ($angle) + $cx, 
			    $obj->{'y_max'} + $obj->{'y_min'} 
			      - ($r * sin ($angle) + $cy),
			    $black);
	$angle += ($ref->[$_] / $obj->{'sum'}) * 2 * $pi;
    }
    
    for (0..360) {
	$angle = ($_ / 360) * 2 * $pi;
	$circle->addPt ($r * cos ($angle) + $cx, 
			$obj->{'y_max'} + $obj->{'y_min'}
			- ($r * sin ($angle) + $cy));
    }

    $obj->{'im'}->polygon ($circle, $black);
}

sub find_proportions {
    my $obj = shift;
    my $dataref = $obj->{'data'};
    my $sum = 0;
    my $ref;
    

    for (0..$#{$dataref->[0]}) {
	$ref->[$_] = $dataref->[1][$_];
	$sum += $ref->[$_];
    }
	 
    $obj->{'sum'} = $sum;

    return $ref;
}
    

1;

