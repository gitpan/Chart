
use FileHandle;

opendir (DIR, "/usr/users/mbrandl/chart/Chart");

foreach $file (readdir(DIR)) {
  if ($file =~ /.pm$/ && $file !~ /temp.pm/) {
       $name =uc( substr ( $file,0, length($file)-3));
       open ($name, "$file") or die "kann $file nicht öffnen\n";
       push @files, $name;
       # print "$name \n"; 
   }
}

my $zeile;
my $i=0;

foreach $datei (@files) { 
open (TEMP, ">temp.pm") or die "kann temp nicht öffnen\n";
 while ($zeile = <$datei>) {
  if ($zeile =~ /\/){
    chomp $zeile;
    chomp $zeile;
    chop $zeile;
  } 
  $i++;
  print TEMP "$zeile\n";
 }
 close TEMP;

 $name = ucfirst(lc ($datei)).".pm";
 unlink $datei;
 rename "temp.pm", $name;
#print $name;
}


print "$i\n";

