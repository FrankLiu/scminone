#!/usr/bin/perl -w

package ncs::Common;

use File::Basename;
use Time::localtime;
use POSIX qw(strftime);

use vars qw(@ISA @EXPORT @EXPORT_OK);
use Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(
	isTrue isFalse
    trim ltrim rtrim lstrip rstrip is_empty is_blank
	parse_template parse_testrate
    cleanup_dir_or_file 
    bname dname
	file_exists check_file_stat file_modtime
    invoke invoke_times 
	count_time compare_date format_time
    copy copy_to_array 
    read_as_array read_range_as_array contains included_in
    save_array_to_file 
	search_line_in_file search_num_in_file contains_in_file replace_line_in_file
	get_status_of_prj add_status_to_prj remove_status_to_prj replace_status_to_prj
    check_var 
    parse_mapping reverse_sr_mappings
	ip
);

sub isTrue
{
	my $str = shift;
	if(&is_empty($str)){ return 0; }
	if(uc($str) eq "TRUE" || uc($str) eq "YES"){ return 1;}
	return 0;
}

sub isFalse
{
	my $str = shift;
	if(&is_empty($str)){ return 1; }
	if(uc($str) eq "FALSE" || uc($str) eq "NO"){ return 1;}
	return 0;
}

# Perl trim function to remove whitespace from the start and end of the string
sub trim
{
	my $string = shift @_;
	$string =~ s/^\s+//;
	$string =~ s/\s+$//;
	return $string;
}

# Left trim function to remove leading whitespace
sub ltrim
{
	my $string = shift @_;
	$string =~ s/^\s+//;
	return $string;
}

# Right trim function to remove trailing whitespace
sub rtrim
{
	my $string = shift @_;
	$string =~ s/\s+$//;
	return $string;
}

sub lstrip
{
	my ($string,$length, $appender) = @_;
	$appender = $appender || ' ';
	local $len = length($string);
	if($len ge $length){ return $string; }
	local $minis = $length - $len;
	return $appender x $minis.$string;
}

sub rstrip
{
	my ($string,$length, $appender) = @_;
	$appender = $appender || ' ';
	local $len = length($string);
	if($len ge $length){ return $string; }
	local $minis = $length - $len;
	return $string.$appender x $minis;
}

sub is_empty
{
	my $string = shift @_;
	if(!defined($string) || length($string) == 0){
		return 1;
	}
	return 0;
}

sub is_blank
{
	my $string = shift;
	return &is_empty(&trim($string));
}

sub parse_template
{
	my ($template, $params) = @_;
	print $template;
	while(local ($k,$v) = each(%$params)){
		print "$k=$v\n";
		$template =~ s/\${?$k}?/$v/g;
	}
	return $template;
}

sub parse_testrate
{
	my ($pnum,$fnum,$enum) = @_;
	my $passrate = 0;
	my $total = $pnum + $fnum + $enum;
	print("passnum: $pnum, failnum: $fnum, errornum: $enum, total: $total\n");
	if($total > 0){ $passrate = $pnum/$total; }
	my $prate = sprintf("%.2f", $passrate*100);
	my $frate = sprintf("%.2f", (100-$prate));
	print("passrate: $prate, failrate: $frate\n");
	return ($prate, $frate);
}

sub count_time
{
	my ($start_time,$end_time) = @_;
	my $spent_time = ($end_time-$start_time);
	print("spent time: $spent_time\n");
	my $spent_sec = $spent_time%60;
	my $spent_mm = $spent_time/60;
	my $spent_hr = $spent_mm >= 60 ? int($spent_mm/60) : 0;
	$spent_mm = $spent_mm >= 60 ? $spent_mm%60 : int($spent_mm);
	return ($spent_hr,$spent_mm,$spent_sec);
}

sub format_time
{
	local ($format,@time) = @_;
	if(is_empty($format)){ $format = "%Y-%m-%d %H:%M:%S"; }
	return strftime($format, @time);
}

sub compare_date
{
	my ($date1, $date2) = @_;
	my ($m1,$d1,$y1) = split(/[-\/]/,$date1,3);
	my ($m2,$d2,$y2) = split(/[-\/]/,$date2,3);
	#print "date1: $m1,$d1,$y1\n";
	#print "date2: $m2,$d2,$y2\n";
	if($y1 > $y2){ return 1; }
	elsif($y1 < $y2){ return -1;}
	else{#$y1=$y2
		if($m1>$m2){ return 1; }
		elsif($m1<$m2){ return -1;}
		else{ #$m1=$m2
			if($d1>$d2){ return 1; }
			elsif($d1<$d2){ return -1;}
			else{return 0;}
		}
	}
}

