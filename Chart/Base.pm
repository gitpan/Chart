#>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>#
#  Chart::Base                   #
#                                #
#  written by david bonner       #
#  dbonner@cs.bu.edu             #
#                                #
#  maintained by the Chart Group #
#  Chart@wettzell.ifag.de        #
#                                #
#  theft is treason, citizen     #
#<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<#

package Chart::Base;

use GD;
use strict;
use Carp;
use FileHandle;

$Chart::Base::VERSION = 1.00;

use vars qw(%named_colors);


#>>>>>>>>>>>>>>>>>>>>>>>>>>#
#  public methods go here  #
#<<<<<<<<<<<<<<<<<<<<<<<<<<#

##  standard nice object creator
sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $self = {};

  bless $self, $class;
  $self->_init(@_);

  return $self;
}


##  main method for customizing the chart, lets users
##  specify values for different parameters
sub set {
  my $self = shift;
  my %opts = @_;
  
  # basic error checking on the options, just warn 'em
  unless ($#_ % 2) {
    carp "Whoops, some option to be set didn't have a value.\n",
         "You might want to look at that.\n";
  }
  
  # set the options
  for (keys %opts) {
    $self->{$_} = $opts{$_};
  }

  # now return
  return 1;
}


##  Graph API
sub add_pt {
  my $self = shift;
  my @data = @_;

  # error check the data (carp, don't croak)
  if ($self->{'dataref'} && ($#{$self->{'dataref'}} != $#data)) {
    carp "New point to be added has an incorrect number of data sets";
    return 0;
  }

  # copy it into the dataref
  for (0..$#data) {
    push @{$self->{'dataref'}->[$_]}, $data[$_];
  }
  
  # now return
  return 1;
}


##  more Graph API
sub add_dataset {
  my $self = shift;
  my @data = @_;

  # error check the data (carp, don't croak)
  if ($self->{'dataref'} && ($#{$self->{'dataref'}->[0]} != $#data)) {
    carp "New data set to be added has an incorrect number of points";
  }

  # copy it into the dataref
  push @{$self->{'dataref'}}, [ @data ];
  
  # now return
  return 1;
}


##  even more Graph API
sub clear_data {
  my $self = shift;

  # undef the internal data reference
  $self->{'dataref'} = undef;

  # now return
  return 1;
}


##  and the last of the Graph API
sub get_data {
  my $self = shift;
  my $ref = [];
  my ($i, $j);

  # give them a copy, not a reference into the object
  for $i (0..$#{$self->{'dataref'}}) {
    @{ $ref->[$i] } = @{ $self->{'dataref'}->[$i] }
## speedup, compared to...
#   for $j (0..$#{$self->{'dataref'}->[$i]}) {
#     $ref->[$i][$j] = $self->{'dataref'}->[$i][$j];
#   }
  }

  # return it
  return $ref;
}


##  called after the options are set, this method
##  invokes all my private methods to actually
##  draw the chart and plot the data
sub png {
  my $self = shift;
  my $file = shift;
  my $dataref = shift;
  my $fh;

  # do some ugly checking to see if they gave me
  # a filehandle or a file name
  if ((ref \$file) eq 'SCALAR') {  
    # they gave me a file name
    $fh = FileHandle->new (">$file");
  }
  elsif ((ref \$file) =~ /^(?:REF|GLOB)$/) {
    # either a FileHandle object or a regular file handle
    $fh = $file;
  }
  else {
    croak "I'm not sure what you gave me to write this png to,\n",
          "but it wasn't a filename or a filehandle.\n";
  }

  # allocate the background color
  $self->_set_colors();

  # make sure the object has its copy of the data
  $self->_copy_data($dataref);

  # do a sanity check on the data, and collect some basic facts
  # about the data
  $self->_check_data();

  # pass off the real work to the appropriate subs
  $self->_draw();

  # now write it to the file handle, and don't forget
  # to be nice to the poor ppl using nt
  binmode $fh;
  print $fh $self->{'gd_obj'}->png();
  
  # now exit
  return 1;
}


##  called after the options are set, this method
##  invokes all my private methods to actually
##  draw the chart and plot the data
sub cgi_png {
  my $self = shift;
  my $dataref = shift;

  # allocate the background color
  $self->_set_colors();

  # make sure the object has its copy of the data
  $self->_copy_data($dataref);

  # do a sanity check on the data, and collect some basic facts
  # about the data
  $self->_check_data();

  # pass off the real work to the appropriate subs
  $self->_draw();

  # print the header (ripped the crlf octal from the CGI module)
  if ($self->{no_cache} =~ /^true$/i) {
      print "Content-type: image/png\015\012Pragma: no-cache\015\012\015\012";
  } else {
      print "Content-type: image/png\015\012\015\012";
  }

  # now print the png, and binmode it first so nt likes us
  binmode STDOUT;
  print STDOUT $self->{'gd_obj'}->png();

  # now exit
  return 1;
}

##  called after the options are set, this method
##  invokes all my private methods to actually
##  draw the chart and plot the data
sub scalar_png {
  my $self = shift;
  my $dataref = shift;

  # make sure the object has its copy of the data
  $self->_copy_data($dataref);

  # do a sanity check on the data, and collect some basic facts
  # about the data
  $self->_check_data();

  # pass off the real work to the appropriate subs
  $self->_draw();

  # returns the png image as a scalar value, so that
  # the programmer-user can do whatever the heck
  # s/he wants to with it
  $self->{'gd_obj'}->png();
}


##  called after the options are set, this method
##  invokes all my private methods to actually
##  draw the chart and plot the data
sub jpeg {
  my $self = shift;
  my $file = shift;
  my $dataref = shift;
  my $fh;

  # do some ugly checking to see if they gave me
  # a filehandle or a file name
  if ((ref \$file) eq 'SCALAR') {  
    # they gave me a file name
    $fh = FileHandle->new (">$file");
  }
  elsif ((ref \$file) =~ /^(?:REF|GLOB)$/) {
    # either a FileHandle object or a regular file handle
    $fh = $file;
  }
  else {
    croak "I'm not sure what you gave me to write this jpeg to,\n",
          "but it wasn't a filename or a filehandle.\n";
  }

  # allocate the background color
  $self->_set_colors();

  # make sure the object has its copy of the data
  $self->_copy_data($dataref);

  # do a sanity check on the data, and collect some basic facts
  # about the data
  $self->_check_data;

  # pass off the real work to the appropriate subs
  $self->_draw();

  # now write it to the file handle, and don't forget
  # to be nice to the poor ppl using nt
  binmode $fh;
  print $fh $self->{'gd_obj'}->jpeg([100]);   # high quality need

  # now exit
  return 1;
}

##  called after the options are set, this method
##  invokes all my private methods to actually
##  draw the chart and plot the data
sub cgi_jpeg {
  my $self = shift;
  my $dataref = shift;

  # allocate the background color
  $self->_set_colors();

  # make sure the object has its copy of the data
  $self->_copy_data($dataref);

  # do a sanity check on the data, and collect some basic facts
  # about the data
  $self->_check_data();

  # pass off the real work to the appropriate subs
  $self->_draw();

  # print the header (ripped the crlf octal from the CGI module)
  if ($self->{no_cache} =~ /^true$/i) {
      print "Content-type: image/jpeg\015\012Pragma: no-cache\015\012\015\012";
  } else {
      print "Content-type: image/jpeg\015\012\015\012";
  }

  # now print the png, and binmode it first so nt likes us
  binmode STDOUT;
  print STDOUT $self->{'gd_obj'}->jpeg([100]);

  # now exit
  return 1;
}

##  called after the options are set, this method
##  invokes all my private methods to actually
##  draw the chart and plot the data
sub scalar_jpeg {
  my $self = shift;
  my $dataref = shift;

  # make sure the object has its copy of the data
  $self->_copy_data($dataref);

  # do a sanity check on the data, and collect some basic facts
  # about the data
  $self->_check_data();

  # pass off the real work to the appropriate subs
  $self->_draw();

  # returns the png image as a scalar value, so that
  # the programmer-user can do whatever the heck
  # s/he wants to with it
  $self->{'gd_obj'}->jpeg([100]);
}

sub make_gd {
  my $self = shift;
  my $dataref = shift;

  # allocate the background color
  $self->_set_colors();

  # make sure the object has its copy of the data
  $self->_copy_data($dataref);

  # do a sanity check on the data, and collect some basic facts
  # about the data
  $self->_check_data();

  # pass off the real work to the appropriate subs
  $self->_draw();

  # return the GD::Image object that we've drawn into
  return $self->{'gd_obj'};
}


##  get the information to turn the chart into an imagemap
sub imagemap_dump {
  my $self = shift;
  my $ref = [];
  my ($i, $j);
 
  # croak if they didn't ask me to remember the data, or if they're asking
  # for the data before I generate it
  unless (($self->{'imagemap'} =~ /^true$/i) && $self->{'imagemap_data'}) {
    croak "You need to set the imagemap option to true, and then call the png method, before you can get the imagemap data";
  }

  # can't just return a ref to my internal structures...
  for $i (0..$#{$self->{'imagemap_data'}}) {
    for $j (0..$#{$self->{'imagemap_data'}->[$i]}) {
      $ref->[$i][$j] = [ @{ $self->{'imagemap_data'}->[$i][$j] } ];
    }
  }

  # return their copy
  return $ref;
}

#>>>>>>>>>>>>>>>>>>>>>>>>>>>#
#  private methods go here  #
#<<<<<<<<<<<<<<<<<<<<<<<<<<<#

##  initialize all the default options here
sub _init {
  my $self = shift;
  my $x = shift || 400;  # give them a 400x300 image
  my $y = shift || 300;  # unless they say otherwise
  
  # get the gd object
  $self->{'gd_obj'} = GD::Image->new($x, $y);

  # start keeping track of used space
  $self->{'curr_y_min'} = 0;
  $self->{'curr_y_max'} = $y;
  $self->{'curr_x_min'} = 0;
  $self->{'curr_x_max'} = $x;

  # use a 10 pixel border around the whole png
  $self->{'png_border'} = 10;

  # leave some space around the text fields
  $self->{'text_space'} = 2;

  # and leave some more space around the chart itself
  $self->{'graph_border'} = 10;

  # leave a bit of space inside the legend box
  $self->{'legend_space'} = 4;
  
  # set some default fonts
  $self->{'title_font'} = gdLargeFont;
  $self->{'sub_title_font'} = gdLargeFont;
  $self->{'legend_font'} = gdSmallFont;
  $self->{'label_font'} = gdMediumBoldFont;
  $self->{'tick_label_font'} = gdSmallFont;

  # put the legend on the bottom of the chart
  $self->{'legend'} = 'right';

  # default to an empty list of labels
  $self->{'legend_labels'} = [];

  # use 20 pixel length example lines in the legend
  $self->{'legend_example_size'} = 20;

  # use 6 ticks on the y-axis
  $self->{'y_ticks'} = 6;

  # make the ticks 4 pixels long
  $self->{'tick_len'} = 4;

  # no custom y tick labels
  $self->{'y_tick_labels'} = undef;
  
  # no patterns
  $self->{'patterns'} = undef;

  # let the lines in Chart::Lines be 6 pixels wide
  $self->{'brush_size'} = 6;

  # let the points in Chart::Points and Chart::LinesPoints be 18 pixels wide
  $self->{'pt_size'} = 18;

  # use the old non-spaced bars
  $self->{'spaced_bars'} = 'true';

  # use the new grey background for the plots
  $self->{'grey_background'} = 'true';

  # don't default to transparent
  $self->{'transparent'} = 'false';

  # default to "normal" x_tick drawing
  $self->{'x_ticks'} = 'normal';

  # we're not a component until Chart::Composite says we are
  $self->{'component'} = 'false';

  # don't force the y-axes in a Composite chare to be the same
  $self->{'same_y_axes'} = 'false';

  # don't force integer y-ticks
  $self->{'integer_ticks_only'} = 'false';

  # don't waste time/memory by storing imagemap info unless they ask
  $self->{'imagemap'} = 'false';

  # default for grid_lines is off
  $self->{grid_lines} = 'false';
  $self->{x_grid_lines} = 'false';
  $self->{y_grid_lines} = 'false';
  $self->{y2_grid_lines} = 'false';

  # default for no_cache is false.  (it breaks netscape 4.5)
  $self->{no_cache} = 'false';

  $self->{typeStyle} = 'default';

  # used function to transform x- and y-tick labels to strings
  $self->{f_x_tick} = \&_default_f_tick;
  $self->{f_y_tick} = \&_default_f_tick;
  
  # default color specs for various color roles.
  # Subclasses should extend as needed.
  my $d = 0;
  $self->{'colors_default_spec'} = {
    background	=> 'white',
    misc	=> 'black',
    text	=> 'black',
    y_label	=> 'black',
    y_label2	=> 'black',
    grid_lines	=> 'black',
    grey_background => 'grey',
    (map { 'dataset'.$d++ => $_ } qw (red green blue purple peach orange mauve olive pink light_purple light_blue plum yellow turquoise light_green brown 
                                      HotPink PaleGreen1 DarkBlue BlueViolet orange2 chocolate1 LightGreen pink light_purple light_blue plum yellow turquoise light_green brown 
                                      pink PaleGreen2 MediumPurple PeachPuff1 orange3 chocolate2 olive pink light_purple light_blue plum yellow turquoise light_green brown 
                                      DarkOrange PaleGreen3 SlateBlue BlueViolet PeachPuff2 orange4 chocolate3 LightGreen pink light_purple light_blue plum yellow turquoise light_green brown) ),

  };
  
  # get default color specs for some color roles from alternate role.
  # Subclasses should extend as needed.
  $self->{'colors_default_role'} = {
    'x_grid_lines'	=> 'grid_lines',
    'y_grid_lines'	=> 'grid_lines',
    'y2_grid_lines'	=> 'grid_lines', # should be added by Char::Composite...
  };

  # and return
  return 1;
}


##  be nice and leave their data alone
sub _copy_data {
  my $self = shift;
  my $extern_ref = shift;
  my ($ref, $i, $j);

  # look to see if they used the other api
  if ($self->{'dataref'}) {
    # we've already got a copy, thanks
    return 1;
  }
  else {
    # get an array reference
    $ref = [];
    
    # loop through and copy
    for $i (0..$#{$extern_ref}) {
      @{ $ref->[$i] } = @{ $extern_ref->[$i] };
## Speedup compared to:
#     for $j (0..$#{$extern_ref->[$i]}) {
#       $ref->[$i][$j] = $extern_ref->[$i][$j];
#     }
    }

    # put it in the object
    $self->{'dataref'} = $ref;
  }
}


##  make sure the data isn't really weird
##  and collect some basic info about it
sub _check_data {
  my $self = shift;
  my $length = 0;

  # first make sure there's something there
  unless (scalar (@{$self->{'dataref'}}) >= 2) {
    croak "Call me again when you have some data to chart";
  }

  # make sure we don't end up dividing by zero if they ask for
  # just one y_tick
  if ($self->{'y_ticks'} == 1) {
    $self->{'y_ticks'} = 2;
    carp "The number of y_ticks displayed must be at least 2";
  }

  # remember the number of datasets
  $self->{'num_datasets'} = $#{$self->{'dataref'}};

  # remember the number of points in the largest dataset
  $self->{'num_datapoints'} = 0;
  for (0..$self->{'num_datasets'}) {
    if (scalar(@{$self->{'dataref'}[$_]}) > $self->{'num_datapoints'}) {
      $self->{'num_datapoints'} = scalar(@{$self->{'dataref'}[$_]});
    }
  }

  # find good min and max y-values for the plot
  $self->_find_y_scale;

  # find the longest x-tick label
  for (@{$self->{'dataref'}->[0]}) {
    if (length($self->{f_x_tick}->($_)) > $length) {
      $length = length ($self->{f_x_tick}->($_));
    }
  }
  if ( $length <= 0 ) { $length = 1; }    # make sure $length is positive and greater 0

  # now store it in the object
  $self->{'x_tick_label_length'} = $length;

  return 1;
}


##  plot the chart to the gd object
sub _draw {
  my $self = shift;
  
## No Longer needed.
#   # use their colors if they want
#   if ($self->{'colors'}) {
#     $self->_set_user_colors();
#   }

## Moved to png(), cgi_png(), etc.
#   # fill in the defaults for the colors
#   $self->_set_colors();

  # leave the appropriate border on the png
  $self->{'curr_x_max'} -= $self->{'png_border'};
  $self->{'curr_x_min'} += $self->{'png_border'};
  $self->{'curr_y_max'} -= $self->{'png_border'};
  $self->{'curr_y_min'} += $self->{'png_border'};

  # draw in the title
  $self->_draw_title() if $self->{'title'};

  # have to leave this here for backwards compatibility
  $self->_draw_sub_title() if $self->{'sub_title'};

  # sort the data if they want to (mainly here to make sure
  # pareto charts get sorted)
  $self->_sort_data() if $self->{'sort'};

  # start drawing the data (most methods in this will be
  # overridden by the derived classes)
  # include _draw_legend() in this to ensure that the legend
  # will be flush with the chart
  $self->_plot();

  # and return
  return 1;
}


%named_colors = (
  'white'		=> [255,255,255],
  'black'		=> [0,0,0],
  'red'			=> [200,0,0],
  'green'		=> [0,175,0],
  'blue'		=> [0,0,200],
  'orange'		=> [250,125,0],
  'orange2'		=> [238,154,0],
  'orange3'		=> [205,133,0],
  'orange4'		=> [139,90,0],
  'yellow'		=> [225,225,0],
  'purple'		=> [200,0,200],
  'light_blue'		=> [0,125,250],
  'light_green'		=> [125,250,0],
  'light_purple'	=> [145,0,250],
  'pink'		=> [250,0,125],
  'peach'		=> [250,125,125],
  'olive'		=> [125,125,0],
  'plum'		=> [125,0,125],
  'turquoise'		=> [0,125,125],
  'mauve'		=> [200,125,125],
  'brown'		=> [160,80,0],
  'grey'		=> [225,225,225],
  'HotPink'             => [255,105,180],
  'PaleGreen1'          => [154,255,154],
  'PaleGreen2'          => [144,238,144],
  'PaleGreen3'          => [124,205,124],
  'PaleGreen4'          => [84,138,84],
  'DarkBlue'            => [0,0,139],
  'BlueViolet'          => [138,43,226],
  'PeachPuff'           => [255,218,185],
  'PeachPuff1'          => [255,218,185],
  'PeachPuff2'          => [238,203,173],
  'PeachPuff3'          => [205,175,149],
  'PeachPuff4'          => [139,119,101],
  'chocolate1'          => [255,127,36], 
  'chocolate2'          => [238,118,33], 
  'chocolate3'          => [205,102,29], 
  'chocolate4'          => [139,69,19],
  'LightGreen'          => [144,238,144],
  'lavender'            => [230,230,250],
  'MediumPurple'        => [147,112,219],
  'DarkOrange'          => [255,127,0],
  'DarkOrange2'         => [238,118,0],
  'DarkOrange3'         => [205,102,0],
  'DarkOrange4'         => [139,69,0],
  'SlateBlue'           => [106,90,205],
  'BlueViolet'          => [138,43,226],
  'RoyalBlue'           => [65,105,225],
);


## No Longer needed.
##  let the user specify their own colors in $self->{'colors'}
# sub _set_user_colors {
#   my $self = shift;
#   my $color_table = {};
#   my @rgb;
#   
#   # see if they want a different background
#   if (($self->{'colors'}{'background'}) &&
#       (scalar(@{$self->{'colors'}{'background'}}) == 3)) {
#     @rgb = @{$self->{'colors'}{'background'}};
#     $color_table->{'background'} = $self->{'gd_obj'}->colorAllocate(@rgb);
#   }
#   else { # make sure white becomes the background color
#     @rgb = (255, 255, 255);
#     $color_table->{'background'} = $self->{'gd_obj'}->colorAllocate(@rgb);
#   }
# 
#   # make the background transparent if they asked nicely
#   if ($self->{'transparent'} =~ /^true$/i) {
#     $self->{'gd_obj'}->transparent ($color_table->{'background'});
#   }
# 
#   # next check for the color for the miscellaneous stuff
#   # (the axes on the plot, the box around the legend, etc.)
#   if (($self->{'colors'}{'misc'}) &&
#       (scalar(@{$self->{'colors'}{'misc'}}) == 3)) {
#     @rgb = @{$self->{'colors'}{'misc'}};
#     $color_table->{'misc'} = $self->{'gd_obj'}->colorAllocate(@rgb);
#   }
# 
#   # what about the text?
#   if (($self->{'colors'}{'text'}) &&
#       (scalar(@{$self->{'colors'}{'text'}}) == 3)) {
#     @rgb = @{$self->{'colors'}{'text'}};
#     $color_table->{'text'} = $self->{'gd_obj'}->colorAllocate(@rgb);
#   }
# 
#   # and how about y_labels?
#   if (($self->{'colors'}{'y_label'}) &&
#       (scalar(@{$self->{'colors'}{'y_label'}}) == 3)) {
#     @rgb = @{$self->{'colors'}{'y_label'}};
#     $color_table->{'y_label'} = $self->{'gd_obj'}->colorAllocate(@rgb);
#   }
#  
#   if (($self->{'colors'}{'y_label2'}) &&
#       (scalar(@{$self->{'colors'}{'y_label2'}}) == 3)) {
#     @rgb = @{$self->{'colors'}{'y_label2'}};
#     $color_table->{'y_label2'} = $self->{'gd_obj'}->colorAllocate(@rgb);
#   }
# 
#   # set user-specified "default" grid_lines color 
#   if (($self->{'colors'}{'grid_lines'}) &&
#       (scalar(@{$self->{'colors'}{'grid_lines'}}) == 3)) {
#     @rgb = @{$self->{'colors'}{'grid_lines'}};
#     $color_table->{'grid_lines'} = $self->{'gd_obj'}->colorAllocate(@rgb);
#   }
# 
#   # x_grid_lines color
#   if (($self->{'colors'}{'x_grid_lines'}) &&
#       (scalar(@{$self->{'colors'}{'x_grid_lines'}}) == 3)) {
#     @rgb = @{$self->{'colors'}{'x_grid_lines'}};
#     $color_table->{'x_grid_lines'} = $self->{'gd_obj'}->colorAllocate(@rgb);
#   }
# 
#   # y_grid_lines color
#   if (($self->{'colors'}{'y_grid_lines'}) &&
#       (scalar(@{$self->{'colors'}{'y_grid_lines'}}) == 3)) {
#     @rgb = @{$self->{'colors'}{'y_grid_lines'}};
#     $color_table->{'y_grid_lines'} = $self->{'gd_obj'}->colorAllocate(@rgb);
#   }
# 
#   # y2_grid_lines color
#   if (($self->{'colors'}{'y2_grid_lines'}) &&
#       (scalar(@{$self->{'colors'}{'y2_grid_lines'}}) == 3)) {
#     @rgb = @{$self->{'colors'}{'y2_grid_lines'}};
#     $color_table->{'y2_grid_lines'} = $self->{'gd_obj'}->colorAllocate(@rgb);
#   }
# 
#   # okay, now go for the data sets
#   for (keys(%{$self->{'colors'}})) {
#     if (($_ =~ /^dataset/i) &&
#         (scalar(@{$self->{'colors'}{$_}}) == 3)) {
#       @rgb = @{$self->{'colors'}{$_}};
#       $color_table->{$_} = $self->{'gd_obj'}->colorAllocate(@rgb);
#     }
#   }
# 
#   # stick the color table in the object
#   $self->{'color_table'} = $color_table;
# 
#   # and return
#   return 1;
# }


##  specify my colors
sub _set_colors {
  my $self = shift;
  
## Moved out to module level.
#   my %colors = ('white'	=> [255,255,255],
#   		'black'		=> [0,0,0],
# 		'red'		=> [200,0,0],
# 		'green'		=> [0,175,0],
# 		'blue'		=> [0,0,200],
# 		'orange'	=> [250,125,0],
# 		'yellow'	=> [225,225,0],
# 		'purple'	=> [200,0,200],
# 		'light_blue'	=> [0,125,250],
# 		'light_green'	=> [125,250,0],
# 		'light_purple'	=> [145,0,250],
# 		'pink'		=> [250,0,125],
# 		'peach'		=> [250,125,125],
# 		'olive'		=> [125,125,0],
# 		'plum'		=> [125,0,125],
# 		'turquoise'	=> [0,125,125],
# 		'mauve'		=> [200,125,125],
# 		'brown'		=> [160,80,0],
# 		'grey'		=> [225,225,225]);


  my $index = $self->_color_role_to_index('background'); # allocate GD color
  if ( $self->{'transparent'} =~ m/^true$/i ) {
    $self->{'gd_obj'}->transparent($index);
  }
  # all other roles are initialized by calling $self->_color_role_to_index(ROLENAME);	



## Replaced by above, and calls to _color_role_to_index method elsewhere.
#   my ($color_table, @rgb, @colors);
# 
#   # check to see if they specified colors
#   if ($self->{'color_table'}) {
#     $color_table = $self->{'color_table'};
#   }
#   else {
#     $color_table = {};
#   }
#   
#   # put the background in first
#   unless ($color_table->{'background'}) {
#     @rgb = @{$colors{'white'}};
#     $color_table->{'background'} = $self->{'gd_obj'}->colorAllocate(@rgb);    
#   }
# 
#   # make the background transparent if they asked for it
#   if ($self->{'transparent'} =~ /^true$/i) {
#     $self->{'gd_obj'}->transparent ($color_table->{'background'});
#   }
# 
#   # now get all my named colors
#   for (keys (%colors)) {
#     @rgb = @{$colors{$_}};
#     $color_table->{$_} = $self->{'gd_obj'}->colorAllocate(@rgb);
#   }
# 
#   # set up the datatset* colors
#   @colors = qw (red green blue purple peach orange mauve olive pink light_purple light_blue plum yellow turquoise light_green brown);
#   for (0..$#colors) {
#     unless ($color_table->{'dataset'.$_}) { # don't override their colors
#       $color_table->{'dataset'.$_} = $color_table->{$colors[$_]};
#     }
#   }
# 
#   # set up the miscellaneous color
#   unless ($color_table->{'misc'}) {
#     $color_table->{'misc'} = $color_table->{'black'};
#   }
# 
#   # and the text color
#   unless ($color_table->{'text'}) {
#     $color_table->{'text'} = $color_table->{'black'};
#   }
# 
#   unless ($color_table->{'y_label'}) {
#     $color_table->{'y_label'} = $color_table->{'black'};
#   }
#   unless ($color_table->{'y_label2'}) {
#     $color_table->{'y_label2'} = $color_table->{'black'};
#   }
# 
#   unless ($color_table->{'grid_lines'}) {
#     $color_table->{'grid_lines'} = $color_table->{'black'};
#   }
# 
#   unless ($color_table->{'x_grid_lines'}) {
#     $color_table->{'x_grid_lines'} = $color_table->{'grid_lines'};
#   }
# 
#   unless ($color_table->{'y_grid_lines'}) {
#     $color_table->{'y_grid_lines'} = $color_table->{'grid_lines'};
#   }
# 
#   unless ($color_table->{'y2_grid_lines'}) {
#     $color_table->{'y2_grid_lines'} = $color_table->{'grid_lines'};
#   }
# 
#   # put the color table back in the object
#   $self->{'color_table'} = $color_table;
#   
#   # and return
#   return 1; 
}

  sub _color_role_to_index {
    my $self = shift;
    
    # Return a (list of) color index(es) corresponding to the (list of) role(s) in @_.
    my @result =  map {
      my $role = $_;
      my $index = $self->{'color_table'}->{$role};
      
      unless ( defined $index ) {
        my $spec = $self->{'colors'}->{$role} 
          || $self->{'colors_default_spec'}->{$role}
          || $self->{'colors_default_spec'}->{$self->{'colors_default_role'}->{$role}};
        my @rgb = $self->_color_spec_to_rgb($role, $spec);
        
        my $string = sprintf " RGB(%d,%d,%d)", map { $_ + 0 } @rgb;
        
        $index = $self->{'color_table'}->{$string};
        unless ( defined $index ) {
          $index = $self->{'gd_obj'}->colorAllocate(@rgb);
         $self->{'color_table'}->{$string} = $index;
        }
        
        $self->{'color_table'}->{$role} = $index;
      }
      $index;
    } @_;
    (wantarray && @_ > 1 ? @result : $result[0]);
  }
      
  sub _color_spec_to_rgb {
    my $self = shift;
    my $role = shift; # for error messages
    my $spec = shift; # [r,g,b] or name
    my @rgb;
    if ( ref($spec) eq 'ARRAY' ) {
      @rgb = @{ $spec };
      croak "Invalid color RGB array (" . join(',', @rgb) . ") for $role\n" 
        unless @rgb == 3 && grep( ! m/^\d+$/ || $_ > 255, @rgb) == 0;
    }
    elsif ( ! ref($spec) ) {
      croak "Unknown named color ($spec) for $role\n"
        unless $named_colors{$spec};
      @rgb = @{ $named_colors{$spec} };
    }
    else {
      croak "Unrecognized color for $role\n";
    }
    @rgb;
  }


##  draw the title for the chart
sub _draw_title {
  my $self = shift;
  my $font = $self->{'title_font'};
  my $color = $self->_color_role_to_index('text');
  my ($h, $w, @lines, $x, $y);

  # make sure we're actually using a real font
  unless ((ref $font) eq 'GD::Font') {
    croak "The title font you specified isn\'t a GD Font object";
  }

  # get the height and width of the font
  ($h, $w) = ($font->height, $font->width);

  # split the title into lines
  @lines = split (/\\n/, $self->{'title'});

  # write the first line
  $x = ($self->{'curr_x_max'} - $self->{'curr_x_min'}) / 2
         + $self->{'curr_x_min'} - (length($lines[0]) * $w) /2;
  $y = $self->{'curr_y_min'} + $self->{'text_space'};
  $self->{'gd_obj'}->string($font, $x, $y, $lines[0], $color);

  # now loop through the rest of them
  for (1..$#lines) {
    $self->{'curr_y_min'} += $self->{'text_space'} + $h;
    $x = ($self->{'curr_x_max'} - $self->{'curr_x_min'}) / 2
           + $self->{'curr_x_min'} - (length($lines[$_]) * $w) /2;
    $y = $self->{'curr_y_min'} + $self->{'text_space'};
    $self->{'gd_obj'}->string($font, $x, $y, $lines[$_], $color);
  }

  # mark off that last space
  $self->{'curr_y_min'} += 2 * $self->{'text_space'} + $h;

  # and return
  return 1;
}


##  pesky backwards-compatible sub
sub _draw_sub_title {
  my $self = shift;
  my $font = $self->{'sub_title_font'};
  my $color = $self->_color_role_to_index('text');
  my $text = $self->{'sub_title'};
  my ($h, $w, $x, $y);

  # make sure we're using a real font
  unless ((ref ($font)) eq 'GD::Font') {
    croak "The subtitle font you specified isn\'t a GD Font object";
  }

  # get the size of the font
  ($h, $w) = ($font->height, $font->width);

  # figure out the placement
  $x = ($self->{'curr_x_max'} - $self->{'curr_x_min'}) / 2
         + $self->{'curr_x_min'} - (length($text) * $w) / 2;
  $y = $self->{'curr_y_min'}; 
  
  # now draw the subtitle
  $self->{'gd_obj'}->string ($font, $x, $y, $text, $color);

  # and return
  return 1;
}


##  sort the data nicely (mostly for the pareto charts)
sub _sort_data {

}


##  find good values for the minimum and maximum y-value on the chart
sub _find_y_scale {
  my $self = shift;
  my $data = $self->{'dataref'};
#   my ($i, $j, $max, $min);
  my ($order, $mult, $tmp);
  my ($range, $delta, @dec, $y_ticks);
  my $labels = [];
  my $length = 0;

## Handle data lying outside of -999999999999 to 999999999999
## Completely ignore missing data.
## Simplify loops.
## Put range finding in a separate method for overriding.
#   # use realy improbable starting max and min values
#   $max = -999999999999;
#   $min = 999999999999;
# 
#   # get the real max and min values
#   for $i (1..$#{$data}) {
#     for $j (0..$#{$data->[$i]}) {
#       if ($data->[$i][$j] > $max) {
# 	$max = $data->[$i][$j];
#       }
#       if ($data->[$i][$j] < $min) {
#         # skip undefined values, for these are 'no data' values
#         if (defined($data->[$i][$j])) {
#           $min = $data->[$i][$j];
#         }
#       }
#     }
#   }

  my ($min, $max) = $self->_find_y_range();

  # calculate good max_val
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

  # now go for a good min_val
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

  # put min_val and max_val into the object unless they're already there
  unless (defined ($self->{'max_val'})) {
    $self->{'max_val'} = $max;
  }
  unless (defined ($self->{'min_val'})) {
    $self->{'min_val'} = $min;
  }

  # find the range of the y-axis, modify the number of y-ticks
  # if they asked for integer ticks only
  $range = $self->{'max_val'} - $self->{'min_val'};
  $y_ticks = $self->{'y_ticks'} - 1;
  ## Don't adjust y_ticks if the user specified custom labels
  if ($self->{'integer_ticks_only'} =~ /^true$/i && ! $self->{'y_tick_labels'}) {
    unless (($range % $y_ticks) == 0) {
      while (($range % $y_ticks) != 0) {
	$y_ticks++;
      }
      $self->{'y_ticks'} = $y_ticks + 1;
    }
  }

## Allow custom y_tick_labels, see below.
#   # generate the y-tick labels, find the longest one
#   $delta = $range / $y_ticks;
#   for (0..$y_ticks) {
#     $tmp = $self->{'min_val'} + ($delta * $_);
#     @dec = split /\./, $tmp;
#     if ($dec[1] && (length($dec[1]) > 3)) {
#       $tmp = sprintf("%.3f", $tmp);
#     }
#     $labels->[$_] = $tmp;
#     if (length($tmp) > $length) {
#       $length = length($tmp);
#     }
#   }

  $labels = $self->{'y_tick_labels'};
  unless ( $labels ) { 
    # generate the y-tick labels, find the longest one
    $delta = $range / $y_ticks;
    for (0..$y_ticks) {
      $tmp = $self->{'min_val'} + ($delta * $_);
      @dec = split /\./, $tmp;
      if ($dec[1] && (length($dec[1]) > 3)) {
        $tmp = sprintf("%.3f", $tmp);
      }
      $labels->[$_] = $tmp;
    }
  }
  else { # custom y tick labels
    croak "Need $self->{'y_ticks'} y_tick_labels, got " . scalar(@$labels) . "\n"
      unless @$labels == $self->{'y_ticks'};
   
  }
#  for my $label ( @$labels ) {
#    if (length($label) > $length) {
#      $length = length($label);
#    }
#  }
  for my $label ( @$labels ) {
    if (length($self->{f_y_tick}->($label)) > $length) {
      $length = length($self->{f_y_tick}->($label));
    }
  }

  # store it in the object
  $self->{'y_tick_labels'} = $labels;
  $self->{'y_tick_label_length'} = $length;
 
  # and return
  return 1;
}

sub _find_y_range {
  my $self = shift;
  my $data = $self->{'dataref'};

  my $max = undef;
  my $min = undef;
  for my $dataset ( @$data[1..$#$data] ) {
    for my $datum ( @$dataset ) {
      if ( defined $datum ) {
## Prettier, but probably slower:
#         $max = $datum unless defined $max && $max >= $datum;
#         $min = $datum unless defined $min && $min <= $datum;
        if ( defined $max ) {
          if ( $datum > $max ) { $max = $datum }
          elsif ( $datum < $min ) { $min = $datum }
        }
        else { $min = $max = $datum }
      }
    }
  }
  ($min, $max);
}

## main sub that controls all the plotting of the actual chart
sub _plot {
  my $self = shift;

  # draw the legend first
  $self->_draw_legend;

  # mark off the graph_border space
  $self->{'curr_x_min'} += $self->{'graph_border'};
  $self->{'curr_x_max'} -= $self->{'graph_border'};
  $self->{'curr_y_min'} += $self->{'graph_border'};
  $self->{'curr_y_max'} -= $self->{'graph_border'};

  # draw the x- and y-axis labels
  $self->_draw_x_label if $self->{'x_label'};
  $self->_draw_y_label('left') if $self->{'y_label'};
  $self->_draw_y_label('right') if $self->{'y_label2'};

  # draw the ticks and tick labels
  $self->_draw_ticks;

  # give the plot a grey background if they want it
  $self->_grey_background if ($self->{'grey_background'} =~ /^true$/i);

  $self->_draw_grid_lines if ($self->{'grid_lines'} =~ /^true$/i);
  $self->_draw_x_grid_lines if ($self->{'x_grid_lines'} =~ /^true$/i);
  $self->_draw_y_grid_lines if ($self->{'y_grid_lines'} =~ /^true$/i);
  $self->_draw_y2_grid_lines if ($self->{'y2_grid_lines'} =~ /^true$/i);

  # plot the data
  $self->_draw_data();

  # and return
  return 1;
}


##  let them know what all the pretty colors mean
sub _draw_legend {
  my $self = shift;
  my ($length);

  # check to see if legend type is none..
  if ($self->{'legend'} =~ /^none$/) {
    return 1;
  }
  # check to see if they have as many labels as datasets,
  # warn them if not
  if (($#{$self->{'legend_labels'}} >= 0) && 
       ((scalar(@{$self->{'legend_labels'}})) != $self->{'num_datasets'})) {
    carp "The number of legend labels and datasets doesn\'t match";
  }

  # init a field to store the length of the longest legend label
  unless ($self->{'max_legend_label'}) {
    $self->{'max_legend_label'} = 0;
  }

  # fill in the legend labels, find the longest one
  for (1..$self->{'num_datasets'}) {
    unless ($self->{'legend_labels'}[$_-1]) {
      $self->{'legend_labels'}[$_-1] = "Dataset $_";
    }
    $length = length($self->{'legend_labels'}[$_-1]);
    if ($length > $self->{'max_legend_label'}) {
      $self->{'max_legend_label'} = $length;
    }
  }
      
  # different legend types
  if ($self->{'legend'} eq 'bottom') {
    $self->_draw_bottom_legend;
  }
  elsif ($self->{'legend'} eq 'right') {
    $self->_draw_right_legend;
  }
  elsif ($self->{'legend'} eq 'left') {
    $self->_draw_left_legend;
  }
  elsif ($self->{'legend'} eq 'top') {
    $self->_draw_top_legend;
  } else {
    carp "I can't put a legend there\n";
  }

  # and return
  return 1;
}


## put the legend on the bottom of the chart
sub _draw_bottom_legend {
  my $self = shift;
  my @labels = @{$self->{'legend_labels'}};
  my ($x1, $y1, $x2, $x3, $y2, $empty_width, $max_label_width, $cols, $rows, $color, $brush);
  my ($col_width, $row_height, $r, $c, $index, $x, $y, $w, $h);
  my $font = $self->{'legend_font'};

  # make sure we're using a real font
  unless ((ref ($font)) eq 'GD::Font') {
    croak "The subtitle font you specified isn\'t a GD Font object";
  }

  # get the size of the font
  ($h, $w) = ($font->height, $font->width);

  # find the base x values
  $x1 = $self->{'curr_x_min'} + $self->{'graph_border'}
          + ($self->{'y_tick_label_length'} * $self->{'tick_label_font'}->width)
	  + $self->{'tick_len'} + (3 * $self->{'text_space'});
  $x2 = $self->{'curr_x_max'} - $self->{'graph_border'};
  if ($self->{'y_label'}) {
    $x1 += $self->{'label_font'}->height + 2 * $self->{'text_space'};
  }
  if ($self->{'y_label2'}) {
    $x2 -= $self->{'label_font'}->height + 2 * $self->{'text_space'};
  }

  # figure out how wide the columns need to be, and how many we
  # can fit in the space available
  $empty_width = ($x2 - $x1) - (2 * $self->{'legend_space'});
  $max_label_width = $self->{'max_legend_label'} * $w
    + (4 * $self->{'text_space'}) + $self->{'legend_example_size'};
  $cols = int ($empty_width / $max_label_width);
  unless ($cols) {
    $cols = 1;
  }
  $col_width = $empty_width / $cols;

  # figure out how many rows we need, remember how tall they are
  $rows = int ($self->{'num_datasets'} / $cols);
  unless (($self->{'num_datasets'} % $cols) == 0) {
    $rows++;
  }
  unless ($rows) {
    $rows = 1;
  }
  $row_height = $h + $self->{'text_space'};

  # box the legend off
  $y1 = $self->{'curr_y_max'} - $self->{'text_space'}
          - ($rows * $row_height) - (2 * $self->{'legend_space'});
  $y2 = $self->{'curr_y_max'};
  $self->{'gd_obj'}->rectangle($x1, $y1, $x2, $y2, 
                               $self->_color_role_to_index('misc'));
  $x1 += $self->{'legend_space'} + $self->{'text_space'};
  $x2 -= $self->{'legend_space'};
  $y1 += $self->{'legend_space'} + $self->{'text_space'};
  $y2 -= $self->{'legend_space'} + $self->{'text_space'};

  # draw in the actual legend
  for $r (0..$rows-1) {
    for $c (0..$cols-1) {
      $index = ($r * $cols) + $c;  # find the index in the label array
      if ($labels[$index]) {
	# get the color
        $color = $self->_color_role_to_index('dataset'.$index); 

        # get the x-y coordinate for the start of the example line
	$x = $x1 + ($col_width * $c);
        $y = $y1 + ($row_height * $r) + $h/2;
	
	# now draw the example line
        $self->{'gd_obj'}->line($x, $y, 
                                $x + $self->{'legend_example_size'}, $y,
                                $color);

        # reset the brush for points
        $brush = $self->_prepare_brush($color, 'point',
				$self->{'pointStyle' . $_});
        $self->{'gd_obj'}->setBrush($brush);
        # draw the point
        $self->{'gd_obj'}->line(int(($x3+$x2)/2), $y2,
	  	int(($x3+$x2)/2), $y2, gdBrushed);

        # adjust the x-y coordinates for the start of the label
	$x += $self->{'legend_example_size'} + (2 * $self->{'text_space'});
	$y -= $h/2;

	# now draw the label
	$self->{'gd_obj'}->string($font, $x, $y, $labels[$index], $color);
      }
    }
  }

  # mark off the space used
  $self->{'curr_y_max'} -= ($rows * $row_height) + $self->{'text_space'}
			      + (2 * $self->{'legend_space'}); 

  # now return
  return 1;
}


## put the legend on the right of the chart
sub _draw_right_legend {
  my $self = shift;
  my @labels = @{$self->{'legend_labels'}};
  my ($x1, $x2, $x3, $y1, $y2, $width, $color, $misccolor, $w, $h, $brush);
  my $font = $self->{'legend_font'};
 
  # make sure we're using a real font
  unless ((ref ($font)) eq 'GD::Font') {
    croak "The subtitle font you specified isn\'t a GD Font object";
  }

  # get the size of the font
  ($h, $w) = ($font->height, $font->width);

  # get the miscellaneous color
  $misccolor = $self->_color_role_to_index('misc');

  # find out how wide the largest label is
  $width = (2 * $self->{'text_space'})
    + ($self->{'max_legend_label'} * $w)
    + $self->{'legend_example_size'}
    + (2 * $self->{'legend_space'});

  # get some starting x-y values
  $x1 = $self->{'curr_x_max'} - $width;
  $x2 = $self->{'curr_x_max'};
  $y1 = $self->{'curr_y_min'} + $self->{'graph_border'} ;
  $y2 = $self->{'curr_y_min'} + $self->{'graph_border'} + $self->{'text_space'}
          + ($self->{'num_datasets'} * ($h + $self->{'text_space'}))
	  + (2 * $self->{'legend_space'});

  # box the legend off
  $self->{'gd_obj'}->rectangle ($x1, $y1, $x2, $y2, $misccolor);

  # leave that nice space inside the legend box
  $x1 += $self->{'legend_space'};
  $y1 += $self->{'legend_space'} + $self->{'text_space'};

  # now draw the actual legend
  for (0..$#labels) {
    # get the color
    $color = $self->_color_role_to_index('dataset'.$_);

    # find the x-y coords
    $x2 = $x1;
    $x3 = $x2 + $self->{'legend_example_size'};
    $y2 = $y1 + ($_ * ($self->{'text_space'} + $h)) + $h/2;

    # do the line first
    $self->{'gd_obj'}->line ($x2, $y2, $x3, $y2, $color);

    # reset the brush for points
    $brush = $self->_prepare_brush($color, 'point',
				$self->{'pointStyle' . $_});
    $self->{'gd_obj'}->setBrush($brush);
    # draw the point
    $self->{'gd_obj'}->line(int(($x3+$x2)/2), $y2,
				int(($x3+$x2)/2), $y2, gdBrushed);

    # now the label
    $x2 = $x3 + (2 * $self->{'text_space'});
    $y2 -= $h/2;
    $self->{'gd_obj'}->string ($font, $x2, $y2, $labels[$_], $color);
  }

  # mark off the used space
  $self->{'curr_x_max'} -= $width;

  # and return
  return 1;
}


## put the legend on top of the chart
sub _draw_top_legend {
  my $self = shift;
  my @labels = @{$self->{'legend_labels'}};
  my ($x1, $y1, $x2, $x3, $y2, $empty_width, $max_label_width, $cols, $rows, $color, $brush);
  my ($col_width, $row_height, $r, $c, $index, $x, $y, $w, $h);
  my $font = $self->{'legend_font'};

  # make sure we're using a real font
  unless ((ref ($font)) eq 'GD::Font') {
    croak "The subtitle font you specified isn\'t a GD Font object";
  }

  # get the size of the font
  ($h, $w) = ($font->height, $font->width);

  # get some base x coordinates
  $x1 = $self->{'curr_x_min'} + $self->{'graph_border'}
          + $self->{'y_tick_label_length'} * $self->{'tick_label_font'}->width
	  + $self->{'tick_len'} + (3 * $self->{'text_space'});
  $x2 = $self->{'curr_x_max'} - $self->{'graph_border'};
  if ($self->{'y_label'}) {
    $x1 += $self->{'label_font'}->height + 2 * $self->{'text_space'};
  }
  if ($self->{'y_label2'}) {
    $x2 -= $self->{'label_font'}->height + 2 * $self->{'text_space'};
  }

  # figure out how wide the columns can be, and how many will fit
  $empty_width = ($x2 - $x1) - (2 * $self->{'legend_space'});
  $max_label_width = (4 * $self->{'text_space'})
    + ($self->{'max_legend_label'} * $w)
    + $self->{'legend_example_size'};
  $cols = int ($empty_width / $max_label_width);
  unless ($cols) {
    $cols = 1;
  }
  $col_width = $empty_width / $cols;

  # figure out how many rows we need and remember how tall they are
  $rows = int ($self->{'num_datasets'} / $cols);
  unless (($self->{'num_datasets'} % $cols) == 0) {
    $rows++;
  }
  unless ($rows) {
    $rows = 1;
  }
  $row_height = $h + $self->{'text_space'};

  # box the legend off
  $y1 = $self->{'curr_y_min'};
  $y2 = $self->{'curr_y_min'} + $self->{'text_space'}
          + ($rows * $row_height) + (2 * $self->{'legend_space'});
  $self->{'gd_obj'}->rectangle($x1, $y1, $x2, $y2, 
                               $self->_color_role_to_index('misc'));

  # leave some space inside the legend
  $x1 += $self->{'legend_space'} + $self->{'text_space'};
  $x2 -= $self->{'legend_space'};
  $y1 += $self->{'legend_space'} + $self->{'text_space'};
  $y2 -= $self->{'legend_space'} + $self->{'text_space'};

  # draw in the actual legend
  for $r (0..$rows-1) {
    for $c (0..$cols-1) {
      $index = ($r * $cols) + $c;  # find the index in the label array
      if ($labels[$index]) {
	# get the color
        $color = $self->_color_role_to_index('dataset'.$index); 
        
	# find the x-y coords
	$x = $x1 + ($col_width * $c);
        $y = $y1 + ($row_height * $r) + $h/2;

	# draw the line first
        $self->{'gd_obj'}->line($x, $y, 
                                $x + $self->{'legend_example_size'}, $y,
                                $color);

        # reset the brush for points
        $brush = $self->_prepare_brush($color, 'point',
				$self->{'pointStyle' . $_});
        $self->{'gd_obj'}->setBrush($brush);
        # draw the point
        $self->{'gd_obj'}->line(int(($x3+$x2)/2), $y2,
	  	int(($x3+$x2)/2), $y2, gdBrushed);

        # now the label
	$x += $self->{'legend_example_size'} + (2 * $self->{'text_space'});
	$y -= $h/2;
	$self->{'gd_obj'}->string($font, $x, $y, $labels[$index], $color);
      }
    }
  }
      
  # mark off the space used
  $self->{'curr_y_min'} += ($rows * $row_height) + $self->{'text_space'}
			      + 2 * $self->{'legend_space'}; 

  # now return
  return 1;
}


## put the legend on the left of the chart
sub _draw_left_legend {
  my $self = shift;
  my @labels = @{$self->{'legend_labels'}};
  my ($x1, $x2, $x3, $y1, $y2, $width, $color, $misccolor, $w, $h, $brush);
  my $font = $self->{'legend_font'};
 
  # make sure we're using a real font
  unless ((ref ($font)) eq 'GD::Font') {
    croak "The subtitle font you specified isn\'t a GD Font object";
  }

  # get the size of the font
  ($h, $w) = ($font->height, $font->width);

  # get the miscellaneous color
  $misccolor = $self->_color_role_to_index('misc');

  # find out how wide the largest label is
  $width = (2 * $self->{'text_space'})
    + ($self->{'max_legend_label'} * $w)
    + $self->{'legend_example_size'}
    + (2 * $self->{'legend_space'});

  # get some base x-y coordinates
  $x1 = $self->{'curr_x_min'};
  $x2 = $self->{'curr_x_min'} + $width;
  $y1 = $self->{'curr_y_min'} + $self->{'graph_border'} ;
  $y2 = $self->{'curr_y_min'} + $self->{'graph_border'} + $self->{'text_space'}
          + ($self->{'num_datasets'} * ($h + $self->{'text_space'}))
	  + (2 * $self->{'legend_space'});

  # box the legend off
  $self->{'gd_obj'}->rectangle ($x1, $y1, $x2, $y2, $misccolor);

  # leave that nice space inside the legend box
  $x1 += $self->{'legend_space'};
  $y1 += $self->{'legend_space'} + $self->{'text_space'};

  # now draw the actual legend
  for (0..$#labels) {
    # get the color
    $color = $self->_color_role_to_index('dataset'.$_);

    # find the x-y coords
    $x2 = $x1;
    $x3 = $x2 + $self->{'legend_example_size'};
    $y2 = $y1 + ($_ * ($self->{'text_space'} + $h)) + $h/2;

    # do the line first
    $self->{'gd_obj'}->line ($x2, $y2, $x3, $y2, $color);

    # reset the brush for points
    $brush = $self->_prepare_brush($color, 'point',
				$self->{'pointStyle' . $_});
    $self->{'gd_obj'}->setBrush($brush);
    # draw the point
    $self->{'gd_obj'}->line(int(($x3+$x2)/2), $y2,
				int(($x3+$x2)/2), $y2, gdBrushed);
    
    # now the label
    $x2 = $x3 + (2 * $self->{'text_space'});
    $y2 -= $h/2;
    $self->{'gd_obj'}->string ($font, $x2, $y2, $labels[$_], $color);
  }

  # mark off the used space
  $self->{'curr_x_min'} += $width;

  # and return
  return 1;
}


## draw the label for the x-axis
sub _draw_x_label {
  my $self = shift;
  my $label = $self->{'x_label'};
  my $font = $self->{'label_font'};
  my $color = $self->_color_role_to_index('text');
  my ($h, $w, $x, $y);

  # make sure it's a real GD Font object
  unless ((ref ($font)) eq 'GD::Font') {
    croak "The x-axis label font you specified isn\'t a GD Font object";
  }

  # get the size of the font
  ($h, $w) = ($font->height, $font->width);

  # make sure it goes in the right place
  $x = ($self->{'curr_x_max'} - $self->{'curr_x_min'}) / 2
         + $self->{'curr_x_min'} - (length($label) * $w) / 2;
  $y = $self->{'curr_y_max'} - ($self->{'text_space'} + $h);

  # now write it
  $self->{'gd_obj'}->string ($font, $x, $y, $label, $color);

  # mark the space written to as used
  $self->{'curr_y_max'} -= $h + 2 * $self->{'text_space'};

  # and return
  return 1;
}


## draw the label for the y-axis
sub _draw_y_label {
  my $self = shift;
  my $side = shift;
  my $font = $self->{'label_font'};
  my ($label, $h, $w, $x, $y, $color);

  # get the label
  if ($side eq 'left') {
    $label = $self->{'y_label'};
    $color = $self->_color_role_to_index('y_label');
  }
  elsif ($side eq 'right') {
    $label = $self->{'y_label2'};
    $color = $self->_color_role_to_index('y_label2');
  }

  # make sure it's a real GD Font object
  unless ((ref ($font)) eq 'GD::Font') {
    croak "The x-axis label font you specified isn\'t a GD Font object";
  }

  # get the size of the font
  ($h, $w) = ($font->height, $font->width);

  # make sure it goes in the right place
  if ($side eq 'left') {
    $x = $self->{'curr_x_min'} + $self->{'text_space'};
  }
  elsif ($side eq 'right') {
    $x = $self->{'curr_x_max'} - $self->{'text_space'} - $h;
  }
  $y = ($self->{'curr_y_max'} - $self->{'curr_y_min'}) / 2
         + $self->{'curr_y_min'} + (length($label) * $w) / 2;

  # write it
  $self->{'gd_obj'}->stringUp($font, $x, $y, $label, $color);

  # mark the space written to as used
  if ($side eq 'left') {
    $self->{'curr_x_min'} += $h + 2 * $self->{'text_space'};
  }
  elsif ($side eq 'right') {
    $self->{'curr_x_max'} -= $h + 2 * $self->{'text_space'};
  }

  # now return
  return 1;
}


## draw the ticks and tick labels
sub _draw_ticks {
  my $self = shift;

  # draw the x ticks
  $self->_draw_x_ticks;

  # now the y ticks
  $self->_draw_y_ticks;

  # then return
  return 1;
}


## draw the x-ticks and their labels
sub _draw_x_ticks {
  my $self = shift;
  my $data = $self->{'dataref'};
  my $font = $self->{'tick_label_font'};
  my $textcolor = $self->_color_role_to_index('text');
  my $misccolor = $self->_color_role_to_index('misc');

  my ($h, $w);
  my ($x1, $x2, $y1, $y2);
  my ($width, $delta);
  my ($stag);

  $self->{'grid_data'}->{'x'} = [];

  # make sure we got a real font
  unless ((ref $font) eq 'GD::Font') {
    croak "The tick label font you specified isn\'t a GD Font object";
  }

  # get the height and width of the font
  ($h, $w) = ($font->height, $font->width);

  # allow for the amount of space the y-ticks will push the
  # axes over to the right
## _draw_y_ticks allows 3 * text_space, not 1 * ;  this caused mismatch between
## the ticks (and grid lines) and the data.
#   $x1 = $self->{'curr_x_min'} + ($w * $self->{'y_tick_label_length'})
#          + $self->{'text_space'} + $self->{'tick_len'};
## And, what about the right-tick space??  Only affects Composite, I guess....
  $x1 = $self->{'curr_x_min'} + ($w * $self->{'y_tick_label_length'})
         + 3 * $self->{'text_space'} + $self->{'tick_len'};
  $y1 = $self->{'curr_y_max'} - $h - $self->{'text_space'};

  # get the delta value, figure out how to draw the labels
  $width = $self->{'curr_x_max'} - $x1;
  $delta = $width / $self->{'num_datapoints'};
  if ($delta <= ($self->{'x_tick_label_length'} * $w)) {
    if ($self->{'x_ticks'} =~ /^normal$/i) {
      $self->{'x_ticks'} = 'staggered';
    }
  }
 
  # now draw the labels 
  if ($self->{'x_ticks'} =~ /^normal$/i) { # normal ticks
    if ($self->{'skip_x_ticks'}) { # draw only every nth tick and label
      for (0..int (($self->{'num_datapoints'} - 1) / $self->{'skip_x_ticks'})) {
        $x2 = $x1 + ($delta / 2) + ($delta * ($_ * $self->{'skip_x_ticks'})) 
	        - ($w*length($self->{f_x_tick}->($data->[0][$_*$self->{'skip_x_ticks'}]))) / 2;
        $self->{'gd_obj'}->string($font, $x2, $y1, 
	                          $self->{f_x_tick}->($data->[0][$_*$self->{'skip_x_ticks'}]), 
				  $textcolor);
      }     
    }
    elsif ($self->{'custom_x_ticks'}) { # draw only the ticks they wanted
      for (@{$self->{'custom_x_ticks'}}) {
        $x2 = $x1 + ($delta/2) + ($delta*$_) - ($w*length($self->{f_x_tick}->($data->[0][$_]))) / 2;
        $self->{'gd_obj'}->string($font, $x2, $y1, $self->{f_x_tick}->($data->[0][$_]), $textcolor);
      }
    }
    else {
      for (0..$self->{'num_datapoints'}-1) {
        $x2 = $x1 + ($delta/2) + ($delta*$_) - ($w*length($self->{f_x_tick}->($data->[0][$_]))) / 2;
        $self->{'gd_obj'}->string($font, $x2, $y1, $self->{f_x_tick}->($data->[0][$_]), $textcolor);
      }
    }
  }
  elsif ($self->{'x_ticks'} =~ /^staggered$/i) { # staggered ticks
    if ($self->{'skip_x_ticks'}) {
      $stag = 0;
      for (0..int(($self->{'num_datapoints'}-1)/$self->{'skip_x_ticks'})) {
        $x2 = $x1 + ($delta / 2) + ($delta * ($_ * $self->{'skip_x_ticks'})) 
	        - ($w*length($self->{f_x_tick}->($data->[0][$_*$self->{'skip_x_ticks'}]))) / 2;
        if (($stag % 2) == 1) {
          $y1 -= $self->{'text_space'} + $h;
        }
        $self->{'gd_obj'}->string($font, $x2, $y1, 
	                          $self->{f_x_tick}->($data->[0][$_*$self->{'skip_x_ticks'}]), 
				  $textcolor);
        if (($stag % 2) == 1) {
          $y1 += $self->{'text_space'} + $h;
        }
	$stag++;
      }
    }
    elsif ($self->{'custom_x_ticks'}) {
      $stag = 0;
      for (sort (@{$self->{'custom_x_ticks'}})) { # sort to make it look good
        $x2 = $x1 + ($delta/2) + ($delta*$_) - ($w*length($self->{f_x_tick}->($data->[0][$_]))) / 2;
        if (($stag % 2) == 1) {
          $y1 -= $self->{'text_space'} + $h;
        }
        $self->{'gd_obj'}->string($font, $x2, $y1, $self->{f_x_tick}->($data->[0][$_]), $textcolor);
        if (($stag % 2) == 1) {
          $y1 += $self->{'text_space'} + $h;
        }
	$stag++;
      }
    }
    else {
      for (0..$self->{'num_datapoints'}-1) {
        $x2 = $x1 + ($delta/2) + ($delta*$_) - ($w*length($self->{f_x_tick}->($data->[0][$_]))) / 2;
        if (($_ % 2) == 1) {
          $y1 -= $self->{'text_space'} + $h;
        }
        $self->{'gd_obj'}->string($font, $x2, $y1, $self->{f_x_tick}->($data->[0][$_]), $textcolor);
        if (($_ % 2) == 1) {
          $y1 += $self->{'text_space'} + $h;
        }
      }
    }
  }
  elsif ($self->{'x_ticks'} =~ /^vertical$/i) { # vertical ticks
    $y1 = $self->{'curr_y_max'} - $self->{'text_space'};
    if ($self->{'skip_x_ticks'}) {
      for (0..int(($self->{'num_datapoints'}-1)/$self->{'skip_x_ticks'})) {
        $x2 = $x1 + ($delta/2) + ($delta*($_*$self->{'skip_x_ticks'})) - $h/2;
        $y2 = $y1 - (($self->{'x_tick_label_length'} 
	              - length($self->{f_x_tick}->($data->[0][$_*$self->{'skip_x_ticks'}]))) * $w);
        $self->{'gd_obj'}->stringUp($font, $x2, $y2, 
                                    $self->{f_x_tick}->($data->[0][$_*$self->{'skip_x_ticks'}]), 
				    $textcolor);
      }
    }
    elsif ($self->{'custom_x_ticks'}) {
      for (@{$self->{'custom_x_ticks'}}) {
        $x2 = $x1 + ($delta/2) + ($delta*$_) - $h/2;
        $y2 = $y1 - (($self->{'x_tick_label_length'} - length($self->{f_x_tick}->($data->[0][$_])))
                      * $w);
        $self->{'gd_obj'}->stringUp($font, $x2, $y2, 
                                    $self->{f_x_tick}->($data->[0][$_]), $textcolor);
      }
    }
    else {
      for (0..$self->{'num_datapoints'}-1) {
        $x2 = $x1 + ($delta/2) + ($delta*$_) - $h/2;
        $y2 = $y1 - (($self->{'x_tick_label_length'} - length($self->{f_x_tick}->($data->[0][$_])))
                      * $w);
        $self->{'gd_obj'}->stringUp($font, $x2, $y2, 
                                    $self->{f_x_tick}->($data->[0][$_]), $textcolor);
      }
    }
  }
  else { # error time
    carp "I don't understand the type of x-ticks you specified";
  }

  # update the current y-max value
  if ($self->{'x_ticks'} =~ /^normal$/i) {
    $self->{'curr_y_max'} -= $h + (2 * $self->{'text_space'});
  }
  elsif ($self->{'x_ticks'} =~ /^staggered$/i) {
    $self->{'curr_y_max'} -= (2 * $h) + (3 * $self->{'text_space'});
  }
  elsif ($self->{'x_ticks'} =~ /^vertical$/i) {
    $self->{'curr_y_max'} -= ($w * $self->{'x_tick_label_length'})
                               + (2 * $self->{'text_space'});
  }

  # now plot the ticks
  $y1 = $self->{'curr_y_max'};
  $y2 = $self->{'curr_y_max'} - $self->{'tick_len'};
  if ($self->{'skip_x_ticks'}) {
    for (0..int(($self->{'num_datapoints'}-1)/$self->{'skip_x_ticks'})) {
      $x2 = $x1 + ($delta/2) + ($delta*($_*$self->{'skip_x_ticks'}));
      $self->{'gd_obj'}->line($x2, $y1, $x2, $y2, $misccolor);
      if ($self->{'grid_lines'} =~ /^true$/i 
	or $self->{'x_grid_lines'} =~ /^true$/i) {
	$self->{'grid_data'}->{'x'}->[$_] = $x2;
      }
    }
  }
  elsif ($self->{'custom_x_ticks'}) {
    for (@{$self->{'custom_x_ticks'}}) {
      $x2 = $x1 + ($delta/2) + ($delta*$_);
      $self->{'gd_obj'}->line($x2, $y1, $x2, $y2, $misccolor);
      if ($self->{'grid_lines'} =~ /^true$/i
	or $self->{'x_grid_lines'} =~ /^true$/i) {
	$self->{'grid_data'}->{'x'}->[$_] = $x2;
      }
    }
  }
  else {
    for (0..$self->{'num_datapoints'}-1) {
      $x2 = $x1 + ($delta/2) + ($delta*$_);
      $self->{'gd_obj'}->line($x2, $y1, $x2, $y2, $misccolor);
      if ($self->{'grid_lines'} =~ /^true$/i
        or $self->{'x_grid_lines'} =~ /^true$/i) {
	$self->{'grid_data'}->{'x'}->[$_] = $x2;
      }
    }
  }

  # update the current y-max value
  $self->{'curr_y_max'} -= $self->{'tick_len'};
}


##  draw the y-ticks and their labels
sub _draw_y_ticks {
  my $self = shift;
  my $side = shift || 'left';
  my $data = $self->{'dataref'};
  my $font = $self->{'tick_label_font'};
  my $textcolor = $self->_color_role_to_index('text');
  my $misccolor = $self->_color_role_to_index('misc');
  my @labels = @{$self->{'y_tick_labels'}};
  my ($w, $h);
  my ($x1, $x2, $y1, $y2);
  my ($height, $delta);
  my ($s, $f);
  
  $self->{grid_data}->{'y'} = [];
  $self->{grid_data}->{'y2'} = [];

  # make sure we got a real font
  unless ((ref $font) eq 'GD::Font') {
    croak "The tick label font you specified isn\'t a GD Font object";
  }

  # find out how big the font is
  ($w, $h) = ($font->width, $font->height);

  # figure out which ticks not to draw
  if ($self->{'min_val'} >= 0) {
    $s = 1;
    $f = $#labels;
  }
  elsif ($self->{'max_val'} <= 0) {
    $s = 0;
    $f = $#labels - 1;
  }
  else {
    $s = 0;
    $f = $#labels;
  }

  # now draw them
  if ($side eq 'right') { # put 'em on the right side of the chart
    # get the base x-y values, and the delta value
    $x1 = $self->{'curr_x_max'} - $self->{'tick_len'}
            - (3 * $self->{'text_space'})
	    - ($w * $self->{'y_tick_label_length'});
    $y1 = $self->{'curr_y_max'};
    $height = $self->{'curr_y_max'} - $self->{'curr_y_min'};
    $delta = $height / ($self->{'y_ticks'} - 1);

    # update the curr_x_max value
    $self->{'curr_x_max'} = $x1;

    # now draw the ticks
    $x2 = $x1 + $self->{'tick_len'};
    for ($s..$f) {
      $y2 = $y1 - ($delta * $_);
      $self->{'gd_obj'}->line($x1, $y2, $x2, $y2, $misccolor);
      if ($self->{grid_lines} =~ /^true$/i
	or $self->{'y2_grid_lines'} =~ /^true$/i) {
        $self->{'grid_data'}->{'y2'}->[$_] = $y2;
      }
    }
  
    # update the current x-min value
    $x1 += $self->{'tick_len'} + (2 * $self->{'text_space'});
    $y1 -= $h/2;

    # now draw the labels
    for (0..$#labels) {
      $y2 = $y1 - ($delta * $_);
      $self->{'gd_obj'}->string($font, $x1, $y2, $self->{f_y_tick}->($labels[$_]), $textcolor);
    }
  }
  elsif ($side eq 'both') { # put the ticks on the both sides
    ## left side first

    # get the base x-y values
    $x1 = $self->{'curr_x_min'} + $self->{'text_space'};
    $y1 = $self->{'curr_y_max'} - $h/2;

    # now draw the labels
    $height = $self->{'curr_y_max'} - $self->{'curr_y_min'};
    $delta = $height / ($self->{'y_ticks'} - 1);
    for (0..$#labels) {
      $y2 = $y1 - ($delta * $_);
      $x2 = $x1 + ($w * $self->{'y_tick_label_length'}) 
              - ($w * length($self->{f_y_tick}->($labels[$_])));
      $self->{'gd_obj'}->string($font, $x2, $y2, $self->{f_y_tick}->($labels[$_]), $textcolor);
    }

    # and update the current x-min value
    $self->{'curr_x_min'} += (3 * $self->{'text_space'}) 
                             + ($w * $self->{'y_tick_label_length'});
  
    # now draw the ticks (skipping the one at zero);
    $x1 = $self->{'curr_x_min'};
    $x2 = $self->{'curr_x_min'} + $self->{'tick_len'};
    $y1 += $h/2;
    for ($s..$f) {
      $y2 = $y1 - ($delta * $_);
      $self->{'gd_obj'}->line($x1, $y2, $x2, $y2, $misccolor);
      if ($self->{grid_lines} =~ /^true$/i
	or $self->{'y_grid_lines'} =~ /^true$/i) {
        $self->{'grid_data'}->{'y'}->[$_] = $y2;
      }
    }
  
    # update the current x-min value
    $self->{'curr_x_min'} += $self->{'tick_len'};

    ## now the right side
    # get the base x-y values, and the delta value
    $x1 = $self->{'curr_x_max'} - $self->{'tick_len'}
            - (3 * $self->{'text_space'})
	    - ($w * $self->{'y_tick_label_length'});
    $y1 = $self->{'curr_y_max'};
    $height = $self->{'curr_y_max'} - $self->{'curr_y_min'};
    $delta = $height / ($self->{'y_ticks'} - 1);

    # update the curr_x_max value
    $self->{'curr_x_max'} = $x1;

    # now draw the ticks (skipping the one at zero);
    $x2 = $x1 + $self->{'tick_len'};
    for ($s..$f) {
      $y2 = $y1 - ($delta * $_);
      $self->{'gd_obj'}->line($x1, $y2, $x2, $y2, $misccolor);
      if ($self->{grid_lines} =~ /^true$/i
	or $self->{'y2_grid_lines'} =~ /^true$/i) {
        $self->{'grid_data'}->{'y2'}->[$_] = $y2;
      }
    }
  
    # update the current x-min value
    $x1 += $self->{'tick_len'} + (2 * $self->{'text_space'});
    $y1 -= $h/2;

    # now draw the labels
    for (0..$#labels) {
      $y2 = $y1 - ($delta * $_);
      $self->{'gd_obj'}->string($font, $x1, $y2, $self->{f_y_tick}->($labels[$_]), $textcolor);
    }   
  }
  else { # just the left side
    # get the base x-y values
    $x1 = $self->{'curr_x_min'} + $self->{'text_space'};
    $y1 = $self->{'curr_y_max'} - $h/2;

    # now draw the labels
    $height = $self->{'curr_y_max'} - $self->{'curr_y_min'};
    $delta = $height / ($self->{'y_ticks'} - 1);
    for (0..$#labels) {
      $y2 = $y1 - ($delta * $_);
      $x2 = $x1 + ($w * $self->{'y_tick_label_length'}) 
              - ($w * length($self->{f_y_tick}->($labels[$_])));
      $self->{'gd_obj'}->string($font, $x2, $y2, $self->{f_y_tick}->($labels[$_]), $textcolor);
    }

    # and update the current x-min value
    $self->{'curr_x_min'} += (3 * $self->{'text_space'}) 
                             + ($w * $self->{'y_tick_label_length'});
  
    # now draw the ticks
    $x1 = $self->{'curr_x_min'};
    $x2 = $self->{'curr_x_min'} + $self->{'tick_len'};
    $y1 += $h/2;
    for ($s..$f) {
      $y2 = $y1 - ($delta * $_);
      $self->{'gd_obj'}->line($x1, $y2, $x2, $y2, $misccolor);
      if ($self->{'grid_lines'} =~ /^true$/i 
	or $self->{'y_grid_lines'} =~ /^true$/i) {
        $self->{'grid_data'}->{'y'}->[$_] = $y2;
      }
    }
  
    # update the current x-min value
    $self->{'curr_x_min'} += $self->{'tick_len'};
  }

  # and return
  return 1;
}


##  put a grey background on the plot of the data itself
sub _grey_background {
  my $self = shift;

  # draw it
  $self->{'gd_obj'}->filledRectangle ($self->{'curr_x_min'},
                                      $self->{'curr_y_min'},
				      $self->{'curr_x_max'},
				      $self->{'curr_y_max'},
				      $self->_color_role_to_index('grey_background'));

  # now return
  return 1;
}

# draw grid_lines 
sub _draw_grid_lines {
  my $self = shift;
  $self->_draw_x_grid_lines();
  $self->_draw_y_grid_lines();
  $self->_draw_y2_grid_lines();
  return 1;
}

sub _draw_x_grid_lines {
  my $self = shift;
  my $gridcolor = $self->_color_role_to_index('x_grid_lines');
  my ($x, $y, $i);

  foreach $x (@{ $self->{grid_data}->{'x'} }) {
    if ( defined $x) {
       $self->{gd_obj}->line(($x, $self->{'curr_y_min'} + 1), $x, ($self->{'curr_y_max'} - 1), $gridcolor);
    }
  }
  return 1;
}

sub _draw_y_grid_lines {
  my $self = shift;
  my $gridcolor = $self->_color_role_to_index('y_grid_lines');
  my ($x, $y, $i);

  # loop for y values is a little different. This is to discard the first 
  # and last values we were given - the top/bottom of the chart area.
  for ($i = 1; $i < $#{ $self->{grid_data}->{'y'} }; $i++) {
    $y = $self->{grid_data}->{'y'}->[$i];
    $self->{gd_obj}->line(($self->{'curr_x_min'} + 1), $y,  ($self->{'curr_x_max'} - 1), $y, $gridcolor);
  }
  return 1;
}

sub _draw_y2_grid_lines {
  my $self = shift;
  my $gridcolor = $self->_color_role_to_index('y2_grid_lines');
  my ($x, $y, $i);

  # loop for y2 values is a little different. This is to discard the first 
  # and last values we were given - the top/bottom of the chart area.
  for ($i = 1; $i < $#{ $self->{grid_data}->{'y2'} }; $i++) {
    $y = $self->{grid_data}->{'y2'}->[$i];
    $self->{gd_obj}->line(($self->{'curr_x_min'} + 1), $y,  ($self->{'curr_x_max'} - 1), $y, $gridcolor);
  }
  return 1;
}

##
##  set the gdBrush object to trick GD into drawing fat lines & points
##  of interesting shapes
##
##  Needed by "Lines", "Points" and "LinesPoints"
##
##  All hacked up by Richard Dice <rdice@pobox.com> Sunday 16 May 1999
##
sub _prepare_brush {

    my $self      = shift;
    my $color     = shift;
    my $type      = shift;
    my $typeStyle = shift;

    # decide what $type should be in the event that a param isn't
    # passed -- this is necessary to preserve backward compatibility
    # with apps that use this module prior to putting _prepare_brush
    # in with Base.pm
    if ( (! length($type) ) ||
         ( ! grep { $type eq $_ } ('line', 'point') ) ) {

        $typeStyle = $type;
        $type = 'line' if ref $self eq 'Chart::Lines';
        $type = 'point' if ref $self eq 'Chart::Points';
        # Chart::LinesPoints is expected to pass a $type param

    }

    my ($radius, @rgb, $brush, $white, $newcolor);

    # get the rgb values for the desired color
    @rgb = $self->{'gd_obj'}->rgb($color);

    # get the appropriate brush size
    if ($type eq 'line') {
        $radius = $self->{'brush_size'}/2;
    } elsif ($type eq 'point') {
        $radius = $self->{'pt_size'}/2;
    }

    # create the new image
    $brush = GD::Image->new ($radius*2, $radius*2);

    # get the colors, make the background transparent
    $white    = $brush->colorAllocate (255,255,255);
    $newcolor = $brush->colorAllocate (@rgb);
    $brush->transparent ($white);

    # draw the circle
    if ( $type eq 'line') {
        $brush->arc ($radius-1, $radius-1, $radius, $radius, 0, 360, $newcolor);
        $brush->fill ($radius-1, $radius-1, $newcolor);

        # RLD
        #
        # Does $brush->fill really have to be here?  Dunno... this
        # seems to be a relic from earlier code
        #
        # Note that 'line's don't benefit from a $typeStyle... yet.
        # It shouldn't be too tough to hack this in by taking advantage
        # of GD's gdStyled facility

    }

    if ( $type eq 'point' ) {
$^W = 0;
        $typeStyle = 'default'
            unless grep { $typeStyle eq $_ } ('circle', 'donut',
                                              'triangle', 'upsidedownTriangle',
                                              'square', 'hollowSquare',
                                              'fatPlus');
$^W = 1;

        my ($xc, $yc) = ($radius-1, $radius-1);

        # Note that 'default' will produce the same effect
        # as a 'circle' typeStyle
        if ( grep { $typeStyle eq $_ } ('default', 'circle', 'donut') ) {

            $brush->arc($xc, $yc, $radius, $radius, 0, 360, $newcolor);
            $brush->fill ($xc, $yc, $newcolor);

            # draw a white (and therefore transparent) circle in the middle
            # of the existing circle to make the "donut", if appropriate

            if ( $typeStyle eq 'donut' ) {
                $brush->arc($xc, $yc, int($radius/2), int($radius/2),
                            0, 360, $white);
                $brush->fill ($xc, $yc, $white);
            }
        }

        if ( grep { $typeStyle eq $_ } ('triangle', 'upsidedownTriangle' ) ){

            my $poly = new GD::Polygon;
            my $sign = ( $typeStyle eq 'triangle' ) ? 1 : (-1);
            my $z = int (0.8 * $radius); # scaling factor

            # co-ords are chosen to make an equilateral triangle

            $poly->addPt($xc,
                         $yc - ($z * $sign));
            $poly->addPt($xc + int((sqrt(3) * $z) / 2),
                         $yc + (int($z/2) * $sign));
            $poly->addPt($xc - int((sqrt(3) * $z) / 2),
                         $yc + (int($z/2) * $sign));

            $brush->filledPolygon($poly, $newcolor);
        }

        if ( $typeStyle eq 'fatPlus' ) {

            my $poly = new GD::Polygon;

            my $z = int(0.3 * $radius);

            $poly->addPt($xc +     $z, $yc + $z);
            $poly->addPt($xc + 2 * $z, $yc + $z);
            $poly->addPt($xc + 2 * $z, $yc - $z);

            $poly->addPt($xc + $z,     $yc - $z);
            $poly->addPt($xc + $z,     $yc - 2 * $z);
            $poly->addPt($xc - $z,     $yc - 2 * $z);

            $poly->addPt($xc -     $z, $yc - $z);
            $poly->addPt($xc - 2 * $z, $yc - $z);
            $poly->addPt($xc - 2 * $z, $yc + $z);

            $poly->addPt($xc - $z,     $yc + $z);
            $poly->addPt($xc - $z,     $yc + 2 * $z);
            $poly->addPt($xc + $z,     $yc + 2 * $z);
            $brush->filledPolygon($poly, $newcolor);
        }

        if ( grep { $typeStyle eq $_ } ('square', 'hollowSquare') ) {

            my $poly = new GD::Polygon;
            my $z = int (0.5 * $radius);

            $brush->filledRectangle($xc - $z, $yc - $z,
                                    $xc + $z, $yc + $z,
                                    $newcolor);

            if ( $typeStyle eq 'hollowSquare' ) {

                $z = int($z/2);

                $brush->filledRectangle($xc - $z, $yc - $z,
                                        $xc + $z, $yc + $z,
                                        $white);
            }
        }
    }

    # set the new image as the main object's brush
    return $brush;
}

#
# default tick conversion function
# This function is pointed to be $self->{f_x_tick} resp. $self->{f_y_tick}
# if the user does not provide another function
#
sub _default_f_tick {
    my $label     = shift;
    
    return $label;
}

## be a good module and return positive
1;
