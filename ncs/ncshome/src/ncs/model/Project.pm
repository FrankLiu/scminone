#!/usr/bin/perl -w

package ncs::model::Project;

use util::Strings;
use util::Files;

sub new
{
	my ($obj) = @_;
    bless $obj;
    return $obj;
}

sub label
{
	my ($obj, $label) = @_;
	if(defined($label)){
		$obj->{LABEL} = $label;
	}
	else{
		return $obj->{LABEL};
	}
}

sub passrate
{
	my ($obj, $passrate) = @_;
	if(defined($passrate)){
		$obj->{PASSRATE} = $passrate;
	}
	else{
		return $obj->{PASSRATE};
	}
}

sub failrate
{
	my ($obj, $failrate) = @_;
	if(defined($failrate)){
		$obj->{FAILRATE} = $failrate;
	}
	else{
		return $obj->{FAILRATE};
	}
}

sub isblocked
{
	my ($obj, $isblocked) = @_;
	if(defined($isblocked)){
		$obj->{ISBLOCKED} = $isblocked;
	}
	else{
		return 1 if(util::isTrue($obj->{ISBLOCKED}) || $obj->{ISBLOCKED} =~ /BLOCK/i);
		return 0;
	}
}

sub modtime
{
	my ($obj, $modtime) = @_;
	if(defined($modtime)){
		$obj->{MODTIME} = $modtime;
	}
	else{
		return $obj->{MODTIME}||&format_time("%Y-%m-%dT%H:%M:%S",localtime(time()));
	}
}

sub to_str
{
	my $obj = shift;
	return $obj->label.",BLOCK,".$obj->modtime() if $obj->isblocked();
	return $obj->label().",".$obj->passrate().",".$obj->failrate().",".$obj->modtime();
}

sub to_json
{
	my $obj = shift;
	return "{label: ".$obj->label.", block: true, modtime: ".$obj->modtime()."}" if $obj->isblocked();
	return "{label: ".$obj->label().", pass: ".$obj->passrate().", fail: ".$obj->failrate().
		", modtime: ".$obj->modtime()."}";
}

sub record
{
	my ($obj,$file) = shift;
	my $line = $obj->to_str();
	system("touch $file") if(! -e $file);
	system("echo $line >> $file");
}

