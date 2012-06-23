#!/usr/bin/perl -w

package ncs::model::SrSummary;

use util::Strings;
use util::Files;

sub new
{
	my ($obj) = @_;
    bless $obj;
    return $obj;
}

sub originated
{
	my ($obj, $originated) = @_;
	if(defined($originated)){
		$obj->{ORIGINATED} = $originated;
	}
	else{
		return $obj->{ORIGINATED};
	}
}

sub assessed
{
	my ($obj, $assessed) = @_;
	if(defined($assessed)){
		$obj->{ASSESSED} = $assessed;
	}
	else{
		return $obj->{ASSESSED};
	}
}

sub study
{
	my ($obj, $study) = @_;
	if(defined($study)){
		$obj->{STUDY} = $study;
	}
	else{
		return $obj->{STUDY};
	}
}

sub performed
{
	my ($obj, $performed) = @_;
	if(defined($performed)){
		$obj->{PERFORMED} = $performed;
	}
	else{
		return $obj->{PERFORMED};
	}
}

sub closed
{
	my ($obj, $closed) = @_;
	if(defined($closed)){
		$obj->{CLOSED} = $closed;
	}
	else{
		return $obj->{CLOSED};
	}
}

sub to_str
{
	my $obj = shift;
	return "Originated[".$obj->originated()."], Assessed[".$obj->assessed()."], Study[".$obj->study()."],". 
		"Performed[".$obj->performed()."], Closed[".$obj->closed()."]";
}
