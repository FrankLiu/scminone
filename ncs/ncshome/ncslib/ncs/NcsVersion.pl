#!/usr/lib/perl -w
#
# NCS is a script built for running Cosim test suite nightly
# 

my $ncs_name = 'Nightly Cosim Script';
my $ncs_version_file = "$ENV{'NCS_HOME'}/version";

sub get_ncs_name
{
	return $ncs_name;
}

sub fromversion
{
	my $key = shift @_;
	my $line = qx{grep '$key: ' $ncs_version_file};
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
	return &fromversion('name');
}

sub get_ncs_version
{
	my $version = &get_ncs_main_version();
	my $build_version  = &get_ncs_build_version();
	return $version."-".$build_version;
}

sub get_ncs_main_version
{
	return &fromversion('version');
}

sub get_ncs_build_version
{
	return &fromversion('build');
}

sub get_ncs_release
{
	return &get_ncs_sname().&get_ncs_version();
}

our $NCS_NAME=&get_ncs_name();
our $NCS_VERSION=&get_ncs_version();
our $NCS_RELEASE=&get_ncs_release();

sub print_ncs_verbose
{
print <<EOT;
NCS($ncs_name) 
---------------------------
NCS Release: $NCS_RELEASE
NCS Version: $NCS_VERSION	
EOT
}


