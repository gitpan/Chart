#===========================#
#                           #
#  Chart::Base              #
#  written by david bonner  #
#  dbonner@cs.bu.edu        #
#                           #
#===========================#


package Chart::Base;

use Carp;
use GD;
use strict;


#==================#
#  public methods  #
#==================#

sub new {
    my $class = shift;
    my $self = {};
    
    bless $self, $class;
    $self->my_init (@_);

    return $self;
}

sub set {
    my $obj = shift;
    my %hash = @_;

    for (keys (%hash)) {
	    $obj->{$_} = $hash{$_};
    }
}

sub add_pt {
    my $obj = shift;
    my @data = @_;   
    my $i = 0;
 
    if ($obj->{'data'} && $#_ != $#{$obj->{'data'}}) {
	carp ("New points must have a value for each dataset");
	return undef;
    }
    else {
	for $i (0..$#data) {
	    push @{$obj->{'data'}->[$i]}, $data[$i];
	}
	return 1;
    }
}

sub add_dataset {
    my $obj = shift;
    my ($set, $i);
    
    if ($obj->{'data'} && $#_ != $#{$obj->{'data'}->[0]}) {
	carp ("New datasets must have as many points as the current ones");
	return undef;
    }
    else {
	$set = $#{$obj->{'data'}} + 1;
	for $i (0..$#_) {
	    push @{$obj->{'data'}->[$set]}, $_[$i];
	}
	return 1;
    }
}

sub clear_data {
    my $obj = shift;
    
    undef $obj->{'data'};
}

sub get_data {
    my $obj = shift;
    
    return $obj->{'data'};
}

sub gif {
    my $obj = shift;
    my $file = shift;
    my $dataref = shift;
    my $prev_data;
    
    $prev_data = $obj->copy_data ($dataref);
    if ($prev_data == 1) {
	if ($#{$dataref} < 1) {
	    croak "Chart::* needs an array of labels and at least one array of data";
	}
	if ($#{$dataref->[0]} == 0) {
	    croak "There aren't any data points!";
	}
    }
	
    $obj->my_plot;
    
    open (GIF, ">$file") or croak ("Couldn\'t open $file:  $!");
    print GIF $obj->{'im'}->gif;
    close GIF;
}

sub cgi_gif {
    my $obj = shift;
    my $dataref = shift;
    my $prev_data;
    
    $prev_data = $obj->copy_data ($dataref);
    if ($prev_data == 1) {
	if ($#{$dataref} < 1) {
	    croak "Chart::* needs an array of labels and at least one array of data";
	}
	if ($#{$dataref->[0]} == 0) {
	    croak "There aren't any data points!";
	}
    }
    
    $obj->my_plot;
    
    print "Content-type: image/gif\n\n";
    print $obj->{'im'}->gif;
}

#===================#
#  private methods  #
#===================#

sub my_init {
    my $self = shift;
    
    #  gimme that image  
    if ($#_ == 1) {
	$self->{'im'} = new GD::Image($_[0], $_[1]);
	$self->{'x_min'} = 0;
	$self->{'x_max'} = $_[0];
	$self->{'y_min'} = 0;
	$self->{'y_max'} = $_[1];
    }
    else {
	$self->{'im'} = new GD::Image(400,300);
	$self->{'x_min'} = 0;
	$self->{'x_max'} = 400;
	$self->{'y_min'} = 0;
	$self->{'y_max'} = 300;
    }
    

    #  allocate some colors
    $self->set_colors;

    #  set the image to be interlaced
    $self->{'im'}->interlaced('true');

    #  tick length of 4 pixels
    $self->{'tick_len'} = 4;

    #  gimme 5 y ticks
    $self->{'y_ticks'} = 5;

    #  show me the legend
    $self->{'legend'} = 'true';

    #  stagger those x-tick labels
    $self->{'stagger_x_labels'} = 'true';

    #  set the pareto cutoff to be 5
    $self->{'cutoff'} = 5;

    #  set the point size to a 5 pixel square
    $self->{'pt_size'} = 4;

    #  give me a 10 pixel border around the whole thing
    $self->{'gif_border'} = 10;

    #  give me a 10 pixel border between the labels and the graph
    $self->{'graph_border'} = 10;

    #  a little space for the text
    $self->{'text_space'} = 2;

    #  pesky pareto graph needs to default sort
    $self->{'sort'} = ['desc', 1, 'num'] if (ref ($self) eq 'Chart::Pareto');
}

