use ExtUtils::MakeMaker;

#  make the samples directory
mkdir ('samples', 00755);

#  write the makefile
WriteMakefile ( 'NAME' => 'Chart',
		'PREREQ_PM' => { 'GD' => 0 },
		'dist' => { 'COMPRESS' => 'gzip', 'SUFFIX' => 'gz' },
		'VERSION' => '0.99' );
