#!/apps/public/perl_5.8.4/bin/perl
#############################################################################
#
#       Copyright Motorola, Inc. 2006 - 2010
#
#       The copyright notice above does not evidence any
#       actual or intended publication of such source code.
#       The code contains Motorola Confidential Restricted Information.
#
#############################################################################
#
#  FILE NAME:    buildProcessor.pl
#
#  OWNER:        LTE SCM Team
#
#  DATE CREATED: 07/07/2006
#
#  SYNOPSIS:     None.
#
#  EXIT VALUE:   1; - Mandatory for module to load successfully
#
#  DESCRIPTION:  This Perl tool/module contains common functions and
#                variables used for building targets.
#
#############################################################################
#
#  MODIFICATION HISTORY:
#
# Ver    Date     Engineer     CR                    Change
# --- ---------- ---------- -------- ----------------------------------------
# 1.0 01/14/2009 skerr1     01120994 Ported from iSD SCM (/vob/sct/bin).
# 1.1 03/31/2009 skerr1     01168245 Fixed SCM metrics reporting issue.
# 1.2 07/06/2009 skerr1     01206580 Now exporting print_and_log symbol.
# 1.3 08/19/2009 skerr1     01217463 Now exporting @targets symbol.
# 1.4 10/02/2009 skerr1     01242038 Updated to support product VOB location
#                                    for build type module and -l option.
# 1.5 11/24/2009 skerr1     01145469 Updated based on ltemgr_bp.pm changes.
# 1.6 11/25/2009 skerr1     01257533 Fixed metrics storage.
# 2.0 12/16/2009 skerr1     01269590 Changed structure so new features added
#				     easily.
# 2.1 05/04/2009 skerr1     01314961 Fixed logMetrics calls.
# 2.2 04/30/2010 skerr1     01304525 For label step, added recording of
#                                    $PUSER for metrics.
# 2.3 04/30/2010 skerr1     01313330 Added -steps none support.
# 3.0 05/21/2010 amn002     01269602 Post CQCM functionality added, closing
#                                    CRs, link baselines and close them
# 3.1 06/07/2010 amn002     01327076 Fix INC path and replace postPackage
#                                    with postPCQCM in post_cqcm step
# 4.0 05/27/2010 skerr1     01313325 Merge component support added.
#                amn002     01323888 valid_cqcm component support added.
#                ajm032     01323809 Restructure for reference storage.
# 5.0 06/30/2010 skerr1     01336346 valid_env component support added.
#                skerr1     01336346 close_build component support added.
#                skerr1     01336346 tracemerge support added to merge
#                                    component.
#                ajm032     01337121 project component support added.
# 5.1 08/05/2010 skerr1     01348638 Fixed processBldStep view and server
#                                    issue.
#                amn002     01351386 Updated INITIAL usage.
#
#############################################################################
#
#  FUNCTIONS:  (Alphabetical)
#
#	Local
#	-----
#	buildTargets()	        - Execute builds for specified targets
#       cleanup_local()         - Cleans up for interrupt or completed build.
#	execWMetrics()		- Execute passed command.  Record metrics and
#				  exit(1) for failures.
#	instrumentTargets()     - Execute instrumentation for specified
#				  targets
#	logMetrics()		- Prints metrics information to the specified
#				  metrics file
#	logTMPMetrics()		- Prints metrics information to the specified
#				  temp metrics file handle and returns
#				  summary time in metrics summary report
#				  format
#	print_usage()		- Prints this tool's usage message
#	procesBldStep()		- Process generic build step using @CMDs
#	processIntBldStep()	- Process internal build step (no @CMDs)
#	processSCMMetrics()	- Process temp metrics keeping only the
#				  longest time for commands executed in
#				  parallel
#	reapParallelProcs()	- Reap child process for parallel commands
#
#	BUILD_ENV
#	---------
#	close_build()		- Build release functionality
#	new()			- Create new object of the MERGE class
#	valid_env()		- Build environment validation functionality
#
#	CQCM
#	----
#	close_cqcm()		- Close CQCM functionality closing CRs, link
#                                 baselines and closing them
#	new()			- Create new object of the CQCM class
#	valid_cqcm()		- CQCM validation functionality, compare
#				  Build Req and CQCM DB
#
#	INITIAL
#	-------
#	new()			- Create new object of the INITIAL class
#
#	MERGE
#	-----
#	merge()			- Functionality for merging branches and
#				  validating merges
#	new()			- Create new object of the MERGE class
#
#	SCM_common
#	----------
#	check_env()		- Verifies and sets up the tool environment
#	daemonize()		- Turns this process into a daemon
#       default_create_view()   - Default command to create a ClearCase view
#	exec_cmd()		- Safely execute command and handle failures
#	mail_setup()		- Setup Mail::Sender configuration
#	print_and_log()		- Prints message to STOUT and/or to logfile
#	process_error()		- Error handling routine
#	send_email_update()	- Sends the passed message to the maillist
#	set_logfile()		- Sets up the logfile
#	trapsig()		- Called when the current process receives
#				  one of the signals monitored by this tool
#	usage_log()		- Records the usage of the current tool
#	write_to_script()	- Write passed command to the passed script
#
#############################################################################

## DEVELOPMENT NOTES:
#  -----------------
# 1. Any variables global to this package must be declared within the 'our'
#    directive, because of the strict pragma.

## CHECKLIST WHEN UPDATING THIS MODULE:
#  -----------------------------------
# 1. Update @EXPORT* if created a function or variable to be exported.
# 2. Update 'our' if added a global variable to this module or if a variable
#    needs to be exported.
# 3. Update the "FUNCTIONS" list in the prologue.
# 4. Update the "MODIFICATION HISTORY" in the prologue.
# 6. Turn Perl diagnostics (use diagnostics;) and strict (use strict) off
#    before release.
#############################################################################

##
## POD Documentation
##
=head1 NAME

B<buildProcessor.pl> - Executes a build for the specified build type

=head1 USAGE for B<buildProcessor.pl> v5.1

Standard B<buildProcessor.pl> usage:

     buildProcessor.pl -B/uild <build type> -V/ersion <build version>
                       [-s/teps <step1>,<step2>,...]
                       [-t/argets <target1>,<target2>,...]
                       [-m/ail <address1>,<address2>,...]
                       [-l/ogfile <logfile>] [-bg]


View the B<buildProcessor.pl> help message:

     buildProcessor.pl -h/elp

=head1 DESCRIPTION

This tool will by default execute all build steps for the specified build
type.  This includes any view creation and setting configuration
specifications as defined for the specified build type.  All targets defined
for the specified build type will be executed in parallel, so
B<buildProcessor.pl> will take only as long as the longest target build to
execute for the compile and instrumentation steps.  Currently, parallel
steps is not supported.

=over 1

=item Features include:

=item =================

=over 2

=item *

Supports any order/combination of valid_env, valid_cqcm, merge, compile, 
package, label, close_cqcm, project, instrumentation, ssm, and close_build
build steps

=item *

Send status messages for each milestone in the execution if desired

=item *

Can execute a subset of the defined targets for the specified build type

=item *

Can execute as a background process if desired

=back

=back

=head1 OPTIONS

=over 1

=item B<-B/uild>

The build type the user wishes to execute.

=item B<-V/ersion>

The build version the user wishes to create.  For some build types
specifying a version is optional as a default version may be defined.

=item B<-t/argets>

A comma delimited list of targets the user wishes to build.  Specify "none"
if you want to skip the target builds and only execute the post<Step> function.

=item B<-s/teps>

Defines the build steps to be executed.  Default behavior is to execute all
steps in @buildSteps for the build type.  You can define any subset of steps
in any order.  Specify "none" if you want to skip all steps and only execute
core B<buildProcessor.pl> functionality and pre and/or post build functions.

=item B<-l/ogfile>

Override the default logfile (./<UserID>_buildProcessor.log) with your own.

=item B<-m/ail>

Paging (email updates) on.  An optional comma delimited list of addresses
can be specified to send pages to instead of the default current user.

=item B<-bg>

B<buildProcessor.pl> will be executed as a background process.

=item B<-h/elp>

Print the help message for B<buildProcessor.pl>.

=back

=head1 RETURN VALUE

 0 for successful execution of all build steps
 !0 for the failure of any build step

=head1 EXAMPLES

=over 2

=item *

Execute a full "LTE WBC" build with version LTE-WBC_R1.0_DEVINT-3.01.00

B<buildProcessor.pl -B ltewbc -V LTE-WBC_R1.0_DEVINT-3.01.00>

=item *

Execute a "LTE WBC" build for just compilation with version
LTE-WBC_R1.0_DEVINT-3.01.00

B<buildProcessor.pl -B ltewbc -s compile -V LTE-WBC_R1.0_DEVINT-3.01.00>

=item *

Execute the same build as a background process with instrumentation

B<buildProcessor.pl -B ltewbc -s compile,instrument -bg -V 
LTE-WBC_R1.0_DEVINT-3.01.00>

=item *

Execute only an "lapsac" instrumentation build for the "LTE eNB" build type
for LTE-ENB_R1.0_BLD-3.01.00

B<buildProcessor.pl -B lteenb -s instrument -targets lapsac -V
LTE-ENB_R1.0_BLD-3.01.00>

=item *

Execute a full "LTE WBC" build with email updates on LTE-WBC_R1.0_DEVINT-3.01.00

B<buildProcessor.pl -B ltewbc -m wbcscm,skerr1>

=back

=head1 FILES

<build_type>_bp.pm - This file defines the steps to create the build type
set with the -B/uild flag.  This file must exist in the current directory
or somewhere else within the Perl library search path.  This includes
$SCM_ADMIN_VOB/bld/lib followed by /mot/proj/lte_scm/lib.

<build_version>.pm - This optional file is picked up for the build version
(aka baseline) specified with the -V/ersion flag.  It is used to define
information for a specific build.  You can override many of the default
values in B<buildProcessor.pl> including things like @branchesToMerge, so you
can set your own list of branches you want merged during the merge step.

=head1 NOTES

=over 2

=item *

B<buildProcessor.pl> requires that:

=over 2

=item *

You have write access to the present working directory.

=item *

You have write access to log directories defined for the current build
type.

=item *

You are in a supported Solaris (2.10) or Red Hat Enterprise
Linux (4.8 or 5.4) environment.

=back

=over 2

=item *

The pre/postBuild functions are always executed

=item *

If you terminate buildProcessor.pl (e.g. ctrl-c), you may lose some SCM
metrics due to the way child processes are reaped (via common solution).

=back

=item *

B<buildProcessor.pl> will send email updates to the user when the -m/ail flag
is invoked without addresses.  When you specify an address(es) with -m/ail,
B<buildProcessor.pl> will send email to that address(es).

=item *

You can specify a user's Unix ID rather than their entire email address.
To email to wgates1, foo@otherdomain.com and sjobs1,

use "-mail wgates1,foo@otherdomain.com,sjobs1".

=back

=head1 AUTHOR

Long Term Evolution Software Configuration Management Team

=cut

#############################################################################

# Used as error checking mechanism: does not allow re-declaration of
# the same variable within the same scope.  For testing purposes only.
# Note: We do not check for strict references in order to access globals from
#       other namespaces when rarely needed.  Sometimes they are dynamic or
#       at least only known at run-time (not compile-time)
#use strict qw(vars subs);
#use diagnostics;

BEGIN {

  # Set the location for LTE SCM modules.
  if (defined($ENV{'SCM_ADMIN_VOB'})) {
    push(@INC, $ENV{'SCM_ADMIN_VOB'} . '/bld/lib');
  } # if (defined...

  # Add path to LTE SCM libraries.
  push(@INC,($ENV{'SCM_ROOT'}||'/vob/ltescm').'/lib');

  # Add path to LTE SCM libraries after SCM_ROOT/lib is used.
  ($ENV{'SCM_ROOT'}) and push(@INC,'/vob/ltescm/lib');

  # Autoflush Standard Error and Output; No Output buffering
  select(STDERR); $| = 1;		# Make unbuffered
  select(STDOUT); $| = 1;		# Make unbuffered

} # end BEGIN

# Indicates that the entire library's symbol table or namespace is labeled
# as buildProcessor.  The compiler will look for any undefined symbols, in the
# calling program, in this package.
package buildProcessor;

use 5.8.4;	# Use Perl 5.8.4 or higher (also for debugging purposes)

## Internal SCM Modules
## Note: ":DEFAULT" will almost always be an entry
##       ! - do not import an entry or group
##       : - import a group
##

# For common SCM symbols
use SCM_common 1.0 qw(:DEFAULT
		      :BTOOLS
		      :CCTOOLS
		     );

# Used to setup export methods into calling programs.  Allows the use of
# import(), @ISA, @EXPORT, etc., which allows for different ways of exporting
# symbols.
require Exporter;

# Use for some functions to be POSIX compliant, allows access to POSIX
# identifiers, takes care of dynamic loading and autoloading (e.g. Perl
# subroutine definitions, etc.), and needed for strftime().
use POSIX;

use English;	    # Allows use of English names for Perl pre-defined vars
use Getopt::Long qw(:config no_ignore_case); # Use for options processing
use IO::Handle;	    # Use for autoflush
use Time::HiRes qw(time); # Use for timing
use Data::Dumper;   # Used for dumping data structures/debugging.

# Standard global symbols
our ($VERSION, @ISA, @EXPORT);

# Search location for unresolved functions in the current package.
# The search is left to right.
# Exporter is included here because of the import() function.
@ISA = qw(Exporter);

