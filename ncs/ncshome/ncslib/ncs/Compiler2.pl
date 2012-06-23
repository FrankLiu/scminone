#!/usr/bin/perl -w

use ncs::Common;
use ncs::TtpParser;
use ncs::Compiler;

sub do_compile
{
	my ($compile_prj_lbl, $compile_type, $beforeProcess, $afterProcess, $errorHandler) = @_;
	my $compile_path = $props->get("ncs.".$compile_type.".compile_path");
	my $compile_tool = $props->get("ncs.".$compile_type.".compile_tool");
    my $compile_params = $props->get("ncs.".$compile_type.".compile_params");
    my $output_path = $props->get("ncs.".$compile_type.".output_path");
    my $output_file = $props->get("ncs.".$compile_type.".output_file");
    my $mk_file = $props->get("ncs.".$compile_type.".mk_file");
	my $mk_params = $props->get("ncs.".$compile_type.".mk_params",'');
	my $compile_message = $props->get("ncs.".$compile_type.".compile_message");
	my $compile_log = $props->get("ncs.".$compile_type.".compile_log");
	my $mk_log = $props->get("ncs.".$compile_type.".mk_log", $compile_log);
	$compile_log = "$log_dir/$compile_prj_lbl/buildlog/$compile_log";
	$mk_log = "$log_dir/$compile_prj_lbl/buildlog/$mk_log";
	#check compile option
    $log->info("compilation start...");
	#invoke compile method
	#initialize compiler
	my $compiler = ncs::Compiler->new();
	$compiler->setLoggingService($log);
	$compiler->setCompilePath($compile_path);
	$compiler->setCompileTool($compile_tool);
	$compiler->setCompileParams($compile_params);
	$compiler->setCompileMessage($compile_message);
	$compiler->setCompileLog($compile_log);
	$compiler->setOutputPath($output_path);
	$compiler->setOutputFile($output_file);
	$compiler->setMakefile($mk_file);
	$compiler->setMakeParams($mk_params);
	$compiler->setMkLog($mk_log);
	$compiler->setMkTimes(3);
	$compiler->registerBeforeProcess($beforeProcess) if $beforeProcess;
	$compiler->registerAfterProcess($afterProcess) if $afterProcess;
	$compiler->registerErrorHandler($errorHandler) if $errorHandler;
	my $compile_result = $compiler->compile();
	#check license issue
	while(&contains_in_file($compiler->getCompileLog(), 'TAU-G2-UML-BASE|TAU-G2-TTCN3-BASE')){
		$compile_result = $compiler->compile();
	}
	#check compile result
	if($compiler->getCompileResult() <= 0){
		&compile_failed_handler($compiler->getCompileMessage(), $compiler->getCompileLog());
	}
	$log->info("compilation end.");
	return $compile_result;
}

sub compile_failed_handler
{
	my ($compile_message,$log_file) = @_;
	my $line_sep = $line_separator;
	$log->error("$compile_message...FAILED");
	push(@build_results, "$compile_message...<span class='failed'>FAILED</span>$line_sep");
	if(-e $log_file){
		# my @logs = read_as_array($log_file);
		# @logs = map($_.$line_sep,@logs);
		# push(@build_results, @logs);
		push(@build_results, "please check log file at $log_file");
	}
	$isbuildfailed = $TRUE;
	&send_mail();
	&record_project();
	&terminate_ncs();
	die("Error due to $compile_message...FAILED");
}

sub need_compile
{
	my ($compile_type) = @_;
	my $line_sep = $line_separator;
	my $enable_compile = $props->get("ncs.option.compile_".$compile_type);
	my $compile_message = $props->get("ncs.".$compile_type.".compile_message");
	if(!$enable_compile){
        $log->warn("ncs.option.compile_".$compile_type."=0, NCS will ignore $compile_type compilation!");
        push(@build_results, "$compile_message...IGNORED$line_sep");
        return $FALSE;
    }
	return $TRUE;
}

