#!/usr/bin/perl -w

package util::Assert;

use vars qw(@ISA @EXPORT @EXPORT_OK);
use Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(ok fatal equal equalIgnoreCase);

my ($testnr, $maxnr, $oknr);

BEGIN { $testnr = 1; $maxnr = 36; print "$testnr..$maxnr\n"; }
sub ok ($) {
  if ($_[0]) {
    print "ok ", $testnr++, "\n";
    $oknr++;
    return 1;
  } else {
    print "not ok ", $testnr++, "\n";
    my ($package, $filename, $line) = caller;
    print "# Test failed at $filename line $line.\n";
    return undef;
  }
}

sub fatal($) {
  ok(shift) or die;
}

sub equal
{
	
}

sub equalIgnoreCase
{
	
}

