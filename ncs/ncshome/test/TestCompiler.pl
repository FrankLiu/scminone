#!/usr/bin/perl -w

use ncs::Log4ncs;
use ncs::Compiler;

my $log = ncs::Log4ncs->new();
$log->init_easy(1, 'file,screen', 'log4compiler.log');
my $compiler = ncs::Compiler->new();
$compiler->setLoggingService($log);

sub before_process{ $log->debug("before process invoked!"); }
sub after_process{ $log->debug("after process invoked!"); }
sub error_handler{ $log->error("error handler invoked!"); }
$compiler->registerBeforeProcess(\&before_process);
$compiler->registerAfterProcess(\&after_process);
$compiler->registerErrorHandler(\&error_handler);
my $logbasedir = qx{pwd};chomp($logbasedir);

sub compile_model{
	$compiler->setCompilePath('/vob/wibb_bts/msm/code/SubscriberManager');
	$compiler->setCompileTool('/opt/apps/Tau/bin/taubatch');
	$compiler->setCompileParams('-B -p SM.ttp -o pkgDeploymentArtifacts::Cosim_Linux');
	$compiler->setCompileMessage('Buiding SM');
	$compiler->setCompileLog("$logbasedir/compile_model.log");
	$compiler->setOutputPath('/vob/wibb_bts/msm/code/SubscriberManager/LinuxCosim');
	$compiler->setOutputFile('SubscriberManager.sct');
	$compiler->setMakefile('Makefile.SubscriberManager');
	$compiler->setMkLog("$logbasedir/compile_model.log");
	$compiler->setMkTimes(3);
	$compiler->compile();
}

sub compile_ttcn{
	my @ttcns = split(",", 'types/null_type.ttcn,types/pkg_SM_msgs_inv.ttcn,system/SystemArch_module.ttcn,templates/HAP_msg_templates.ttcn,templates/Headers_msg_templates.ttcn,functions/Functions_OLCC.ttcn,functions/Functions_MultiCarrier.ttcn,functions/Functions_HAP.ttcn,templates/CommonTemplates.ttcn,templates/NetworkEntry_msg_templates.ttcn,templates/Handover_msg_templates.ttcn,templates/IdleMode_msg_templates.ttcn,templates/CreateFlow_msg_templates.ttcn,functions/Functions.ttcn,functions/Functions_CreateFlow.ttcn,templates/Dhcp_msg_templates.ttcn,functions/Functions_NE_MIP_LEASE.ttcn,functions/Functions_IdleMode.ttcn,functions/Functions_DHCP.ttcn,functions/Functions_NetworkExit.ttcn,functions/Functions_Handover.ttcn,testcases/SM_HAP.ttcn,testcases/SM_DhcpMsgs.ttcn,testcases/SM_IdleMode.ttcn,testcases/SM_Init.ttcn,testcases/SM_NetworkEntry.ttcn,testcases/SM_InterAPHO.ttcn,testcases/SM_IntraAPHO.ttcn,testcases/SM_OLCC.ttcn,testcases/SM_MultiCarrier.ttcn,SM_OpenR6.ttcn');
	$compiler->setTtcns(@ttcns);
	$compiler->setCompilePath('/vob/wibb_bts/msm/test/sm_test');
	$compiler->setCompileTool('/opt/apps/Tester/bin/t3cg');
	$compiler->setCompileParams('-m 100 -l 100 -t 0 -K -B -O -r SM_OpenR6 -p "/vob/wibb_bts/msm/test/sm_test/cosim" -T -v 3 -c -d "build" -F');
	$compiler->setCompileMessage('Buiding Test');
	$compiler->setCompileLog("$logbasedir/compile_test.log");
	$compiler->setOutputPath('/vob/wibb_bts/msm/test/sm_test/cosim/build');
	$compiler->setOutputFile('SM_OpenR6');
	$compiler->setMakefile('TestModule.mak');
	$compiler->setMkLog("$logbasedir/mk_test.log");
	$compiler->setMkTimes(1);
	$compiler->compile();
}

&compile_model();
&compile_ttcn();
$log->close();
