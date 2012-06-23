#!/usr/bin/perl -w

use Expect;
use ncs::Common;

my %TESTCASE_RESULTS = (
	'testcase_ignored'			=> "Test case ignored",
    'finished_normally'         => "Test case summary",
    'address_not_mapped'        => "Description: Address not mapped to object",
    'model_is_not_startup'      => "CRITICAL ERROR: [CLIENT] Exiting",
    'log_is_not_opened'         => "Cannot open Testcase log",
    'time_out'                  => "Timeout"
);
my %MODEL_RESULTS = (
    'uml_error'                 => "************ ERROR *************",
    'uml_warning'               => "************ WARNING ************",
    'address_already_in_use'    => "Exiting - bind error: Address already in use",
    'cmi_register_req'          => "OUTPUT of CMI_REGISTER_REQ",
    'log_is_not_opened'         => "Cannot open Model log",
);
my $exp;

sub run_model
{
    my $testcase = shift @_;
    my $localtime = localtime;
    $log->info("run model at: $localtime");
    my $model_exec_path = $props->get("ncs.model.output_path");
    local $model_params = $props->get("ncs.model.test_params");
    my $model_exec = $props->get("ncs.model.output_file");
	local $test_params_file = $props->get("ncs.model.test_params_file");
    my $test_log_prefix = $props->get("ncs.model.test_log_prefix");
    my $model_test_log = "$log_dir/$latest_project_label/testlog/$test_log_prefix$testcase.log";
    if(-e $model_test_log){
		$log->info("remove previous test log: $model_test_log");
        system("rm -f $model_test_log");
    }
    sub mk_test_params_file{
		$test_params_file = "$CUR_PATH/$test_params_file";
		if(!(-e "$test_params_file")){
			system("touch $test_params_file");
			my @params = split(/,|;/, $model_params);
			foreach $param (@params){
				system("echo 'echo $param' >> $test_params_file");
				system("echo 'sleep 1' >> $test_params_file");
			}
			system("chmod +x $test_params_file");
		}
	};
	#&mk_test_params_file();
	$log->info("cd $model_exec_path");
    chdir($model_exec_path);
	#$log->debug("$test_params_file | $model_exec_path/$model_exec 1>$model_test_log 2>/dev/null &");
	#system("$test_params_file | $model_exec_path/$model_exec 1>$model_test_log 2>/dev/null &");
	$exp = Expect->new();
	$exp->spawn("$model_exec_path/$model_exec 1>$model_test_log 2>/dev/null");
	$log->debug("expect spawn started: $model_exec_path/$model_exec 1>$model_test_log 2>/dev/null");
	#$exp->log_stdout(1);
	#$exp->log_file($model_test_log);
    $log->info("model running now, waiting for connect...");
}

sub start_model
{
	$log->info("start model...");
	my $model_params = $props->get("ncs.model.test_params");
	my @params = split(/,|;/, $model_params);
	foreach $param (@params){
		$log->debug("send command: $param");
		$exp->send("${param}\n");
	}
}

sub stop_model
{
	$log->info("stop model...");
	$exp->send("\n");
	sleep(1);
	$log->debug("send command: exit");
	$exp->send("exit\n");
	$exp->soft_close();
}

