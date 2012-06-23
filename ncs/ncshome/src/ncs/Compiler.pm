#!/usr/bin/perl -w

use core::Component;
package ncs::Compiler;
@ISA=qw(core::Component);

use util::Strings;
use util::Files;
use util::Arrays;

sub new
{
    my $pkg = shift;
	my $obj = $pkg->SUPER::new('ncs::Compiler',('docompile'));
    bless $obj;
}

sub compilePath
{
	my ($obj, $compilePath) = @_;
	if(defined($compilePath)){
		$obj->{'compile_path'} = $compilePath;
	}
	else{
		return $obj->{'compile_path'};
	}
}

sub compileTool
{
	my ($obj, $compileTool) = @_;
	if(defined($compileTool)){
		$obj->{'compile_tool'} = $compileTool;
	}
	else{
		return $obj->{'compile_tool'};
	}
}

sub compileParams
{
	my ($obj, $compileParams) = @_;
	if(defined($compileParams)){
		$obj->{'compile_params'} = $compileParams;
	}
	else{
		return $obj->{'compile_params'};
	}
}

sub compileMessage
{
	my ($obj, $compileMessage) = @_;
	if(defined($compileMessage)){
		$obj->{'compile_message'} = $compileMessage;
	}
	else{
		return $obj->{'compile_message'};
	}
}

sub compileLog
{
	my ($obj, $compileLog) = @_;
	if(defined($compileLog)){
		$obj->{'compile_log'} = $compileLog;
	}
	else{
		return $obj->{'compile_log'};
	}
}

sub outputPath
{
	my ($obj, $outputPath) = @_;
	if(defined($outputPath)){
		$obj->{'output_path'} = $outputPath;
	}
	else{
		return $obj->{'output_path'};
	}
}

sub outputFile
{
	my ($obj, $outputFile) = @_;
	if(defined($outputFile)){
		$obj->{'output_file'} = $outputFile;
	}
	else{
		return $obj->{'output_file'};
	}
}

sub cleanupPreviousOutput
{
	my ($obj) = @_;
	$obj->{'cleanup_previous_output'} = 'YES';
}

##########register dependencies services
sub registerLoggingService
{
	my ($obj, $loggingService) = @_;
	$obj->{'logger'} = $loggingService;
}

sub registerPropertiesService
{
	my ($obj, $propertiesService) = @_;
	$obj->{'properties'} = $propertiesService;
}

sub registerBeforeProcess
{
	my ($obj, $beforeProcess) = @_;
	$obj->{'before_process'} = $beforeProcess;
}
sub registerAfterProcess
{
	my ($obj, $afterProcess) = @_;
	$obj->{'after_process'} = $afterProcess;
}
sub registerErrorHandler
{
	my ($obj, $errorHandler) = @_;
	$obj->{'error_handler'} = $errorHandler;
}

sub needCompile
{
	my $obj = shift;
	return 1;
}

sub doCompile
{
	my $obj = shift;
	#invoke before process
	my $before_process = $obj->{'before_process'};
	if($before_process){
		$log->debug("before process: $before_process");
		eval{&$before_process($obj)};
		if($@){$log->warn("Cannot execute before process: $@");}
	}
	
	#initialize variables
	my $cleanup_previous_output = $obj->{'cleanup_previous_output'}||'YES';
	my $compile_message = $obj->{'compile_message'};
	my $compile_tool = $obj->{'compile_tool'};
	my $compile_params = $obj->{'compile_params'};
	my $compile_path = $obj->{'compile_path'};
	my $output_file = $obj->{'output_file'};
	my $output_path = $obj->{'output_path'};
	my $compile_log = $obj->{'compile_log'};
	
	$log->info("");
    $log->info("$compile_message start...");
	#clean up output folder & compile log
	if(&isTrue($cleanup_previous_output)){
		$log->warn("clearnup dir: $output_path");
		&cleanup($output_path);
	}
	if (-e $compile_log){ unlink($compile_log); }
	
	#start compilation with compile tool
	eval{
		$log->debug("cd $compile_path");
		chdir($compile_path);
		$compile_params =~ s/-r \w+/-r $output_file/;
		$log->info("$compile_tool $compile_params 1>$compile_log 2>&1");
		system("$compile_tool $compile_params 1>$compile_log 2>&1");
		$log->info("$compile_message to $output_path/$output_file");
		sleep (10);
	};
	if($@){
		$log->error("compilation error due to $@");
		if($error_handler){#invoke error handler
			$log->debug("error handler: $error_handler");
			&$error_handler($obj);
		}
	}
	
	#check compilation
	my $compile_result = 1;
	$log->info("check $compile_message start");
	if(-e "$output_path/$output_file"){
		$log->info("find output file: $output_path/$output_file!");
		$log->info("compilation successful!");
		$compile_result = 1;
	}
	else{
		$log->error("cannot find output file: $output_path/$output_file!");
		$log->error("compilation failed!!!");
		$compile_result = -1;
	}
	$log->info("check $compile_message end");
	$log->info("$compile_message end");
	
	#invoke after process
	my $after_process = $obj->{'after_process'};
	if($after_process){
		$log->debug("after process: $after_process");
		eval{&$after_process($obj)};
		if($@){$log->warn("Cannot execute after process: $@");}
	}
	return $compile_result;
}

1;
__END__

