#!/usr/local/bin/perl

use Chart::LinesPoints;

print "1..1\n";

$g = Chart::LinesPoints->new;
$g->add_dataset ('foo', 'bar', 'junk');
$g->add_dataset (3, 4, 9);
$g->add_dataset (8, 6, 0);
$g->add_dataset (5, 7, 2);

$g->set ('title' => 'Lines and Points Chart');

$g->gif ("samples/linespoints.gif");

print "ok 1\n";

exit (0);

