#!/usr/bin/perl -w

package util::Nets;

use Net::FTP;
use util::Files;
use vars qw(@ISA @EXPORT @EXPORT_OK);
use Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(
	ip
);

sub ip
{
	my ($hostname) = shift;
	my ($name,$aliases,$addrtype,$length,@addrs) = gethostbyname($hostname);
	#print "name: $name\n" ;
	my ($a , $b , $c , $d) = unpack('C4', $addrs[0]);
	#print "$a.$b.$c.$d\n" ;
	return "$a.$b.$c.$d";
}

sub ftp
{
	my ($server,$user,$password) = @_;
	my $ftp = Net::FTP->new($server) or die "Could not connect: $server\n";
	$ftp->login($user,$password) or die "Could not login with user $user.\n";
	return $ftp;
}

# please invoke after ftp
sub fls
{
	my ($ftp, $dir,$pattern,$first) = @_;
	my @result;
	$ftp->cwd("$dir");
	if($pattern){
		@result = $ftp->ls("-t $pattern");
	}
	else{
		@result = $ftp->ls("-t");
	}
	return $result[0] if $first;
	return @result;
}

sub fget
{
	my ($ftp, $src, $dst) = @_;
	$ftp->get($src,$dst) or die "Could not get file: $src\n";
}

sub fclose
{
	my $ftp = shift;
	$ftp->quit() if $ftp;
}