sub run_test
{
    my ($testcase,$suite_type) = @_;
	sub build_test_params{
		my ($testcase) = @_;
		my $test_flag = $props->get("ncs.test.test_flag");
		my $test_params_str = "$test_flag \"";
		my @test_params = split(/,|;/,$props->get("ncs.test.test_params"));
		my $test_params_prefix = $props->get("ncs.test.test_params.prefix");
		my @test_params_values = split(/,|;/, $props->get("ncs.test.test_params.values"));
		for(my $i=0; $i<scalar(@test_params); $i++){
			my $param = $test_params[$i];
			my $val = $test_params_values[$i];
			if($val eq '$testcase'){
				$test_params_str .= " $test_params_prefix $param $testcase";
				next;
			}
			my @values = split(/,|;/, $props->get('ncs.test.test_params.'.$param));
			foreach $value (@values){
				my $testcases = $props->get('ncs.test.test_params.'.$param.'.'.$value,'');
				if(!&is_empty($testcases)){
					#remove previous , and append ,
					$testcases =~ s/^,//g; $testcases =~ s/,$//g;
					$testcases =~ s/-/../g;
					my @suite = eval($testcases);
					$log->debug('ncs.test.test_params.'.$param.'.'.$value.": @suite");
					if(&included_in($testcase, @suite)){
						$val = $value;
						$log->debug("test case $testcase is included in suite, $param=$val");
						last;
					}
				}
			}
			$test_params_str .= " $test_params_prefix $param $val";
		}
		$test_params_str .= "\"";
		return $test_params_str;
	};
    my $localtime = localtime;
    $log->info("run testcase $testcase at: $localtime");
    my $test_params = &build_test_params($testcase);
    my $test_timeout_flag = $props->get("ncs.test.test_timeout_flag");
	my $test_timeout = $props->get("ncs.test.test_timeout");
	my $test_path = $props->get("ncs.test.output_path");
    my $test_exec = $props->get("ncs.test.${suite_type}.executable", $props->get("ncs.test.output_file"));
	$log->debug("$suite_type executable file is: $test_exec");
    my $test_log_prefix = $props->get("ncs.test.test_log_prefix");
    my $test_log = "$log_dir/$latest_project_label/testlog/$test_log_prefix$testcase.log";
    if(-e $test_log){
        system("rm -f $test_log");
        $log->info("removed previous log: $test_log");
    }
    $log->debug("$test_path/$test_exec $test_timeout_flag $test_timeout $test_params 1>$test_log 2>&1 &");
	system("$test_path/$test_exec $test_timeout_flag $test_timeout $test_params 1>$test_log 2>&1 &");
}

###################################################
#Function used to Run one model & one test
###################################################
sub run_model_and_test
{
    my ($testcase,$suite_type) = @_;
    $log->info("");
    $log->info("run model and test for testcase: $testcase");
    run_model($testcase);
    run_test($testcase, $suite_type);
	sleep(3);
	start_model();
}

########################################print coverage
sub print_testcase_coverage
{
	my ($testcase) = @_;
	my $coverage_command = $props->get("ncs.model.coverage_command","print-coverage-table");
	my $coverage_log = "$log_dir/$latest_project_label/coverage/Coverage_${testcase}.log";
	$log->debug("send \\n");
	$exp->send("\n");
	sleep(1);
	#$exp->expect(3, "Command : ");
	$log->debug("send command: $coverage_command $coverage_log");
	$exp->send("$coverage_command $coverage_log\n");
}

