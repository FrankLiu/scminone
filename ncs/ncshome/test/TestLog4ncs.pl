#/usr/lib/perl -w

use ncs::Log4ncs;

my $log = ncs::Log4ncs->new();
$log->init();

$log->debug("is_loggable=".$log->is_loggable());
$log->debug("test debug");
$log->info("test info");
$log->warn("test warn");
$log->error("test error");

$log->info("sleep 10 seconds to check the auto flesh!");
sleep(10);
$log->debug("test debug");
$log->info("test info");
$log->warn("test warn");
$log->error("test error");

$log->close();
