#============================#
#                            #
#  Chart::Bars               #
#  written by davidb bonner  #
#  dbonner@cs.bu.edu         #
#                            #
#============================#

package Chart::Bars;

use Chart::Base;
use GD;
use Carp;
use strict;

@Chart::Bars::ISA = qw ( Chart::Base );

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
    my ($tmp, $i);
    
    for (1..$#{$dataref}) {
	for $i (0..$#{$dataref->[$_]}) {
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
    my $grey = $obj->get_color ('grey');
    my ($h, $w) = (gdSmallFont->height, gdSmallFont->width);
    my $str_max = 0;
    my $stag = 0;
    my ($y_step, $y_diff, $x_step, $val, $str_len);
    my ($x_min, $x_max, @dec);
    my @ticks;
    
    #===============================#
    #  check for custom tick array  #
    #===============================#

    if ($obj->{'custom_x_ticks'}) {
	@ticks = sort {$Chart::Bars::a <=> $Chart::Bars::b} 
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
	$val = (($obj->{'max_val'} / $obj->{'y_ticks'}) * $_);
        @dec = split /\./, $val;
        if ($dec[1] && length($dec[1]) > 3) { $val = sprintf ("%.3f", $val) }
	$str_len = length($val);
	
	if ($str_len > $str_max) {
	    $str_max = $str_len;
	}
    }

    
    for (0..$obj->{'y_ticks'}) {
	$val = (($obj->{'max_val'} / $obj->{'y_ticks'}) * $_);
        @dec = split /\./, $val;
        if ($dec[1] && length($dec[1]) > 3) { $val = sprintf ("%.3f", $val) }
	$str_len = length($val);
	$obj->{'im'}->string (gdSmallFont,
			      $obj->{'x_min'} + ($str_max - $str_len) * $w,
			      $obj->{'y_max'} - $y_step * $_ - $h / 2
			         - $obj->{'tick_len'} - $y_diff,
			      $val,
			      $black);
    }

    $obj->{'x_min'} += ($str_max * $w) + 3 * $obj->{'text_space'};

    #==========================#
    #  draw the x tick labels  #
    #==========================#

    $x_step = (($obj->{'x_max'} - ($obj->{'x_min'} + $obj->{'tick_len'})) 
	       / ($#{$dataref->[0]} + 1));
    ($x_min, $x_max) = ($obj->{'x_min'} + $obj->{'tick_len'} + $x_step / 2,
			$obj->{'x_max'} - $x_step / 2);

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
				  $x_min + $x_step * $_ - $str_len,
				  $y,
				  $dataref->[0][$_],
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
				  $x_min + $x_step * $_ - $str_len,
				  $y,
				  $dataref->[0][$_],
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
				  $x_min + ($x_step * $_) - $str_len,
				  $y,
				  $val,
				  $black);
	}
    }
    
    $obj->{'y_max'} -= ($obj->{'stagger_x_labels'}) 
	? 2 * $h + $obj->{'text_space'} 
        : $h + $obj->{'text_space'};

    #======================#
    #  now draw the ticks  #
    #======================#

    for (0..$obj->{'y_ticks'}-1) {
	$obj->{'im'}->line ($obj->{'x_min'} + 2 * $obj->{'text_space'},
			    $obj->{'y_min'} + $y_step * $_,
			    $obj->{'x_min'} - $obj->{'tick_len'} 
			        + 2 * $obj->{'text_space'},
			    $obj->{'y_min'} + $y_step * $_,
			    $black);
	if ($obj->{'grid_lines'} && $obj->{'grid_lines'} eq 'true') {
	    $obj->{'im'}->line ($obj->{'x_min'} + 2 * $obj->{'text_space'},
	                        $obj->{'y_min'} + $y_step * $_,
				$obj->{'x_max'},
				$obj->{'y_min'} + $y_step * $_,
				$grey);
	}
    }

    if (@ticks) {  #custom ticks
	for (@ticks) {
	    $obj->{'im'}->line ($x_min + ($x_step * $_),
				$obj->{'y_max'},
				$x_min + $x_step * $_,
				$obj->{'y_max'} - $obj->{'tick_len'},
				$black);
	    if ($obj->{'grid_lines'} && $obj->{'grid_lines'} eq 'true') {
		$obj->{'im'}->line ($x_min + ($x_step * $_),
		                    $obj->{'y_max'} - $obj->{'tick_len'},
				    $x_min + $x_step * $_,
				    $obj->{'y_min'},
				    $grey);
	    }
	}
    }
    elsif ($obj->{'skip_x_ticks'}) {  #every n ticks
	for (0..$#{$dataref->[0]}) {
	    if ($_ % $obj->{'skip_x_ticks'} == 0) {
		$obj->{'im'}->line ($x_min + ($x_step * $_),
				    $obj->{'y_max'},
				    $x_min + $x_step * $_,
				    $obj->{'y_max'} - $obj->{'tick_len'},
				    $black);
	        if ($obj->{'grid_lines'} && $obj->{'grid_lines'} eq 'true') {
                    $obj->{'im'}->line ($x_min + ($x_step * $_),
                                        $obj->{'y_max'} - $obj->{'tick_len'},
                                        $x_min + $x_step * $_,
                                        $obj->{'y_min'},
                                        $grey);
                }	
	    }
	}
    }
    else {
	for (0..$#{$dataref->[0]}) {
	    $obj->{'im'}->line ($x_min + ($x_step * $_),
				$obj->{'y_max'},
				$x_min + $x_step * $_,
				$obj->{'y_max'} - $obj->{'tick_len'},
				$black);
            if ($obj->{'grid_lines'} && $obj->{'grid_lines'} eq 'true') {
                $obj->{'im'}->line ($x_min + ($x_step * $_),
                                    $obj->{'y_max'} - $obj->{'tick_len'},
                                    $x_min + $x_step * $_,
                                    $obj->{'y_min'},
                                    $grey);
            }
	}
    }

    $obj->{'x_min'} += $obj->{'tick_len'};
    $obj->{'y_max'} -= $obj->{'tick_len'};
}