sub set_colors {
    my $self = shift;

    $self->{'im'}->colorAllocate (250, 250, 250);
    $self->{'im'}->colorAllocate (0, 0, 0);
    $self->{'im'}->colorAllocate (225, 0, 0);
    $self->{'im'}->colorAllocate (0, 225, 0);
    $self->{'im'}->colorAllocate (0, 0, 225);
    $self->{'im'}->colorAllocate (200, 0, 200);
    $self->{'im'}->colorAllocate (0, 200, 200);
    $self->{'im'}->colorAllocate (225, 225, 0);
    $self->{'im'}->colorAllocate (250, 170, 85);
    $self->{'im'}->colorAllocate (200,200,200);
}

sub copy_data {
    my $obj = shift;
    my $their_ref = shift;
    my $my_ref = [];
    my ($i, $j);

    if ($obj->{'data'}) {
	return -1;
    }
    else {
	for $i (0..$#{$their_ref}) {
	    for $j (0..$#{$their_ref->[$i]}) {
		$my_ref->[$i][$j] = $their_ref->[$i][$j];
	    }
	}
	$obj->{'data'} = $my_ref;
	return 1;
    }
}

sub my_plot {
    my $obj = shift;
    my $dataref = $obj->{'data'};

    if ($obj->{'colors'}) { $obj->set_user_colors }
    if ($obj->{'transparent'} && $obj->{'transparent'} eq 'true') { 
	my $white = $obj->get_color ('white');
	$obj->{'im'}->transparent ($white);
    }
    
    $obj->{'x_min'} += $obj->{'gif_border'};
    $obj->{'y_min'} += $obj->{'gif_border'};
    $obj->{'x_max'} -= $obj->{'gif_border'};
    $obj->{'y_max'} -= $obj->{'gif_border'};

    $obj->check_data; 

    if ($obj->{'title'}) { $obj->draw_title; }
    if ($obj->{'sub_title'}) { $obj->draw_sub_title; }
    if ($obj->{'legend'} eq 'true') { $obj->draw_legend ($dataref) }
    if ($obj->{'x_label'} or $obj->{'y_label'}) { $obj->draw_labels; }

    $obj->{'x_min'} += $obj->{'graph_border'};
    $obj->{'y_min'} += $obj->{'graph_border'};
    $obj->{'x_max'} -= $obj->{'graph_border'};
    $obj->{'y_max'} -= $obj->{'graph_border'};


    if ($obj->{'sort'}) { $obj->sort_data; } 
    $obj->draw_data;
}

sub check_data {
    my $obj = shift;
    my $ref = $obj->{'data'};
    my $mismatch;

    CHECK: for (1..$#{$ref}) {
	       if ($#{$ref->[$_]} > $#{$ref->[0]}) {
		   $mismatch = 1;
		   last CHECK;
	       }
    }

    if ($mismatch) {
	croak ("One or more data sets longer than set of data point labels");
    }
}
    
sub draw_title {
    my $obj = shift;
    my ($w, $h) = (gdLargeFont->width,gdLargeFont->height);
    my $black = $obj->get_color ('black');
    my ($x, $y);
    
    $y = $obj->{'y_min'} + $obj->{'text_space'};
    $obj->{'y_min'} += $h + 2 * $obj->{'text_space'} + $obj->{'gif_border'} / 2;
    $x = ((($obj->{'x_max'} - $obj->{'x_min'}) / $obj->{'text_space'}) - 
	  (($w * length ($obj->{'title'})) / $obj->{'text_space'}));
    $obj->{'im'}->string (gdLargeFont, $x, $y, $obj->{'title'}, $black);
} 

sub draw_sub_title {
    my $obj = shift;
    my ($w, $h) = (gdLargeFont->width,gdLargeFont->height);
    my $black = $obj->get_color ('black');
    my ($x, $y);
		        
    $y = $obj->{'y_min'} + $obj->{'text_space'};
    $obj->{'y_min'} += $h + 2 * $obj->{'text_space'} + $obj->{'gif_border'} / 2;
    $x = ((($obj->{'x_max'} - $obj->{'x_min'}) / $obj->{'text_space'}) -
          (($w * length ($obj->{'sub_title'})) / $obj->{'text_space'}));
    $obj->{'im'}->string (gdLargeFont, $x, $y, $obj->{'sub_title'}, $black);
}


