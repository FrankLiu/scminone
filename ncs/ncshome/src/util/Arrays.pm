#!/usr/bin/perl -w

package util::Arrays;
use util::Strings;

use vars qw(@ISA @EXPORT @EXPORT_OK);
use Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(
	contains save_to_file
);

#this function used for string comparation
sub contains
{
	my ($elem, @array) = @_;
	if(grep(/$elem/, @array)){ return 1;}
	foreach (@array){
		if($_ =~ /$elem/i){ return 1; }
		if(index(ucfirst($elem), ucfirst($_)) >= 0){ return 1; }
	}
	return 0;
}

sub save_to_file
{
    local ($file, @array) = @_;
	open(FILE, ">$file") || die("Cannot open file: $file");
	foreach $item (@array){
		print FILE "$item\n";
	}
    close(FILE);
}