###########################################################
#parse test result and check if testcase need to be retest
###########################################################
sub parse_test_result
{
    my $testcase = shift @_;
    $log->info("parse result for testcase: $testcase");
    
    #get variables
    my $test_log_prefix = $props->get("ncs.test.test_log_prefix");
    my $test_log = "$log_dir/$latest_project_label/testlog/$test_log_prefix$testcase.log";
    my $model_log_prefix = $props->get("ncs.model.test_log_prefix");
    my $model_test_log = "$log_dir/$latest_project_label/testlog/$model_log_prefix$testcase.log";
    
    #check if testcase finished
    my $test_timeout = $props->get("ncs.test.test_timeout")||600;
    my $i = 0;
	my $last_string = 0;
	my $start_time = time();
    my $loop = 1;
    while (1)
	{
		if((! -r "$test_log") || !open(TEST_LOG, "<$test_log")){
            $log->error("cannot open test log: $test_log");
            return $TESTCASE_RESULTS{'log_is_not_opened'};
        }
        if((! -r "$model_test_log") || !open(MODEL_LOG, "<$model_test_log")){
            $log->error("cannot open model log: $model_test_log");
            return $MODEL_RESULTS{'log_is_not_opened'};
        }
		while(defined($line = <TEST_LOG>)){
			if(index($line, $TESTCASE_RESULTS{'finished_normally'}) ne -1){ 
                close(TEST_LOG); 
                $log->info("Testcase $testcase finished normally.");
                my $pass = qx{grep "setverdict(pass)" $test_log | wc -l};
                my $fail = qx{grep "setverdict(FAIL)" $test_log | wc -l};
                my $error =qx{grep "setverdict(ERROR)" $test_log | wc -l};
               
                if($error > 0){
                    push(@test_results, "$testcase:ERROR");
                    $log->info("Testcase $testcase... ERROR");
                    $errornum=$errornum+1;
					return "ERROR";
                }
                elsif($fail > 0){
                    push(@test_results, "$testcase:FAILED");
                    $log->info("Testcase $testcase... FAILED");
                    $failnum=$failnum+1;
					return "FAILED";
                }
                elsif($pass >0){
                    push(@test_results, "$testcase:PASS");
                    $log->info("Testcase $testcase... PASS");
                    $passnum=$passnum+1;
					return "PASS";
                }
                return $TESTCASE_RESULTS{'finished_normally'};
            }
            if(index ($line, $TESTCASE_RESULTS{'address_not_mapped'}) ne -1){ 
                close (TEST_LOG); 
                #push(@test_results, "$testcase:ERROR"); #to quick fix the error in SM4.0
                $log->error("Testcase $testcase crashed: Address not mapped to object.");
                #$log->info("Testcase $testcase... ERROR");
                #$errornum=$errornum+1;
                return $TESTCASE_RESULTS{'address_not_mapped'};
            }
			if(index($line, $TESTCASE_RESULTS{'model_is_not_startup'}) ne -1){
                close (TEST_LOG); 
                $log->error("Testcase $testcase... NOT CONNECT: Model is not startup correctly!");
                return $TESTCASE_RESULTS{'model_is_not_startup'};
            }
		}
		close (TEST_LOG);
		sleep (1);

		$last_string = $i;
		$i = 0;
		while(defined($line = <MODEL_LOG>))
		{
			if(index($line, $MODEL_RESULTS{'uml_error'}) ne -1){ 
                close (MODEL_LOG); 
                push(@test_results, "$testcase:UML Error:error");
                $log->info("Testcase $testcase... ERROR: UML Error.");
                $errornum=$errornum+1;
                return $MODEL_RESULTS{'uml_error'};
            }
			if(index($line, $MODEL_RESULTS{'uml_warning'}) ne -1){ 
                close (MODEL_LOG); 
                push(@test_results, "$testcase:UML Warning:error");
                $log->error("Testcase $testcase... ERROR: UML Warning.");
                $errornum=$errornum+1;
                return $MODEL_RESULTS{'uml_warning'};
            }
			if(index($line, $MODEL_RESULTS{'address_already_in_use'}) ne -1){ 
                close (MODEL_LOG); 
                $log->error("Testcase Error: Address already in use.");
                return $MODEL_RESULTS{'address_already_in_use'};
            }
			$i = $i + 1;
			if($last_string == $i){
				if (index ($line, $MODEL_RESULTS{'cmi_register_req'}) ne -1){ 
                    close (MODEL_LOG); 
                    $log->error("Testcase Error: CMI_REGISTER_REQ");
                    return $MODEL_RESULTS{'cmi_register_req'};
                }
			}
		}
		close (MODEL_LOG);
		sleep(1);
		
		my $end_time = time();
        if(($end_time - $start_time) >= $test_timeout){
            $log->warn("Testcase $testcase... timeout - $test_timeout, need retest!!");
            return $TESTCASE_RESULTS{'time_out'};
        }
        $log->debug("waiting for testcase $testcase finished loop: $loop");
        sleep(5);
        $loop++;
	}
    $log->info("parsed result for testcase: $testcase");
}

sub need_retest
{
    my $test_result = shift @_;
    $log->info("check if testcase need to be retested?");
    $log->info("testcase result: $test_result");
    if($test_result eq $TESTCASE_RESULTS{'time_out'} || 
        $test_result eq $TESTCASE_RESULTS{'model_is_not_startup'} ||
        $test_result eq $MODEL_RESULTS{'address_already_in_use'} || 
        $test_result eq $MODEL_RESULTS{'cmi_register_req'} ||
        $test_result eq $TESTCASE_RESULTS{'log_is_not_opened'} ||
        $test_result eq $MODEL_RESULTS{'log_is_not_opened'} ||
		$test_result eq $TESTCASE_RESULTS{'address_not_mapped'})
    {
        $log->info("testcase need to be retested!!");
        return $TRUE;
    }
    $log->info("testcase need not to be retested!!");
    return $FALSE;
}

