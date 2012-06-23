#!/usr/bin/perl -w

package util::Strings;

use vars qw(@ISA @EXPORT @EXPORT_OK);
use Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(
	isEmpty isBlank
	isTrue isFalse
    trim ltrim rtrim lstrip rstrip 
);

sub isEmpty
{
	my $string = shift @_;
	if(!defined($string) || length($string) == 0){
		return 1;
	}
	return 0;
}

sub isBlank
{
	my $string = shift;
	return &isEmpty(&trim($string));
}

sub isTrue
{
	my $str = shift;
	if(&isEmpty($str)){ return 0; }
	if(uc($str) eq "TRUE" || uc($str) eq "YES"){ return 1;}
	return 0;
}

sub isFalse
{
	my $str = shift;
	if(&isEmpty($str)){ return 1; }
	if(uc($str) eq "FALSE" || uc($str) eq "NO"){ return 1;}
	return 0;
}

# Perl trim function to remove whitespace from the start and end of the string
sub trim
{
	my $string = shift @_;
	$string =~ s/^\s+//;
	$string =~ s/\s+$//;
	return $string;
}

# Left trim function to remove leading whitespace
sub ltrim
{
	my $string = shift @_;
	$string =~ s/^\s+//;
	return $string;
}

# Right trim function to remove trailing whitespace
sub rtrim
{
	my $string = shift @_;
	$string =~ s/\s+$//;
	return $string;
}

sub lstrip
{
	my ($string,$length, $appender) = @_;
	$appender = $appender || ' ';
	local $len = length($string);
	if($len ge $length){ return $string; }
	local $minis = $length - $len;
	return $appender x $minis.$string;
}

sub rstrip
{
	my ($string,$length, $appender) = @_;
	$appender = $appender || ' ';
	local $len = length($string);
	if($len ge $length){ return $string; }
	local $minis = $length - $len;
	return $string.$appender x $minis;
}


