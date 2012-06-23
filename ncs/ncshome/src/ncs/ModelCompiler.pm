#!/usr/bin/perl -w

use core::Compiler;
package ncs::ModelCompiler;
@ISA=qw(core::Compiler);

use util::Strings;
use util::Files;
use util::Arrays;

sub new
{
    my $pkg = shift;
	my $obj = $pkg->SUPER::new('ncs::ModelCompiler',('docompile'));
    bless $obj;
}

sub needCompile
{
	my $obj = shift;
	return 1;
}

sub doCompile
{
	my $obj = shift;
	
}

