#!/usr/bin/perl -w

use Chart::Composite;

print "1..1\n";

$g = Chart::Composite->new;

$g->add_dataset ('foo', 'bar', 'junk','whee');
$g->add_dataset (3, 4, 9,3);
$g->add_dataset (8, 6, 1,11);
$g->add_dataset (115, 115, 112.5,120.0);
$g->add_dataset (112.5, 115, 117.5,112.5);
$g->add_dataset (132.5,112.5,115,130);

$g->set ('legend' => 'bottom', 'imagemap' => 'true');
$g->set ('title' => 'Composite Chart',
	 'composite_info' => [ ['Bars', [1,2]],
	 		       ['Lines', [3,4,5]] ]);

$g->set ('y_label' => 'y label 1', 'y_label2' => 'y label 2');
#$g->set ('colors' => {'y_label' => [0,0,255], y_label2 => [0,255,0],
#	'dataset0' => [0,127,0], 'dataset1' => [0,0,127], 'dataset8', => [0,255,0],
#       'dataset9' => [ 255,0,0 ] });

$g->set (legend_labels => [ 1,2, 3, 4, 'test']);
$g->set ('png_border' => 20);
#$g->set ('max_val' => 130);
#$g->set ('min_val' => 100);
#$g->set(grey_background => 'false');


$g->png("composite.png");

#$imagemap_data = $g->imagemap_dump();
#print $imagemap_data->[0][0];
print "ok 1\n";



