#!/usr/lib/perl -w
#
# NCS is a script built for running Cosim test suite nightly
# 

BEGIN{
	if(!defined($ENV{'NCS_HOME'})){ 
		our $NCS_HOME = `pwd`; chomp($NCS_HOME);
		$ENV{'NCS_HOME'} = $NCS_HOME
	}
	if(-e "$ENV{'NCS_HOME'}/ncslib"){ unshift(@INC, "$ENV{'NCS_HOME'}/ncslib"); }
}
use Getopt::Long;
use Net::FTP;
use POSIX qw(strftime);

use ncs::Common;
use ncs::Properties;
use ncs::Log4ncs;
use ncs::SR4ncs;
require "ncs/NcsVersion.pl";
require "ncs/Compiler2.pl";
require "ncs/Runner.pl";
require "ncs/Coverage.pl";
require "ncs/Mail4ncs.pl";

our $OS_NAME=`uname`; chomp($OS_NAME);
our $HOST_NAME=`uname -n`; chomp($HOST_NAME);
our $CUR_PATH=`pwd`; chomp($CUR_PATH);

my $ncslock = "$CUR_PATH/.ncslock";
my $ncslock_log = "$CUR_PATH/ncslock.log";
our ($ncs_start_time, $ncs_end_time);
our ($line_separator);
our ($properties_file, $props, $properties);
our ($store_dir, $log_dir, $log);
our ($pduconverter,$cleartool);
our ($tested_projects, $latest_project_label);
our ($TRUE,$FALSE) = (1,0);
#store current status
our $isbuildfailed = $FALSE;
our ($passnum, $failnum, $errornum) = (0, 0, 0);
our @build_results = ();
our @test_results = ();
our @err_messages = ();

