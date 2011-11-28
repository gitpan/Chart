#!/usr/bin/perl -w

use Chart::Points;

print "1..1\n";

$g = Chart::Points->new();
$g->add_dataset( 'foo', 'bar', 'junk' );
$g->add_dataset( 3,     4,     9 );
$g->add_dataset( 8,     6,     0 );
$g->add_dataset( 5,     7,     2 );

@hash = (
    'title'      => 'Points Chart',
    'type_style' => 'donut',
    'png_border' => 10,
    'pt_size'    => 18,
    'grid_lines' => 'true',

    #    'brushStyle' => 'OpenRectangle',
    #    'brushStyle' => 'OpenCircle',
    #    'brushStyle' => 'FilledCircle',
    #    'brushStyle' => 'OpenRectangle',
    'brushStyle' => 'fatPlus',
);

$g->set(@hash);

$g->png("samples/points.png");

print "ok 1\n";

exit(0);