sub draw_labels {
    my $obj = shift;
    my ($w, $h) = (gdMediumBoldFont->width,gdMediumBoldFont->height);
    my $black = $obj->get_color ('black');
    my ($x, $y);
    
    if ($obj->{'x_label'}) {
	$y = $obj->{'y_max'} - ($obj->{'text_space'} + $h);
	$x = (($obj->{'x_max'} - $obj->{'x_min'}) / 2) + $obj->{'x_min'}
	        - (length ($obj->{'x_label'}) / 2) * $w;
	$obj->{'im'}->string (gdMediumBoldFont, $x, $y, 
			      $obj->{'x_label'}, $black);
    }
    
    if ($obj->{'y_label'}) {
	$y = (($obj->{'y_max'} - $obj->{'y_min'}) / 2) + $obj->{'y_min'} +
	    (length ($obj->{'y_label'}) / 2) * $w;
	$x = $obj->{'x_min'} + $obj->{'text_space'};
	$obj->{'im'}->stringUp (gdMediumBoldFont, $x, $y, 
				$obj->{'y_label'}, $black);
    }

    $obj->{'y_max'} -= ($obj->{'x_label'}) ? $h + 2 * $obj->{'text_space'} : 0;
    $obj->{'x_min'} += ($obj->{'y_label'}) ? $h + 2 * $obj->{'text_space'} : 0;
}

