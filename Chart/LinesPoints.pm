#============================#
#                            #
#  Chart::LinesPoints        #
#  written by davidb bonner  #
#  dbonner@cs.bu.edu         #
#                            #
#============================#

package Chart::LinesPoints;

use Chart::Base;
use GD;
use Carp;
use strict;

@Chart::LinesPoints::ISA = qw ( Chart::Base );
$Chart::LinesPoints::VERSION = $Chart::Base::VERSION;

#==================#
#  public methods  #
#==================#



#===================#
#  private methods  #
#===================#

sub find_range {
    my $obj = shift;
    my $dataref = $obj->{'data'};
    my $max = 0;
    my $tmp;
    
    for (1..$#{$dataref}) {
	for my $i (0..$#{$dataref->[$_]}) {
	    if ($dataref->[$_][$i] > $max) {
		$max = $dataref->[$_][$i];
	    }
	}
    }

    $tmp = ($max) ? 10 ** (int (log ($max) / log (10))) : 10;
    $max = $tmp * (int ($max / $tmp) + 1);
    $obj->{'max_val'} = $max;
}

sub draw_ticks {
    my $obj = shift;
    my $dataref = $obj->{'data'};
    my $black = $obj->get_color ('black');
    my ($y_step, $y_diff, $x_step, $val, $str_len);
    my ($h, $w) = (gdSmallFont->height, gdSmallFont->width);
    my $str_max = 0;
    my ($x_min, $x_max);
    my $stag = 0;
    my @ticks;
    
    #===============================#
    #  check for custom tick array  #
    #===============================#

    if ($obj->{'custom_x_ticks'}) {
	@ticks = sort {$Chart::LinesPoints::a <=> $Chart::LinesPoints::b} 
	           @{$obj->{'custom_x_ticks'}};
    }

    #==========================#
    #  draw the y tick labels  #  
    #==========================#

    $y_diff = ($obj->{'stagger_x_labels'}) 
	? 2 * $h + $obj->{'text_space'} 
        : $h + $obj->{'text_space'};
    $y_step = (($obj->{'y_max'} - 
		($obj->{'y_min'} + $obj->{'tick_len'} + $y_diff)) 
	       / $obj->{'y_ticks'});

    for (0..$obj->{'y_ticks'}) {
	$val = int (($obj->{'max_val'} / $obj->{'y_ticks'}) * $_);
	$str_len = length($val);
	
	if ($str_len > $str_max) {
	    $str_max = $str_len;
	}
    }

    
    for (0..$obj->{'y_ticks'}) {
	$val = ($obj->{'max_val'} / $obj->{'y_ticks'}) * $_;
	$str_len = length($val);
	$obj->{'im'}->string (gdSmallFont,
			      $obj->{'x_min'} + ($str_max - $str_len) * $w 
			          + 2 * $obj->{'text_space'},
			      $obj->{'y_max'} - $y_step * $_ - $h / 2
			         - $obj->{'tick_len'} - $y_diff,
			      $val,
			      $black);
    }

    $obj->{'x_min'} += ($str_max * $w) + 3 * $obj->{'text_space'};
    
    #==========================#
    #  draw the x tick labels  #
    #==========================#

    ($x_min, $x_max) = ($obj->{'x_min'} + 10 + $obj->{'tick_len'},
			$obj->{'x_max'} - 10);
    $x_step = ($x_max - $x_min) / $#{$dataref->[0]};
    

    if (@ticks) {  #custom ticks
	for (@ticks) {
	    $val = $dataref->[0][$_];
	    $str_len = length($val) * ($w/2);

	    my $y;
	    if ($obj->{'stagger_x_labels'} eq 'true') {
		$y = ($stag++ % 2) ? $obj->{'y_max'} - (2 * $h)
		    : $obj->{'y_max'} - ($h);
	    }
	    else {
		$y = $obj->{'y_max'} - (1.5 * $h);
	    }
	    
	    $obj->{'im'}->string (gdSmallFont,
				  $x_min - $str_len + ($x_step * $_),
				  $y,
				  $val,
				  $black);
	}
    }
    elsif ($obj->{'skip_x_ticks'}) {  #every n ticks
	for (0..$#{$dataref->[0]}) {
	    $val = $dataref->[0][$_];
	    $str_len = length($val) * ($w/2);
	    if ($_ % $obj->{'skip_x_ticks'} == 0) {
		my $y;
		if ($obj->{'stagger_x_labels'} eq 'true') {
		    $y = ($stag++ % 2) ? $obj->{'y_max'} - (2 * $h)
			: $obj->{'y_max'} - ($h);
		}
		else {
		    $y = $obj->{'y_max'} - (1.5 * $h);
		}
		
		$obj->{'im'}->string (gdSmallFont,
				      $x_min - $str_len + ($x_step * $_),
				      $y,
				      $val,
				      $black);
	    }
	}
    }
    else {  #all the ticks
	for (0..$#{$dataref->[0]}) {
	    $val = $dataref->[0][$_];
	    $str_len = length($val) * ($w/2);

	    my $y;
	    if ($obj->{'stagger_x_labels'} eq 'true') {
		$y = ($stag++ % 2) ? $obj->{'y_max'} - (2 * $h)
		    : $obj->{'y_max'} - ($h);
	    }
	    else {
		$y = $obj->{'y_max'} - (1.5 * $h);
	    }
		

	    $obj->{'im'}->string (gdSmallFont,
				  $x_min - $str_len + ($x_step * $_),
				  $y,
				  $val,
				  $black);
	}
    }

    $obj->{'y_max'} -= ($obj->{'stagger_x_labels'} eq 'true') 
	? 2 * $h + $obj->{'text_space'} 
        : $h + $obj->{'text_space'};

    #==================#
    #  draw the ticks  #
    #==================#

    $obj->{'x_min'} += $obj->{'tick_len'};
    $obj->{'y_max'} -= $obj->{'tick_len'};

    $y_step = ($obj->{'y_max'} - $obj->{'y_min'}) / $obj->{'y_ticks'};
    ($x_min, $x_max) = ($obj->{'x_min'} + 10, $obj->{'x_max'} - 10);
    $x_step = ($x_max - $x_min) / $#{$dataref->[0]};

    if (@ticks) {  #custom ticks
	for (@ticks) {
	    $obj->{'im'}->line ($x_min + ($x_step * $_),
				$obj->{'y_max'},
				$x_min + $x_step * $_,
				$obj->{'y_max'} + $obj->{'tick_len'},
				$black);
	}
    }
    elsif ($obj->{'skip_x_ticks'}) {  #every n ticks
	for (0..$#{$dataref->[0]}) {
	    if ($_ % $obj->{'skip_x_ticks'} == 0) {
		$obj->{'im'}->line ($x_min + ($x_step * $_),
				    $obj->{'y_max'},
				    $x_min + $x_step * $_,
				    $obj->{'y_max'} + $obj->{'tick_len'},
				    $black);
	    }
	}
    }
    else {
	for (0..$#{$dataref->[0]}) {
	    $obj->{'im'}->line ($x_min + ($x_step * $_),
				$obj->{'y_max'},
				$x_min + $x_step * $_,
				$obj->{'y_max'} + $obj->{'tick_len'},
				$black);
	}
    }

    for (0..$obj->{'y_ticks'}-1) {
	$obj->{'im'}->line ($obj->{'x_min'},
			    $obj->{'y_min'} + $y_step * $_,
			    $obj->{'x_min'} - $obj->{'tick_len'},
			    $obj->{'y_min'} + $y_step * $_,
			    $black);
    }
}