# List of symbols to be exported by :DEFAULT.
# List functions first, then all other symbols.
@EXPORT	  =  qw(default_create_view
                exec_cmd
                execWMetrics
        	logMetrics
		print_and_log
		process_error
		time
		write_to_script
        	send_email_update

        	@bTDirs
        	@buildSteps
        	$buildVer
        	$COMPILE_METRICS_FH
		$cp
		$createView
		$ct
		$DOMAIN
		$httpReleaseLoc
		$INSTR_METRICS_FH
		$lapTime
		*LOG_FH
		$logsDir
		$LABEL_METRICS_FH
		$MACHINE
		$maillist
		$MERGE_METRICS_FH
       		$objectsRef
		$pause
		$PKG_METRICS_FH
		$plcode
		$POSTBLD_METRICS_FH
		$PREBLD_METRICS_FH
		$product
		$release
		$releaseDir
		$results
		$SCM_ADMIN_VOB
		$scmEmail
		$scriptDir
		$SSM_METRICS_FH
		$STATUS_ERROR
		$STATUS_OK
		$system
		@targets
		$teamEmail
		$timeStamp
		$TIME_STAMP
		$tool
		$tool_version
		$USER
		$USE_BUILD_REQ
		$VIEWNAME
	       );

#============================================================================
#=====================  Exported Variable Initialization  ===================
#============================================================================
#
#  All exported package symbols must be declared with "our".
#

our @buildSteps = ();		# Build steps to execute
our $buildType = '';		# Build type
our $buildVer = '';		# Build version
our %close_cqcm = ();		# post compile CQCM
our %labeling = ();		# Labeling hash
our %merge = ();		# Merge hash
our %packaging = ();		# Packaging hash
our %close_build = ();		# Release build hash
our %ssm = ();			# SSM hash
our %project = ();		# CQCM project file hash
our %targets = ();		# Targets hash
our @targets = ();		# Array of targets to process
our %valid_env = ();		# pre compile ClearCase hash
our %valid_cqcm = ();		# pre compile CQCM hash

our $COMPILE_METRICS_FH = undef(); # Compile Metrics File Handle
our $TMP_COMPILE_METRICS_FH = undef(); # Temp Compile Metrics File Handle
our $INSTR_METRICS_FH = undef(); # Instrumentation Metrics File Handle
our $TMP_INSTR_METRICS_FH = undef(); # Temp Instr. Metrics File Handle
our $LABEL_METRICS_FH = undef(); # Label Metrics File Handle
our $MERGE_METRICS_FH = undef(); # Merge Metrics File Handle
our $PKG_METRICS_FH = undef();  # Packaging Metrics File Handle
our $POSTBLD_METRICS_FH = undef(); # Post Build Metrics File Handle
our $PREBLD_METRICS_FH = undef(); # Pre Build Metrics File Handle
our $SSM_METRICS_FH = undef();  # SSM Metrics File Handle

my $backGround = 0;		# $tool not run in the background by default
our @branchesToMerge = ();      # Branches we need to merge
our @bTDirs = ();		# Build Type=specific dirs to create
my $childInfo = '';		# Information about child processes
my @cLBuildSteps = ();		# Build step list from the command line
my @cLTargets = ();		# Target list from the command line
our $createView = '';		# ClearCase view creation command
our $debug = $ENV{'DEBUG'};	# Debug mode is set from environment
our $defaultBuildVer = '';	# Default Build Version
our $delivDir = '';             # Location of deliverables
my $execution_info = '';	# Information about this execution
our $httpReleaseLoc = '';	# http release link
my $lapTime = 0;		# Lap time
our $logsDir = '';              # Location of log files
our $maillist = '';		# String of email addresses
my @maillist = ();		# Array of email addresses
my %metrics = ();		# SCM Metrics storage
our $metricsDir = '';		# Location of build metrics
our $paging = $FALSE;		# Paging (send email updates) off by default
our $pause = $FALSE;		# Pause after steps (default is false)
our $plcode = 'pl';		# Default print_and_log code
$process_leader = $PROCESS_ID;	# Process ID for the process group
				# leader ($tool)
our $product = '';		# Product value (set in build type module)
our $release = '';		# Current system release
our $releaseDir = '';		# Root directory for logs, objects etc.
my $reqBTTemplateVer = 2.4;	# Required Build Type template version
our $results = '';              # Results to be displayed upon $tool exit
my $return_code = $STATUS_OK;	# $tool return value (default success)
our $SCM_ADMIN_VOB = '';	# Defined in build type template
our $scmEmail = '';		# SCM team email
our $scriptDir = '';		# Location of build script(s)
my $sTime = 0;			# Start time
my $reqFile;                    # Path to file which contain request
our $system = '';		# System value (set in build type module)
our $teamEmail = '';		# Customer/team email list
our $templateVersion = 0.0;	# Template version of the latest imported
				# module
our $timeStamp = strftime("%m%d%Y_%H%M", localtime); # Log file timestamp

# Supported build steps
our @validSteps = qw(valid_env valid_cqcm merge compile package label
                     close_cqcm project close_build instrument ssm);

our $USE_BUILD_REQ = undef();   # flag, turn on INITIAL object creation
# Hash table mapping module name to reference to it's object
our $objectsRef = {};

our $pager = '';		# Used for paging through output
# Set the pager to the user's environment PAGER or default to "more"
($pager = $ENV{'PAGER'}) or ($pager=$more);
# Add -E if the page is "less" so less won't hang at the end of the output
((grep(/less/,$pager)) > 0) and ($pager.=" -E");

my $package = __PACKAGE__;	# Current package name
my $logfile = "${USER}_${package}.log"; # Default $tool log file name

# Tool/Package Version Handling.  Note: VERSION is a Perl built-in and used
# when loading this package by other tools to verify any version
# requirements. $tool_version is used in this tool and SCM_common.pm.
our $tool_version = '5.1';
$VERSION = $tool_version;

#============================================================================
#==============================  Functions  =================================
#============================================================================

#----------------------------------------------------------------------------
#                         Function: buildTargets
#----------------------------------------------------------------------------
# Description:
#	Process the passed list of targets, building each in parallel.
#
# Argument(s):
#	$targetsRef	- Reference to %targets
#	@targets	- Array of targets to build
#
# Return value(s):
#	Exits process with $STATUS_ERROR, $STATUS_OK or function returns an
#	empty list, undefined or nothing depending on the context.
#
# Pre condition(s):
#	At least one target defined.
#	Metrics file handle already open.
#
# Post condition(s):
#	All target builds executed.
#
# Note(s):
#
sub buildTargets {
  my ($targetsRef, @targets) = @ARG;

  # Set lap time initial value
  $lapTime = time();

  foreach my $target (@targets) {

    print_and_log("$plcode", "($tool) Processing $target...\n\n");

    my $build = $targetsRef->{$target}->{'build'};

    my $buildCMDs  =  $build->{'buildCMDs'};
    my $buildLog   =  $build->{'buildLog'};
    my $configSpec =  $build->{'configSpec'};
    my $envVars    =  $build->{'envVars'};
    my $logging    =  $build->{'logging'};
    my $startDir   =  $build->{'startDir'};
    my $view       =  $build->{'view'};

    my $scriptName = "${target}_${buildVer}_build_script";
    my $script     = "${scriptDir}/${scriptName}";

    # If httpReleaseLoc is set and $buildLog is in $logsDir then add a http
    # link to the execution information
    my $logs = "\nLog File: \"$buildLog\"";
    if (defined($httpReleaseLoc) and $httpReleaseLoc and $buildLog =~ m/$logsDir/) {
      (my $http_loc = $buildLog) =~ s/$logsDir/$httpReleaseLoc\/logs/;
      chomp($http_loc=`wget "http://lnk.mot.com/?save=y&url=${http_loc}" -O - 2>/dev/null | grep Link:| cut -d\\\' -f2`);
      $logs .= "\nLog File Link: $http_loc";
    } # end if (defined...
    
    # Reset execution information for this specific target
    my $execution_info = "Build Type: \"$buildType\"\nStep: \"compile\"\nTarg"
      . "et: \"$target\"\nServer: \"$MACHINE.$DOMAIN\"$logs\nBuild View: \""
      . "$view\"\n$tool Process ID: \"$process_leader\"";

    # Parallel target builds
    defined(my $child = fork) or
      process_error('x',"Couldn't fork process for $target: $!");
    # $child has the child's PID if we are the parent process and 0 if we
    # are the child process, so next if we are the parent.
    $child and do {
      $childInfo .= "$target PID: $child\n";
      $targetsRef->{$child} = $target;
      $execution_info .= "\nTarget Process ID: \"$child\"";
      # Store the child specific execution information
      $targetsRef->{"${child}exec"} = $execution_info;
      sleep(1);
      next;
    }; # end $child and...   

    # We need to set the targetPID to the child process ID
    my $targetPID = $PROCESS_ID; # Process ID for the current process

    $execution_info .= "\nTarget Process ID: \"$targetPID\"";

    print_and_log($plcode,"Target Information:\n$execution_info\n\n");

    ## Setup logging
    # Redirect STDOUT to the correct log file for each target
    # (necessary for each target build)
    open(STDOUT, '>', "$buildLog") or
      process_error('x', "Can't redirect STDOUT to $buildLog: $!.");
    STDOUT->autoflush(1);

    # Redirect STDERR to the correct log file for each target
    # (necessary for each target build)
    open(STDERR, '>&', \*STDOUT) or
      process_error('x', "Can't dup STDERR to STDOUT: $!.");
    STDERR->autoflush(1);

#----------------------------------------------------------------------------

    # Check for "tee" in build commands
    (grep(/\|.*tee/, @$buildCMDs) > 0) and process_error('mw',
      "It appears one of the build commands for target $target is being"
      . ' piped to "tee", which would hide any failed return values from'
      . " the command.  This is dangerous and should be removed.  $tool"
      . " supports logging which can be setup in the $buildType.pm module.",
      $maillist, "$target build warning.");

#----------------------------------------------------------------------------

    ## Build
    ## Setup the build for $target

    # Check to see if view already exists
    `$ct lsview $view 2>&1 1>/dev/null`;

    # Capture the return status from the program and not the shell.
    # Exit value of the subprocess is in the high byte, $? >> 8.
    # The low byte says which signal the process died from, $?.
    my $rc = ($? >> 8);

    ## Create view if it doesn't exist
    if ($rc) {
      print("($tool) Creating View $view\n");
      # If a build specific createView is defined then use it, otherwise use
      # the default_create_view.
      if (defined &createView) {
	createView($view);
      } else {
	default_create_view($view, $createView);
      } # end if (defined...
    } else {
      print("($tool) View $view already exists. Continuing...\n");
    } # end if (!$rc...
    print("\n");

    # Set the view config spec
    print("($tool) Setting configuration specification $configSpec\n");
    exec_cmd('x', "$ct setcs -tag $view $configSpec",
             "Could not set config spec $configSpec for view $view!");
    print("($tool) Finished setting config spec.\n\n");


    ## Generate the target specific build script
    my $BLDSCRPT = undef(); # BLDSCRPT FH

    open($BLDSCRPT, '>' , "$script") or
      process_error('x',"Could not create the target build script" .
                        " \"$script\": $!");
    print($BLDSCRPT "#!/bin/ksh -p\n");
    print($BLDSCRPT "# Build Script for target: $target\n");
    print($BLDSCRPT "# Created $TIME_STAMP for $USER\n");
    print($BLDSCRPT "# Created by $tool $tool_version\n\n");

    # Check if build logging is desired
    if ($logging) { # Build command logging
      print($BLDSCRPT 'print "\n' . "($scriptName) $target build " .
                     "command logging active" . '.\n"' . "\n\n");
    } else { # No build command logging
      print($BLDSCRPT 'print "\n' . "($scriptName) Suppressing " .
                     "$target build command " . 'logging.\n"' . "\n\n");
    } # end if (!$logging...

    # Set into proper directory
    if ($startDir) {
      write_to_script($BLDSCRPT, $script, "cd ${startDir}",
                    "Setting into build start directory.");
    } # end if ($startDir...

    # Set environment vars
    if (scalar(keys(%$envVars)) > 0) {
      print($BLDSCRPT "print \"($scriptName) Setting env vars.\"\n");
      foreach my $k (sort keys %$envVars) {
        write_to_script($BLDSCRPT, $script, "export $k=$envVars->{$k}",
                      "Setting $k to $envVars->{$k}");
      } # end foreach...
      print($BLDSCRPT 'print "' . "($scriptName) Finished setting " .
                     'env vars.\n"' . "\n\n");
    } # end if (scalar(keys...

    # Execute the Build
    print($BLDSCRPT "print \"($scriptName) Building the $target target." .
		   '\n"' . "\n");
    foreach my $cmd (@$buildCMDs) {

      if (!$logging) { # No logging
        $cmd .= " 1>/dev/null 2>&1";
      } # end if ($logging...

      write_to_script($BLDSCRPT, $script, $cmd, "Executing build command");

    } # end foreach my $cmd...
    print($BLDSCRPT "print \"($scriptName) Finished executing build " .
                   'commands.\n"' . "\n\n");

    close($BLDSCRPT) or process_error('x', "Could not close BLDSCRPT: $!");

    # Set the permissions for $script
    (chmod(0775,$script) == 1)
      or process_error('x',
        "Cannot change permissions for $script to 775.");

    my $execCmd = "$ct setview -exec \"$script\" $view";

    print("($tool) Executing setview -exec for ${target}...\n");
    print("($tool) Command: $execCmd\n");

    my $PH = undef();   # Execution Process Handle
    open ($PH, '|-', "$execCmd")
      or process_error('x',
        "Could not open process handle for command ($execCmd): $!");
    close($PH);

    # Capture the return status from the program and not the shell.
    # Exit value of the subprocess is in the high byte, $? >> 8.
    # The low byte says which signal the process died from, $?.
    $rc = ($? >> 8);
    ($rc > 0) and do {
        # Log the metrics
        print_and_log('pl',logTMPMetrics($TMP_COMPILE_METRICS_FH,
          "$target Build Time", time()-$lapTime));
        # Error out
    	process_error('x',
	  "$target build failed with a return code of $rc: $!\n");
    }; # end ($rc > 0) and...

    # Get derived object count
    print("\n($tool) Getting the number of derived objects for SCM Build" .
          " Metrics.\n");
    my @derivedObjs = `$ct setview -exec \"$ct lspriv -do\" $view`;

    # Capture the return status from the program and not the shell.
    # Exit value of the subprocess is in the high byte, $? >> 8.
    # The low byte says which signal the process died from, $?.
    $rc = ($? >> 8);
    $rc and process_error('x',
      "\"$ct lspriv -do | wc -l\" failed with a return code of $rc: $!");
    (@derivedObjs) and print("($tool) Number of derived objects for " .
                             "$target: " . @derivedObjs . "\n");

    # Add build time
    $metrics{"$target Build Time"} = time()-$lapTime;

    # Add DO Count
    if (@derivedObjs) {
      $metrics{"$target Build Derived Object Count"} = scalar(@derivedObjs);
    } # end if (@derivedObjs...

    print("\n($tool) Finished processing $target!\n");

   ($paging) and send_email_update(
     "\n($tool) -\n\nTarget Information:\n\n$execution_info\n",
     "${tool} $target build complete!",$maillist);

#----------------------------------------------------------------------------

    # Finish up the target processing by writing SCM metric info to the build
    # log.
    open(STDOUT, '>>', "$buildLog") or
      process_error('x', "Can't redirect STDOUT to $buildLog: $!.");
    STDOUT->autoflush(1);


    foreach my $k (sort keys %metrics) {
      my $logEntry = '';

      if ($k =~ /Build Time/) {
        $logEntry = logTMPMetrics($TMP_COMPILE_METRICS_FH, $k, $metrics{$k});

      } else {
        $logEntry = sprintf("%s - %d\n", $k, $metrics{$k});

      } # end if ($k...
      print_and_log('pl',$logEntry);

    } # end foreach...

    # Close standard out and error.
    close(STDOUT);
    close(STDERR);

    exit($STATUS_OK); # exit child (target) process
  } # end foreach my $target...

return;

} # end sub buildTargets

