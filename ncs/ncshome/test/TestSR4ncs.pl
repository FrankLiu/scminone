#!/usr/bin/perl -w

use ncs::SR4ncs;

sub space_line
{
	print "\n\n";
}

my $sr4ncs = ncs::SR4ncs->new('WMX_CoSim_SR.xls');
my @header = $sr4ncs->headline('WMX5.0');
print "Headline for work sheet WMX5.0\n";
foreach (@header){
	print "$_\t";
}
print "\n";
sub printSr
{
	local $sr = shift;
	foreach $h (@header){
		my $elem = $sr->{$h}||"";
		print "$elem\t";
	}
}
my @srlist = $sr4ncs->srlist('WMX5.0');
print "sr list: ".scalar(@srlist)."\n";
foreach $sr (@srlist){
	&printSr($sr); print "\n";
}
&space_line();

my @srlistBy = $sr4ncs->srlistBy('WMX5.0', '#Status', ('Performed'));
print "sr list by:".scalar(@srlistBy)."\n";
foreach $sr (@srlistBy){
	&printSr($sr); print "\n";
}
&space_line();

my @srlistNot = $sr4ncs->srlistNot('WMX5.0', '#Status', ('Closed'));
print "sr list not:".scalar(@srlistNot)."\n";
foreach $sr (reverse(@srlistNot)){
	&printSr($sr); print "\n";
}
&space_line();

my @latestSrlist = $sr4ncs->latestSrlist('WMX5.0');
print "sr list latest:".scalar(@latestSrlist)."\n";
foreach $sr (reverse(@latestSrlist)){
	&printSr($sr); print "\n";
}
&space_line();

my $sr = $sr4ncs->srById('WMX5.0', 'MOTCM01321586');
print "sr MOTCM01321586: \n";
&printSr($sr); print "\n";
&space_line();

my $srMappings = $sr4ncs->srMappings4SM50();
print "sr mappings for WMX50: ".length($srMappings)."\n";
my $srMapping = $sr4ncs->srMapping('WMX5.0 CASE-SR Mapping', '3001');
print "sr mapping for 3001: $srMapping\n";
my $srMappings2 = $sr4ncs->srMappings4SM40();
print "sr mappings for WMX40: ".length($srMappings2)."\n";
my $srMapping2 = $sr4ncs->srMapping('WMX4.0 CASE-SR Mapping', '1000');
print "sr mapping for 1000: $srMapping2\n";
&space_line();