#check NCS timeout before go to next case
sub check_ncstimeout{
	my $cur_time = time();
	my $ncs_timeout = $props->get("ncs.option.timeout", "20*60*60"); #default 20 hours
	$ncs_timeout = eval($ncs_timeout);
	if(($cur_time-$ncs_start_time) >= $ncs_timeout){
		$log->error("NCS timeout[$ncs_timeout secs]!!!!!!!!!");
		$log->error("NCS will terminate itself due to timeout!!!!!!");
		my @mailbody = (
			"NCS terminate due to timeout[$ncs_timeout secs]",
			"The root cause maybe ncs running machine is crashed at runtime,",
			"please check ncs running machine and kick off NCS for $latest_project_label again!");
		#fixed issue: slaver machine crash, but main machine still send email out with inaccurate test result
		$props->set("ncs.option.enable_sendmail", "1");
		send_error($latest_project_label,@mailbody);
		terminate_ncs();
		die("system exit due to NCS timeout [ $ncs_timeout secs]!!!");
	}
};

###################################################
#Function used to Run one test suite
###################################################
sub run_testsuite
{
    my ($suite_type,@test_suite) = @_;
    $log->info("Run $suite_type test suite: @test_suite");
    #killed sleep time
    my $killed_sleep_time = $props->get("ncs.model.killed_sleep_time", 61);
    #ignore test level
    my $ignore_test = $props->get("ncs.option.ignore_test", "NONE");
    #trtry on need
    my $retry_on_need = $props->get("ncs.option.retry_on_need", 10);
	#retry on timeout
	my $retry_on_timeout = $props->get("ncs.option.retry_on_timeout", 3);
	#print coverage
	my $print_coverage = $props->get("ncs.option.print_coverage", 0);
    #kill model & test processes
    sub kill_all{
		my $suite_type = shift;
        my $m_pname = $props->get("ncs.model.output_file");
        system("killall -s 9 $m_pname 2>/dev/null");
        $log->warn("killed model process: $m_pname");
        my $t_pname = $props->get("ncs.test.${suite_type}.executable", $props->get("ncs.test.output_file"));
        system("killall -s 9 $t_pname 2>/dev/null");
        $log->warn("killed test process: $t_pname");
    };
	
    foreach my $testcase (@test_suite){
        my $retried_times = 1;
		my $retried_timeout = 0;
        my $test_result;
        my $need_retest;
		if(&is_blank($testcase)){
			$log->warn("testcase no is blank, will be ignored!");
			next;
		}
		#$log->info("NCS will ignore $ignore_test testcase!!!");
        if($ignore_test eq "ALL"){
            $log->info("NCS ignored testcase: $testcase");
            $test_result = &parse_test_result($testcase);
			$need_retest = &need_retest($test_result);
			if($need_retest){ push(@test_results, "$testcase:FAILED"); }
            next;
        }
		elsif($ignore_test eq "TESTED"){
			$test_result = &parse_test_result($testcase);
			$need_retest = &need_retest($test_result);
			if(!$need_retest){
				$log->info("NCS ignored $ignore_test testcase: $testcase");
				next;
			}
		}
		elsif($ignore_test eq "PASS"){
			$test_result = &parse_test_result($testcase);
			if($test_result eq "PASS"){
				$log->info("NCS ignored $ignore_test testcase: $testcase");
				next;
			}
		}
		#retry 10 times for each case
        while($retried_times == 1 || 
            ($need_retest && $retried_times<=$retry_on_need && $retried_timeout<=$retry_on_timeout)){
            $log->info("run testcase $testcase times [$retried_times], timeouts [$retried_timeout]");
            eval{
                &run_model_and_test($testcase, $suite_type);
                $test_result = &parse_test_result($testcase);
				#print coverage
				if($print_coverage && $test_result eq "PASS"){
					&print_testcase_coverage($testcase);
				}
				#stop model
				sleep(1);
				&stop_model();
				if($test_result eq $TESTCASE_RESULTS{'time_out'}){$retried_timeout++;}
                $need_retest = &need_retest($test_result);
                kill_all($suite_type);
            };
            if($@){
                $log->error("NCS broken when test case: $testcase");
                $log->error("Cause: $@");
                $log->error("The testcase $testcase will be ignored");
                next;
            }
            #reset the test port
            $log->info("reset BASEPORT to a new one!");
            system("$ENV{'COSIM_DIR'}/tools/portCatch.pl >/dev/null");
            #wait 60 seconds for next test
            $log->info("sleep $killed_sleep_time seconds for next test.\n");
            sleep($killed_sleep_time);
            $retried_times++;
        }
        #tried 10 times and still failed, give up
        if($need_retest){
			$log->warn("give up testcase: $testcase");
			$log->warn("It may caused by the following 2 reasons: ");
            $log->warn("1. retried $retry_on_need times but testcase still not connected or not finished!");
			$log->warn("2. retried $retry_on_timeout times but testcase still timeout!");
            if($test_result eq $TESTCASE_RESULTS{'time_out'}){
                push(@test_results, "$testcase:TIMEOUT:error");
                $log->warn("Testcase $testcase... TIMEOUT");
            }
            else{ #$test_result eq $TESTCASE_RESULTS{'model_is_not_startup'}||...
                push(@test_results, "$testcase:FAILED");
                $log->warn("Testcase $testcase... FAILED");
            }
            $failnum=$failnum+1;
        }
        $log->info("\n");
		#check ncs timeout before go to next case
		&check_ncstimeout();
    }
}