#----------------------------------------------------------------------------
#                          Function: cleanup_local
#----------------------------------------------------------------------------
# Description:
#	This function cleans up for an interrupt or upon build completion.
#
# Argument(s):
#	None.
#
# Return value:
#	Function returns an empty list, undefined or nothing depending on
#	the context the function was called in.
#
# Pre condition(s):
#	None.
#
# Post condition(s):
#	All open file handles closed.
#
sub cleanup_local {

# Close all open file handles.
foreach my $kl(keys %buildProcessor::) {
  # If the symbol ends with _FH, it is not LOG_FH (in case we need to log
  # more) and it is a defined file handle, close it.
  (($kl =~ /_FH/) && ($kl ne "LOG_FH") && fileno($kl)) && close($kl);
} # end foreach my $kl...

return;

} # end sub cleanup_local

#----------------------------------------------------------------------------
#                          Function: execWMetrics
#----------------------------------------------------------------------------
# Description:
#	This function executes the passed command.  If it fails, it will
#	record the SCM metrics and exit gracefully.
#
# Argument(s):
#       $cmd		- The command to execute
#	$metricsFH	- Specific Metrics type File Handle
#	$sTime		- Start time for the current step
#
# Return value(s):
#	Exits with $STATUS_ERROR for any failure.  Function returns empty
#	list, undefined or nothing depending on the context.
#
# Pre condition(s):
#	Passed file handle has already been opened for writing to $script.
#
# Post condition(s):
#	Command executed.  Time added to metrics file and exited with
#	$STATUS_ERROR for any failure.
#
sub execWMetrics {

my ($cmd, $metricsFH, $sTime) = @ARG;
my $PH = undef();   # Process Handle
my $rc = undef;     # Return code from executed command

# Get the name of the calling subroutine
my $callSub = (caller (1) )[3];
# Strip off the namespace
$callSub =~ s/\w+:://;


open($PH, '|-', "$cmd") or do {
  logMetrics($metricsFH, '', $sTime, time()); # log the time
  # Log results
  $results .= "$callSub FAILED to complete successfully!\n";
  # Process and print the SCM metrics
  processSCMMetrics();
  process_error('mx',
                'Failed to open PH on ' . __FILE__ .
                ' line ' . (__LINE__ - 3) . '!', $maillist,
                "$tool failure (PID $$)");
};

close($PH);

# Capture the return status from the program and not the shell.
# Exit value of the subprocess is in the high byte, $? >> 8.
# The low byte says which signal the process died from, $?.
$rc = ($? >> 8);
($rc > 0) && do {
  logMetrics($metricsFH, '', $sTime, time()); # log the time
  # Log results
  $results .= "$callSub FAILED to complete successfully!\n";
  # Process and print the SCM metrics
  processSCMMetrics();
  process_error('mx',
                "$cmd failed with a return code of $rc: $!\n", $maillist,
                "$tool failure (PID $$)"
               );
};

return;

} # end sub execWMetrics

#----------------------------------------------------------------------------
#                         Function: instrumentTargets
#----------------------------------------------------------------------------
# Description:
#	Process the passed list of targets, instrumenting each in parallel.
#
# Argument(s):
#	$targetsRef	- Reference to %targets
#	@targets	- Array of targets to build
#
# Return value(s):
#	Exits process with $STATUS_ERROR, $STATUS_OK or function returns an
#	empty list, undefined or nothing depending on the context.
#
# Pre condition(s):
#	At least one target defined.
#	Metrics file handle already open.
#
# Post condition(s):
#	All defined instrumentation executed for each target.
#
# Note(s):
#
sub instrumentTargets {
  my ($targetsRef, @targets) = @ARG;
  my $rc = undef;     # Return code from executed command

  foreach my $target (@targets) {

    # Grab the instrumentation information for this target
    my $instrument = $targetsRef->{$target}->{'instrument'};

    # We need to set the targetPID to the child process ID
    my $targetPID = $PROCESS_ID; # Process ID for the current process

    # Skip this target if no instrumentation is defined (just warn)
    (scalar(keys(%$instrument) == 0)) and do {
      process_error('mw',"No instrumentation defined for target $target.  Skipping...\n",
        $maillist, "${tool} Process ${process_leader} Warning - No $target instrumentation defined");
      next;
    }; # end (scalar(keys...

    # Process each key in the %$instrument hash each of which represent types
    # of instrumentation for the current target.
    foreach my $iTarget (keys %$instrument) {

      # Set lap time
      $lapTime = time();

      my $curInstr    = $instrument->{$iTarget};
      my $iView       = $curInstr->{'view'};
      my $iConfigSpec = $curInstr->{'configSpec'};
      my $iEnvVars    = $curInstr->{'envVars'};
      my $iStartDir   = $curInstr->{'startDir'};
      my $iBuildCMDs  = $curInstr->{'buildCMDs'};
      my $iBuildLog   = $curInstr->{'buildLog'};
      my $iLogging    = $curInstr->{'logging'};
      my $iScriptName = "${target}_${iTarget}_${buildVer}_build_script";
      my $iScript     = "${scriptDir}/${iScriptName}";

      print_and_log("$plcode", "($tool) Processing $target $iTarget...\n\n");

      # If httpReleaseLoc is set and $iBuildLog is in $logsDir then add a
      # http link to the execution information
      my $logs = "\nLog File: \"$iBuildLog\"";
      if (defined($httpReleaseLoc) and $httpReleaseLoc and $iBuildLog =~ m/$logsDir/) {
        (my $http_loc = $iBuildLog) =~ s/$logsDir/$httpReleaseLoc\/logs/;
        chomp($http_loc=`wget "http://lnk.mot.com/?save=y&url=${http_loc}" -O - 2>/dev/null | grep Link:| cut -d\\\' -f2`);
        $logs .= "\nLog File Link: $http_loc";
      } # end if (defined...

      # Reset execution information for this target instrumentation
      my $execution_info = "Build Type: \"$buildType\"\nStep: \"instrument\""
	. "\nTarget: \"$target\"\nInstrumentation Type: \"$iTarget\"\nServer:"
	. " \"$MACHINE.$DOMAIN\"$logs\nBuild View: \"$iView\"\n$tool Process"
	. " ID: \"$process_leader\"";

      # Parallel target instrumentation
      defined(my $child = fork) or
        process_error('x',"Couldn't fork process for $target: $!");
      # $child has the child's PID if we are the parent process and 0 if we
      # are the child process, so next if we are the parent.
      $child and do {
        $childInfo .= "$target $iTarget instrumentation PID: $child\n";
        # Store the target name plus instrumentation type for later use
        $targetsRef->{$child} = "$target $iTarget";
        $execution_info .= "\nTarget Process ID: \"$child\"";
        # Store the child specific execution information
        $targetsRef->{"${child}exec"} = $execution_info;
        sleep(1);
        next;
      }; # end $child and...

      # We need to set the targetPID to the child process ID
      my $targetPID = $PROCESS_ID; # Process ID for the current process

      # Reset execution information now that the child process ID is known
      $execution_info .= "\nTarget Process ID: \"$targetPID\"";


      print_and_log($plcode,"Target Information:\n$execution_info\n\n");

      # Check for "tee" in instrumentation build commands
      (grep(/\|.*tee/, @$iBuildCMDs) > 0) and process_error('mw',
        "It appears one of the build commands for the $target $iTarget"
        . ' build is being piped to "tee", which would hide any failed'
        . ' return values from the command. This is dangerous and should'
        . " be removed. $tool supports logging which can be setup in the"
        . " $buildType.pm module.", $maillist, "$target build warning.");

      ## Setup logging
      # Redirect STDOUT to the correct log file for each target
      # (necessary for each target instrumentation build)
      open(STDOUT, '>', "$iBuildLog") or
        process_error('x', "Can't redirect STDOUT to $iBuildLog: $!.");
      STDOUT->autoflush(1);

      # Redirect STDERR to the correct log file for each target
      # (necessary for each target instrumentation build)
      open(STDERR, '>&', \*STDOUT) or
        process_error('x', "Can't dup STDERR to STDOUT: $!.");
      STDERR->autoflush(1);

      # Exit with an error if there are no build commands
      (scalar(@$iBuildCMDs) == 0) and process_error('x',
         "$target $iTarget has no build commands.\n");

      # Check to see if view already exists
      `$ct lsview $iView 2>&1 1>/dev/null`;
      # Capture the return status from the program and not the shell.
      # Exit value of the subprocess is in the high byte, $? >> 8.
      # The low byte says which signal the process died from, $?.
      $rc = ($? >> 8);

      ## Create view if it doesn't exist
      if ($rc) {
        print("($tool) Creating View $iView\n");
        # If a build specific createView is defined then use it, otherwise
        # use the default_create_view.
        if (defined &createView) {
          createView($iView);
        } else {
          default_create_view($iView, $createView);
        } # end if (defined...
      } else {
        print("($tool) View $iView already exists. Continuing...\n");
      } # end if (!$rc...
      print("\n");

      # Set the config spec if desired
      if ($iConfigSpec) {
        # Set the view config spec
        print("($tool) Setting configuration specification $iConfigSpec\n");
        exec_cmd('x', "$ct setcs -tag $iView $iConfigSpec",
                 "Could not set config spec $iConfigSpec for view $iView!");
        print("($tool) Finished setting config spec.\n\n");
      } # end if ($iConfigSpec...

      ## Generate the target specific instrumentation build script
      my $iBLDSCRPT = undef();    # Instrumentation BLDSCRPT FH

      open($iBLDSCRPT, '>' , "$iScript") or
        process_error('x',"Could not create the target instrumentation" .
                          " build script \"$iScript\": $!");
      print($iBLDSCRPT "#!/bin/ksh -p\n");
      print($iBLDSCRPT "# Build Script for target: $target\n");
      print($iBLDSCRPT "#    instrumentation type: $iTarget\n");
      print($iBLDSCRPT "# Created $TIME_STAMP for $USER\n");
      print($iBLDSCRPT "# Created by $tool $tool_version\n\n");

      # Check if build instr logging is desired
      if ($iLogging) { # Build instr command logging
        print($iBLDSCRPT 'print "\n' . "($iScriptName) $target $iTarget " .
                         "build command logging active" . '.\n"' . "\n\n");
      } else { # No build command logging
        print($iBLDSCRPT 'print "\n' . "($iScriptName) Suppressing " .
                         "$target $iTarget build command " . 'logging.\n"'
                       . "\n\n");
      } # end if (!$iLogging...

      # Set into proper directory
      if ($iStartDir) {
        write_to_script($iBLDSCRPT, $iScript, "cd ${iStartDir}",
                        "Setting into build start directory.");
      } # end if ($iStartDir...

      # Set environment vars
      if (scalar(keys(%$iEnvVars)) > 0) {
        print($iBLDSCRPT "print \"($iScriptName) Setting env vars.\"\n");
        foreach my $k (sort keys %$iEnvVars) {
          write_to_script($iBLDSCRPT, $iScript, "export $k=$iEnvVars->{$k}",
                          "Setting $k to $iEnvVars->{$k}");
        } # end foreach...
        print($iBLDSCRPT 'print "' . "($iScriptName) Finished setting " .
                         'env vars.\n"' . "\n\n");
      } # end if (scalar(keys...

      # Execute the Instrumentation Build
      print($iBLDSCRPT "print \"($iScriptName) Instrumenting the $target" .
            " target.\"\n");
      foreach my $cmd (@$iBuildCMDs) {

        if (!$iLogging) { # No logging
          $cmd .= " 1>/dev/null 2>&1";
        } # end if ($logging...

        write_to_script($iBLDSCRPT, $iScript, $cmd, "Executing $iTarget build"
                                                  . " command");

      } # end foreach my $cmd...
      print($iBLDSCRPT "print \"($iScriptName) Finished executing $iTarget " .
                       'build commands.\n"' . "\n\n");

      close($iBLDSCRPT)
        or process_error('x', "Could not close iBLDSCRPT: $!");

      # Set the permissions for $iScript
      (chmod(0775,$iScript) == 1)
        or process_error('x',
          "Cannot change permissions for $iScript to 775.");

      my $iExecCmd = "$ct setview -exec \"$iScript\" $iView";

      print("($tool) Executing setview -exec for ${iTarget}...\n");
      print("($tool) Command: $iExecCmd\n");

      my $iPH = undef();   # Execution Process Handle
      open ($iPH, '|-', "$iExecCmd")
        or process_error('x',
          "Could not open process handle for command ($iExecCmd): $!");
      close($iPH);

      # Capture the return status from the program and not the shell.
      # Exit value of the subprocess is in the high byte, $? >> 8.
      # The low byte says which signal the process died from, $?.
      $rc = ($? >> 8);
      ($rc > 0) and do {
        # Log the metrics
        print_and_log('pl',logTMPMetrics($TMP_INSTR_METRICS_FH,
          "$target $iTarget Build Time", time()-$lapTime));
        # Error out
        process_error('x',
         "$target $iTarget build failed with a return code of $rc: $!\n");
      }; # end ($rc > 0) and...

      # Add instr time
      $metrics{"$target $iTarget Build Time"} =
        time()-$lapTime;

      # Reset lap time
      $lapTime = time();

      print("\n($tool) Finished processing $target $iTarget!\n\n");

      ($paging) and send_email_update(
        "\n($tool) -\n\nTarget Information:\n\n$execution_info\n",
        "${tool} $target $iTarget build complete!",$maillist);

#----------------------------------------------------------------------------

      # Finish up the target processing by writing SCM metric info to the build
      # log.
      open(STDOUT, '>>', "$iBuildLog") or
        process_error('x', "Can't redirect STDOUT to $iBuildLog: $!.");
      STDOUT->autoflush(1);

      foreach my $k (sort keys %metrics) {
        my $logEntry = '';

        if ($k =~ /Build Time/) {
          $logEntry = logTMPMetrics($TMP_INSTR_METRICS_FH, $k, $metrics{$k});

        } else {
          $logEntry = sprintf("%s - %d\n", $k, $metrics{$k});

        } # end if ($k...
        print_and_log('pl',$logEntry);

      } # end foreach...

      # Close standard out and error.
      close(STDOUT);
      close(STDERR);

      exit($STATUS_OK); # exit child (target) process

    } # end foreach my $iTarget

  } # end foreach my $target...

return;

} # end sub instrumentTargets

