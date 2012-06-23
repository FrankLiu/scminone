#!/usr/bin/perl -w

package ncs::Version;

use util::Strings;
use util::Files;

sub new
{
    my $this = {};
	$this->{'ncs_version_file'} = "$ENV{'NCS_HOME'}/version";
    bless $this;
    return $this;
}

sub get_ncs_name
{
	my $obj = shift;
	my $ncs_name = qx{cat $obj->{'ncs_version_file'} | head -1};
	chomp($ncs_name);
	return $ncs_name;
}

sub _fromversion
{
	my ($obj,$key) = @_;
	my $line = qx{grep '$key: ' $obj->{'ncs_version_file'}};
	my @pair = split(/:/, $line);
	my $value = $pair[1];
	my $cur_date = qx{date +%Y%m%d};
	$value =~ s/%BLDREV%/$cur_date/;
	$value  =~ s/^\s+//;
	$value  =~ s/\s+$//;
	return $value;
}

sub get_ncs_sname
{
	my $obj = shift;
	return $obj->_fromversion('name');
}

sub get_ncs_main_version
{
	my $obj = shift;
	return $obj->_fromversion('version');
}

sub get_ncs_build_version
{
	my $obj = shift;
	return $obj->_fromversion('build');
}

sub get_ncs_version
{
	my $obj = shift;
	my $version = $obj->get_ncs_main_version();
	my $build_version  = $obj->get_ncs_build_version();
	return $version."-".$build_version;
}

sub get_ncs_release
{
	my $obj = shift;
	return $obj->get_ncs_sname().$obj->get_ncs_version();
}

sub print_ncs_version
{
	my $obj = shift;
	print $obj->get_ncs_version()."\n";
}

sub print_ncs_verbose
{
	my $obj = shift;
	my $ncs_name = $obj->get_ncs_name();
	my $ncs_release = $obj->get_ncs_release();
	my $ncs_version = $obj->get_ncs_version();
print <<EOT;
NCS($ncs_name) 
---------------------------
Release: $ncs_release
Version: $ncs_version	
EOT
}

1;
__END__