sub intialize_ncs
{
    print("initialize NCS ...\n");
	my $localtime = localtime;
    $ncs_start_time = time();
	print("Initialize NCS at: $localtime\n");
	print("NCS start time is: $ncs_start_time\n");
	sub check_ncs_is_running{
		print "check if there is another NCS running?\n";
		my $ps = qx{ps -f -C perl|grep `whoami`|grep $properties_file|wc -l};
		print "found running NCS instance: $ps\n";
		$ps = int($ps||0);
		if(-e $ncslock){
			print("NCS found $ncslock file...\n");
			if($ps > 1){ #includes my self process, it should be more than 1
				print("NCS found another process is running\n");
				system("ps -ef|grep NCS");
				print("system exit due to another NCS process is running\n");
				exit(-1);
			}
			print("Probely NCS is terminated abnormally at last running!\n");
			print("No detected running instance, NCS will remove $ncslock and continue the process!\n");
			print("rm -f $ncslock"); system("rm -f $ncslock");
		}
	};
	sub check_sys_vars{
		print("\ncheck sytem variables ...\n");
		my @vars = qw{
			MOUSETRAP_HOME COSIM_DIR COSIM_PATH TEST_CDF
			TAU_TESTER TAU_TESTER_MAJOR_VER TAU_TESTER_MINOR_VER
			TAU_TTCN_DIR TAU_UML_DIR TIPC_DEV_ROOT
			OSTYPE DEBUG_LEVEL G2_GENERATE_MAPFILE AUTOGEN_EXTERNAL_OPS CC};
		foreach $var (@vars){
			check_var($var);
		}
	};
	sub load_configure{
		print("\nload configure file ...\n");
		$properties_file = "ncs_sm5.0.properties" if(!defined($properties_file));
		$props = ncs::Properties->new();
		$properties = $props->load($properties_file);
		$line_separator = $props->get("ncs.mail.line_sep","\n");
		#initialize cleartool
		$cleartool = $props->get("ncs.tool.cleartool");
		$pduconverter = $props->get("ncs.tool.pduconverter");
		#dirs
		$store_dir = $props->get("ncs.store.dir");
		$log_dir = $props->get("ncs.log.dir");
		#tested projects
		$tested_projects = $props->get("ncs.store.tested_projects");
	};
	sub initialize_ncs_dir{
		my $dir = shift;
		if (! -e "$dir"){
			print("$dir not exists, NCS will create it automatically\n");
			system("mkdir -p $dir");
			system("chmod 775 $dir");
		}
	};
	sub initialize_log{
		#initialize log
		print("\ninitialize log ...\n");
		my $log_level = $props->get("ncs.log.level")||0;
		my $log_appender = $props->get("ncs.log.appender", "file");
		my $log_file = $props->get("ncs.log.file");
		$log = ncs::Log4ncs->new();
		$log->init_easy($log_level, $log_appender, $log_file);
		print("ncs log is: $log_file\n");
	};
	#check if ncs is running now
    check_ncs_is_running();
	system("touch '$ncslock'");
    #check system variables
    check_sys_vars();
    #load configuration file
    load_configure();
	#initialize store dir & log dir
	initialize_ncs_dir($store_dir); 
	initialize_ncs_dir($log_dir);
    #initialize log service
    initialize_log();
    $localtime = localtime;
    $log->info("Initialized NCS at: $localtime");
    #print out configuration
    $log->debug("########## system variables ###########");
	foreach $var (keys(%ENV)){
		$log->debug("$var = $ENV{$var}");
	}
	$log->debug("########### system variables ###########");
	$log->debug("########### cofiguration variables ###########");
    foreach $prop (sort(keys(%$properties))){
        $log->debug("$prop = $$properties{$prop}");
    }
    $log->debug("########### cofiguration variables ###########");
}
sub initialize_project
{
    #initialize project
    $log->info("");
    $log->info("initialize project start...");
	sub initialize_ftp{
		my $servername = $props->get("ncs.ftp.server");
		my $username = $props->get("ncs.ftp.username");
		my $password = $props->get("ncs.ftp.password");
		my $ftp = Net::FTP->new($servername) or die "Could not connect: $servername\n";
		$ftp->login($username,$password) or die "Could not login with user $username.\n";
		return $ftp;
	};
	sub get_latest_prj_and_cs{
		$log->info("get latest project and config-spec...");
		my $ftp = &initialize_ftp();
		my $daily_prj_dir = $props->get('ncs.prj.daily_prj_dir');
		my $daily_build_dir = $props->get("ncs.prj.daily_build_dir");
		my $latest_prjs = $props->get('ncs.prj.latestprj_pattern');
		#get latest project
		$ftp->cwd("$daily_prj_dir");
		my @prjs = $ftp->ls("-t $latest_prjs");
		my $latestprj = $prjs[0];
		$latestprj =~ s/\.prj//;
		chomp($latestprj);
		#initialize log dir
        if (! -e "$log_dir/$latestprj"){ mkdir("$log_dir/$latestprj", 0777); }
		#initialize store dir
		if(!(-e "$store_dir/$latestprj")){ mkdir("$store_dir/$latestprj", 0777); }
		#prepare sync mails dir
		my $sync_dir = $props->get("ncs.ftp.sync_mails_dir");
		$ftp->cwd($sync_dir);
		my @fprjs = $ftp->ls("-t $latestprj");
		if(@fprjs == 0){$ftp->mkdir($latestprj);}
		#excludes the baseline release(1.XX.00) according to AP build policy
		my $prj_excludes_pattern = $props->get('ncs.prj.excludes_pattern');
		if($latestprj =~ /$prj_excludes_pattern/){
			$log->warn("The project $latestprj is same to previous release and will not be tested..");
			push(@err_messages,"The project $latestprj is same to previous release and will not be tested.");
			$latest_project_label = $latestprj;
			send_inform($latestprj,@err_messages);
			terminate_ncs(1);
			die("system exit due to project $latestprj is same to previous one!!!");
		}
		#download config-spec to local
		chdir("$log_dir/$latestprj");
		$ftp->cwd("$daily_build_dir/$latestprj");
		my $remotefile = "$latestprj".".cs";
		my $localfile  = "$latestprj"."_AH.cs";
		$ftp->get($remotefile,$localfile) or die "Could not get config-spec file: $remotefile\n";
		$ftp->quit();
		return $latestprj;
	};
	sub update_and_set_cs{
		$log->info("update config-spec and set config-spec...");
		my $prj = shift @_;
		my $fromfile  = "$prj"."_AH.cs";
		my $tofile = "$prj".".cs";
		chdir("$log_dir/$prj"); system("chmod 777 *");
		#update config-spec
		my $cs_prepends = $props->get('ncs.cs.prepends','');
		$log->info("config spec prepends: $cs_prepends");
		my $cosim_label_path = $props->get("ncs.cosim.path");
		my $cosim_label = $props->get("ncs.cosim.label");
		$log->info("cosim label: $cosim_label");
		my @append_lines = ();
		if(!&is_empty($cs_prepends)){
			my @prepends = split(/,|;/, $cs_prepends);
			foreach $prepend (@prepends){
				my $csrule = $props->get('ncs.cs.prepends.'.$prepend, '');
				push(@append_lines, $csrule) if(!&is_empty($csrule));
			}
		}
		push(@append_lines, "element $cosim_label_path/... $cosim_label") if(length($cosim_label) > 0);
		push(@append_lines, "element * $latest_project_label") if($latest_project_label);
		my $comment_line = "";
		copy($fromfile,$tofile,$comment_line,@append_lines);
		sleep(2);
		#set config-spec
		$log->debug("$cleartool setcs $log_dir/$prj/$prj.cs");
		system("$cleartool setcs $log_dir/$prj/$prj.cs");
	};
	sub get_project_name{
		my $project_name = shift;
		$project_name = qx{basename $project_name};
		$project_name =~ s/\.cs//; chomp($project_name);
		return $project_name;
	};
	sub initialize_prj_dir{
		my $project_name = shift;
		$log->info("initialize project dir: $project_name");
		#initialize project dir
		mkdir("$log_dir/$project_name", 0777) if (! -e "$log_dir/$project_name");
		#initiliaze buildlog & testlog dir & coverage dir
		mkdir("$log_dir/$project_name/buildlog", 0777) if (! -e "$log_dir/$project_name/buildlog");
		mkdir("$log_dir/$project_name/testlog", 0777) if (! -e "$log_dir/$project_name/testlog" );
		mkdir("$log_dir/$project_name/coverage", 0777) if (! -e "$log_dir/$project_name/coverage" );
		#initialize project store dir
		mkdir("$store_dir/$project_name", 0777) if(! -e "$store_dir/$project_name");
	};
	sub cleanup_prj_dir{
		my $project_name = shift;
		$log->info("cleanup project dir: $project_name");
		#clean up test logs
		my $cleanup_testlogs = $props->get("ncs.option.cleanup_testlogs", "0");
		if($cleanup_testlogs){
			#clean up all of logs under project
			$log->info("ncs.option.cleanup_testlogs turned on, NCS will clean up all of previous test log!");
			system("rm -rf $log_dir/$project_name/testlog/*.log") if(-e "$log_dir/$project_name/testlog/");
		}
		my $mail_store = $props->get("ncs.mail.store");
		$mail_store = "$store_dir/$project_name/$mail_store";
		$log->info("remove previous mail message: $mail_store");
		system("rm -f $mail_store") if(-e $mail_store);
	};
	
	my $run_with_cs = $props->get("ncs.option.run_with_cs", $FALSE);
    my $project_name;
    if($run_with_cs){ #run with specific config-spec
        $log->info("initialize project with config-spec $run_with_cs");
        if (!(-e $run_with_cs)){
            $log->error("Config-spec file not exists: $run_with_cs");
			push(@err_messages,"Config-spec file not exists: $run_with_cs!");
            send_inform($project_name,@err_messages);
            &terminate_ncs(1);
            die("system exit due to NCS Config-spec file not exists: $run_with_cs!!!");
        }
        $latest_project_label = $project_name = &get_project_name($run_with_cs);
		$log->info("project name is $project_name");
		&cleanup_prj_dir($project_name);
        &initialize_prj_dir($project_name);
		$cs_name = qx{basename $run_with_cs}; chomp($cs_name);
		$log->debug("cp $run_with_cs $log_dir/$project_name/$cs_name");
		system("cp $run_with_cs $log_dir/$project_name/$cs_name");
        #set config-spec
        $log->debug("$cleartool setcs $log_dir/$project_name/$cs_name");
        system("$cleartool setcs $log_dir/$project_name/$cs_name");
    }
    else{ #run with latest project's config-spec
        $log->info("initialize project by nightly build projects");
        $latest_project_label = $project_name = &get_latest_prj_and_cs();
		$log->info("project name is $project_name");
		&initialize_prj_dir($project_name);
        if((-e $tested_projects) && &contains_in_file($tested_projects, $project_name)){
            $log->error("Baseline $project_name is tested before and will be ignored!");
            push(@err_messages,"Baseline $project_name is tested before and will be ignored!");
            send_inform($project_name,@err_messages);
            &terminate_ncs(1);
            die("system exit due to NCS baseline $project_name is tested before!!!");
        }
		&cleanup_prj_dir($project_name);
        &update_and_set_cs($project_name);
    }
    $log->info("project name: $project_name");
    $log->info("latest project label: $latest_project_label");
    $log->info("initialize project end.");
}