#----------------------------------------------------------------------------
#                          Function: logMetrics
#----------------------------------------------------------------------------
# Description:
#	This function prints the calculated "real" time metrics to the passed
#       file handle.
#
# Argument(s):
#	$metricsFH	- Specific Metrics File Handle
#	$mType		- Metrics type (compile, instrument etc)
#	$sTime		- Start time we will subtract from Finish time
#	$fTime		- Finish time
#
# Return value(s):
#	Returns the "real" time.
#
# Pre condition(s):
#	Passed file handle has already been opened for writing.
#
# Post condition(s):
#	Time added to metrics file
#
# Note(s):
#       If you already have the total time, pass the total time in $fTime
#       and 0 for $sTime (when $fTime already = $tTime, $fTime-0=$tTime).
#
sub logMetrics {

my ($metricsFH, $mType, $sTime, $fTime) = @ARG;

# Log Metrics
my $tTime     = $fTime - $sTime;
my $tHour     = int($tTime/3600);
my $tMin      = int($tTime/60 - $tHour*60);
my $tSec      = ($tTime - $tHour*3600 - $tMin*60);
my $bTime     = sprintf("%dh%dm%.02fs", $tHour, $tMin, $tSec);

# Build time_scripts logging
print($metricsFH "real\t$bTime\n\n") or process_error("e",
  "Could not write metrics \"$bTime\".");

return sprintf("%s - %s\n", $mType, $bTime);

} # end logMetrics

#----------------------------------------------------------------------------
#                         Function: logTMPMetrics
#----------------------------------------------------------------------------
# Description:
#	This function prints the passed time to the passed TMP file handle
#	and then returns the time formatted for the summary report.
#
# Argument(s):
#	$metricsFH	- Specific Metrics File Handle
#	$mType		- Metrics type ()
#	$fTime		- Finish time
#
# Return value(s):
#	Returns the log entry containing what was built and time.
#
# Pre condition(s):
#	Passed file handle has already been opened for writing.
#
# Post condition(s):
#	Time added to already opened TMP metrics file
#
# Note(s):
#       If you already have the total time, pass the total time in $fTime
#       and 0 for $sTime (when $fTime already = $tTime, $fTime-0=$tTime).
#
sub logTMPMetrics {

my ($metricsFH, $mType, $bTime) = @ARG;

# TMP Build time_scripts logging
print($metricsFH "$bTime\n") or process_error(
  "e","Could not write $bTime to metricsFH.");

my $tHour    = int($bTime/3600);
my $tMin     = int($bTime/60 - $tHour*60);
my $tSec     = ($bTime - $tHour*3600 - $tMin*60);
$bTime    = sprintf("%dh%dm%.02fs", $tHour, $tMin, $tSec);

return sprintf("%s - %s\n", $mType, $bTime);

} # end logTMPMetrics

#----------------------------------------------------------------------------
#                          Function: print_usage
#----------------------------------------------------------------------------
# Description:
#	This function prints the usage of this tool to standard output.
#
# Argument(s):
#	Optional: Error message.
#
# Return value:
#	Exits tool with $STATUS_ERROR or function returns Empty List,
#       Undefined or Nothing depending on the context.
#
# Pre condition(s):
#	None.
#
# Post condition(s):
#	None.
#
sub print_usage {

my ($usage_error) = @ARG; # gathering the usage error sub argument
my $USAGE_OUT = undef();  # USAGE_OUT FH

# This next line makes sure usage_error has something
if (not defined($usage_error) or $usage_error eq "help") { $usage_error="";}

# We don't want the usage to fly by on the screen, so we need to open a
# process handle so we can pipe to $pager.  This will allow the user to
# page through the usage output even when usage errors are encountered.

open($USAGE_OUT, '|-', "$pager")
	or process_error('x',"Can't fork your pager ($pager): $!.");

print $USAGE_OUT <<EOT_USAGE;
$usage_error USAGE for $tool v$tool_version:

      Standard $tool usage:

               $tool -B/uild <build type> -V/ersion <build version>
                              [-s/teps <step1>,<step2>,...]
                              [-t/argets <target1>,<target2>,...]
                              [-m/ail <address1>,<address2>,...]
                              [-l/ogfile <logfile>] [-bg]


      View the $tool help message:

               $tool -h/elp


 NOTES:
  - Specify "-s none" to execute no steps but still execute core tool
    functionality and any pre/post build functions if defined.

  - Specify "-t none" to execute no target builds/instrumentation but
    still execute any pre/post build/step functions if defined.

  - $tool requires that:
       1. You have write access to the present working directory or
          the directory you specified for -l/ogfile.
       2. You have write access to the build type's log directory.
       3. You are in a supported Solaris 2.10 or Red Hat Enterprise
          Linux 4.8 or 5.4 (32/64-bit) environment.

  - $tool will send email updates to you ($USER) when the -m/ail
    flag is used without addresses.  When you specify an address(es),
    $tool will send email to the address(es).

  - You can specify a user's Unix ID rather than their entire email
    address.  To email to wgates1, foo\@otherdomain.com and sjobs1,
    use "-mail wgates1,foo\@otherdomain.com,sjobs1".

EOT_USAGE

close($USAGE_OUT) or process_error('w',
			"Can't close process handle USAGE_OUT: $!.");

return;

} # end sub print_usage

