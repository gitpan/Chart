#============================#
#                            #
#  Chart::Pareto	     #
#  written by davidb bonner  #
#  dbonner@cs.bu.edu         #
#                            #
#============================#

package Chart::Pareto;

use Chart::Base;
use GD;
use Carp;
use strict;

@Chart::Pareto::ISA = qw ( Chart::Base );
$Chart::Pareto::VERSION = $Chart::Base::VERSION;

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

    #==========================#
    #  prepare list of labels  #
    #==========================#

    if ($obj->{'legend_labels'}) {
	@labels = @{$obj->{'legend_labels'}};
	if ($#labels == 0) {
	    $labels[1] = "Running sum";
	}
	elsif ($#labels != $#{$dataref} - 1) {
	    croak ("Number of data set labels does not match number of data sets");
	}
    }
    else {
	$labels[0] = "Dataset";
	$labels[1] = "Running sum";
	
    }
    
    for (@labels) {
	my $str_len = length ($_);
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
			      $obj->{'x_max'} + 7,
			      $obj->{'y_min'} + $obj->{'text_space'} 
			          + $_ * ($h + 2 * $obj->{'text_space'}),
			      $labels[$_],
			      $color);
    }
    
}

sub find_range {
    my $obj = shift;
    my $dataref = $obj->{'data'};
    my $sum = 0;
    my ($tmp, $i, $j);

    if ($#{$dataref} != 1) {
	croak "Only one data set suported for pareto graphs";
    }

    for $i (0..1) {
	for $j (0..$#{$dataref->[$i]}) {
	    $sum += $dataref->[$i][$j] if ($i == 1);
	}
    }

    $obj->{'sum'} = $sum;

    if (!($obj->{'max_val'})) {    
	$tmp = ($sum) ? 10 ** (int (log ($sum) / log (10))) : 10;
	$sum = $tmp * (int ($sum / $tmp) + 1);
	$obj->{'max_val'} = $sum;
    }
}