sub cleanup_dir_or_file
{
    my $dir_or_file = shift @_;
    if(-e "$dir_or_file"){
     	if( -d "$dir_or_file"){
			#print("rm -Rf $dir_or_file/*\n");
     	  	system("rm -Rf $dir_or_file/*");
        }
        else{
			#print("rm -Rf $dir_or_file\n");
            system("rm -Rf $dir_or_file");
        }
    }
}

sub bname
{
	my $file = shift;
	basename $file;
}

sub dname
{
	my $file = shift;
	dirname $file;
}

sub file_exists
{
	my $file = shift;
	if(-e "$file"){ return 1; }
	return 0;
}

sub file_modtime
{
	local ($filename) = @_;
	if(&file_exists($filename)){
		local @stats = stat($filename);
		return $stats[9];
	}
	return -1; 
}

sub check_file_stat
{
    my ($filename,$sleep_time,$timeout) = @_;
    my $last_mtime = 0;
    my $last_size = 0;
    my $start_time = time;
    my $end_time;
    $timeout = $timeout || "300";
    print("check file stat: $filename\n");
    while(1){
        my($dev, $ino, $mode, $nlink, $uid, $gid, $rdev,
            $size, $atime, $mtime, $ctime, $blksize, $blocks) = stat($filename);
        if($mtime == $last_mtime && $size == $last_size){
            print("file stoped increace");
            return 1;
        }
        $last_mtime = $mtime;
        $last_size = $size;
        #print("filename=$filename\n");
        print("last_mtime=$mtime\n");
        print("last_size=$size\n");
        print("wait $sleep_time seconds for next check...\n");
        sleep($sleep_time);
        $end_time = time;
        if(($end_time - $start_time) >= $timeout){
            print("wait too much time: $timeout");
            return 1;
        }
    }
}

sub invoke
{
    my ($sub_name, @sub_params) = @_;
    print("invoke sub $sub_name with params @sub_params.");
    eval("$sub_name(\@sub_params)");
    if($@){
        warn("invoke error: $@");
    }
}

sub invoke_times
{
    my ($times, $sub_name, @sub_params) = @_;
    print("invoke sub $sub_name with params @sub_params, $times times.");
    for($count=1; $count<=$times; $count++){
        #print("invoke times: $count");
        eval("$sub_name(\@sub_params)");
        if($@){
            warn("invoke_times error: $@");
        }
    }
}

sub read_as_array
{
    my ($file) = @_;
    my @result = ();
    if(open(FILE, "<$file")){
        @result = <FILE>;
        close(FILE);
    }
    return @result;
}

sub read_range_as_array
{
	my ($file,$start_index,$end_index) = @_;
	if(!$start_index){ $start_index=0;}
    my @result = ();
    if(open(FILE, "<$file")){
        @result = <FILE>;
        close(FILE);
    }
	if(!$end_index){$end_index=@result;}
	if($end_index<=0){
		local $len = @result;
		$end_index = $len+$end_index;
	}
    return @result[$start_index..$end_index];
}

sub copy
{
    my ($src,$dst,$comment_line,@append_lines) = @_;
    open(SRC, "<$src") || die("Cannot open source file: $src");
    open(DST, ">$dst") || die("Cannot open dest file: $dst");
    
    if(@append_lines){
        foreach $append_line (@append_lines){
            print DST "$append_line\n";
        }
    }
    while($line = <SRC>){
        if(defined($comment_line) && length($comment_line) > 0 && index($line,$comment_line) ne -1){
			$line = "# $line";
		}
        print DST $line;
    }
    close(SRC);
    close(DST);
}

sub copy_to_array
{
    my ($src,$start_pattern,$end_pattern,$includes_end_pattern) = @_;
    my @res = ();
    open(SRC, "<$src") || die("Cannot open source file: $src");
    my $allow_copy = 0,$at_end_pattern_pos=0;
    if(!$start_pattern){ $allow_copy = 1; }
    while($line = <SRC>){
        if($start_pattern && $line =~ /$start_pattern/){
            $allow_copy = 1;
        }
		if($end_pattern && $line =~ /$end_pattern/){
            $allow_copy = 0;
			if($includes_end_pattern){$at_end_pattern_pos = 1;}
        }
		push(@res, $line) if($allow_copy || $at_end_pattern_pos);
		if($at_end_pattern_pos){ $at_end_pattern_pos = 0;}
    }
    close(SRC);
    return @res;
}

