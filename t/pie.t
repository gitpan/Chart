use Chart::Pie;

print "1..1\n";

$g = Chart::Pie->new;
$g->add_dataset ('foo', 'bar', 'junk');
$g->add_dataset (6, 4, 9);

$g->set ('title' => 'Pie Chart');
$g->gif ("samples/pie.gif");

print "ok 1\n";

exit (0);

