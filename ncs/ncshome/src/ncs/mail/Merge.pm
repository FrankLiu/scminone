#!/usr/bin/perl -w

use core::Component;
package ncs::Merge;
@ISA=qw(core::Component);

use util::Strings;
use util::Files;

sub new
{
	my ($pkg,$config) = @_;
	my $obj = $pkg->SUPER::new('ncs::Merge',('merge'));
    bless {
		_MAIL_CONTENT => ()
	},$obj;
    return $obj;
}

sub merge
{
	
}
