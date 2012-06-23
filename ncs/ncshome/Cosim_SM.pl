#!/usr/lib/perl -w

use Expect;

my $OS_NAME=`uname`; chomp($OS_NAME);
my $HOST_NAME=`uname -n`; chomp($HOST_NAME);
my $CUR_PATH=`pwd`; chomp($CUR_PATH);

my ($TRUE,$FALSE) = (1,0);
my ($PASS,$FAIL,$ERROR,$TIMEOUT,$NOTCONNECT,$CANNOTOPEN) = (1,2,4,8,16,32);

#runtime configure
my $MODEL_EXEC = "SubscriberManager.sct";
my $TEST_EXEC = "SM_OpenR6";
my $model_exec_path = "/vob/wibb_bts/msm/code/SubscriberManager/LinuxCosim";
my $model_log_prefix = "SM_";
my $test_exec_path = "/vob/wibb_bts/msm/test/sm_test/cosim/build";
my $test_log_prefix = "Testcase_";
my $test_timeout = 600;

#necb configure
my $necb_path = "/vob/wibb_bts/msm/test/sm_regression/necb";
my $necb_file = "NECB.xml";
my $necb_ftfile = "NECB_FT.xml";
my $necb_motor6 = "NECB_MotR6.xml";
my $necb_rrm = "NECB_RRM.xml";
my $exp;

sub log4ncs
{
    $msg = shift @_;
    print("$msg\n");
}

sub kill_all
{
    system("killall -s 9 $MODEL_EXEC 2>/dev/null");
    log4ncs("killed model process: $MODEL_EXEC");
	system("killall -s 9 $TEST_EXEC 2>/dev/null");
    log4ncs("killed test process: $TEST_EXEC");
}

sub run_model
{
    my $testcase = shift @_;
    my $localtime = localtime;
    log4ncs("run model at: $localtime");

    chdir("$model_exec_path");
    my $model_exec = "$model_exec_path/$MODEL_EXEC";
    my $model_test_log = "$CUR_PATH/$model_log_prefix$testcase.log";
    if(-e $model_test_log){
        system("rm -f $model_test_log");
        log4ncs("removed previous log: $model_test_log");
    }
    else{
        system("touch $model_test_log");
    }
    
    my $model_params = "set-trace 1;start-env;go-for;";
    my $test_params_file = "$CUR_PATH/test_params.sh";
    if(!(-e "$test_params_file")){
        system("touch $test_params_file");
        my @params = split(/,|;/, $model_params);
        foreach $param (@params){
            system("echo 'echo $param' >> $test_params_file");
			system("echo 'sleep 1' >> $test_params_file");
        }
		system("chmod +x $test_params_file");
    }
    log4ncs("echo '$model_params' | $model_exec >>$model_test_log 2>/dev/null &");
	#system("$test_params_file | $model_exec >>$model_test_log 2>/dev/null &");
	$exp = Expect->new();
	$exp->spawn("$model_exec >>$model_test_log 2>/dev/null");
	log4ncs("expect spawn $model_exec started...");
	$exp->log_stdout(1);
	#$exp->log_file($model_test_log);
    log4ncs("model running now, waiting for connect...");
}

sub start_model
{
	# unless ($exp->expect(30, "Waiting for TTCN-3 Runtime Interface (TRI) to connect ...")){
		# die("cannot initialize ttcn-3 runtime interface (tri)!");
	# }
	# $exp->expect(30, "Command : ");
	$exp->send("set-trace 1\n");
	sleep(1);
	#$exp->expect(30, "Command : ");
	$exp->send("start-env\n");
	sleep(1);
	#$exp->expect(30, "Command : ");
	$exp->send("go-for\n");
	#$exp->soft_close();
}

sub run_test
{
    my ($testcase,$nwg_mode) = @_;
    my $localtime = localtime;
    log4ncs("run testcase $testcase at: $localtime");
    
    my $test_flag = "-t3rt";
    my $test_params = "-par test_run $testcase -par approach 1 -par nwg_mode 1";
    my $test_params_nonwg = "-par test_run $testcase -par approach 1 -par nwg_mode 0";
    my $test_timeout_flag = "-conffloat t3rt.behavior.default.testcase_timeout";
    my $test_exec = "$test_exec_path/$TEST_EXEC";
    my $test_log = "$CUR_PATH/$test_log_prefix$testcase.log";
    if(-e $test_log){
        system("rm -f $test_log");
        log4ncs("removed previous log: $test_log");
    }
    else{
        system("touch $test_log");
    }
    
    if($nwg_mode){
        $test_params = "$test_flag \"$test_params\"";
    }
    else{
        $test_params = "$test_flag \"$test_params_nonwg\"";
    }
    log4ncs("$test_exec $test_timeout_flag $test_timeout $test_params >>$test_log 2>&1 &");
	system("$test_exec $test_timeout_flag $test_timeout $test_params >>$test_log 2>&1 &");
}

