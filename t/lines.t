use Chart::Lines;

print "1..1\n";

$g = Chart::Lines->new;
$g->add_dataset ('foo', 'bar', 'whee', 'ding','bat');
$g->add_dataset (3, 4, 9, 10, 11);
$g->add_dataset (8, 5, 3, 4, 5);
$g->add_dataset (5, 7, 2, 10, 12);

$g->set ('title' => 'Lines Chart');
$g->set ('colors' => {'y_label' => [255,0,0], y_label2 => [0,255,0], 
	'y_grid_lines' => [127,127,0]});
$g->set ('y_label' => 'y label 1');
$g->set ('y_label2' => 'y label 2');
$g->set ('y_grid_lines' => 'true');
$g->gif ("samples/lines.gif");

print "ok 1\n";

exit (0);