sub draw_data {
    my $obj = shift;
    my $dataref = $obj->{'data'};
    my $black = $obj->get_color ('black');
    my ($x_step, $offset, $ref, @data, $color, $i, $j);

    if (!($obj->{'max_val'})) { $obj->find_range ($dataref); }
    $obj->draw_ticks ($dataref);
    
    $x_step = ($obj->{'x_max'} - $obj->{'x_min'}) / ($#{$dataref->[0]} + 1);
    $offset = $x_step / $#{$dataref};
    $ref = $obj->data_map ($dataref);

    for $i (0..$#{$ref}) {
	$color = $obj->data_color ($i);
	@data = @{$ref->[$i]};
	for $j (0..$#data) {
	    $obj->{'im'}->filledRectangle ($obj->{'x_min'} + $i * $offset
					       + $x_step * $j,
					   $data[$j],
					   $obj->{'x_min'} + ($i + 1) * $offset
					       + $x_step * $j,
					   $obj->{'y_max'},
					   $color) if defined ($data[$j]);
	    $obj->{'im'}->rectangle ($obj->{'x_min'} + $i * $offset 
				         + $x_step * $j,
				     $data[$j],
				     $obj->{'x_min'} + ($i + 1) * $offset
				         + $x_step * $j,
				     $obj->{'y_max'},
				     $black) if defined ($data[$j]);
	}
    }

    $obj->draw_axes;
}

sub data_map {
    my $obj = shift;
    my $dataref = $obj->{'data'};
    my ($ref, $map, $i, $j);
    
    $map = ($obj->{'max_val'})
                ? ($obj->{'y_max'} - $obj->{'y_min'}) / $obj->{'max_val'}
                : ($obj->{'y_max'} - $obj->{'y_min'}) / 10;

    for $i (1..$#{$dataref}) {
	for $j (0..$#{$dataref->[$i]}) {
	    $ref->[$i-1][$j] = (defined ($dataref->[$i][$j]))
	    			? $obj->{'y_max'} - $map * $dataref->[$i][$j]
				: undef;
	}
    }

    return $ref;
}

1;