#----------------------------------------------------------------------------
#                        Function: processBldStep
#----------------------------------------------------------------------------
# Description:
#	Process the passed hash to execute the build step.
#
# Argument(s):
#	$stepHashRef	- Reference to step has configuration
#	$curStep	- Current build step
#	$metricsFH      - Metrics FH to use for this build step
#
# Return value(s):
#	Exits process with $STATUS_ERROR, $STATUS_OK or function returns an
#	empty list, undefined or nothing depending on the context.
#
# Pre condition(s):
#	Metrics file handle already open.
#
# Post condition(s):
#
# Note(s):
#
sub processBldStep {
  my ($stepHashRef, $curStep, $metricsFH) = @ARG;
  my $rc = undef;	# Return code for local commands
  
  # Set lap time initial value
  $lapTime = time();

  my $buildCMDs  = $stepHashRef->{'CMDs'};
  my $buildLog   = $stepHashRef->{'logFile'};
  my $configSpec = $stepHashRef->{'configSpec'};
  my $envVars    = $stepHashRef->{'envVars'};
  my $logging    = $stepHashRef->{'logging'};

  # Define the server we're executing on
  my $server     = '';
  if (defined $stepHashRef->{'server'}) {
     $server     = $stepHashRef->{'server'};
  } else {
     $server     = "$MACHINE.$DOMAIN";
  } # end if (defined...

  my $startDir   = $stepHashRef->{'startDir'};

  # Set the view value to the current view if not defined
  if (not defined $stepHashRef->{'view'} or $stepHashRef->{'view'} eq '') {
     $stepHashRef->{'view'} = $VIEWNAME;
  } # end if (not defined...
  my $view = $stepHashRef->{'view'};

  my $scriptName = "${curStep}_${buildVer}_build_script";
  my $script     = "${scriptDir}/${scriptName}";

  # If httpReleaseLoc is set and $buildLog is in $logsDir then add a http
  # link to the execution information
  my $logs = "\nLog File: \"$buildLog\"";
  if (defined($httpReleaseLoc) and $httpReleaseLoc and $buildLog =~ m/$logsDir/) {
    (my $http_loc = $buildLog) =~ s/$logsDir/$httpReleaseLoc\/logs/;
    chomp($http_loc=`wget "http://lnk.mot.com/?save=y&url=${http_loc}" -O - 2>/dev/null | grep Link:| cut -d\\\' -f2`);
    $logs .= "\nLog File Link: $http_loc";
  } # end if (defined...

  # Reset execution information for this build step
  my $execution_info = "Build Type: \"$buildType\"\nBuild Step: \"$curStep\""
    . "\nServer: \"$server\"$logs\nBuild View: \"$view\"\n$tool Process ID:"
    . " \"$process_leader\"";

  # Fork a child process for this build
  defined(my $child = fork) or
    process_error('x',"Couldn't fork process for $curStep: $!");
  # $child has the child's PID if we are the parent process and 0 if we
  # are the child process, so next if we are the parent.
  $child and do {
    $childInfo .= "$curStep PID: $child\n";
    $stepHashRef->{$child} = $curStep;
    $execution_info .= "\nStep Process ID: \"$child\"";
    # Store the child specific execution information
    $stepHashRef->{"${child}exec"} = $execution_info;
    sleep(1);
    return; # leave the function as we are the parent

  }; # end $child and...

  # We need to set the stepPID to the child process ID
  my $stepPID = $PROCESS_ID; # Process ID for the current process

  $execution_info .= "\nStep Process ID: \"$stepPID\"";

  print_and_log($plcode,"Build Step Information:\n$execution_info\n\n");

    ## Setup logging
    # Redirect STDOUT to the correct log file for each step
    # (necessary for each step)
    open(STDOUT, '>', "$buildLog") or
      process_error('x', "Can't redirect STDOUT to $buildLog: $!.");
    STDOUT->autoflush(1);

    # Redirect STDERR to the correct log file for each step
    # (necessary for each step build)
    open(STDERR, '>&', \*STDOUT) or
      process_error('x', "Can't dup STDERR to STDOUT: $!.");
    STDERR->autoflush(1);

#----------------------------------------------------------------------------

  # Check for "tee" in build commands
  (grep(/\|.*tee/, @$buildCMDs) > 0) and process_error('mw',
    "It appears one of the build commands for step $curStep is being"
    . ' piped to "tee", which would hide any failed return values from'
    . " the command.  This is dangerous and should be removed.  $tool"
    . " supports logging which can be setup in the $buildType.pm module.",
    $maillist, "$curStep build warning.");

#----------------------------------------------------------------------------

  ## Build
  ## Setup the build for $step

  # Don't bother creating the view if we're already set into it
  if ($view ne $VIEWNAME) {
    # Check to see if view already exists
    `$ct lsview $view 2>&1 1>/dev/null`;

    # Capture the return status from the program and not the shell.
    # Exit value of the subprocess is in the high byte, $? >> 8.
    # The low byte says which signal the process died from, $?.
    $rc = ($? >> 8);

    ## Create view if it doesn't exist
    if ($rc) {
      print("($tool) Creating View $view\n");
      # If a build specific createView is defined then use it, otherwise use
      # the default_create_view.
      if (defined &createView) {
        createView($view);
      } else {
        default_create_view($view, $createView);
      } # end if (defined...
    } else {
      print("($tool) View $view already exists. Continuing...\n");
    } # end if (!$rc...
    print("\n");

  } # end if ($view...

  # Set the view config spec if desired
  if (defined($configSpec) and $configSpec) {
    print("($tool) Setting configuration specification $configSpec\n");
    exec_cmd('x', "$ct setcs -tag $view $configSpec",
             "Could not set config spec $configSpec for view $view!");
    print("($tool) Finished setting config spec.\n\n");
  } # if ($configSpec...

  ## Generate the step specific build script
  my $BLDSCRPT = undef(); # BLDSCRPT FH

  open($BLDSCRPT, '>' , "$script") or process_error('x',
    "Could not create the step build script \"$script\": $!");

  print($BLDSCRPT "#!/bin/ksh -p\n");
  print($BLDSCRPT "# Build Script for step: $curStep\n");
  print($BLDSCRPT "# Created $TIME_STAMP for $USER\n");
  print($BLDSCRPT "# Created by $tool $tool_version\n\n");

  # Check if build logging is desired
  if ($logging) { # Build command logging
    print($BLDSCRPT 'print "\n' . "($scriptName) $curStep step " .
                   "command logging active" . '.\n"' . "\n\n");
  } else { # No build command logging
    print($BLDSCRPT 'print "\n' . "($scriptName) Suppressing " .
                   "$curStep step command " . 'logging.\n"' . "\n\n");
  } # end if (!$logging...

  if ($startDir) {
    # Set into proper directory
    write_to_script($BLDSCRPT, $script, "cd ${startDir}",
                  "Setting into build start directory.");
  } # end if ($startDir...

  # Set environment vars
  if (scalar(keys(%$envVars)) > 0) {
    print($BLDSCRPT "print \"($scriptName) Setting env vars.\"\n");
    foreach my $k (sort keys %$envVars) {
      write_to_script($BLDSCRPT, $script, "export $k=$envVars->{$k}",
                    "Setting $k to $envVars->{$k}");
    } # end foreach...
    print($BLDSCRPT 'print "' . "($scriptName) Finished setting " .
                    'env vars.\n"' . "\n\n");
  } # end if (scalar(keys...

  # Execute the Build
  print($BLDSCRPT "print \"($scriptName) Executing the $curStep step." .
  		   '\n"' . "\n");
  foreach my $cmd (@$buildCMDs) {

    if (!$logging) { # No logging
      $cmd .= " 1>/dev/null 2>&1";
    } # end if ($logging...

    write_to_script($BLDSCRPT, $script, $cmd, "Executing command");

  } # end foreach my $cmd...
  print($BLDSCRPT "print \"($scriptName) Finished executing commands.\n"
                . "\"\n\n");

  close($BLDSCRPT) or process_error('x', "Could not close BLDSCRPT: $!");

  # Set the permissions for $script
  (chmod(0775,$script) == 1) or process_error('x',
      "Cannot change permissions for $script to 775.");

  # Command we'll execute
  my $execCmd = "$script";
    
  # Only prefix with ct setview if $view not equal to $VIEWNAME or we are
  # running on a remote server.
  if ($view ne $VIEWNAME) {
    # SSH if we are instructed to use a remote server.
    if ($server and $server ne "$MACHINE.$DOMAIN" and $server ne "$MACHINE") {
      $execCmd = "/apps/public/bin/ssh -q $server $ct setview -exec "
               . "\"$execCmd\" $view";
    } else { # Local server but different view
      $execCmd = "$ct setview -exec \"$execCmd\" $view";
    } # end if ($server...
  } else { # we are already set into $view
    # SSH and setview if we are instructed to use a remote server.
    if ($server and $server ne "$MACHINE.$DOMAIN") {
      $execCmd = "/apps/public/bin/ssh -q $server $ct setview -exec "
               . "\"$execCmd\" $view";
    } # end if ($server...
  } # end if (defined($view)...

    print("($tool) Executing generated script for ${curStep}...\n");
    print("($tool) Command: $execCmd\n");

  my $PH = undef();   # Execution Process Handle
  open ($PH, '|-', "$execCmd")
    or process_error('e',
      "Could not open process handle for command ($execCmd): $!");
  close($PH);

  # Capture the return status from the program and not the shell.
  # Exit value of the subprocess is in the high byte, $? >> 8.
  # The low byte says which signal the process died from, $?.
  $rc = ($? >> 8);
  ($rc > 0) and do {
      # Next print them to the log
      print_and_log('pl',logMetrics($metricsFH,
        "$curStep Execution Time", $lapTime, time));
      # Error out
      process_error('x',
        "$curStep step failed with a return code of $rc!\n");
    }; # end ($rc > 0) and...

  # Add step execution time
  $metrics{"$curStep Execution Time"} = time()-$lapTime;

  print("\n($tool) Finished processing $curStep step!\n");

  ($paging) and send_email_update(
    "\n($tool) -\n\nBuild Step Information:\n\n$execution_info\n",
    "${tool} $curStep Step Complete!",$maillist);

#----------------------------------------------------------------------------

  # Print the metrics line to the log file
  foreach my $k (sort keys %metrics) {
    my $logEntry = logMetrics($metricsFH, $k, 0, $metrics{$k});

    print_and_log('pl',$logEntry);
  } # end foreach...

  # Close standard out and error.
  close(STDOUT);
  close(STDERR);

  exit($STATUS_OK); # exit child (curStep) process

} # end sub processBldStep

#----------------------------------------------------------------------------
#                        Function: processIntBldStep
#----------------------------------------------------------------------------
# Description:
#	Process the passed hash to execute the build step.
#
# Argument(s):
#	$stepHashRef	- Reference to step has configuration
#	$curStep	- Current build step
#	$metricsFH	- Specific Metrics type File Handle
#
# Return value(s):
#	Exits tool with $STATUS_ERROR or function returns with return value
#	of the last executed command (not particularly useful).
#
# Pre condition(s):
#
# Post condition(s):
#
# Note(s):
#
sub processIntBldStep {
   my ($stepHashRef, $curStep, $metricsFH) = @ARG;
   my $rc;

   # Set lap time initial value
   $lapTime = time();

   my $buildLog   = $stepHashRef->{'logFile'};

   # Define the server we're building on
   my $server     = '';
   if (defined $stepHashRef->{'server'}) {
      $server     = $stepHashRef->{'server'};
   } else {
      # We use $server locally as it is just easier
      $server     = "$MACHINE.$DOMAIN";
      $stepHashRef->{'server'} = "$MACHINE.$DOMAIN";
   } # end if (defined...

   # Set the view value to the current view if not defined
   if (not defined $stepHashRef->{'view'} or $stepHashRef->{'view'} eq '') {
      $stepHashRef->{'view'} = $VIEWNAME;
   } # end if (not defined...
   my $view = $stepHashRef->{'view'};

   # If httpReleaseLoc is set and $buildLog is in $logsDir then add a http
   # link to the execution information
   my $logs = "\nLog File: \"$buildLog\"";
   if (defined($httpReleaseLoc) and $httpReleaseLoc and $buildLog =~ m/$logsDir/) {
     (my $http_loc = $buildLog) =~ s/$logsDir/$httpReleaseLoc\/logs/;
     chomp($http_loc=`wget "http://lnk.mot.com/?save=y&url=${http_loc}" -O - 2>/dev/null | grep Link:| cut -d\\\' -f2`);
     $logs .= "\nLog File Link: $http_loc";
   } # end if (defined...

   # Reset execution information for this build step
   my $execution_info = "Build Type: \"$buildType\"\nBuild Step: \"$curStep\""
     . "\nServer: \"$server\"$logs\nBuild View: \"$view\"\n$tool Process ID:"
     . " \"$process_leader\"";


   # Fork a child process for this build
   defined(my $child = fork) or
     process_error('x',"Couldn't fork process for $curStep: $!");
   # $child has the child's PID if we are the parent process and 0 if we
   # are the child process, so next if we are the parent.
   $child and do {
     $childInfo .= "$curStep PID: $child\n";
     $stepHashRef->{$child} = $curStep;
     $execution_info .= "\nStep Process ID: \"$child\"";
     # Store the child specific execution information
     $stepHashRef->{"${child}exec"} = $execution_info;
     sleep(1);
     return; # leave the function as we are the parent

   }; # end $child and...

   # We need to set the targetPID to the child process ID
   my $stepPID = $PROCESS_ID; # Process ID for the current process

   $execution_info .= "\nStep Process ID: \"$stepPID\"";
   
   print_and_log($plcode,"Build Step Information:\n$execution_info\n\n");

   ## Setup logging
   # Redirect STDOUT to the correct log file for each target
   # (necessary for each target build)
   open(STDOUT, '>', "$buildLog") or
      process_error('x', "Can't redirect STDOUT to $buildLog: $!.");
   STDOUT->autoflush(1);

   # Redirect STDERR to the correct log file for each target
   # (necessary for each step build)
   open(STDERR, '>&', \*STDOUT) or
      process_error('x', "Can't dup STDERR to STDOUT: $!.");
   STDERR->autoflush(1);

#----------------------------------------------------------------------------

   # For steps project and rel_build we need COMMON.pm
   if (($curStep eq 'project') or ($curStep eq 'close_build')) {
     
     # Only process COMMON.pm if we haven't already
     if (!defined $objectsRef->{'COMMON'} ) {
       print_and_log($plcode, "\n\nrequiring COMMON.pm...\n");
       eval {
         require "COMMON.pm";  # COMMON module
         COMMON->import;
       }; # end eval
       $EVAL_ERROR and  process_error('x',
          "Could not load COMMON.pm.  There is probably a syntax error in "
         ."this file: $@");

       # Create new COMMON object
       # Wrap with eval to capture possible bless exception
       eval {
         $objectsRef->{'COMMON'} = new COMMON(  'LTE_LBL_NAME'   => $buildVer,
	 					'LTE_BLD_VIEW'   => $view,
                                                'PRE_BUILD_MODE' => 0 );
       } # end eval...
     } # end if (!defined...

     # Error out if object wasn't created properly
     if (!defined $objectsRef->{'COMMON'} or $EVAL_ERROR) {
       process_error('x',
         "$curStep step failed, common obj creation failed: $EVAL_ERROR\n");
     } # end if (!defined...
   } # end if (($curStep...


   # Step-specific actions
   case: {

     (($curStep eq 'valid_env') or ($curStep eq 'close_build')) and do  {

        # Create new BUILD_ENV object
     	# Require and read in symbols from BUILD_ENV.pm
        if (!defined $objectsRef->{'BUILD_ENV'} ) {
          print_and_log($plcode, "\n\nrequiring BUILD_ENV.pm...\n");
          eval {
            require "BUILD_ENV.pm";  # Environment module
            BUILD_ENV->import;
          }; # end eval
          $EVAL_ERROR and process_error('x',
            "Could not load BUILD_ENV.pm.  There is probably a syntax error in"
            ."this file: $EVAL_ERROR");

          # Create new BUILD_ENV object
          # Wrap with eval to capture possible bless exception
          eval {
            $objectsRef->{'BUILD_ENV'} = new BUILD_ENV($stepHashRef, $debug);
          }; # end eval...
        } # end if (!defined...

        # Error out if object creation failed
        if (!defined $objectsRef->{'BUILD_ENV'} or $EVAL_ERROR) {
           process_error('x',
             "$curStep step failed, $curStep obj creation failed: $EVAL_ERROR\n");
        } # if (!defined objectsRef...

        ($debug) and print Dumper $objectsRef;

        # Execute the proper step function and capture the return code
        if ($curStep eq 'valid_env') {
          $rc = $objectsRef->{'BUILD_ENV'}->valid_env();
        } elsif($curStep eq 'close_build'){
          $rc = $objectsRef->{'BUILD_ENV'}->close_build();
        } else {
         print "Warning unexpected step: $curStep\n";
         $rc = 1;
        } # end if ($curStep...
        
        last case;
     }; # end valid_env or close_build step

     (($curStep eq "close_cqcm") or ($curStep eq "valid_cqcm")) and do  {
        # Create new CQCM object
        if (!defined $objectsRef->{'CQCM'} ) {
          print_and_log($plcode, "\n\nrequiring CQCM.pm...\n");
          eval {
            require "CQCM.pm";  # CQCM module
               CQCM->import;
          }; # end eval
          $EVAL_ERROR and  process_error('x',
              "Could not load CQCM.pm.  There is probably a syntax error in "
              ."this file: $EVAL_ERROR");
          my  $sys_prod    =   $system."-".$product;

          # Create new CQCM object
          # Wrap with eval to capture possible bless exception
          eval { 
            $objectsRef->{'CQCM'} = new CQCM($buildVer,$sys_prod);
          }; # end eval...
        } # end if (!defined...

        # Error out if object creation failed
        if (!defined $objectsRef->{'CQCM'} or $EVAL_ERROR) {
           process_error('x',
             "$curStep step failed, cqcm obj creation failed $EVAL_ERROR\n");
        } # end if (!defined...
          
        ($debug) and print Dumper $objectsRef;
        
        if ($curStep eq "valid_cqcm") {
          $rc = $objectsRef->{'CQCM'}->valid_cqcm();
        } elsif($curStep eq "close_cqcm"){
          $rc = $objectsRef->{'CQCM'}->close_cqcm();
        } else {
         print "Warning unexpected step: $curStep\n";
         $rc = 1;
        } # if ($curStep...
     }; # end valid or close CQCM step

     ($curStep eq "merge") and do  {
        # We assume that the integration branch we are merging to follows the
        # CQCM convention of matching the View tag.  The LTE process is to
        # execute the build from the integration view, so we assume the
        # branch is the $VIEWNAME.
        my $intBranch = $VIEWNAME;
        
        # The following covers WiMax and LTE view names for REL builds
        # Examples:
        #	lte-wbc_r2.0_rel-8.00.00
        #	lte-enb_r2.0_rel-1.02
        #	wmx-ap_r4.0_bld-bmc-ecloud-rel # They have bmc and ecloud for R4.0+
        #
        # This block will transform the view tag in the above formats to the
        # correct integration branch format for REL builds.
        #                      $1=system    $2=release
        if ($intBranch =~ /^([^-]*)-[^_]*_([^_]*)_.*rel.*$/) {
          my $locSys=$1;
          my $locRel=$2;
          if ($locSys =~ /wmx/) { $locSys='wimax';}
          
          $intBranch="${locSys}_${locRel}-main";
        } # end if ($intBranch...

     	# Only run the merge if there are branches to merge
        print_and_log($plcode, "\n\nrequiring MERGE.pm...\n");
        eval {
          require "MERGE.pm";  # MERGE module
          MERGE->import;
        }; # end eval
        $EVAL_ERROR and process_error('x',
            "Could not load MERGE.pm.  There is probably a syntax error in"
            ."this file: $EVAL_ERROR");

        # Create new MERGE object
        # Wrap with eval to capture possible bless exception
        eval {
          # Store the object
          $objectsRef->{'MERGE'} = new MERGE($stepHashRef, $intBranch, $debug);
        }; # end eval...

        # Error out if object creation failed
        if (!defined $objectsRef->{'MERGE'} or $EVAL_ERROR) {
           process_error('x',
             "$curStep step failed, $curStep obj creation failed $EVAL_ERROR\n");
        } # if (!defined $merge...

        ($debug) and print Dumper $objectsRef;

        $rc = $objectsRef->{'MERGE'}->processFunctions(@branchesToMerge);
        
        last case;
     }; # end merge step

     ($curStep eq "project") and do  {
     	print "$curStep\n";

        ($debug) and print Dumper $objectsRef;
	my $arr = $project{'exclude_lines'};
        $rc = $objectsRef->{'COMMON'}->create_dev_project($project{'in_vob'}, $project{'newgrp'},$project{'server'},$arr, $project{'projDir'});

     }; # end project step


   } # end case

   print Dumper $objectsRef if $debug; 

   # Check the return value from the function executed
   ($rc > 0) and do {
      # Next print them to the log
      print_and_log($plcode,logMetrics($metricsFH,
               "$curStep Execution Time", $lapTime, time() ));
      # Error out if object creation failed
      process_error('x',
            "$curStep step failed with a return code of $rc!\n");
   }; # end ($rc > 0) and...

   # Add step execution time
   $metrics{"$curStep Execution Time"} = time()-$lapTime;

   print("\n($tool) Finished processing $curStep step!\n");

   ($paging) and send_email_update(
         "\n($tool) -\n\nBuild Step Information:\n\n$execution_info\n",
         "${tool} $curStep Step Complete!",$maillist);

#----------------------------------------------------------------------------

   # Print the metrics line to the log file
   foreach my $k (sort keys %metrics) {
      my $logEntry = logMetrics($metricsFH, $k, 0, $metrics{$k});

      print_and_log($plcode,$logEntry);
   } # end foreach...

   # Close standard out and error.
   close(STDOUT);
   close(STDERR);

   exit($STATUS_OK); # exit child (curStep) process

} # end sub processIntBldStep

