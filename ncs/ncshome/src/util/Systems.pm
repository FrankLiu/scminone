#!/usr/bin/perl -w

package util::Systems;

use vars qw(@ISA @EXPORT @EXPORT_OK);
use Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(
	check_var check_vars
);

sub check_var
{
    my $var = shift @_;
    if(!defined($ENV{$var})){
        die("variable $var not defined!\n");
    }
    else{
        print("variable $var = $ENV{$var}\n");
    }
}

sub check_vars
{
	my (@vars) = @_;
	foreach (@vars){
		&check_var($_);
	}
}