#always check executable file to make sure it exists before run testcase
#otherwise, send out a inform email, 
#this means it need handle by development team!
sub check_executable_file
{
	my ($type, $suite_type) = @_;
	my $line_sep = $line_separator;
	my $compile_message = $props->get("ncs.${type}.compile_message");
	my $exec_path = $props->get("ncs.${type}.output_path");
	my $exec = $props->get("ncs.${type}.output_file");
	$exec = $props->get("ncs.${type}.${suite_type}.executable", $exec) if($suite_type);
	$log->info("check $type executable file: $exec_path/$exec");
	$log->info("suite type: $suite_type") if $suite_type;
	if(! -e "$exec_path/$exec"){
		$log->error("executable file not exists: $exec_path/$exec");
		$log->error("please turn on compile $type option as: ncs.option.compile_${type}=1");
		push(@build_results, "$compile_message...<span class='failed'>FAILED</span>$line_sep");
		push(@build_results, "<span class='failed'>executable file not exist: $exec_path/$exec!</span>$line_sep");
		push(@build_results, "<span class='failed'>please turn on compile $type option as below if it is not turned on!</span>$line_sep");
		push(@build_results, "&nbsp;&nbsp;<span class='failed'>ncs.option.compile_${type}=1</span>$line_sep");
		push(@build_results, "<span class='failed'>please check your config spec or code if the compile option already turned on</span>");
		#TODO: should we need check the depends emails?
		$isbuildfailed = $TRUE;
		&send_mail();
		&terminate_ncs();
		die("Error due to executable file not exists!");
	}
	$log->info("found $type executable file: $exec_path/$exec");
}

sub compile_isl
{
	my $compile_prj_lbl = shift @_;
	my $line_sep = $line_separator;
	my $compile_message = $props->get("ncs.isl.compile_message");
	local $output_path = $props->get("ncs.isl.output_path", "$log_dir/$compile_prj_lbl");
	local $output_file = $props->get("ncs.isl.output_file");
	sub set_output_path{
		my $compiler = shift;
		$compiler->setOutputPath($output_path);
		$compiler->setMkTimes(0);
		$compiler->cleanupPreviousOutput('no');#not need cleanup here
	};
	sub cp_output{
		my $target_file = $props->get("ncs.isl.target_file");
		$log->debug("cp $output_path/$output_file $target_file") if($target_file);
		system("cp $output_path/$output_file $target_file") if($target_file);
	};
	if(&need_compile('isl')){
		my $compile_result = &do_compile($compile_prj_lbl, 'isl', \&set_output_path, \&cp_output);
		#push compile result
		push(@build_results, "$compile_message...OK$line_sep");
	}
}

sub compile_model
{
	my $compile_prj_lbl = shift @_;
	my $line_sep = $line_separator;
	my $compile_message = $props->get("ncs.model.compile_message");
	my $compile_result = 0;
	if(&need_compile('model')){
		$compile_result = &do_compile($compile_prj_lbl, 'model');
		#push compile result
		push(@build_results, "$compile_message...OK$line_sep");
	}
	&check_executable_file('model');
}