#----------------------------------------------------------------------------
#                      Function: processSCMMetrics
#----------------------------------------------------------------------------
# Description:
#	Process the TMP SCM Metrics.  We process those metrics here for steps
#	that execute target builds in parallel, keeping only the longest time
#	in the tmp file.
#
# Argument(s):
#	None.
#
# Return value(s):
#	Exits tool with $STATUS_ERROR or function returns with return value
#	of the last executed command (not particularly useful).
#
# Pre condition(s):
#
# Post condition(s):
#
# Note(s):
#	We add support only for those build steps that have parallel
#	processing and thus multiple parallel execution times.
#
sub processSCMMetrics {

#   "Final metrics FH" => "temporary metrics content location"
my %tmpDirs = ();

# Add compile if it was a build step (because parallel targets)
if (grep(/^compile$/, @buildSteps) >= 1 and
    -s "$metricsDir/compile/tmp_time_scripts" and $COMPILE_METRICS_FH) {
  $tmpDirs{"$metricsDir/compile/tmp_time_scripts"} = $COMPILE_METRICS_FH;
} # end unless (grep...

# Add instrumentation if it was a build step (because parallel targets)
if (grep(/^instrument$/, @buildSteps) >= 1 and
    -s "$metricsDir/instrumentation/tmp_time_scripts" and $INSTR_METRICS_FH) {
  $tmpDirs{"$metricsDir/instrumentation/tmp_time_scripts"} = $INSTR_METRICS_FH;
} # end unless (grep...

# Close up the tmp metrics files if they exist
($TMP_COMPILE_METRICS_FH) and close($TMP_COMPILE_METRICS_FH);
($TMP_INSTR_METRICS_FH) and close($TMP_INSTR_METRICS_FH);

# Process all metrics
for my $tmpMFile (keys %tmpDirs) {
    open(my $tmpFH, '<', $tmpMFile) or
      process_error('x', "Can't open " . $tmpMFile . ": $!.");

    my @lines = ();         # metrics lines

    # Read in file contents and push data to @lines
    while (my $tempLine = <$tmpFH>) {
      next if $tempLine =~ /^(\s)*$/; # skip blank lines
      chomp($tempLine);               # remove trailing newline characters
      push(@lines, $tempLine);        # push the data line onto the array
    } # end while ...

    close($tmpFH);

    # Find the longest build time
    my $maxTime = (sort { $b <=> $a } @lines)[0];

    # We only store the longest build time since the builds are executed in
    # parallel.  We pass empty string since this is not a build step.
    logMetrics($tmpDirs{$tmpMFile}, '', 0, $maxTime);

} # end for my $tmpMFile...

# Print target build results
print_and_log($plcode, "Execution Results:\n==================\n$results\n");

# Calculate and print the total build time
my $totalBuildHours = int((time()-$sTime)/3600);
my $totalBuildMins  = int((time()-$sTime)/60 - $totalBuildHours*60);
my $totalBuildTime = sprintf("Total $system $product Build Time - %u hour(s)"
  . " %u min(s)\n", $totalBuildHours, $totalBuildMins);
print_and_log($plcode,"\n$totalBuildTime\n");

($paging) and do {
  send_email_update(
    "\n($tool) -\n\n$execution_info\n\nExecution Results:\n$results\n" .
    "$totalBuildTime", "${tool} Process $process_leader Finished",$maillist);
  print("\n");
};

cleanup();

return;

} # end sub processSCMMetrics

#----------------------------------------------------------------------------
#                      Function: reapParallelProcs
#----------------------------------------------------------------------------
# Description:
#	This function prints the usage of this tool to standard output.
#
# Argument(s):
#	$hashRef	- Reference to the step configuration hash
#       $curStep	- The current build step we are processing
#
# Return value:
#	$STATUS_OK	- Success
#	$STATUS_ERROR	- Failure
#
# Pre condition(s):
#	Child process(es) waiting to be reaped.
#
# Post condition(s):
#	All child processes have been reaped and return values processed.
#
sub reapParallelProcs {

my ($hashRef, $curStep) = @ARG;
my $frc = $STATUS_OK;		# Function return value

print_and_log($plcode,
  "($tool) All child processes for $curStep step spawned.\n\n");

($paging) and do {send_email_update(
    "\n($tool) -\n\nBuild Information:\n\n$execution_info\n"
    . "\nChild process ID(s):\n$childInfo",
    "${tool} $curStep Step Started for Process $process_leader",$maillist);
  print("\n");};

print_and_log('l',"$curStep Step Metrics:\n");

#----------------------------------------------------------------------------

# Reap child processes before continuing.
# Waiting for all child processes to terminate.
# This will avoid zombie processes and the parent process needs to collect
# all child process return values in order to exit with the proper status.
my $child = '';
do {
  $child = waitpid(-1, &WNOHANG);
  my $rc = ($? >> 8);
  if ($child > 0) {
    # Set the title for this child
    my $title = $hashRef->{$child};
    if ($title ne $curStep) { $title .= " $curStep";}

    if ($rc == 0) {
      $results .= "$title (PID $child) completed successfully!\n";
    } else { # rc != 0
      $results .= "$title (PID $child) FAILED to complete successfully!\n";
      my $exec_info = $hashRef->{"${child}exec"};
      send_email_update("($tool) - ERROR:\n\n$title (PID:$child) build " .
        " failed with a return code of \"$rc\"!\n\n$exec_info\n",
        "$tool failure for $title",$maillist);
      $frc = $STATUS_ERROR; # Set function return code to failed
    } # end if ($rc...

  } # end if ($child...

  # This sleep is important to keep buildProcessor.pl from consuming too
  # many CPU cycles unnecessarily.
  sleep 1;

} until $child == -1;

print_and_log($plcode,"\n");

# Reset childInfo
$childInfo = '';

# Return function return code
return $frc;

} # end sub reapParallelProcs


#============================================================================
#===============================   M A I N   ================================
#============================================================================


##
## Validate the environment etc.
##

# Supported Operating System with version(s)
%sup_os = ('Linux' => [qw(2.6.9-55.ELsmp 2.6.9-89.ELsmp)],
           'SunOS' => [qw(5.10)],
);

@sup_domains = qw(cig.mot.com comm.mot.com);  # Supported Domains

check_env(qw(os_name os_ver domains));

#----------------------------------------------------------------------------


##
## Setup Mail
##

# set smtp server and mail domain suffix
mail_setup();

#----------------------------------------------------------------------------


##
## Trap signals
##

$SIG{'HUP'}  = sub { trapsig($ARG[0]); }; # 1 controlling TTY gets hang-up
$SIG{'INT'}  = sub { trapsig($ARG[0]); }; # 2 Ctrl+C (Interrupt)
$SIG{'QUIT'} = sub { trapsig($ARG[0]); }; # 3 Quit key
$SIG{'BUS'}  = sub { trapsig($ARG[0]); }; # 7 bus fault
$SIG{'SEGV'} = sub { trapsig($ARG[0]); }; # 11 segmentation fault
$SIG{'PIPE'} = sub { trapsig($ARG[0]); }; # 13 Broken Pipe
$SIG{'TERM'} = sub { trapsig($ARG[0]); }; # 15 Termination
$SIG{'XFSZ'} = sub { trapsig($ARG[0]); }; # 25 Excessive File Size limits
					  # reached

#----------------------------------------------------------------------------


##
## Log Tool Usage
##

undef(@ccsupport); 	# In this instance let's track ccsupport usage.
usage_log(@ARGV);

#----------------------------------------------------------------------------

##
## Process command line arguments
##

# Catch any bad opts, which are passed in the __WARN__ signal
$SIG{'__WARN__'} = sub {
  if ($ARG[0] =~ /^Unknown option: (.*)/) {
    # We only want the bad arg
    my $bad_arg = $1;
    chomp($bad_arg);
    process_error('u', "Invalid argument (-$bad_arg) specified.\n");
  } else {
    # GetOptions cuts the - off the arg, so we add it back for clarity
    (my $bad_arg = $ARG[0]) =~ s/Option /Option -/;
    chomp($bad_arg);
    process_error('u', "$bad_arg");
  } # if ($ARG[0]...
}; # end sub {

my $rc = GetOptions("Build|BUILD=s"     => \$buildType,
                    "bg|background"     => \$backGround,
                    "logfile=s"         => \$logfile,
                    "mail:s"            => sub { if ($ARG[1]) {
                                                   $paging = $TRUE; # Paging on
                                                   # Add list
                                                   push(@maillist, split(/,/,
                                                     join(',',$ARG[1])));
                                                 } else {
                                                   $paging = $TRUE; # Paging on
                                                   # Add $USER if not already
                                                   (!grep /$USER/,@maillist)
                                                   and push(@maillist,
                                                   $USER);
                                                 } # end if ($ARG...
                                               },
                    "steps=s"           => \@cLBuildSteps,
                    "targets=s"         => \@cLTargets,
                    "Version|VERSION=s" => \$buildVer,
                    "help|Help|HELP|?"  => sub { &print_usage;
					         exit($STATUS_OK)
                                               },
                    "version" => sub { print(
                                         "$tool version $tool_version\n");
				       exit($STATUS_OK)
                                     },
                    '<>'      => sub { process_error("u",
                                    "Received bad argument: $_[0]")
                                     },
                   );

(!$rc) and process_error('x', 'Some failure other than bad option has '
  . "occurred during option processing.\n");

# Set the __WARN__ back to the default behavior
local $SIG{'__WARN__'} = 'DEFAULT';

# Process @cLTargets to combine into properly formatted array.
@cLTargets = split(/,/,join(',',@cLTargets));

# Process @cLBuildSteps to combine into properly formatted array.
@cLBuildSteps = split(/,/,join(',',@cLBuildSteps));