sub parse_sr_mappings
{
	$log->info("parse sr mappings start...");
	my $sr_file = $props->get("ncs.test.sr_mapping_file");
	my $sr_mapping_worksheet = $props->get("ncs.test.sr_mapping_worksheet");
	local $sr_mappings;
	$log->info("sr mapping file: $sr_file");
	if(-e $sr_file){
		$log->debug("parse sr mapping file: $sr_file");
		my $sr4ncs = ncs::SR4ncs->new($sr_file);
		#$sr_mappings = &parse_mapping($sr_file);
		$sr_mappings = $sr4ncs->srMappings($sr_mapping_worksheet);
		$log->debug("parsed sr mapping file: $sr_file");
	}
	sub get_testcase_desc{
		my ($testcase, $result, $s) = @_;
		my $sr_desc = "";
		if($result ne "PASS" && exists($sr_mappings->{$testcase})){
			$sr_desc = $sr_mappings->{$testcase};
		}
		if($sr_desc eq "" && $result ne "PASS"){
			$sr_desc = "New failed case, need to be analyzed";
		}
		my $style = $s || lc($result);
		$testcase = &rstrip($testcase, 5, ".");
		return "Test Case $testcase... <span class='$style'>$result</span> $sr_desc$line_separator";
	};
	@test_results = map(&get_testcase_desc(split(':', $_, 3)), @test_results);
	$log->info("parse sr mappings end...");
}

