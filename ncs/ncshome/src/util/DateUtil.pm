#!/usr/bin/perl -w

package util::DateUtil;
use Time::localtime;
use POSIX qw(strftime);
use util::Strings;

use vars qw(@ISA @EXPORT @EXPORT_OK);
use Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(
	format_time compare_date count_time
);

sub format_time
{
	local ($format,@time) = @_;
	if(&isEmpty($format)){ $format = "%Y-%m-%d %H:%M:%S"; }
	return strftime($format, @time);
}

sub compare_date
{
	my ($date1, $date2) = @_;
	my ($m1,$d1,$y1) = split(/[-\/]/,$date1,3);
	my ($m2,$d2,$y2) = split(/[-\/]/,$date2,3);
	#print "date1: $m1,$d1,$y1\n";
	#print "date2: $m2,$d2,$y2\n";
	if($y1 > $y2){ return 1; }
	elsif($y1 < $y2){ return -1;}
	else{#$y1=$y2
		if($m1>$m2){ return 1; }
		elsif($m1<$m2){ return -1;}
		else{ #$m1=$m2
			if($d1>$d2){ return 1; }
			elsif($d1<$d2){ return -1;}
			else{return 0;}
		}
	}
}

sub count_time
{
	my ($start_time,$end_time) = @_;
	my $spent_time = ($end_time-$start_time);
	print("spent time: $spent_time\n");
	my $spent_sec = $spent_time%60;
	my $spent_mm = $spent_time/60;
	my $spent_hr = $spent_mm >= 60 ? int($spent_mm/60) : 0;
	$spent_mm = $spent_mm >= 60 ? $spent_mm%60 : int($spent_mm);
	return ($spent_hr,$spent_mm,$spent_sec);
}
