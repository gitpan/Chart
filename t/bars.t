use Chart::Bars;

print "1..1\n";

$g = Chart::Bars->new;
$g->add_dataset ('foo', 'bar', 'junk', 'ding', 'bat');
$g->add_dataset (3000, 4000, 8000, 5000, 9000);
$g->add_dataset (8000, 6000, 3000, 3000, 4000);
$g->add_dataset (5000, 7000, 2020, 8000, 9000);

$g->set ('y_grid_lines' => 'true');
$g->set ('title' => 'Bar Chart');

$g->png ("samples/bars.png");

print "ok 1\n";

exit (0);
