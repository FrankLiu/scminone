#!/usr/bin/perl -w

package ncs::TtpParser;

use util::Strings;
use util::Files;

use vars qw(@ISA @EXPORT @EXPORT_OK);
use Exporter;
@ISA = qw(Exporter);
@EXPORT_OK = qw(
	parse get_sheet row_range col_range get_data
);

sub new
{
    my $this = {};
	$class->{'definitions'} = {};
	$class->{'values'} = {};
    bless $this;
    return $this;
}

sub setTtpFile
{
	my ($class, $ttp_file) = @_;
	$class->{'ttp_file'} = $ttp_file;
}

sub parse
{
	my ($class) = shift;
	my @lines = &read_as_array($class->{'ttp_file'});
	$class->{'ttp_content'} = @lines;
	my $is_def_block = 0;
	my $is_val_block = 0;
	my $def_name = '';
	my $val_name = '';
	foreach $line (@lines){
		chomp($line); #remove \n
		if($line =~ /^$/){ #blank line
            next;  
        }
		#print("$line");
		#parse definition block
		if($line =~ /(\w+) ::= SEQUENCE OF \{/){ #definition block start
			$is_def_block = 1;
			$def_name = $1;
			$class->{'definitions'}->{$def_name} = ();
		}
		if($is_def_block && !&isEmpty($def_name)){
			#print "$def_name : $line\n";
			push(@{$class->{'definitions'}->{$def_name}}, $line);
		}
		if($line =~ /^\}$/ && !&isEmpty($def_name)){
			$is_def_block = 0;
			$def_name = '';
		}
		#parse value block
		if($line =~ /(\w+) ::= \{/){ #value block start
			$is_val_block = 1;
			$val_name = $1;
			$class->{'values'}->{$val_name} = ();
		}
		if($is_val_block && !&isEmpty($val_name)){
			#print "$val_name : $line\n";
			push(@{$class->{'values'}->{$val_name}}, $line);
		}
		if($line =~ /^\}$/ && !&isEmpty($val_name)){ #value block end
			$is_val_block = 0;
			$val_name = '';
		}
	}
}

sub getDefinitionAsArray
{
	my ($class, $name) = @_;
	if(!exists($class->{'definitions'}->{$name})){ return (); }
	return @{$class->{'definitions'}->{$name}};
}

sub getDefinition
{
	my ($class, $name) = @_;
	my @definition = $class->getDefinitionAsArray($name);
	return "" if scalar(@definition) <= 0;
	return join("\n", @definition);
}

sub getValueAsArray
{
	my ($class, $name) = @_;
	if(!exists($class->{'values'}->{$name})){ return (); }
	return @{$class->{'values'}->{$name}};
}

sub getValue
{
	my ($class, $name) = @_;
	my @value = $class->getValueAsArray($name);
	return "" if scalar(@value) <= 0;
	return join("\n", @value);
}

sub getProp
{
	my ($class, $name) = @_;
	my @prop = $class->getValueAsArray('prop');
	foreach $p (@prop){
		if($p =~ /$name/){
			my @val = split(',', $p, 5);
			if(scalar(@val) >= 5){
				my $val = $val[4];
				#print "$val\n";
				$val =~ s/\{"//; $val =~ s/"\}\},?//; #remove {" and "}},
				return $val;
			}
		}
	}
	return "";
}

sub getTtcns
{
	my ($class) = shift;
	my @files = $class->getValueAsArray('file_ref');
	my @ttcns = ();
	foreach $file (@files){
		if($file =~ /\.ttcn/){
			my @val = split(/\,/,$file, 3);
			if(scalar(@val) >= 3){
				my $val = $val[2];
				#print "$val\n";
				$val =~ s/\{"//; $val =~ s/"\},?//; #remove {" and "}},
				#remove " and } and \\, replace \\\\ with /
				$val =~ s/\"//g; $val =~ s/\}//g; $val =~ s/\\\\/\//g; $val =~ s/^ //;
				#print "$val\n";
				push(@ttcns, $val);
			}
		}
	}
	return @ttcns;
}

sub getMakefile
{
	my ($class) = shift;
	return $class->getProp('MAKE_FILE');
}

sub getMakeCommand
{
	my ($class) = shift;
	return $class->getProp('MAKE_COMMAND');
}

sub getRootModule
{
	my ($class) = shift;
	return $class->getProp('ROOT_MODULE');
}

sub getProduct
{
	my ($class) = shift;
	return $class->getProp('PRODUCT');
}

sub getOutputDirectory
{
	my ($class) = shift;
	return $class->getProp('OUTPUT_DIRECTORY');
}
