use Chart::Composite;

print "1..1\n";

$g = Chart::Composite->new;

$g->add_dataset ('foo', 'bar', 'junk');
$g->add_dataset (3, 4, 9);
$g->add_dataset (8, 6, 1);
$g->add_dataset (5, 7, 2);
$g->add_dataset (2, 5, 7);

$g->set ('title' => 'Composite Chart',
	 'composite_info' => [ ['Bars', [1,2]],
	 		       ['Lines', [3,4]] ]);

$g->gif("samples/composite.gif");

print "ok 1\n";

exit(0);

