#!/usr/bin/perl -w

use core::Component;
package core::Logger;
@ISA=qw(core::Component);

use POSIX qw(strftime);
use File::Basename;
sub new
{
	my ($pkg, $cfg) = @_;
	my $obj = $pkg->SUPER::new('core::Logger',('debug','info','warn','error','fatal'));
	sub loadcfg{
		my ($cfg) = @_;
		#log level includes: 1(debug),2(info),3(warn),4(error),5(fatal)
		#log.level<1 or log.level>5 will turn off log
		if(!exists($cfg->{'log.level'})){
			print "log level not exist, use default level 'ERROR'\n" if $obj->isdebugon();
			$cfg->{'log.level'} = 'ERROR';
		}
		#log appender includes: screen, file
		if(!exists($cfg->{'log.appender'})){
			print "log appender not exist, use default appender 'screen'\n" if $obj->isdebugon();
			$cfg->{'log.appender'} = 'screen';
		}
		if(index($cfg->{'log.appender'}, 'file') ne -1){
			#logging to a file
			if(!exists($cfg->{'log.appender.file'})){
				print "log appender file not exist, use default appender file 'unknown.log'\n" if $obj->isdebugon();
				$cfg->{'log.appender.file'} = 'unknown.log';
			}
		}
		#log dateformat includes: %Y-%m-%d %H:%M:%S
		if(!exists($cfg->{'log.dateformat'})){
			print "log dateformat not exist, use default dateformat '%Y-%m-%d %H:%M:%S'\n" if $obj->isdebugon();
			$cfg->{'log.dateformat'} = '%Y-%m-%d %H:%M:%S';
		}
		return $cfg;
	}
	sub initilize{
		my ($cfg) = @_;
		my $log_file = $cfg->{'log.appender.file'};
		if(index($cfg->{'log.appender'}, 'file') ne -1 && defined($log_file)){
			my $log_dir = dirname($log_file);
			print("log dir is $log_dir \n") if $obj->isdebugon();
			mkdir($log_dir) if(! -e $log_dir);
			open(LOG_FILE, ">>$log_file") || die("cannot open log file $log_file");
			chmod($log_file, 0755);
			select(LOG_FILE);$|=1;select(STDOUT);
			$cfg->{'log.appender.file.handler'} = LOG_FILE;
        }
	}
	loadcfg($cfg);
	initilize($cfg);
	$obj->{_configure} = $cfg;
	bless $obj;
}

sub print_cfg
{
	my $obj = shift;
	if($obj->isdebugon()){
		print("component [".$obj->name()."] configurations\n");
		print("-"x50 ."\n");
		foreach $key (sort(keys(%{$obj->{_configure}}))){
			print("$key = $obj->{_configure}->{$key}\n");
		}
		print("-"x50 ."\n");
	}
}

sub is_loggable
{
	my $obj = shift;
    my $log_level = $obj->{_configure}->{'log.level'};
	#print("log level: $log_level \n") if $obj->isdebugon();
	my $log_level_i = $obj->_level_to_i($log_level);
    return ($log_level_i > 0 and $log_level_i <= 5);
}

sub _level_to_s
{
	my ($obj, $log_level) = @_;
	if($log_level == 1){
		return 'DEBUG';
	}
	elsif($log_level == 2){
		return 'INFO';
	}
	elsif($log_level == 3){
		return 'WARN';
	}
	elsif($log_level == 4){
		return 'ERROR';
	}
	elsif($log_level == 5){
		return 'FATAL';
	}
	else{
		return 'NOT SUPPORTED!';
	}
}

sub _level_to_i
{
	my ($obj, $log_level) = @_;
	if(uc($log_level) eq 'DEBUG'){
		return 1;
	}
	elsif(uc($log_level) eq 'INFO'){
		return 2;
	}
	elsif(uc($log_level) eq 'WARN'){
		return 3;
	}
	elsif(uc($log_level) eq 'ERROR'){
		return 4;
	}
	elsif(uc($log_level) eq 'FATAL'){
		return 5;
	}
	else{
		return -1;
	}
}

sub log
{
	my ($obj, $msg, $log_level) = @_;
    if(! $obj->is_loggable()){
        return;
    }
	my $line_sep = "\n";
	my $log_default_level = $obj->{_configure}->{'log.level'};
	my $log_default_level_i = $obj->_level_to_i($log_default_level);
    my $log_appender = $obj->{_configure}->{'log.appender'};
	my $log_file = $obj->{_configure}->{'log.appender.file'};
	my $log_file_handler = $obj->{_configure}->{'log.appender.file.handler'};
	my $log_dateformat = $obj->{_configure}->{'log.dateformat'};
    my $now = strftime($log_dateformat, localtime());
	my $level_i = $obj->_level_to_i($log_level);
    #print("$log_appender $log_level $msg \n") if $obj->isdebugon();
    if($level_i >= $log_default_level_i){
		#logging to screen
        if(index($log_appender, 'screen') ne -1){
			print "log is append to screen\n" if $obj->isdebugon();
            print STDOUT "[$now] [$log_level] $msg $line_sep";
        }
		#logging to a file
        if(index($log_appender, 'file') ne -1 && defined($log_file_handler)){
			print "log is append to file $log_file\n" if $obj->isdebugon();
            print $log_file_handler "[$now] [$log_level] $msg $line_sep";
        }
    }
}

sub debug
{
	my ($obj, $msg) = @_;
	$obj->log($msg, 'DEBUG');
}

sub info
{
	my ($obj, $msg) = @_;
	$obj->log($msg, 'INFO');
}

sub warn
{
	my ($obj, $msg) = @_;
	$obj->log($msg, 'WARN');
}

sub error
{	
	my ($obj, $msg) = @_;
	$obj->log($msg, 'ERROR');
}

sub fatal
{
	my ($obj, $msg) = @_;
	$obj->log($msg, 'FATAL');
}

sub DESTROY
{
	my $obj = shift;
	my $component_name = $obj->name();
	print("destroying component [$component_name]...\n") if $obj->isdebugon();
	my $log_file_handler = $obj->{_configure}->{'log.appender.file.handler'};
	if(defined($log_file_handler)){
		close($log_file_handler);
	}
	$obj->{_configure} = {};
	print("destroyed component [$component_name]...\n") if $obj->isdebugon();
}
1;
