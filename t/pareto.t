use Chart::Pareto;

print "1..1\n";

$g = Chart::Pareto->new;
$g->add_dataset ('bifur', 'bofur', 'bombur', 'fili', 'kili', 'nili');
$g->add_dataset (6, 4, 9, 2, 7, 13);

$g->set ('title' => 'Pareto Chart');
$g->gif ("samples/pareto.gif");

print "ok 1\n";

exit (0);

