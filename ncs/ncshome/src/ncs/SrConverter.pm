#!/usr/bin/perl -w

package ncs::SrConverter;

use ncs::model::Sr;

sub new
{
	my ($obj, $sr) = @_;
    bless {
		_SR => $sr
	},$obj;
    return $obj;
}

sub convert
{
	my $obj = shift;
	my $sr = $obj->{_SR};
	return {} if(!$sr);
	my $srno = $sr->{'#SR'};
	my $srfunc = $sr->{'#Function'};
	my $srhl = $sr->{'#SR Headline'};
	my $srassign = $sr->{'#Assigned to'};
	my $srstatus = $sr->{'#Status'};
	my $srod = $sr->{'#Open Date'};
	my $srcd = $sr->{'#Close Date'};
	my $srli = $sr->{'#Load Info'};
	
	my $srobj = ncs::model::Sr->new();
	$srobj->id($srno);
	$srobj->function($srfunc);
	$srobj->headline($srhl);
	$srobj->assignedto($srassign);
	$srobj->status($srstatus);
	$srobj->opendate($srod);
	$srobj->closedate($srcd);
	$srobj->loadinfo($srli);
	return $srobj;
}
