use Chart::Bars;

print "1..1\n";

$g = Chart::Bars->new;
$g->add_dataset ('foo', 'bar', 'junk');
$g->add_dataset (3, 4, 9);
$g->add_dataset (8, 6, 1);
$g->add_dataset (5, 7, 2);

$g->set ('title' => 'Bar Chart');

$g->gif ("samples/bars.gif");

print "ok 1\n";

exit (0);
