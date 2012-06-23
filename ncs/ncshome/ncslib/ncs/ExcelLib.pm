#!/usr/lib/perl -w

package ncs::ExcelLib;

use warnings;
use strict;
use Spreadsheet::ParseExcel;

use vars qw(@ISA @EXPORT @EXPORT_OK);
use Exporter;
@ISA = qw(Exporter);
@EXPORT_OK = qw(
	parse get_sheet row_range col_range get_data
);

sub new
{
	my $this = {};
    my $parser = Spreadsheet::ParseExcel->new();
	$this->{'parser'} = $parser;
	bless $this;
    return $this;
}

sub parse
{
	my ($class, $filename) = @_;
	my $parser = $class->{'parser'};
	my $workbook = $parser->parse($filename);
	if(!defined $workbook){
		die "Parsing error: ", $parser->error(), ".\n";
	}
	$class->{'workbook'} = $workbook;
}

sub get_sheet
{
	my ($class, $sheetname) = @_;
	my $workbook = $class->{'workbook'} ;
	for my $worksheet ($workbook->worksheets()){
		if($sheetname eq $worksheet->get_name()){
			return $worksheet;
		}
	}
	return undef;
}

sub row_range
{
	my ($class, $sheetname) = @_;
	my $worksheet = $class->get_sheet($sheetname);
	if(!defined($worksheet)){ return (0,0);}
	return $worksheet->row_range();
}
sub col_range
{
	my ($class, $sheetname) = @_;
	my $worksheet = $class->get_sheet($sheetname);
	if(!defined($worksheet)){ return (0,0);}
	return $worksheet->col_range();
}

sub get_data
{
	my ($class, $sheetname, $row, $col) = @_;
	my $worksheet = $class->get_sheet($sheetname);
	if(!defined($worksheet)){ return ''; }
	my $cell = $worksheet->get_cell($row, $col);
	if($cell){ return $cell->value(); }
	return '';
}


1;
__END__