sub terminate_ncs
{
	my $ncs_exception = shift;
	$log->info("terminate ncs");
    #close log service
    my $log_name = $props->get("ncs.log.name");
    print("\nterminate log...\n");
    $log->close();
	if($latest_project_label){
		if($ncs_exception){
			system("mv $log_dir/$log_name $log_dir/$latest_project_label/${log_name}.err");
			print("log is located at: $log_dir/$latest_project_label/${log_name}.err\n\n");
		}
		else{
			system("mv $log_dir/$log_name $log_dir/$latest_project_label/$log_name");
			print("log is located at: $log_dir/$latest_project_label/$log_name\n\n");
		}
	}
    #remove ncslock file for next run
    if(-e $ncslock){
        system("rm -f $ncslock");
        if(-e $ncslock_log){ system("rm -f $ncslock_log"); }
        $ncs_end_time = time();
        my $localtime = localtime;
		print("NCS end time is: $ncs_end_time\n");
        print("NCS is terminated at: $localtime\n");
        my ($spent_hr,$spent_mm,$spent_sec) = &count_time($ncs_start_time, $ncs_end_time);
        print("NCS spent ${spent_hr} hours,${spent_mm} minutes,${spent_sec} seconds to run all test suite!\n");
    }
	exit 1;
}

sub usage
{
	print <<"EOF"
Usage: NCS.pl [-p] <properties_file>
Usage: NCS.pl -help
Mandatory option -p <properties_file> should be the properties file
	eg, ncs_sm5.0.properties,ncs_sm4.0.properties etc.
EOF
}

sub parse_args
{
	my ($verbose,$name,$version,$help);
	Getopt::Long::GetOptions(
		"properties_file|p=s" 	=> \$properties_file,
		"verbose|verb"			=> \$verbose,
		"name|n"				=> \$name,
		"version|v"				=> \$version,
		"help|h|x" 				=> \$help
	);
	if(defined $help){
		&usage();
		exit -1;
	}
	if(defined $verbose){
		&print_ncs_verbose();
		exit -1;
	}
	if(defined $name){
		print &get_ncs_sname()."\n";
		exit -1;
	}
	if(defined $version){
		my $ncs_version = &get_ncs_version();
		print $ncs_version."\n";
		exit -1;
	}
	if(@ARGV>0){ $properties_file = $ARGV[0]; }
	if(&is_empty($properties_file)){
	    print STDERR "Please correctly input all mandatory options\n"; 
        &usage;
	    exit -1;
    }
}
	
#main function
sub main
{
    &print_ncs_verbose();
    print "OS NAME: $OS_NAME\n";
    print "HOST NAME: $HOST_NAME\n";
    print "CUR PATH: $CUR_PATH\n";
    #initialize NCS
    intialize_ncs();
    #initialize project
    initialize_project();
    #compile isl
    compile_isl($latest_project_label);
    #compile model code
    compile_model($latest_project_label);
    #compile test code
    compile_ttcn($latest_project_label);
    #run all test suite
    run_all_testsuite();
	#parse SR mappings
	parse_sr_mappings();
	#print coverage report
	export_coverage();
    #send mail
    send_mail();
    #terminate ncs
    terminate_ncs();
}

&parse_args();
&main();
exit 0;
