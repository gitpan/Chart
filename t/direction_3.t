use Chart::Direction;

print "1..1\n";

$g = Chart::Direction->new(500,500);

$g->add_dataset(0,  100,  50, 200,  300, 350);
$g->add_dataset(30,  40,  20,  35,   45,  20);

$g->set( 'title' => 'Direction Demo',
	 'angle_interval' => 45,
         'precision' => 1,
         'arrow' => 'true',
         'point' => 'false',
	 'include_zero' => 'true',

        );

$g->png("samples/direction_3.png");

print "ok 1\n";

exit (0);

