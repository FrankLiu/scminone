#!/usr/bin/perl -w

package ncs::model::Sr;

use util::Strings;
use util::Files;

sub new
{
	my ($obj) = @_;
    bless $obj;
    return $obj;
}

sub id
{
	my ($obj, $srno) = @_;
	if(defined($srno)){
		$obj->{SRNO} = $srno;
	}
	else{
		return $obj->{SRNO};
	}
}

sub function
{
	my ($obj, $function) = @_;
	if(defined($function)){
		$obj->{FUNCTION} = $function;
	}
	else{
		return $obj->{FUNCTION};
	}
}

sub headline
{
	my ($obj, $headline) = @_;
	if(defined($headline)){
		$obj->{HEADLINE} = $headline;
	}
	else{
		return $obj->{HEADLINE};
	}
}

sub assignedto
{
	my ($obj, $assignedto) = @_;
	if(defined($assignedto)){
		$obj->{ASSIGNEDTO} = $assignedto;
	}
	else{
		return $obj->{ASSIGNEDTO};
	}
}

sub status
{
	my ($obj, $status) = @_;
	if(defined($status)){
		$obj->{STATUS} = $status;
	}
	else{
		return $obj->{STATUS};
	}
}

sub opendate
{
	my ($obj, $opendate) = @_;
	if(defined($opendate)){
		$obj->{OPENDATE} = $opendate;
	}
	else{
		return $obj->{OPENDATE};
	}
}

sub closedate
{
	my ($obj, $closedate) = @_;
	if(defined($closedate)){
		$obj->{CLOSEDATE} = $closedate;
	}
	else{
		return $obj->{CLOSEDATE};
	}
}

sub loadinfo
{
	my ($obj, $loadinfo) = @_;
	if(defined($loadinfo)){
		$obj->{LOADINFO} = $loadinfo;
	}
	else{
		return $obj->{LOADINFO};
	}
}

sub to_str
{
	
}
