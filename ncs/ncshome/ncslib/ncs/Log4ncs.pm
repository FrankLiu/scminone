#!/usr/bin/perl -w

package ncs::Log4ncs;

use vars qw(@ISA @EXPORT @EXPORT_OK);
use Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(init init_easy log_level is_loggable debug info warn error close);

use POSIX qw(strftime);
use ncs::Properties;

sub new
{
    my $this = {};
    bless $this;
    return $this;
}

sub init
{
    my ($class, $cfg) = @_;
    if (!defined($cfg) || $cfg eq ""){ 
        $cfg = "log4ncs.cfg";
    }
    $class->{'configure_file'} = $cfg;
    #print("cfg=$cfg\n");
    my $properties = ncs::Properties->new();
    $properties->load($cfg);
    $class->{'line_separator'} = $properties->get("log.line_separator", "\n");
    $class->{'log_level'} = $log_level = $properties->get("log.level", 4);
    $class->{'is_loggable'} = $class->is_loggable($log_level);
    $class->{'log_appender'} = $log_appender = $properties->get("log.appender", "screen");
    $class->{'log_file'} = $log_file = $properties->get("log.file", "log4ncs.log");
    #print("log_appender=$log_appender, log_file=$log_file");
    if($class->is_loggable() && index($log_appender, 'file') ne -1 && defined($log_file)){
        #print("open $log_file for write log");
        open(LOG_FILE, ">$log_file") || die("cannot open log file $log_file");
		system("chmod 775 $log_file");
        select(LOG_FILE);$|=1;select(STDOUT);
        $class->{'LOG_FILE'} = LOG_FILE;
    }
}

sub init_easy
{
    my ($class, $log_level, $log_appender, $log_file) = @_;
    $class->{'line_separator'} = "\n";
    $class->{'log_level'} = $log_level || 4;
    $class->{'is_loggable'} = ($log_level != 0 || $log_level > 4);
    $class->{'log_appender'} = $log_appender || "screen";
    $class->{'log_file'} = $log_file || "log4ncs.log";
    #print("log_appender=$log_appender, log_file=$log_file");
    if($class->is_loggable() && index($log_appender, 'file') ne -1 && defined($log_file)){
        #print("open $log_file for write log");
        open(LOG_FILE, ">$log_file") || die("cannot open log file $log_file");
		system("chmod 775 $log_file");
        select(LOG_FILE);$|=1;select(STDOUT);
        $class->{'LOG_FILE'} = LOG_FILE;
    }
}

sub log_level
{
    my $class = shift;
    return $class->{'log_level'};
}

sub is_loggable
{
    my ($class) = shift @_;
    my $log_level = $class->{'log_level'};
    #print("log_level=$log_level\n");
    #print("is_loggable=".($log_level > 0 || $log_level <= 4));
    return ($log_level > 0 || $log_level <= 4);
}

sub log
{
    my ($class, $msg, $log_type, $log_level_min) = @_;
    local $log_level = $class->{'log_level'};
    local $is_loggable = $class->{'is_loggable'};
    if(!$is_loggable){
        return;
    }
    local $log_appender = $class->{'log_appender'};
    local $line_separator = $class->{'line_separator'};
    local $now = strftime("%Y-%m-%d %H:%M:%S", localtime());
    #print("$msg, $log_level , $log_level_min,");
    if($log_level <= $log_level_min){
        if(index($log_appender, 'screen') ne -1){
            print STDOUT "[$now] [$log_type] $msg $line_separator";
        }
        local $LOG_FILE = $class->{'LOG_FILE'};
        if(index($log_appender, 'file') ne -1 && defined($LOG_FILE)){
            print $LOG_FILE "[$now] [$log_type] $msg $line_separator";
        }
    }
}

sub debug
{
    my ($class,$msg) = @_;
    $class->log($msg, 'DEBUG', 1);
}

sub info
{
    my ($class,$msg) = @_;
    $class->log($msg, 'INFO', 2);
}

sub warn
{
    my ($class,$msg) = @_;
    $class->log($msg, 'WARN', 3);
}

sub error
{
    my ($class,$msg) = @_;
    $class->log($msg, 'ERROR', 4);
}

sub close
{
    my $class = shift;
    if(defined($class->{'LOG_FILE'})){
        close($class->{'LOG_FILE'});
    }
    $class = {};
}

1;

__END__