sub draw_ticks {
    my $obj = shift;
    my $dataref = $obj->{'data'};
    my $black = $obj->get_color ('black');
    my ($h, $w) = (gdSmallFont->height, gdSmallFont->width);
    my $str_max = 0;
    my $stag = 0;
    my ($y_step, $y_diff, $x_step, $val, $str_len);
    my ($x_min, $x_max, $y, $map, $y_per_step);

    #===========================#
    #  draw the y value labels  #  
    #===========================#

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
	$val = int (($obj->{'max_val'} / $obj->{'y_ticks'}) * $_);
	$str_len = length($val);
	$obj->{'im'}->string (gdSmallFont,
			      $obj->{'x_min'} + ($str_max - $str_len) * $w,
			      $obj->{'y_max'} - $y_step * $_ - $h / 2
			         - $obj->{'tick_len'} - $y_diff,
			      $val,
			      $black);
    }

    $obj->{'x_min'} += ($str_max * $w) + 3 * $obj->{'text_space'};

    #================================#
    #  draw the y percentage labels  #
    #================================#

    $map = ($obj->{'y_max'} - ($obj->{'y_min'} + $y_diff + $obj->{'tick_len'}))
	/ $obj->{'max_val'};
    $y = $obj->{'y_max'} - $map * $obj->{'sum'};
    $y_per_step = ($obj->{'y_max'} - $y) / $obj->{'y_ticks'};


    for (0..$obj->{'y_ticks'}) {
	$val = int (100 * (1 / $obj->{'y_ticks'}) * $_);
	$str_len = length($val) + 1;
	
	if ($str_len > $str_max) {
	    $str_max = $str_len;
	}
    }

    for (0..$obj->{'y_ticks'}) {
	$val = int (100 * (1 / $obj->{'y_ticks'}) * $_);
	$obj->{'im'}->string (gdSmallFont,
			      $obj->{'x_max'} - $str_max * $w,
			      $obj->{'y_max'} - $y_per_step * $_ - $h / 2
			         - $obj->{'tick_len'} - $y_diff,
			      "$val\%",
			      $black);
    }

    $obj->{'x_max'} -= ($str_max * $w) + 3 * $obj->{'text_space'};
    

    #==========================#
    #  draw the x tick labels  #
    #==========================#

    
    if ($obj->{'nocutoff'}) {  #display all the values
	$x_step = (($obj->{'x_max'} - ($obj->{'x_min'} + $obj->{'tick_len'})) 
		   / ($#{$dataref->[0]} + 1));
	($x_min, $x_max) = ($obj->{'x_min'} + $obj->{'tick_len'} + $x_step / 2,
			    $obj->{'x_max'} - $x_step / 2);
	
	for (0..$#{$dataref->[0]}) {
	    $str_len = length ($dataref->[0][$_]);
	    
	    if ($obj->{'stagger_x_labels'}) {
		$y = ($stag++ % 2) ? $obj->{'y_max'} - (2 * $h)
		    : $obj->{'y_max'} - ($h);
	    }
	    else {
		$y = $obj->{'y_max'} - (1.5 * $h);
	    }
	    
	    $obj->{'im'}->string (gdSmallFont,
				  $x_min + $x_step * $_ - ($str_len * $w) / 2,
				  $y,
				  $dataref->[0][$_],
				  $black);
	}
    }
    else {  #group everything after the first $obj->{'cutoff'} values together
	$x_step = (($obj->{'x_max'} - ($obj->{'x_min'} + $obj->{'tick_len'})) 
		   / ($obj->{'cutoff'} + 1));
	($x_min, $x_max) = ($obj->{'x_min'} + $obj->{'tick_len'} + $x_step / 2,
			    $obj->{'x_max'} - $x_step / 2);
	
	for (0..$obj->{'cutoff'}-1) {
	    $str_len = length ($dataref->[0][$_]);
	    
	    if ($obj->{'stagger_x_labels'}) {
		$y = ($stag++ % 2) ? $obj->{'y_max'} - (2 * $h)
		    : $obj->{'y_max'} - ($h);
	    }
	    else {
		$y = $obj->{'y_max'} - (1.5 * $h);
	    }
	    
	    $obj->{'im'}->string (gdSmallFont,
				  $x_min + $x_step * $_ - ($str_len * $w) / 2,
				  $y,
				  $dataref->[0][$_],
				  $black);
	}
    
	if ($obj->{'stagger_x_labels'}) {
	    $y = ($stag++ % 2) ? $obj->{'y_max'} - (2 * $h)
		: $obj->{'y_max'} - ($h);
	}
	else {
	    $y = $obj->{'y_max'} - (1.5 * $h);
	}
	
	$obj->{'im'}->string (gdSmallFont,
			      $x_min + $x_step * $obj->{'cutoff'} 
			      - (5 * $w) / 2,
			      $y,
			      "Other",
			      $black);
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
	$obj->{'im'}->line ($obj->{'x_max'},
			    $obj->{'y_max'} - $obj->{'tick_len'}
			      - $y_per_step * ($obj->{'y_ticks'} - $_),
			    $obj->{'x_max'} - $obj->{'tick_len'},
			    $obj->{'y_max'} - $obj->{'tick_len'}
			      - $y_per_step * ($obj->{'y_ticks'} - $_),
			    $black);
    }

    if ($obj->{'nocutoff'}) {
	for (0..$#{$dataref->[0]}) {
	    $obj->{'im'}->line ($x_min + $x_step * $_,
				$obj->{'y_max'},
				$x_min + $x_step * $_,
				$obj->{'y_max'} - $obj->{'tick_len'},
				$black);
	}
    }
    else {
	for (0..$obj->{'cutoff'}) {
	    $obj->{'im'}->line ($x_min + $x_step * $_,
				$obj->{'y_max'},
				$x_min + $x_step * $_,
				$obj->{'y_max'} - $obj->{'tick_len'},
				$black);
	}
    }
    
    $obj->{'x_min'} += $obj->{'tick_len'};
    $obj->{'x_max'} -= $obj->{'tick_len'};
    $obj->{'y_max'} -= $obj->{'tick_len'};
}


sub draw_data {
    my $obj = shift;
    my $dataref = $obj->{'data'};
    my $black = $obj->get_color ('black');
    my ($x_step, $offset, $ref, @data, $color, @per, $per);
    my ($w, $h) = (gdSmallFont->width, gdSmallFont->height);

    $obj->find_range ($dataref);
    $obj->draw_ticks ($dataref);
    
    #==============#
    #  bars first  #
    #==============#

    $ref = $obj->data_map ($dataref);
    @data = @{$ref};
    $color = $obj->data_color (0);

    if ($obj->{'nocutoff'}) {
	$x_step = ($obj->{'x_max'} - $obj->{'x_min'}) / ($#{$ref} + 1);
    }
    else {
	$x_step = ($obj->{'x_max'} - $obj->{'x_min'}) / ($obj->{'cutoff'} + 1);
    }

    for my $j (0..$#data) {
	$obj->{'im'}->filledRectangle ($obj->{'x_min'} + $x_step * $j,
				       $data[$j],
				       $obj->{'x_min'} + $x_step * ($j+1),
				       $obj->{'y_max'},
				       $color);
	$obj->{'im'}->rectangle ($obj->{'x_min'} + $x_step * $j,
				 $data[$j],
				 $obj->{'x_min'} + $x_step * ($j + 1),
				 $obj->{'y_max'},
				 $black);
    }
    
    
    #=================================#
    #  now calculate the running sum  #
    #=================================#

    undef $ref;
    $ref->[1][0] = $dataref->[1][0];
    $per[0] = $ref->[1][0] / $obj->{'sum'};
    if ($obj->{'nocutoff'}) {
	for (1..$#{$dataref->[0]}) {
	    $ref->[1][$_] = $ref->[1][$_-1] + $dataref->[1][$_];
	    $per[$_] = $ref->[1][$_] / $obj->{'sum'};
	}
    }
    else {
	for (1..$obj->{'cutoff'}) {
	    $ref->[1][$_] = $ref->[1][$_-1] + $dataref->[1][$_];
	    $per[$_] = $ref->[1][$_] / $obj->{'sum'};
	}
	for ($obj->{'cutoff'}+1..$#{$dataref->[1]}) {
	    $ref->[1][$obj->{'cutoff'}] += $dataref->[1][$_];
	}
	$per[$obj->{'cutoff'}] = 1;
    }

    #======================#
    #  and draw the lines  #
    #======================#

    $ref = $obj->data_map ($ref);
        
    $color = $obj->data_color (1);
    @data = @{$ref};

    $per = sprintf ("%d%%", $per[0] * 100);
    $obj->{'im'}->string (gdSmallFont,
			  $x_step + $obj->{'x_min'} - $w * (length ($per) + 1),
			  $data[0] - ($h + $obj->{'pt_size'} / 2),
			  $per,
			  $color);
    $obj->{'im'}->line ($obj->{'x_min'}, 
			$obj->{'y_max'},
			$x_step + $obj->{'x_min'},
			$data[0],
			$color);
    $obj->{'im'}->filledRectangle ($obj->{'x_min'} + $x_step 
				   - ($obj->{'pt_size'} / 2),
				   $data[0] - ($obj->{'pt_size'} / 2),
				   $obj->{'x_min'} + $x_step
				   + ($obj->{'pt_size'} / 2),
				   $data[0] + ($obj->{'pt_size'} / 2),
				   $color);

    for (1..$#data) {
	$per = sprintf ("%d%%", $per[$_] * 100);
	$obj->{'im'}->line (($_) * $x_step + $obj->{'x_min'}, 
			    $data[$_-1],
			    ($_+1) * $x_step + $obj->{'x_min'},
			    $data[$_],
			    $color);
	$obj->{'im'}->filledRectangle (($_+1) * $x_step + $obj->{'x_min'}
				       - ($obj->{'pt_size'} / 2),
				       $data[$_] - ($obj->{'pt_size'} / 2),
				       ($_+1) * $x_step + $obj->{'x_min'}
				       + ($obj->{'pt_size'} / 2),
				       $data[$_] + ($obj->{'pt_size'} / 2),
				       $color);
	$obj->{'im'}->string (gdSmallFont,
			      ($_+1) * $x_step + $obj->{'x_min'} 
			        - $w * (length ($per) + 1),
			      $data[$_] - ($h + $obj->{'pt_size'} / 2),
			      $per,
			      $color) unless ($_ == $#data);
    }

    $obj->draw_axes;
}

sub data_map {
    my $obj = shift;
    my $dataref = shift;
    my ($ref, $map, $i);

    $map = ($obj->{'max_val'})
                ? ($obj->{'y_max'} - $obj->{'y_min'}) / $obj->{'max_val'}
                : ($obj->{'y_max'} - $obj->{'y_min'}) / 10;

    if ($obj->{'nocutoff'}) {
	for $i (0..$#{$dataref->[1]}) {
	    $ref->[$i] = $obj->{'y_max'} - $map * $dataref->[1][$i];
	}
    }
    else {
	for $i (0..$obj->{'cutoff'}-1) {
	    $ref->[$i] = $obj->{'y_max'} - $map * $dataref->[1][$i];
	}
	
	for $i ($obj->{'cutoff'}..$#{$dataref->[1]}) {
	    $ref->[$obj->{'cutoff'}] += $dataref->[1][$i];
	}
	
	$ref->[$obj->{'cutoff'}] = ($obj->{'y_max'} - 
				    ($map * $ref->[$obj->{'cutoff'}]));
    }

    return $ref;
}

1;