sub draw_data {
    my $obj = shift;
    my $dataref = $obj->{'data'};
    my ($x_step, $ref);
    my ($dataset, $color, @data);
    my ($x_min, $x_max);

    if (!($obj->{'max_val'})) { $obj->find_range ($dataref); }
    $obj->draw_ticks ($dataref);

    ($x_min, $x_max) = ($obj->{'x_min'} + 10, $obj->{'x_max'} - 10);
    $x_step = ($x_max - $x_min) / $#{$dataref->[0]};

    $ref = $obj->data_map ($dataref);
    
    for $dataset (0..$#{$ref}) {
	$color = $obj->data_color ($dataset);
	@data = @{$ref->[$dataset]};
	for (0..$#data) {
	    $obj->{'im'}->line (($_-1) * $x_step + $x_min, 
				$data[$_-1],
				$_ * $x_step + $x_min,
				$data[$_],
				$color) unless ($_ == 0);
	    $obj->{'im'}->filledRectangle (($_) * $x_step + $x_min
                                           - ($obj->{'pt_size'} / 2),
                                           $data[$_] - ($obj->{'pt_size'} / 2),
                                           ($_) * $x_step + $x_min
                                           + ($obj->{'pt_size'} / 2),
                                           $data[$_] + ($obj->{'pt_size'} / 2),
                                           $color);
	}
    }

    $obj->draw_axes;
}    

sub data_map {
    my $obj = shift;
    my $dataref = $obj->{'data'};
    my ($ref, $map);
    
    $map = ($obj->{'max_val'})
                ? ($obj->{'y_max'} - $obj->{'y_min'}) / $obj->{'max_val'}
                : ($obj->{'y_max'} - $obj->{'y_min'}) / 10;

    for my $i (1..$#{$dataref}) {
	for my $j (0..$#{$dataref->[$i]}) {
	    $ref->[$i-1][$j] = $obj->{'y_max'} - $map * $dataref->[$i][$j];
	}
    }

    return $ref;
}

1;



