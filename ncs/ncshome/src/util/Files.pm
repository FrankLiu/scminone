#!/usr/bin/perl -w

package util::Files;
use File::Basename;

use vars qw(@ISA @EXPORT @EXPORT_OK);
use Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(
	exists cleanup 
	bname dname 
	modtime stat 
	read_as_array search_line_in_file 
	copy copy_to_array replace_line_in_file
	
);

sub exists
{
	my $file = shift;
	if(-e "$file"){ return 1; }
	return 0;
}

sub cleanup
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

sub modtime
{
	local ($filename) = @_;
	if(&file_exists($filename)){
		local @stats = stat($filename);
		return $stats[9];
	}
	return -1; 
}

sub stat
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

sub read_as_array
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

sub contains_in_file
{
	my ($file, $pattern) = @_;
	my $result = 0;
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

