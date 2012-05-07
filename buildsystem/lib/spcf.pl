my %spcf_dir = ();
my %spcf_targets = ();

sub readspcf($)
{
   my $spcf = shift;

   open(SPCF, "<$ENV{CVOB}/bld/wuce/mk/$spcf.spcf") or warn("no SPCF: $ENV{CVOB}/bld/wuce/mk/$spcf.spcf\n") and return;
   
   while (<SPCF>) {
      if (/^\s*#/ or /^\s*$/) {
         next;
      }
      
      chomp;
      my @line = split(/:/, $_);
      
      for my $i (0 .. 4) {
         push @{$spcf_targets{$line[$i]}}, $line[5];
      }
      
      #target = path
      $spcf_dir{$line[5]} = $line[6];
   
   }
   
   close(SPCF);
}

if (!exists $ENV{WUCE_APP_CFG}) {
   print STDERR "WUCE_APP_CFG must be set in the environment!\n\n";
   exit(-1);
}

#HACK?
$ENV{AC_PRODUCT} = (split /-/, $ENV{WUCE_APP_CFG})[1];
readspcf($ENV{AC_PRODUCT});
