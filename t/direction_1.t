use Chart::Direction;

print "1..1\n";

$g = Chart::Direction->new(500,500);

$g->add_dataset(0, 10, 30, 100, 110, 200, 250, 300, 350);
$g->add_dataset(10, 4, 11,  40,  20,  35,  5,   45,  20);

$g->set( 'title' => 'Direction Demo',
	 'grey_background' => 'false',
	 'line' => 'true',
         'precision' => 0,
#	 'pt_size' => 12,

        );

$g->png("samples/direction_1.png");

print "ok 1\n";

exit (0);

