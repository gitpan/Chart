#!/usr/local/bin/perl

use Chart::StackedBars;

print "1..1\n";

$g = Chart::StackedBars->new;
$g->add_dataset ('foo', 'bar', 'junk');
$g->add_dataset (3, 4, 9);
$g->add_dataset (8, 6, 1);
$g->add_dataset (5, 7, 2);

$g->set ('title' => 'Stacked Bar Chart');

$g->gif ("samples/stackedbars.gif");

print "ok 1\n";

exit (0);