###################################################
#Function used to Run one model & one test
###################################################
sub run_model_and_test
{
    my ($testcase,$suite_type) = shift @_;
    if(!defined($suite_type)){
        $suite_type = "openr6";
    }
    
    log4ncs("run model and test for testcase: $testcase");
	run_model($testcase);
	if($suite_type eq "motor6"){
        run_test($testcase, 0);
    }
    elsif($suite_type eq "rrm"){
        run_test($testcase, 1);
    }
    else{
        run_test($testcase, 1);
    }
	sleep(3);
	start_model();
}

sub get_test_suite
{
    my $ori_suite = shift @_;
    my @suite = ();
    $ori_suite =~ s/-/../g;
    @suite = eval($ori_suite);
    return @suite;
}

sub switch_necb
{
    log4ncs("switch necb file start...");
    my $suite_type = shift @_;
    if(!defined($suite_type)){
        $suite_type = "openr6";
    }
    system("rm -f $model_exec_path/$necb_file");
    system("rm -f $model_exec_path/$necb_ftfile");
    system ("cp $necb_path/$necb_ftfile $model_exec_path/$necb_ftfile");	
    if($suite_type eq "motor6"){
        system ("cp $necb_path/$necb_motor6 $model_exec_path/$necb_file");	
    }
    elsif($suite_type eq "rrm"){
        system ("cp $necb_path/$necb_rrm $model_exec_path/$necb_file");	
    }
    else{
        system ("cp $necb_path/$necb_file $model_exec_path/$necb_file");	
    }
    log4ncs("swithed necb file to $suite_type");
    log4ncs("switch necb file end.");
}

sub parse_test_result
{
    my $testcase = shift @_;
    log4ncs("parse result for testcase: $testcase");
    my $model_test_log = "$CUR_PATH/$model_log_prefix$testcase.log";
    my $test_log = "$CUR_PATH/$test_log_prefix$testcase.log";
    
    #check if testcase finished
    my $test_timeout = 600;
    my $waiting_time = 1;
    my $model_logs_count = 0;
    
    my $i = 0;
	my $last_string = 0;
	my $seconds = 0;
    my $loop = 1;
	
    while (1)
	{
		if(!open(TEST_LOG, "<$test_log")){
            log4ncs("cannot open test log: $test_log");
            return $CANNOTOPEN;
        }
        if(!open(MODEL_LOG, "<$model_test_log")){
            log4ncs("cannot open model log: $model_test_log");
            return $CANNOTOPEN;
        }
        
		while(defined($line = <TEST_LOG>))
		{
			if (index ($line, "Test case summary") >= 0){ 
                close (TEST_LOG); 
                log4ncs("Testcase $testcase finished normally.");
                my $passnum = `grep "setverdict(pass)" $test_log | wc -l`;
                my $failnum = `grep "setverdict(FAIL)" $test_log | wc -l`;
                my $errornum =`grep "setverdict(ERROR)" $test_log | wc -l`;
               
                if($errornum > 0) {
                    log4ncs("Testcase $testcase... ERROR");
                    return $ERROR;
                }
                elsif($failnum > 0){
                    log4ncs("Testcase $testcase... FAILED");
                    return $FAIL;
                }
                elsif($passnum >0){
                    log4ncs("Testcase $testcase... PASS");
                    return $PASS;
                }
                return "FINISH";
            }
            if (index($line, "Description: Address not mapped to object") >= 0){ 
                close (TEST_LOG); 
                log4ncs("Testcase $testcase crashed: Address not mapped to object.");
                log4ncs("Testcase $testcase... ERROR");
                return $ERROR;
            }
			if (index($line, "CRITICAL ERROR: [CLIENT] Exiting") >= 0){ 
                close (TEST_LOG); 
                log4ncs("Testcase $testcase... NOT CONNECT: Model is not startup correctly, need retest!");
                return $NOTCONNECT;
            }
		}
		close (TEST_LOG);
		sleep (10);

		$last_string = $i;
		$i = 0;
		while(defined($line = <MODEL_LOG>))
		{
			if (index($line, "**************** ERROR *****************") >= 0){ 
                close (MODEL_LOG); 
                log4ncs("Testcase $testcase... ERROR: UML Error.");
                return $ERROR;
            }
			if (index($line, "**************** WARNING *****************") >= 0){ 
                close (MODEL_LOG);
                log4ncs("Testcase $testcase... ERROR: UML Warning.");
                return $ERROR;
            }
			if (index($line, "Exiting - bind error: Address already in use") >= 0){ 
                close (MODEL_LOG); 
                log4ncs("Testcase Error: Address already in use.");
                log4ncs("Testcase $testcase... NOT CONNECT, need retest!");
                return $NOTCONNECT;
            }
			$i = $i + 1;
			if ($last_string eq $i)
			{
				if (index($line, "OUTPUT of CMI_REGISTER_REQ") >= 0){ 
                    close (MODEL_LOG); 
                    log4ncs("Testcase Error: CMI_REGISTER_REQ");
                    log4ncs("Testcase $testcase... NOT CONNECT, need retest!");
                    return $NOTCONNECT;
                }
			}
		}
		close (MODEL_LOG);
		sleep (1);
		
		$seconds = $seconds + 1;
        if ($seconds eq $test_timeout)
        {
            log4ncs("Testcase $testcase... timeout - $test_timeout, need retest!!");
            return $TIMEOUT;
        }
		log4ncs("waiting for testcase $testcase finished loop: $loop");
        $loop++;
	}
}