###################################################
#Function used to Run all test suite
###################################################
sub run_all_testsuite
{
    $log->info("");
    $log->info("run all test suite start...");
    my @suite_types = split(/\s+|,/, $props->get("ncs.test.suites"));
    $log->info("suite types: @suite_types\n");
	sub get_test_suite{
		my ($test_suite_label) = @_;
		my $ori_suite = &trim($props->get($test_suite_label, ""));
		$ori_suite =~ s/-/../g;
		my @suite = eval($ori_suite);
		return @suite;
	};
	sub switch_configurable{
		my $suite_type = shift @_;
		if(!defined($suite_type)){ $suite_type = "openr6"; }
		$log->info("switch configurables start...");
		my @configurables = split(',', $props->get('ncs.configurable','necb,necb_ft'));
		$log->info("configurables: @configurables\n");
		my $command = $props->get('ncs.configurable.command', 'cp -f');
		my $model_exec_path = $props->get("ncs.model.output_path");
		foreach $conf (@configurables){
			$log->debug("switch $conf file...");
			my $path = $props->get("ncs.${conf}.path");
			my $file = $props->get("ncs.${conf}.file");
			$log->debug("get $conf file from key: ncs.${conf}.".$suite_type);
			my $conf_suite = $props->get("ncs.${conf}.".$suite_type);
			$log->debug("got ${conf} file: $conf_suite");
			system("$command $path/$conf_suite $model_exec_path/$file");
			$log->info("swithed $conf file to $conf_suite");
		}
		$log->info("switch configurables end.");
	};
    foreach $suite_type (@suite_types){
        $log->info("");
        $log->info("run test suite $suite_type start...");
        my @test_suite = get_test_suite("ncs.test.suite.".$suite_type);
        if(@test_suite == 0){
            $log->warn("suite type may not valid: $suite_type");
            $log->warn("cannot found matched suite: ncs.test.suite.".$suite_type);
            next;
        }
		#check executable file
		&check_executable_file('model');
		&check_executable_file('test',$suite_type);
        #run test suite
        &switch_configurable($suite_type);
        &run_testsuite($suite_type, @test_suite);
        $log->info("run test suite $suite_type end...");
        $log->info("sleep 10 seconds to run next suite......");
        sleep(10);
    }
    $log->info("run all test suite end...");
}

1;
__END__