# Add $USER if @maillist has not been set (for error paging)
(@maillist) or push(@maillist,$USER);
$maillist = join(",", @maillist);

# end of processing command line arguments


#----------------------------------------------------------------------------

##
## Setup logfile.
##

set_logfile($logfile);

#----------------------------------------------------------------------------


## Ensure all mandatory command line flags have been supplied

# Ensure a build type was defined
(!defined($buildType) or $buildType =~ /^\s*$/) and
  process_error("u",
    "Build type \"-B/uild <build type>\" must be provided!");

#----------------------------------------------------------------------------

## Read in necessary build-specific symbols

# Symbols from this module would be used within this tool or the buildType.pm
# module.
if ($buildVer and -f "${buildVer}.pm") {
  print_and_log('l', "\n\nrequiring ${buildVer}.pm...\n");
  eval {
    require "${buildVer}.pm";  # Release specific symbols
    $buildVer->import;
  }; # end eval {
  $EVAL_ERROR and process_error('x',
    "Could not load ${buildVer}.pm.  There is probably a syntax error in "
    . "this file: $EVAL_ERROR");
} # if (-f ...

#----------------------------------------------------------------------------

## Read in necessary build type symbols

# Append "_bp" to the $buildType as this tool uses *_bp.pm modules
$buildType .= "_bp";

print_and_log('l', "($tool) requiring ${buildType}.pm...\n\n");

eval {
  require "${buildType}.pm"; # Build type specific symbols
  $buildType->import;
}; # end eval {
$EVAL_ERROR and process_error('x',
  "Could not load ${buildType}.pm.  There is probably a syntax error "
  . "in this file: $EVAL_ERROR");
($templateVersion < $reqBTTemplateVer) and process_error('x',
  "The template version for $buildType.pm is " . $templateVersion . ", but"
  . " $tool requires version $reqBTTemplateVer!  Please update your "
  . "template.");

# And now remove the _bp from the build type so the use of $buildType makes
# sense the rest of the way through this tool.
$buildType =~ s/_bp$//;

#----------------------------------------------------------------------------

## Set initial execution information

# If httpReleaseLoc is set and $buildLog is in $logsDir then add a http
# link to the execution information
my $logs = "\nLog File: \"$logfile\"";
if (defined($httpReleaseLoc) and $httpReleaseLoc and $logfile =~ m/$logsDir/) {
  (my $http_loc = $logfile) =~ s/$logsDir/$httpReleaseLoc\/logs/;
  chomp($http_loc=`wget "http://lnk.mot.com/?save=y&url=${http_loc}" -O - 2>/dev/null | grep Link:| cut -d\\\' -f2`);
  $logs .= "\nLog File Link: $http_loc";
} # end if (defined...

$execution_info = "Tool: \"$tool\"\n$tool Process ID: \"$process_leader\""
  . "\nServer: \"$MACHINE.$DOMAIN\"\nExecution Directory: \"$cwd\"$logs";

# Append the view tag if the user is set into a ClearCase view
($VIEWNAME) and do {$execution_info .=
                      "\nCurrent ClearCase View: \"$VIEWNAME\"";};

#----------------------------------------------------------------------------

## Set target list if necessary, otherwise validate the passed list.

# If a target list wasn't defined on the command line or $buildVer.pm,
# populate @targets with all available targets.
case: {
  # Command line target lists always take precedence
  (scalar(@cLTargets) > 0) and do {
    @targets = @cLTargets;
    last case;
  }; # end (scalar...

  # Use all available targets if no command line or $buildVer.pm targets
  # defined
  ((scalar(@targets) <= 0) and (scalar(@cLTargets) <= 0)) and do {
    @targets = keys(%targets);
    last case;
  }; # end ((scalar...

} # end case: {

# Check to see that we have at least 1 target in @targets
if (scalar(@targets) <= 0) {
  process_error('x', "There are no targets to build.  Please check your"
    . "$tool usage.");
} # end if (!defined...

# Validate targets
foreach my $target (@targets) {
  if (!defined($targets{$target}) and $target ne "none") {
    process_error('x',
      "Invalid target \"$target\" specified for build type $buildType");
  } # end if (!defined($targets...
} # end foreach...

#----------------------------------------------------------------------------

## Set buildSteps list if necessary, otherwise validate the passed list.

# If a buildSteps list wasn't defined on the command line or $buildVer.pm,
# populate @buildSteps with all available steps.

# Command line target lists always take precedence
if (scalar(@cLBuildSteps) > 0) {
    @buildSteps = @cLBuildSteps;
} # end if (scalar...)

# Check to see that we have at least 1 step in @buildSteps
if (scalar(@buildSteps) <= 0) {
  process_error('x', "There are no build steps to execute.  Please check"
    . " your $tool usage.");
} # end if (!defined...

# Validate steps
foreach my $step (@buildSteps) {
  if (grep(/^$step$/,@validSteps) == 0 and $step ne "none") {
    process_error('x',
      "Invalid build step \"$step\" specified.  Valid steps are: " .
      join(', ',@validSteps) . '.');
  } # end if (grep...
} # end foreach...

#----------------------------------------------------------------------------

## Ensure a build version is set.

# A build version must be provided on the command line or a default
# provided for the current build type.
$buildVer ||= $defaultBuildVer;
if ((!defined($buildVer) or $buildVer =~ /^\s*$/)) {
  process_error("u",
    "Build version \"-V/ersion <version>\" must be provided!");
 } # end if ((!defined...

#----------------------------------------------------------------------------

##
## Background the current process if requested
##

if ($backGround) {

  print_and_log($plcode,
   "($tool) Backgrounding this process.\n\n");

  # Turn paging on
  $paging = $TRUE;

  # Background the process
  $execution_info = daemonize($logfile, $maillist);

  # Set $plcode to 'l' so text is not written twice now that STDOUT is
  # copied to LOG_FH.
  $plcode = 'l'

} # end if ($backGround...

#----------------------------------------------------------------------------

## Set execution information

# If httpReleaseLoc is set and $buildLog is in $logsDir then add a http
# link to the execution information
$logs = "\nLog File: \"$logfile\"";
if (defined($httpReleaseLoc) and $httpReleaseLoc and $logfile =~ m/$logsDir/) {
  (my $http_loc = $logfile) =~ s/$logsDir/$httpReleaseLoc\/logs/;
  chomp($http_loc=`wget "http://lnk.mot.com/?save=y&url=${http_loc}" -O - 2>/dev/null | grep Link:| cut -d\\\' -f2`);
  $logs .= "\nLog File Link: $http_loc";
} # end if (defined...

$execution_info = "Build Type: \"$buildType\"\nBuild Steps: \"" .
  join(",",@buildSteps) . "\"\nTargets: \"" . join(",",@targets) .
  "\"\n$tool Process ID: \"$process_leader\"\nServer: \"" .
  "$MACHINE.$DOMAIN\"\nExecution Directory: \"$cwd\"$logs";

# Append the view tag if the user is set into a ClearCase view
($VIEWNAME) and do {$execution_info .=
                      "\nCurrent ClearCase View: \"$VIEWNAME\"";};

print_and_log('l',"Execution Information:\n$execution_info\n");

#----------------------------------------------------------------------------

## Setup release directories

# Setup scriptDir (this is used internally by buildProcessor.pl)
$scriptDir = "$releaseDir/bin";

my @dirList = ($releaseDir,
               $scriptDir,
               $logsDir,
               $metricsDir,
               "$metricsDir/compile",
               "$metricsDir/instrumentation",
               "$metricsDir/label",
               "$metricsDir/merge",
               "$metricsDir/packaging",
               "$metricsDir/post_build",
               "$metricsDir/pre_build",
               "$metricsDir/ssmt",
               $delivDir,
              );

# Combine the buildProcessor and build type-specific dir lists
push(@dirList, @bTDirs);

print_and_log($plcode, "\n($tool) Creating required directories:\n");

foreach my $curDir (@dirList) {
    if (! -d $curDir) {
      print_and_log($plcode,"$curDir\n");
      mkdir($curDir, 0755) or process_error('mx', "Unable to create the "
        . "${curDir} directory: $!.\n\n$execution_info\n",
        $maillist, "${tool} failure (PID ${process_leader})");
    } # end if (! -d...
} # end foreach...
print_and_log($plcode,"\n");

#----------------------------------------------------------------------------

## Set start time
$sTime = time();

#----------------------------------------------------------------------------

## Create path to Build Request file if requested

# We only use INITIAL.pm if the build type requests it
if (defined $USE_BUILD_REQ and $USE_BUILD_REQ) {
   print_and_log($plcode, "\n\nUsing a build request.\n");
   (my $buildver = $buildVer) =~ tr/A-Z/a-z/;
   $reqFile = $logsDir."/request_".$buildver.".txt";
   print_and_log($plcode, "\n\nRequest will be stored in: $reqFile\n");

   print_and_log($plcode, "\n\nrequiring INITIAL.pm...\n\n");
   eval {
        require "INITIAL.pm";  # INITIAL module
        INITIAL->import;
   }; # end eval
   $EVAL_ERROR and  process_error('x',
            "Could not load INITIAL.pm.
            There is probably a syntax error in "
            ."this file: $EVAL_ERROR");

   # Create the initial object
   my $initial = new INITIAL($buildVer, $reqFile, $system);
   # Store the new object in the objects reference hash
   $objectsRef->{'INITIAL'} = $initial;

   # Error if there was an issue setting up and storing the new object
   if (!defined $objectsRef->{'INITIAL'}) {
        process_error('x',"INITIAL obj creation failed $!\n");
   } # end if (!defined...
   
   print Dumper $objectsRef if $debug;
} else {
  print_and_log($plcode, "\n\nNot using a build request.\n\n");
} # end if (defined...

#----------------------------------------------------------------------------

## Step processing

# Execute the preBuild function if defined (see build type module).
defined(&preBuild) and do {
  open($PREBLD_METRICS_FH, '>>', "$metricsDir/pre_build/time_scripts") or
    process_error('x', "Can't open $metricsDir/pre_build/time_scripts: $!.");
  $PREBLD_METRICS_FH->autoflush(1);
  print_and_log($plcode,"($tool) Executing custom preBuild function.\n\n");
  $lapTime = time();
  &preBuild;
  logMetrics($PREBLD_METRICS_FH, 'pre build', $lapTime, time());
  $results .= "preBuild completed successfully!\n";
}; # end defined...

