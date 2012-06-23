#!/usr/bin/perl -w

package ncs::SR4ncs;

use vars qw(@ISA @EXPORT @EXPORT_OK);
use Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(
	headline srlist srlistBy srById
	srMappings srMappings4WMX40 srMappings4WMX50 srMapping
);
use ncs::Common;
use ncs::ExcelLib;

sub new
{
	my ($class, $excelf) = @_;
    my $this = {};
	$excelf = $excelf||'WMX_CoSim_SR.xls';
	$this->{'excel_file'} = $excelf;
	$this->{'excel'} = ncs::ExcelLib->new();
	$this->{'excel'}->parse($excelf);
    bless $this;
    return $this;
}

sub headline
{
	my ($class, $sheetname) = @_;
	my @header = ();
	my $excel = $class->{'excel'};
	my $sheet = $excel->get_sheet($sheetname);
	my ($col_min,$col_max) = $excel->col_range($sheetname);
	#print "col_range: $col_min-$col_max\n";
	for(my $i=$col_min;$i<=$col_max;$i++){
		push(@header, $excel->get_data($sheetname, 0, $i));
	}
	return @header;
}

sub srlist
{
	my ($class, $sheetname) = @_;
	my @srlist = ();
	my $excel = $class->{'excel'};
	my $sheet = $excel->get_sheet($sheetname);
	my ($row_min,$row_max) = $excel->row_range($sheetname);
	my ($col_min,$col_max) = $excel->col_range($sheetname);
	my @header = $class->headline($sheetname);
	for(my $i=$row_min+1;$i<=$row_max;$i++){ #ignore the head line
		my $line = {};
		for(my $j=$col_min;$j<=$col_max;$j++){
			my $data = $excel->get_data($sheetname, $i, $j); $data=is_empty($data)?'':trim($data);
			$line->{$header[$j]} = $data;
			#print "$header[$j] = $data\n"
		}
		push(@srlist, $line);
	}
	return @srlist;
}

sub srlistBy
{
	my ($class, $sheetname, $byType, @byVals) = @_;
	my @srlist = $class->srlist($sheetname);
	my @srListBy = ();
	foreach $sr (@srlist){
		if(&contains($sr->{$byType}, @byVals)){
			push(@srListBy, $sr);
		}
	}
	return @srListBy;
}

sub srlistNot
{
	my ($class, $sheetname, $byType, @byVals) = @_;
	my @srlist = $class->srlist($sheetname);
	my @srListBy = ();
	foreach $sr (@srlist){
		if(!&contains($sr->{$byType}, @byVals)){
			push(@srListBy, $sr);
		}
	}
	return @srListBy;
}

#get the latest day's SR list
sub latestSrlist
{
	my ($class, $sheetname) = @_;
	my @srlist = $class->srlistNot($sheetname, '#Status', ('Closed', 'Performed'));
	my @latestSrlist = ();
	foreach $sr (@srlist){
		my ($openDate,$openTime) = split(/\s+/, $sr->{'#Open Date'}, 2);
		#print "open date: $openDate\n";
		if(scalar(@latestSrlist) < 1){
			push(@latestSrlist, $sr);
			next;
		}
		my ($latestOpenDate,$latestOpenTime) = split(/\s+/, $latestSrlist[0]->{'#Open Date'}, 2);
		#print "latest open date: $latestOpenDate\n";
		my $comp_date = &compare_date($openDate,$latestOpenDate);
		if($comp_date>0){
			splice(@latestSrlist, 0, scalar(@latestSrlist), $sr);#delete all elements & insert new one
		}
		elsif($comp_date==0){
			push(@latestSrlist, $sr);
		}
		else{ #$comp_date<0
			#do nothing, just ignore the sr
		}
	}
	return @latestSrlist;
}

sub srById
{
	my ($class, $sheetname, $srid) = @_;
	my @srlist = $class->srlistBy($sheetname, '#SR', ($srid));
	if(scalar(@srlist) <=0){return {};}
	return $srlist[0];
}

sub srMappings
{
	my ($class, $sheetname) = @_;
	my @srlist = $class->srlist($sheetname);
	my $srMappings = {};
	foreach $sr (@srlist){
		my $tcno = $sr->{'#Failed Case No.'}; $tcno = is_empty($tcno)?'':trim($tcno);
		my $srno = $sr->{'#SR No.'}; $srno = is_empty($srno)?'':trim($srno);
		#print "$tcno = $srno\n";
		$srMappings->{$tcno} = $srno;
	}
	return $srMappings;
}

sub srMapping
{
	my ($class, $sheetname, $tcno) = @_;
	my $srMappings = $class->srMappings($sheetname);
	if(exists($srMappings->{$tcno})){
		return $srMappings->{$tcno};
	}
	return '';
}

#specific functions for WMX_CoSim_SR
sub srlist4SM40
{
	my ($class,$byTpe,@byVals) = @_;
	if(!is_empty($byType)){
		return $class->srlistBy('WMX4.0', $byType, @byVals);
	}
	return $class->srlist('WMX4.0');
}

sub srlist4SM50
{
	my ($class,$byTpe,@byVals) = @_;
	if(!is_empty($byType)){
		return $class->srlistBy('WMX5.0', $byType, @byVals);
	}
	return $class->srlist('WMX5.0');
}

sub srMappings4SM40
{
	my $class = shift;
	return $class->srMappings('WMX4.0 CASE-SR Mapping');
}

sub srMappings4SM50
{
	my $class = shift;
	return $class->srMappings('WMX5.0 CASE-SR Mapping');
}

sub srMappings4SFM40
{
	my $class = shift;
	return $class->srMappings('WMX4.0 SFM CASE-SR Mapping');
}


1;
__END__