sub draw_legend {
    my $obj = shift;
    my $dataref = $obj->{'data'};
    my (@labels, $legend_w, $legend_h, $color, $dash, $ymin);
    my ($w, $h) = (gdSmallFont->width, gdSmallFont->height);
    my $black = $obj->get_color ('black');
    my $max_len = 0;

    #==========================#
    #  prepare list of labels  #
    #==========================#

    if ($obj->{'legend_labels'}) {
	@labels = @{$obj->{'legend_labels'}};
	if ($#labels != $#{$dataref} - 1) {
	    croak ("Number of data set labels does not match number of data sets");
	}
    }
    else {
	for (1..$#{$dataref}) {
	    $labels[$_-1] = "Dataset $_";
	}
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

    $ymin = $obj->{'y_min'} + $obj->{'graph_border'};

    if (!($obj->{'dashed_lines'})) {
	$legend_h = ($#labels + 1) * ($h + 2 * $obj->{'text_space'});
	$legend_w = ($max_len * $w) + 3 * $obj->{'text_space'};
	$obj->{'x_max'} -= $legend_w + 2 * $obj->{'text_space'};
	
	$obj->{'im'}->rectangle ($obj->{'x_max'} + 2 * $obj->{'text_space'},
				 $ymin,
				 $obj->{'x_max'} + 2 * $obj->{'text_space'} 
			             + $legend_w,
				 $ymin + $legend_h,
				 $black);
	
	for (0..$#labels) {
	    $color = $obj->data_color($_);
	    
	    $obj->{'im'}->string (gdSmallFont,
				  $obj->{'x_max'} + 7,
				  $ymin + $obj->{'text_space'} 
			              + $_ * ($h + 2 * $obj->{'text_space'}),
				  $labels[$_],
				  $color);
	}
    }
    else {
	$legend_h = ($#labels + 1) * ($h + 2 * $obj->{'text_space'});
	$legend_w = ($max_len * $w) + 3 * $obj->{'text_space'} + 22;
	$obj->{'x_max'} -= $legend_w + 2 * $obj->{'text_space'} + 22;
	
	$obj->{'im'}->rectangle ($obj->{'x_max'} + 2 * $obj->{'text_space'},
				 $ymin,
				 $obj->{'x_max'} + 2 * $obj->{'text_space'} 
			             + $legend_w,
				 $ymin + $legend_h,
				 $black);
	
	$dash = $obj->{'dashed_lines'};
	$obj->{'dashed_lines'} = '';

	for (0..$#labels) {
	    $color = $obj->data_color($_);
	    
	    $obj->{'im'}->string (gdSmallFont,
				  $obj->{'x_max'} + 29,
				  $ymin + $obj->{'text_space'} 
				      + $_ * ($h + 2 * $obj->{'text_space'}),
				  $labels[$_],
				  $color);
	}

	$obj->{'dashed_lines'} = $dash;

	for (0..$#labels) {
	    $color = $obj->data_color($_);
	    
	    $obj->{'im'}->line ($obj->{'x_max'} + 7,
				$ymin + $obj->{'text_space'} + $h/2
				    + $_ * ($h + 2 * $obj->{'text_space'}),
				$obj->{'x_max'} + 27,
				$ymin + $obj->{'text_space'} + $h/2
				    + $_ * ($h + 2 * $obj->{'text_space'}),
				$color);
	}
    }
}

sub sort_data {
    my $obj = shift;
    my $dataref = $obj->{'data'};
    my ($order, $set, $type);
    my ($ref, $i, $j);

    if ($obj->{'nosort'}) { return }

    if (ref ($obj->{'sort'})) {
	($order, $set, $type) = @{$obj->{'sort'}};
    }
    else {
	$order = $obj->{'sort'};
    }

    $set = 0 unless ($set);
    $type = 'alpha' unless ($type);

    for $i (0..$#{$dataref->[0]}) {
	for $j (0..$#{$dataref}) {
	    $ref->[$i][$j] = $dataref->[$j][$i];
	}
    }
    
    if ($order eq 'asc') {
	if ($type eq 'alpha') {
            @{$ref} = sort {$Chart::Base::a->[$set] cmp $Chart::Base::b->[$set]}
	                       @{$ref};
	}
	else {
	    @{$ref} = sort {$Chart::Base::a->[$set] <=> $Chart::Base::b->[$set]}
	                       @{$ref};
	} 
    }
    else {
	if ($type eq 'alpha') {
            @{$ref} = sort {$Chart::Base::b->[$set] cmp $Chart::Base::a->[$set]}
	                       @{$ref};
        }
        else {
            @{$ref} = sort {$Chart::Base::b->[$set] <=> $Chart::Base::a->[$set]}
                               @{$ref};
        }   
    }
    
    for $i (0..$#{$dataref->[0]}) {
        for $j (0..$#{$dataref}) {
            $dataref->[$j][$i] = $ref->[$i][$j];
        }
    }
					    
    
    $obj->{'data'} = $dataref;
}

sub draw_axes {
    my $obj = shift;
    my $black = $obj->get_color ('black');
    
    $obj->{'im'}->rectangle ($obj->{'x_min'}, $obj->{'y_min'},
			     $obj->{'x_max'}, $obj->{'y_max'},
			     $black);
}

sub set_user_colors {
    my $obj = shift;
    my @rgbs = @{$obj->{'colors'}};

    for (@rgbs) {
	if ($_) {
	    $obj->{'im'}->colorAllocate (@{$_});
	}
    }
}

sub get_color {
    my $obj = shift;
    my $color = shift;
    my %colors = ('white' => [250,250,250],
		  'black' => [0,0,0],
		  'red' => [225,0,0],
		  'green' => [0,225,0],
		  'blue' => [0,0,225],
		  'purple' => [200,0,200],
		  'light_blue' => [0,200,200],
		  'yellow' => [225,225,0],
		  'orange' => [250,170,85],
		  'grey' => [200,200,200]);
    my @rgb = (defined($colors{$color})) ? @{$colors{$color}} : (0,0,0);

    return $obj->{'im'}->colorClosest(@rgb);
}

sub data_color {
    my $obj = shift;
    my $num = shift;
    my %colors = (0 => 'red',
		  1 => 'blue',
		  2 => 'green',
		  3 => 'purple',
		  4 => 'orange',
		  5 => 'light_blue',
		  6 => 'yellow');
    my ($col,%dots);

    $col = ($obj->{'colors'}->[$num]) 
    		? $obj->{'im'}->colorClosest (@{$obj->{'colors'}->[$num]})
		: $obj->get_color ($colors{$num});

    %dots = (4 => [$col],
             0 => [$col,$col,gdTransparent],
	     1 => [$col,$col,$col,$col,$col,$col,gdTransparent,gdTransparent,gdTransparent,$col,$col,$col,gdTransparent,gdTransparent,gdTransparent],
	     2 => [$col,$col,$col,$col,$col,$col,$col,$col,gdTransparent,gdTransparent,gdTransparent,gdTransparent],
	     3 => [$col,$col,$col,$col,gdTransparent,gdTransparent]);

    if ($obj->{'dashed_lines'} && $obj->{'dashed_lines'} ne '') {
        $obj->{'im'}->setStyle ((@{$dots{$num}}) 
	              ? @{$dots{$num}} : ($col,gdTransparent));
	return gdStyled;
    }
    else {
        return $col;
    }
}

1;