sub save_array_to_file
{
    local ($file, @array) = @_;
	open(FILE, ">$file") || die("Cannot open file: $file");
	foreach $item (@array){
		print FILE "$item\n";
	}
	sleep(5);
    close(FILE);
}

sub search_line_in_file
{
	my ($file, $pattern) = @_;
	my $result = '';
	#print($pattern);
    open(FILE, "<$file") || die("Cannot open file: $file");
    while($line = <FILE>){
        if($line =~ /$pattern/){
			#print("matched line: $line");
            $result = $line;
        }
    }
	close(FILE);
    return $result;
}
sub search_num_in_file
{
	my ($file,$pattern) = @_;
	my $result = search_line_in_file($file, "$pattern - <.*>(\\d+)");
	if(length($result) == 0){ return 0;}
	$result =~ s/$pattern - <.*>(\d+).*/$1/;
	chomp($result);
	return $result;
}

sub replace_line_in_file
{
	my ($file, $pattern, $replacement) = @_;
	my $tmp = "$file".".tmp";
    open(FILE, "<$file") || die("Cannot open file: $file");
	open(TMP, ">$tmp") || die("Cannot open file: $tmp");
    while($line = <FILE>){
        $line =~ s/$pattern/$replacement/g;
		print TMP $line;
    }
	close(FILE);
	close(TMP);
    system("mv $tmp $file");
}

sub get_status_of_prj
{
	my ($file, $prj) = @_;
	my $result = &search_line_in_file($file, "$prj (\\w+)");
	if(length($result) == 0){ return '';}
	$result =~ s/$prj (\w+)/$1/;
	chomp($result);
	return $result;
}
sub add_status_to_prj
{
	my ($file, $prj, $status) = @_;
	&replace_line_in_file($file, "$prj", "$prj $status");
}
sub remove_status_to_prj
{
	my ($file, $prj, $status) = @_;
	&replace_line_in_file($file, "$prj $status", "$prj");
}
sub replace_status_to_prj
{
	my ($file, $prj, $status, $new_status) = @_;
	&replace_line_in_file($file, "$prj $status", "$prj $new_status");
}

#this function used for numberic comparation
sub included_in
{
	my ($elem, @array) = @_;
	foreach (@array){
		if($_ == $elem){ return 1; }
	}
	return 0;
}

#this function used for string comparation
sub contains
{
	my ($elem, @array) = @_;
	if(grep(/$elem/, @array)){ return 1;}
	foreach (@array){
		if($_ =~ /$elem/i){ return 1; }
		if(index(ucfirst($elem), ucfirst($_)) >= 0){ return 1; }
	}
	return 0;
}

sub contains_in_file
{
	my ($file, $pattern) = @_;
	my $result = 0;
	return 0 if(! -e $file);
    open(FILE, "<$file") || die("Cannot open file: $file");
    while($line = <FILE>){
        if($line =~ /$pattern/){
			#print("matched line: $line");
            $result = 1;
        }
    }
	close(FILE);
    return $result;
}

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

sub parse_mapping
{
    my ($file,$split_pattern) = @_;
    if(!$split_pattern){$split_pattern = "[\\s:;,]+";};
	#print "split pattern: $split_pattern\n";
    my %mappings = ();
    my $k = $v = "";
    open(MAPPINGFILE, "<$file") || die("Cannot open mapping file $file");
    while($line = <MAPPINGFILE>){
        #space line or commentted line will be ignored
        if($line =~ /^$/ || $line =~ /^#/){ 
            next;  
        }
        ($k,$v) = split(/$split_pattern/, $line, 2);
        if(trim($k) eq "" || is_empty($v)){
            next;
        }
		chomp($v);
        #print("$k=$v\n");
        $mappings->{trim($k)} = trim($v);
    }
    close(MAPPINGFILE);
    return $mappings;
}

sub reverse_sr_mappings
{
	my ($mappings) = @_;
	my $r_mappings = {};
	while(my ($k,$v) = each(%$mappings)){
		#print("$k=$v\n");
        if(!exists($r_mappings{$v})){
			#print "not exists $v !";
			$r_mappings{$v} = [];
			#print "$r_mappings->{$v}\n";
		}
		if(!contains($k, $r_mappings->{$v})){
			push(@{$r_mappings->{$v}}, $k);
		}
    }
	return $r_mappings;
}

sub ip
{
	my ($hostname) = shift;
	my ($name,$aliases,$addrtype,$length,@addrs) = gethostbyname($hostname||"$HOST_NAME");
	#print "name: $name\n" ;
	my ($a , $b , $c , $d) = unpack('C4', $addrs[0]);
	#print "$a.$b.$c.$d\n" ;
	return "$a.$b.$c.$d";
}

