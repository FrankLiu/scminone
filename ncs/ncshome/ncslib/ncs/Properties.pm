#!/usr/bin/perl -w

package ncs::Properties;

use vars qw(@ISA @EXPORT @EXPORT_OK);
use Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(load get set merge merge_with_file);

use ncs::Common;

sub new
{
    my $this = {};
    $this->{'properties_file'} = 'ncs_default.properties';
    $this->{'properties'} = {};
    bless $this;
    return $this;
}

sub load
{
    my ($class, $properties_file, $keep_escape) = @_;
    if (!defined($properties_file) || $properties_file eq ""){ 
        $properties_file = "ncs.properties";
    }
    $class->{'properties_file'} = $properties_file;
    my $k = $v = "";
	my $is_multiline = 0;
    open(PROPFILE, "<$properties_file") || die("Cannot open properties file $properties_file");
    while($line = <PROPFILE>){
		$line = trim($line);
        #space line or commentted line will be ignored
        if($line =~ /^$/ || $line =~ /^#/){ 
            next;  
        }
		if($line =~ /\\$/){ #end with \
			$line =~ s/\\$//;
			if($is_multiline){ #not first line,not end line
				$v = $v.' '.$line;
			}
			else{ #first line
				($k,$v) = split("=", $line, 2);
				$is_multiline = 1;
			}
			next;
		}
		if($is_multiline){
			#print "is multiline: $is_multiline\n";
			#print "$line\n";
			$v = $v.' '.$line;
			if($line =~ /[^\\]$/){ #end line
				$class->{'properties'}->{trim($k)} = trim($v);
				#print "$k=$v\n";
				$k = $v = "";
				$is_multiline = 0;
			}
			next;
		}
        ($k,$v) = split("=", $line, 2);
        if(trim($k) eq ""){
            next;
        }
        #print("$k=$v");
        $class->{'properties'}->{trim($k)} = trim($v);
		$k = $v = "";
    }
    close(PROPFILE);
	my $import = $class->get("ncs.import");
	$import = $class->unescapeProperty("ncs.import", $import) if $import;
	if(-e $import){
		print("found import properties: $import\n");
		$class->merge_with_file($import);
	}
	$class->unescapeProperties() if !$keep_escape;
    return $class->{'properties'};
}

sub unescapeProperty
{
    my ($class, $k, $v) = @_;
    if(!defined($v) || $v =~ /^\s*$/){ 
        return;
    }
    
    while($v =~ /^(.*)\${([^}]+)}(.*)$/){ #match ${ncs.log.dir}
        my $prefix = (defined($1) ? $1 : "");
        my $matched = $2;
        my $suffix = (defined($3) ? $3 : "");
        #print("matched key: $matched\n");
        if(!exists($class->{'properties'}->{$matched})){
			warn("[warn] matched key not exists: $matched");
			last;
		}
		#matched key exits
		#print("$matched=".$class->{'properties'}->{$matched}."\n");
		$class->{'properties'}->{$k} = $prefix.$class->{'properties'}->{$matched}.$suffix;
		$v = $class->{'properties'}->{$k};
    }
    
    while($v =~ /^(.*)(\$ENV{[^}]+})(.*)$/){ #match $ENV{HOME}
        my $prefix = (defined($1) ? $1 : "");
        my $matched = $2;
        my $suffix = (defined($3) ? $3 : "");
		#print("matched env: $matched\n");
        $matched = eval($matched) || '';
		#print("matched env value:".$matched."\n");
        $matched = (defined($matched) ? $matched : "");
        $class->{'properties'}{$k} = $prefix.$matched.$suffix;
        $v = $class->{'properties'}->{$k};
    }
    #print("$k=$class->{'properties'}->{$k}\n");
	return $v;
}

sub unescapeProperties
{
    my $class = shift @_;
    my $props = $class->{'properties'};
	#print "list properties before unescape start\n";
    while( local ($k,$v) = each(%$props)){
		#print("$k=$v\n");
        $class->unescapeProperty($k, $v);
    }
	#print "list properties before unescape end\n";
}

sub get
{
    my ($class,$key,$default) = @_;
    if(exists($class->{'properties'}->{$key})){
        return $class->{'properties'}->{$key};
    }
    if(defined($default)){ #not exists $props{$key}
        return $default;
    }
    return ""; #no default
}

sub set
{
    my ($class, $key, $value) = @_;
    $class->{'properties'}->{$key} = $value;
}

sub merge
{
	my ($class, $props_to_be_merged, $override) = @_;
	my $props = $class->{'properties'};
	while(local ($k,$v) = each(%$props_to_be_merged)){
		$k = trim($k);
		if($k eq ""){ next; }
        if(exists($props->{$k})){ next if(!$override); }
		$props->{$k} = trim($v);
    }
    return $props;
}

sub merge_with_file
{
	my ($class, $file_to_be_merged, $override) = @_;
	if(-e $file_to_be_merged){
		return $class->merge(ncs::Properties->new()->load($file_to_be_merged, 1), $override);
	}
	return $class->{'properties'};
}
