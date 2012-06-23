#/usr/lib/perl -w

use core::Logger;
use File::Basename;

my $cur_dir = dirname($0);
my $cfg = {
		'log.level' => "debug",
		'log.appender' => "screen,file",
		'log.appender.file' => "$cur_dir/LoggerTest.log",
		'log.dateformat' => "%Y-%m-%dT%H:%M:%S"
	};
my $logger = core::Logger->new($cfg);
#$logger->debugon();
$logger->print_cfg();
$logger->info("-"x60);
$logger->debug("is_loggable=".$logger->is_loggable());
$logger->debug("test debug");
$logger->info("test info");
$logger->warn("test warn");
$logger->error("test error");
#$logger->debugoff();
sub test_extend
{
	my $component_name = $logger->name();
	my $component_actions = join(',',$logger->actions());
	my $original_component_actions = $component_actions;
	$logger->info("test extend...");
	$logger->info("component [$component_name] has actions: [$component_actions]");
	$logger->info("add action 'fine,finest'");
	$logger->add_actions('fine','finest');
	$component_actions = join(',',$logger->actions());
	$logger->info("component [$component_name] has actions: [$component_actions]");
	$logger->actions(split(',',$original_component_actions));
	$component_actions = join(',',$logger->actions());
	$logger->info("component [$component_name] has actions: [$component_actions]");
	
	#invoke action
	#$logger->invoke_action('info', 'invoke action test');
}
test_extend();

# $logger->info("sleep 10 seconds to check the auto flesh!");
# sleep(10);
# $logger->debug("test debug");
# $logger->info("test info");
# $logger->warn("test warn");
# $logger->error("test error");