#  Check if -steps none was specified
if (grep(/^none$/, @buildSteps) >= 1) {

  # The user specified -steps none, so we'll warn them and log it
  ($paging) and do {send_email_update(
  "\n($tool) -\n\nAll Steps SKIPPED because \"-steps none\" specified\n\nBuild"
  . " Information:\n\n$execution_info", "${tool} All Steps SKIPPED for Process"
  . " $process_leader.",$maillist);};
  $results .= "All Steps SKIPPED because -steps list had \"none\"!\n";

} else { #  Skip step processing if the user specified none.

  ## Process the build steps (order defined in build type module or cmd line)
  foreach my $step (@buildSteps) {

   case: {

    ## User requests to validate the ClearCase environment
    ($step eq "valid_env") and do {
      print_and_log($plcode,"($tool) Executing $step step.\n\n");
      # Open the standard metrics file.
      open($PREBLD_METRICS_FH, '>>', "$metricsDir/pre_build/time_scripts") or
        process_error('x',
         "Can't open open $metricsDir/pre_build/time_scripts: $!.");
      $PREBLD_METRICS_FH->autoflush(1);

      # Process the product-specific internal ClearCase validation definition
      processIntBldStep(\%valid_env, $step, $PREBLD_METRICS_FH);

      my $tmpRC = reapParallelProcs(\%valid_env, $step);
      ($tmpRC) and do {
        # Process and print the SCM metrics
        processSCMMetrics();
        process_error("x", "The $step step Failed!\n");
      }; # end ($tmpRC)...

      (defined &postValidENV) and do {
         print_and_log($plcode,
           "\n($tool) Executing custom postValidENV function.\n\n");
         $lapTime = time();
         &postValidENV;
         logMetrics($PREBLD_METRICS_FH, $step, $lapTime, time());
      	 $results .= "postValidENV completed successfully!\n";
      }; # (defined...
      last case;
    }; # end ($step

    ## Pre compilation cqcm activities like comparing REQ and DB
    ($step eq "valid_cqcm") and do {
      print_and_log($plcode,"($tool) Executing $step step.\n\n");
      # Open the standard metrics file.
      open($PREBLD_METRICS_FH, '>>', "$metricsDir/pre_build/time_scripts") or
        process_error('x',
         "Can't open open $metricsDir/pre_build/time_scripts: $!.");
      $PREBLD_METRICS_FH->autoflush(1);

      # Process the product-specific internal CQCM definition
      processIntBldStep(\%valid_cqcm, $step, $PREBLD_METRICS_FH);

      my $tmpRC = reapParallelProcs(\%valid_cqcm, $step);
      ($tmpRC) and do {
        # Process and print the SCM metrics
        processSCMMetrics();
        process_error("x", "The $step step Failed!\n");
      }; # end ($tmpRC)...

      (defined &postValidCQCM) and do {
         print_and_log($plcode,
           "\n($tool) Executing custom postValidCQCM function.\n\n");
         $lapTime = time();
         &postValidCQCM;
         logMetrics($PREBLD_METRICS_FH, $step, $lapTime, time());
      	 $results .= "postValidCQCM completed successfully!\n";
      }; # (defined...
      last case;
    }; # end ($step

    ## User requests merge brances
    ($step eq "merge") and do {
      print_and_log($plcode,"($tool) Executing $step step.\n\n");
      # Open the standard metrics file.
      open($MERGE_METRICS_FH, '>>', "$metricsDir/$step/time_scripts") or
        process_error('x',
         "Can't open open $metricsDir/$step/time_scripts: $!.");
      $MERGE_METRICS_FH->autoflush(1);

      # Process the product-specific internal merge definition
      processIntBldStep(\%merge, $step, $MERGE_METRICS_FH);

      my $tmpRC = reapParallelProcs(\%merge, $step);
      ($tmpRC) and do {
        # Process and print the SCM metrics
        processSCMMetrics();
        process_error("x", "The $step step Failed!\n");
      }; # end ($tmpRC)...

      (defined &postMerge) and do {
         print_and_log($plcode,
           "\n($tool) Executing custom postMerge function.\n\n");
         $lapTime = time();
         &postMerge;
         logMetrics($MERGE_METRICS_FH, $step, $lapTime, time());
      	 $results .= "postMerge completed successfully!\n";
      }; # (defined...
      last case;
    }; # end ($step

    ## User requests compilation
    ($step eq "compile") and do {
      print_and_log($plcode,"($tool) Executing $step step.\n\n");
      # Open the standard metrics file.
      open($COMPILE_METRICS_FH, '>>', "$metricsDir/$step/time_scripts") or
        process_error('x', "Can't open $metricsDir/$step/time_scripts: $!.");
      $COMPILE_METRICS_FH->autoflush(1);

      # Now open the tmp metrics file so we can collect parallel builds and
      # keep the longest build time.
      open($TMP_COMPILE_METRICS_FH, '>',
        "$metricsDir/$step/tmp_time_scripts") or
        process_error('x',
          "Can't open $metricsDir/$step/tmp_time_scripts: $!.");
      $TMP_COMPILE_METRICS_FH->autoflush(1);

      unless (grep(/^none$/, @targets) >= 1) {
      	# Process the product-specific target builds
        buildTargets(\%targets, @targets);

        my $tmpRC = reapParallelProcs(\%targets, $step);
        ($tmpRC) and do {
          # Process and print the SCM metrics
	  processSCMMetrics();
          process_error("x", "The $step step Failed!\n");
        }; # end ($tmpRC)...

      } else {
      	# The user specified -t none, so we'll warn them and log it
      	($paging) and do {send_email_update(
          "\n($tool) -\n\n$step Step SKIPPED because \"-targets none\" "
        . "specified\n\nBuild Information:\n\n$execution_info", "${tool} "
        . "$step Step SKIPPED for Process $process_leader.",$maillist);};
      	$results .= "$step SKIPPED because -target list had \"none\"!\n";
      } # unless (grep(/none/...
      (defined &postCompile) and do {
         print_and_log($plcode,
           "\n($tool) Executing custom postCompile function.\n\n");
         $lapTime = time();
         &postCompile;
         logMetrics($COMPILE_METRICS_FH, $step, $lapTime, time());
      	 $results .= "postCompile completed successfully!\n";
      }; # (defined...
      last case;
    }; # end ($step

    ## User requests packaging
    ($step eq "package") and do {
      print_and_log($plcode,"($tool) Executing $step step.\n\n");
      # Open the standard metrics file.
      open($PKG_METRICS_FH, '>>', "$metricsDir/packaging/time_scripts") or
        process_error('x',
         "Can't open $metricsDir/packaging/time_scripts: $!.");
      $PKG_METRICS_FH->autoflush(1);

      # Process the product-specific packaging definition
      processBldStep(\%packaging, $step, $PKG_METRICS_FH);

      my $tmpRC = reapParallelProcs(\%packaging, $step);
      ($tmpRC) and do {
        # Process and print the SCM metrics
        processSCMMetrics();
        process_error("x", "The $step step Failed!\n");
      }; # end ($tmpRC)...

      (defined &postPackage) and do {
         print_and_log($plcode,
           "\n($tool) Executing custom postPackage function.\n\n");
         $lapTime = time();
         &postPackage;
         logMetrics($PKG_METRICS_FH, $step, $lapTime, time());
      	 $results .= "postPackage completed successfully!\n";
      }; # (defined...
      last case;
    }; # end ($step

    ## User requests labeling
    ($step eq "label") and do {
      print_and_log($plcode,"($tool) Executing $step step.\n\n");
      # Open the standard metrics file.
      open($LABEL_METRICS_FH, '>>', "$metricsDir/$step/time_scripts") or
        process_error('x',
         "Can't open $metricsDir/$step/time_scripts: $!.");
      $LABEL_METRICS_FH->autoflush(1);

      # Record $PUSER as builder for this baseline
      open(my $BUILDER, '>>', "$metricsDir/builder") or
        process_error('mw',
          "Could not open $metricsDir/builder to record \"$ENV{PUSER}\" for $buildVer.\n",
          $maillist,
          "${tool} Process ${process_leader} Warning - Could not record builder.");
      
      # Not all systems support $PUSER, so we default to unknown.
      if (not defined $ENV{'PUSER'}) {$ENV{'PUSER'} = "unknown";}
      printf($BUILDER "$ENV{'PUSER'}\n");
      close($BUILDER);

      # Process the product-specific labeling definition
      processBldStep(\%labeling, $step, $LABEL_METRICS_FH);

      my $tmpRC = reapParallelProcs(\%labeling, $step);
      ($tmpRC) and do {
        # Process and print the SCM metrics
        processSCMMetrics();
        process_error("x", "The $step step Failed!\n");
      }; # end ($tmpRC)...

      (defined &postLabel) and do {
         print_and_log($plcode,
           "\n($tool) Executing custom postLabel function.\n\n");
         $lapTime = time();
         &postLabel;
         logMetrics($LABEL_METRICS_FH, $step, $lapTime, time());
      	 $results .= "postLabel completed successfully!\n";
      }; # (defined...
      last case;
    }; # end ($step

    ## Post compilation cqcm activities like closing CRs, linking baselines
    ## and closing them
    ($step eq "close_cqcm") and do {
      print_and_log($plcode,"($tool) Executing $step step.\n\n");
      # Open the standard metrics file.
      open($POSTBLD_METRICS_FH, '>>', "$metricsDir/post_build/time_scripts") or
        process_error('x',
         "Can't open open $metricsDir/post_build/time_scripts: $!.");
      $POSTBLD_METRICS_FH->autoflush(1);

      # Process the product-specific internal CQCM definition
      processIntBldStep(\%close_cqcm, $step, $POSTBLD_METRICS_FH);

      my $tmpRC = reapParallelProcs(\%close_cqcm, $step);
      ($tmpRC) and do {
        # Process and print the SCM metrics
        processSCMMetrics();
        process_error("x", "The $step step Failed!\n");
      }; # end ($tmpRC)...

      (defined &postCloseCQCM) and do {
         print_and_log($plcode,
           "\n($tool) Executing custom postCloseCQCM function.\n\n");
         $lapTime = time();
         &postCloseCQCM;
         logMetrics($POSTBLD_METRICS_FH, $step, $lapTime, time());
      	 $results .= "postCloseCQCM completed successfully!\n";
      }; # (defined...
      last case;
    }; # end ($step


    ## Creation CQCM project files
    ($step eq "project") and do {
      print_and_log($plcode,"($tool) Executing $step step.\n\n");
      print "--METRICS_FH:$metricsDir/post_build/time_scripts\n";
      # Open the standard metrics file.
      open($POSTBLD_METRICS_FH, '>>', "$metricsDir/post_build/time_scripts") or
        process_error('x',
         "Can't open open $metricsDir/post_build/time_scripts: $!.");
      $POSTBLD_METRICS_FH->autoflush(1);

      # Process the product-specific internal CQCM definition
      processIntBldStep(\%project, $step, $POSTBLD_METRICS_FH);

      my $tmpRC = reapParallelProcs(\%project, $step);
      ($tmpRC) and do {
        # Process and print the SCM metrics
        processSCMMetrics();
        process_error("x", "The $step step Failed!\n");
      }; # end ($tmpRC)...

      (defined &postProject) and do {
         print_and_log($plcode,
           "\n($tool) Executing custom postProject function.\n\n");
         $lapTime = time();
         &postProject;
         logMetrics($POSTBLD_METRICS_FH, $step, $lapTime, time());
      	 $results .= "postProject completed successfully!\n";
      }; # (defined...
      last case;
    }; # end ($step
    
    ## User requests instrumentation
    ($step eq "instrument") and do {
      print_and_log($plcode,"($tool) Executing $step step.\n\n");
      # Open the standard metrics file.
      open($INSTR_METRICS_FH, '>>', "$metricsDir/instrumentation/time_scripts")
        or process_error('x',
          "Can't open $metricsDir/instrumentation/time_scripts: $!.");
      $INSTR_METRICS_FH->autoflush(1);

      # Now open the tmp metrics file so we can collect parallel builds and
      # keep the longest build time.
      open($TMP_INSTR_METRICS_FH, '>',
        "$metricsDir/instrumentation/tmp_time_scripts") or
        process_error('x',
          "Can't open $metricsDir/instrumentation/tmp_time_scripts: $!.");
      $TMP_INSTR_METRICS_FH->autoflush(1);

      unless (grep(/^none$/, @targets) >= 1) {
      	# Process the product-specific target instrumentation
        instrumentTargets(\%targets, @targets);

        my $tmpRC = reapParallelProcs(\%targets, $step);
        ($tmpRC) and do {
          # Process and print the SCM metrics
	  processSCMMetrics();
          process_error("x", "The $step step Failed!\n");
        }; # end ($tmpRC)...

      } else {
      	# The user specified -t none, so we'll warn them and log it
      	($paging) and do {send_email_update(
          "\n($tool) -\n\n$step Step SKIPPED because \"-targets none\" "
        . "specified\n\nBuild Information:\n\n$execution_info", "${tool} "
        . "$step Step SKIPPED for Process $process_leader.",$maillist);};
      	$results .= "$step SKIPPED because -target list had \"none\"!\n";
      } # unless (grep(/none/...
      (defined &postInstrument) and do {
         print_and_log($plcode,
           "\n($tool) Executing custom postInstrument function.\n\n");
         $lapTime = time();
         &postInstrument;
         logMetrics($INSTR_METRICS_FH, $step, $lapTime, time());
      	 $results .= "postInstrument completed successfully!\n";
      }; # (defined...
      last case;
    }; # end ($step

    ## User requests source size metrics or "ssm"
    ($step eq "ssm") and do {
      print_and_log($plcode,"($tool) Executing $step step.\n\n");
      # Open the standard metrics file.
      open($SSM_METRICS_FH, '>>', "$metricsDir/ssmt/time_scripts") or
        process_error('x',
         "Can't open $metricsDir/ssmt/time_scripts: $!.");
      $SSM_METRICS_FH->autoflush(1);

      # Process the product-specific packaging definition
      processBldStep(\%ssm, $step, $SSM_METRICS_FH);

      my $tmpRC = reapParallelProcs(\%ssm, $step);
      ($tmpRC) and do {
        # Process and print the SCM metrics
        processSCMMetrics();
        process_error("x", "The $step step Failed!\n");
      }; # end ($tmpRC)...

      (defined &postSSM) and do {
         print_and_log($plcode,
           "\n($tool) Executing custom postSSM function.\n\n");
         $lapTime = time();
         &postPackage;
         logMetrics($SSM_METRICS_FH, $step, $lapTime, time());
      	 $results .= "postSSM completed successfully!\n";
      }; # (defined...
      last case;
    }; # end ($step

    ## User requests to close out the build
    ($step eq "close_build") and do {
      print_and_log($plcode,"($tool) Executing $step step.\n\n");
      # Open the standard metrics file.
      open($POSTBLD_METRICS_FH, '>>', "$metricsDir/post_build/time_scripts") or
        process_error('x',
         "Can't open open $metricsDir/post_build/time_scripts: $!.");
      $POSTBLD_METRICS_FH->autoflush(1);

      # Process the product-specific internal close build definition
      processIntBldStep(\%close_build, $step, $POSTBLD_METRICS_FH);

      my $tmpRC = reapParallelProcs(\%close_build, $step);
      ($tmpRC) and do {
        # Process and print the SCM metrics
        processSCMMetrics();
        process_error("x", "The $step step Failed!\n");
      }; # end ($tmpRC)...

      (defined &postCloseBuild) and do {
         print_and_log($plcode,
           "\n($tool) Executing custom postCloseBuild function.\n\n");
         $lapTime = time();
         &postCloseBuild;
         logMetrics($POSTBLD_METRICS_FH, $step, $lapTime, time());
      	 $results .= "postCloseBuild completed successfully!\n";
      }; # (defined...
      last case;
    }; # end ($step

   } # end case

  } # foreach my $step...

} # unless (grep(/none/...

# Execute the postBuild function if defined (see build type module).
defined(&postBuild) and do {
  open($POSTBLD_METRICS_FH, '>>', "$metricsDir/post_build/time_scripts") or
   process_error('x', "Can't open $metricsDir/post_build/time_scripts: $!.");
  $POSTBLD_METRICS_FH->autoflush(1);

  print_and_log($plcode,"($tool) Executing custom postBuild function.\n\n");
  $lapTime = time();
  &postBuild;
  logMetrics($POSTBLD_METRICS_FH, 'post build', $lapTime, time());
  $results .= "postBuild completed successfully!\n";
}; # end defined...

#----------------------------------------------------------------------------

# Process and print the SCM metrics
processSCMMetrics();

exit($return_code);

# EOF