sub waiting_stop
{
    my $test_result = shift @_;
    log4ncs("check if testcase need to be retested?");
    
    if($test_result == $TIMEOUT || $test_result == $NOTCONNECT || $test_result == $CANNOTOPEN){
        log4ncs("testcase need to be retested!!");
        return $TRUE;
    }
    log4ncs("testcase need not to be retested!!");
    return $FALSE;
}

########################################print coverage
sub print_testcase_coverage
{
	my ($testcase) = @_;
	return if not $exp;
	my $coverage_command = "print-coverage-table";
	my $coverage_log = "$CUR_PATH/Coverage_${testcase}.log";
	log4ncs("send \\n");
	$exp->send("\n");
	sleep(3);
	#$exp->expect(10, "Command : ");
	log4ncs("send $coverage_command $coverage_log");
	$exp->send("$coverage_command ${coverage_log}\n");
	#$exp->expect(10, "Command : ");
	$exp->soft_close();
}

###################################################
#Function used to Run one test suite
###################################################
sub run_testsuite
{
    my ($suite, $suite_type) = @_;
    if(!defined($suite)){
        log4ncs("please specify the suite you want to test!!");
        log4ncs("Usages:");
        log4ncs("\tperl Cosim.pl 20001-20005 [openr6|motor6|rrm]");
        log4ncs("");
        exit(-1);
    }
    if(!defined($suite_type)){
        $suite_type = "openr6";
    }
    log4ncs("run test suite $suite_type start...");
    
    my @test_suite = get_test_suite($suite);
    if(@test_suite eq 0){
        log4ncs("cannot load suite: $suite");
        return $FALSE;
    }
    
    #run test suite
    switch_necb($suite_type);
    log4ncs("test suite: @test_suite");
    foreach my $testcase (@test_suite){
		my $retried_times = 1;
		my $need_retest;
        #waiting stop
        while($retried_times == 1 || ($retried_times <= 10 && $need_retest)){
			run_model_and_test($testcase, $suite_type);
			my $test_result = parse_test_result($testcase);
			if($test_result == $PASS){
				&print_testcase_coverage($testcase);
			}
			$need_retest = waiting_stop($test_result);
            #kill all processes in any case
            kill_all();
            sleep(61);
            $retried_times++;
        }
		if($need_retest){
			log4ncs("we retried $retried_times times but testcase still not connected or not finished");
            log4ncs("give up testcase: $testcase");
		}
    }
    log4ncs("run test suite $suite_type end...");
}

#main function
sub main
{
    print <<EOT;
      ===============================
      Cosim Script for Developer
      ===============================
EOT
    print "OS_NAME=$OS_NAME\n";
    print "HOST_NAME=$HOST_NAME\n";
    print "CUR_PATH=$CUR_PATH\n";
    
    #run all test suite
    my ($suite, $suite_type) = @_;
    if(!defined($suite_type)){
        $suite_type = "openr6";
    }
    run_testsuite($suite, $suite_type);
}

main(@ARGV);
