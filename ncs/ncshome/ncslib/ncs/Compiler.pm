#!/usr/bin/perl -w

package ncs::Compiler;

use ncs::Common;

sub new
{
    my $this = {};
    bless $this;
    return $this;
}
#this is required
sub setLoggingService
{
	my ($class, $loggingService) = @_;
	$class->{'logger'} = $loggingService;
}
sub cleanupPreviousOutput
{
	my ($class, $cleanup) = @_;
	$class->{'cleanup_previous_output'} = $cleanup||'YES';
}
sub setTtcns
{
	my ($class, @ttcns) = @_;
	$class->{'ttcn_files'} = \@ttcns;
}
sub getTtcns
{
	my ($class) = @_;
	return $class->{'ttcn_files'} ? @{$class->{'ttcn_files'}} : ();
}
sub setCompilePath
{
	my ($class, $compile_path) = @_;
	$class->{'compile_path'} = $compile_path;
}
sub getCompilePath
{
	my ($class) = @_;
	return $class->{'compile_path'};
}
sub setCompileTool
{
	my ($class, $compile_tool) = @_;
	$class->{'compile_tool'} = $compile_tool;
}
sub getCompileTool
{
	my ($class) = @_;
	return $class->{'compile_tool'};
}
sub setCompileParams
{
	my ($class, $compileParams) = @_;
	$class->{'compile_params'} = $compileParams;
}
sub getCompileParams
{
	my ($class) = @_;
	return $class->{'compile_params'};
}
sub setCompileMessage
{
	my ($class, $compileMessage) = @_;
	$class->{'compile_message'} = $compileMessage;
}
sub getCompileMessage
{
	my ($class) = @_;
	return $class->{'compile_message'};
}
sub setCompileLog
{
	my ($class, $compileLog) = @_;
	$class->{'compile_log'} = $compileLog;
}
sub getCompileLog
{
	my ($class) = @_;
	return $class->{'compile_log'};
}
sub setOutputPath
{
	my ($class, $outputPath) = @_;
	$class->{'output_path'} = $outputPath;
}
sub getOutputPath
{
	my ($class) = @_;
	return $class->{'output_path'};
}
sub setOutputFile
{
	my ($class, $outputFile) = @_;
	$class->{'output_file'} = $outputFile;
}
sub getOutputFile
{
	my ($class) = @_;
	return $class->{'output_file'};
}
sub setMakefile
{
	my ($class, $mkFile) = @_;
	$class->{'mk_file'} = $mkFile;
}
sub getMakefile
{
	my ($class) = @_;
	return $class->{'mk_file'};
}
sub setMakeParams
{
	my ($class, $mkParams) = @_;
	$class->{'mk_params'} = $mkParams;
}
sub getMakeParams
{
	my ($class) = @_;
	return $class->{'mk_params'};
}
sub setMkLog
{
	my ($class, $mkLog) = @_;
	$class->{'mk_log'} = $mkLog;
}
sub getMkLog
{
	my ($class) = @_;
	return $class->{'mk_log'};
}
sub setMkTimes
{
	my ($class, $mkTimes) = @_;
	$class->{'mk_times'} = $mkTimes;
}
sub getMkTimes
{
	my ($class) = @_;
	return $class->{'mk_times'};
}
sub getCompileResult
{
	my ($class) = @_;
	return $class->{'compile_result'};
}
sub registerBeforeProcess
{
	my ($class, $beforeProcess) = @_;
	$class->{'before_process'} = $beforeProcess;
}
sub registerAfterProcess
{
	my ($class, $afterProcess) = @_;
	$class->{'after_process'} = $afterProcess;
}
sub registerErrorHandler
{
	my ($class, $errorHandler) = @_;
	$class->{'error_handler'} = $errorHandler;
}
sub compile
{
	my ($class) = @_;
	my $log = $class->{'logger'};
	#invoke before process
	my $before_process = $class->{'before_process'};
	if($before_process){
		$log->debug("before process: $before_process");
		eval{&$before_process($class)};
		if($@){$log->warn("Cannot execute before process: $@");}
	}
	#initialize variables
	my $cleanup_previous_output = $class->{'cleanup_previous_output'}||'YES';
	#$log->debug("ttcn files: $class->{'ttcn_files'}");
	my @ttcns = $class->{'ttcn_files'} ? @{$class->{'ttcn_files'}} : ();
	my $compile_tool = $class->{'compile_tool'};
	my $compile_params = $class->{'compile_params'};
	my $compile_path = $class->{'compile_path'};
	my $compile_message = $class->{'compile_message'};
	my $output_file = $class->{'output_file'};
	my $output_path = $class->{'output_path'};
	my $compile_log = $class->{'compile_log'};
	my $mk_file = $class->{'mk_file'};
	my $mk_params = $class->{'mk_params'}||'';
	my $mk_log = $class->{'mk_log'}||$class->{'compile_log'};
	my $mk_times = $class->{'mk_times'};
	my $error_handler = $class->{'error_handler'};
	$log->info("");
    $log->info("$compile_message start...");
	#clean up output folder
	if(&isTrue($cleanup_previous_output)){
		$log->warn("clearnup dir: $output_path");
		&cleanup_dir_or_file($output_path);
	}
	if (-e $compile_log){ unlink($compile_log); }
    if (-e $mk_log){ unlink($mk_log);}
	
	#start compilation with compile tool
	$log->debug("cd $compile_path");
    chdir($compile_path);
	$compile_params =~ s/-r \w+/-r $output_file/;
	#$compile_params =~ s/-p ".*"/-p "$compile_path"/;
	#$compile_params =~ s/-d ".*"/-d "$output_path"/;
	#stringlize ttcn files
	if(scalar(@ttcns) > 0){
		$log->debug("ttcn files: @ttcns\n");
		my $ttcn_str = join(" ", @ttcns);
		$compile_params .= " $ttcn_str" 
	}
	eval{
		$log->info("$compile_tool $compile_params 1>$compile_log 2>&1");
		system("$compile_tool $compile_params 1>$compile_log 2>&1");
		$log->info("$compile_message to $output_path/$output_file");
		sleep (10);
		#start compilation with makefile
		if(!(-e "$output_path/$output_file") && $mk_times > 0){
			$log->warn("output file not exist: $output_path/$output_file");
			$log->warn("Try to build $mk_times times with make file: $mk_file");
			$log->debug("cd $output_path");
			chdir($output_path); $mk_file = &bname($mk_file);
			if(-e $mk_file){
				for(my $i=0; $i<$mk_times; $i++){
					# try to build using makefile
					$log->info("Try to build using make file: $mk_file");
					system("touch $mk_log") if (! -e $mk_log);
					$log->info("make -f $mk_file $mk_params 1>>$mk_log 2>&1");
					system("make -f $mk_file $mk_params 1>>$mk_log 2>&1");
					sleep(5);
					last if(-e $output_file);
				}
			}
			else{
				$log->error("make file $mk_file not exists! give up!");
			}
			$log->debug("cd $compile_path");
			chdir($compile_path);
			$log->warn("Finished building using make file: $mk_file");
		}
		sleep(10);
	};
	if($@){
		$log->error("compilation error due to $@");
		if($error_handler){#invoke error handler
			$log->debug("error handler: $error_handler");
			&$error_handler($class);
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
	$class->{'compile_result'} = $compile_result;
	$log->info("$compile_message end");
	#invoke after process
	my $after_process = $class->{'after_process'};
	if($after_process){
		$log->debug("after process: $after_process");
		eval{&$after_process($class)};
		if($@){$log->warn("Cannot execute after process: $@");}
	}
	return $compile_result;
}

1;
__END__
