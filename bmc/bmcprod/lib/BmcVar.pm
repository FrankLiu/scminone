## Need to use the following vars from the main:: package
use vars qw($BIN_DIR $CONFIG_DIR $DATA_DIR);

package BmcVar;

use Sys::Hostname;

use vars qw(@ISA @EXPORT @EXPORT_OK);
use Exporter;
@ISA = qw(Exporter);
@EXPORT = qw($ct $cmbpBin $prjDir $wuceBin $commonView $bmcErrorPrefix $bmc $bmcInfoPrefix %scmCntPart $bmcInternalDebug $bmcDebug $cmbpMeta $mkView $scMergeList $scBRMerge $mergeStat $blreport $closebl $closecr $createbl $editrecord $linkbl $phaseTmpFile $stepTmpFile $bmcLogCnt $login $cronDir $host);

# ClearCase Env Vars
$ct = "/usr/atria/bin/cleartool";

# CMBP Env Vars
$cmbpBin = "/mot/proj/wibb_bts/cmbp/prod/cm-policy/bin";
$mkView = "$cmbpBin/mkview";
$scMergeList = "$cmbpBin/scMergeList";
$scBRMerge = "$cmbpBin/scBRMerge";
$mergeStat = "$cmbpBin/mergestat";
$blreport = "$cmbpBin/cqtool blreport";
$closebl = "$cmbpBin/cqtool closebl";
$closecr = "$cmbpBin/cqtool closecr";
$createbl = "$cmbpBin/cqtool createbl";
$editrecord = "$cmbpBin/cqtool editrecord";
$linkbl = "$cmbpBin/cqtool linkbl";
$prjDir = "/mot/proj/wibb_bts/cmbp/prod/cm-policy/config";
%scmCntPart = (
	    "BLD" => "REL",
	    "DEVINT" => "DEVINT",
	    "INT" => "INT",
);
$cmbpMeta ='bld|devint|int|BLD|DEVINT|INT';

# WUCE Env Vars
$wuceBin = "/vob/wuce/wuce/bin";

# BMC Env Vars
$stepTmpFile = 'WMX.template';
$phaseTmpFile = 'WMX-COMPOSITE.step';
$commonView = 'wibbstart';
$bmcErrorPrefix = 'be Error:';
$bmcInfoPrefix = 'be Info:';
$bmc = 'bmc';
$bmcInternalDebug = (defined $ENV{BMC_DEBUG})? 1:0;
$bmcDebug = 1;
$login = getlogin || (getpwuid($REAL_USER_ID))[0] || "Intruder";
$cronDir = "/home/$login/cron";
$host = hostname;

$bmcLogCnt = 15;

1;