sub compile_ttcn
{
	local $compile_prj_lbl = shift @_;
	my $line_sep = $line_separator;
	my $compile_message = $props->get("ncs.test.compile_message");
	local $isl_check_file_name = $props->get("ncs.isl.check_file");
	local $isl_check_file = "$log_dir/$compile_prj_lbl/$isl_check_file_name";
	sub correct_pkg_ttcn{
		my ($isl_check_file) = @_;
		my $dirname = &dname($isl_check_file);
		my $basename = &bname($isl_check_file);
		$log->info("correct pkg ttcn file...");
		chdir ($dirname);
		open(ORIG, "<$basename") or die "\n Cannot open $isl_check_file\n";
		open(TMP, ">tmp.ttcn") or die "\n Cannot create tmp.ttcn\n";
		while(defined($line = <ORIG>))
		{
			chomp($line);
			if ((index ($line, "PCD_REL_CONTAINMENT_TARGET (3),") ne -1) ||
				(index ($line, "PCD_REL_CONTAINMENT_SOURCE (4)") ne -1) ||
				(index ($line, "PCD_REL_DEPENDENCY_TARGET (6)") ne -1) ||
				(index ($line, "PCD_REL_DEPENDENCY_SOURCE (7)") ne -1))
			{
				$line = "// $line";
			}
			print TMP "$line\n";
		}
		close (ORIG);
		close (TMP);
		sleep(2);
		system("cp $basename ${basename}.bak");
		system("mv tmp.ttcn $basename");
	};
	sub prepare_compiler{
		my ($compiler, $ttp_file) = @_;
		my $ttpParser = ncs::TtpParser->new();
		$ttpParser->setTtpFile($ttp_file);
		$ttpParser->parse();
		my $root_module = $ttpParser->getRootModule();
		my $makefile = $ttpParser->getMakefile();
		#my $outputDir = $ttpParser->getOutputDirectory();
		my @ttcns = $ttpParser->getTtcns();
		#$compiler->setOutputPath(&trim($outputDir)) if $outputDir;
		if($root_module){
			$root_module=&trim($root_module);
			$compiler->setOutputFile(&trim($root_module));
			my $compileLog = $compiler->getCompileLog(), $mkLog = $compiler->getMkLog();
			$compiler->setCompileLog(&dname($compileLog)."/${root_module}_".&bname($compileLog));
			$compiler->setMkLog(&dname($mkLog)."/${root_module}_".&bname($mkLog));
		}
		if($makefile && -e $compiler->getOutputPath()."/".&bname($makefile)){
			$compiler->setMakefile(&trim($makefile));
		}
		$compiler->setTtcns(@ttcns) if scalar(@ttcns) > 0;
		$compiler->cleanupPreviousOutput('no');#not need cleanup here
	};
	
	if(&need_compile('test')){
		my $compiler_result=0;
		&correct_pkg_ttcn($isl_check_file) if(-e $isl_check_file);
		#read ttcn files from ttp files
		if($props->get("ncs.test.ttp_files")){
			my @ttp_files = split(",", $props->get("ncs.test.ttp_files"));
			$log->info("read ttcn files from ttp files: @ttp_files");
			my $output_path = $props->get("ncs.test.output_path");
			$log->warn("clearnup dir $output_path");
			&cleanup_dir_or_file($output_path);#only cleanup 1 time
			foreach $ttp_file (@ttp_files){
				sub pre_ttpfiles_compiler{
					my $compiler = shift;
					&prepare_compiler($compiler, $ttp_file);
				};
				if(! -e $ttp_file){
					$log->warn("ttp file not exists: $ttp_file");
					next;
				}
				$compiler_result = &do_compile($compile_prj_lbl, 'test', \&pre_ttpfiles_compiler);
			}
		}
		#read ttcn files from properties file
		elsif($props->get("ncs.test.ttcn_files")){
			my $compile_path = $props->get("ncs.test.compile_path");
			local @ttcn_files = split(",", $props->get("ncs.test.ttcn_files"));
			$log->info("read ttcn files from properties file");
			foreach $ttcn (@ttcn_files){
				if(-e $isl_check_file && $ttcn =~ /$isl_check_file_name/){ $ttcn = $isl_check_file; }
				else{ $ttcn = "$compile_path/$ttcn"; }
			}
			$log->debug("ttcn files: @ttcn_files\n");
			sub pre_ttcnfiles_compile{
				my $compiler = shift; 
				$compiler->setTtcns(@ttcn_files) if scalar(@ttcn_files) > 0;
			};
			$compiler_result = &do_compile($compile_prj_lbl, 'test', \&pre_ttcnfiles_compile);
		}
		else{
			$log->error("please configure ncs.test.ttp_files or ncs.test.ttcn_files for compile ttcn!");
			$isbuildfailed = $TRUE;
			&send_mail($compile_prj_lbl);
			&terminate_ncs();
			die("Error due to $compile_msg...FAILED");
		}
		#push compile result
		push(@build_results, "$compile_message...OK$line_sep");
	}
	#check executable file
	my @suite_types = split(/\s+|,/, $props->get("ncs.test.suite"));
	foreach $suite_type (@suite_types){
		&check_executable_file('test', $suite_type);
	}
}


1;

__END__
