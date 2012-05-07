#!/usr/bin/perl -w
use vars qw($cwdir);
use vars qw($BIN_DIR $CONFIG_DIR $DATA_DIR);
use vars qw($SITE_CONFIG);
use vars qw($ct $CLEARTOOL $CMBP_HOME $cmbpBin $cmbpConfigDir $cmbpMeta $WUCE_HOME $wuceBin);
use vars qw($SEDNMAIL $SMTP_SERVER $MAILFROM $SCM_MAIL_GROUP);
use vars qw($bmcInstance $bmcComposite);

package Task;

use vars qw(@ISA @EXPORT @EXPORT_OK);
use Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(
	iRun
);

use Common;
use Mailiter;
use Clearcase;

sub sendmail
{
	my ($subject, $tolist, @mailbody) = @_;
	my $mailiter = Mailiter->new($subject, $tolist, @mailbody);
	$mailiter->smtpserver($SMTP_SERVER);
	$mailiter->from($MAILFROM);
	$mailiter->send();
}

#check whether the label exists or not
sub cCheckLabel
{
	my ($ins) = @_;
	(&isScmDebug()) && debug("...cCheckLabel start...");
	my $cmbpLabel = &iVersionInView($ins->{wuceProduct}, $ins->{nBView});
	info("Next Label/Version for Nightly Build View [$ins->{nBView}] is $cmbpLabel");
	my $vob = "/vob/$ins->{vobFamilyLower}";
	my $out = `$ct lstype -s lbtype:$cmbpLabel\@${vob}`;
	chomp($out);
	if($out =~ /$cmbpLabel/){
		my $errorMsg = "Nightly build under view $nbView was not kicked off because the label [$cmbpLabel] exists.";
		fatal($errorMsg);
		sendmail("Nightly build under view $nbView was not kicked off", $SCM_MAIL_GROUP, $errorMsg);
	}
	(&isScmDebug()) && debug("..cCheckLabel end!");
}

#check whether the given branches/config-spec is changed in nightly build view
sub cCheckBranches
{
	my ($ins) = @_;
	(&isScmDebug()) && debug("...cCheckBranches start...");
	my $brIsChanged = 0;
	my $smartbuildDir = $ins{smartbuildDir};
	my $nbView = $ins->{nBView};
	my $prev_cs = "$smartbuildDir/prev_cs_$nbView";
	my $curr_cs = "$smartbuildDir/curr_cs_$nbView";
	my $prev_crlist = "$smartbuildDir/prev_crlist_$nbView";
	my $curr_crlist = "$smartbuildDir/curr_crlist_$nbView";
	if(! -e $smartbuildDir){
		mkdir($smartbuildDir, 0775) or warn "Cannot make $smartbuildDir directory: $!";
		system("touch $prev_cs $curr_cs $prev_crlist $curr_crlist");
	}
	#check config spec change
	system("$ct catcs -tag $nbView > $curr_cs");
	my $csdiffout = `diff $prev_cs $curr_cs`;
	chomp($csdiffout);
	$brIsChanged = 1 if &isNotBlank($csdiffout);
	
	#check cr list to see if there is new cr merged
	system("$ct setview -exe \"$cmbpBin/mergestat | grep -E '.*yes.*yes.*|.*no.*yes.*' > $curr_crlist\" $nbView");
	my $crdiffout = `diff $prev_crlist $curr_crlist`;
	chomp($crdiffout);
	$brIsChanged = 1 if &isNotBlank($crdiffout);
	
	if(! $brIsChanged){
		my $errorMsg = "Nightly build under view $nbView was not kicked off because there's no change to the code or config spec.";
		fatal($errorMsg);
		sendmail("Nightly build under view $nbView was not kicked off", $SCM_MAIL_GROUP, $errorMsg);
	}
	
	(&isScmDebug()) && debug("..cCheckBranches end!");
}

sub cCheckNBVer
{
	my ($ins) = @_;
	(&isScmDebug()) && debug("...cCheckNBVer start...");
	my $cmbpLabel = &iVersionInView($ins->{wuceProduct}, $ins->{nBView});
	info("Next Label/Version for Nightly Build View [$ins->{nBView}] is $cmbpLabel");
	(&isScmDebug()) && debug("..cCheckNBVer end!");
}

sub sUpdateNBVer
{
	my ($targetLabel, $ins) = @_;
	(&isScmDebug()) && debug("...sUpdateNBVer start...");
	my $cmbpLabel = &iVersionInView($ins->{wuceProduct}, $ins->{nBView});
	my $cmbpPart = &iParseLabel($targetLabel, 'uc');
	my $out;
	my $vobFamily = $ins->{vobFamilyLower};
	my $nBView = $ins->{nBView};
	info("$ct setview -exe \"cd /vob/$vobFamily/bld/wuce/ver; $ct co -nc sysrel iter prodver bldrev sys prod bld extra 2>&1\" $nBView");
	$out =`$ct setview -exe \"cd /vob/$vobFamily/bld/wuce/ver; $ct co -nc sysrel iter prodver bldrev sys prod bld extra 2>&1\" $nBView`;
	($out =~ /cleartool: Error/) && fatal($out);
	system("$ct setview -exe \"cd /vob/$vobFamily/bld/wuce/ver; echo $cmbpPart->{sys} > sys \" $nBView");
	system("$ct setview -exe \"cd /vob/$vobFamily/bld/wuce/ver; echo $cmbpPart->{prod} > prod \" $nBView");
	system("$ct setview -exe \"cd /vob/$vobFamily/bld/wuce/ver; echo $cmbpPart->{sysrel} > sysrel \" $nBView");
	system("$ct setview -exe \"cd /vob/$vobFamily/bld/wuce/ver; echo $cmbpPart->{bld} > bld \" $nBView");
	system("$ct setview -exe \"cd /vob/$vobFamily/bld/wuce/ver; echo $cmbpPart->{iter} > iter \" $nBView");
	system("$ct setview -exe \"cd /vob/$vobFamily/bld/wuce/ver; echo $cmbpPart->{prodver} > prodver \" $nBView");
	system("$ct setview -exe \"cd /vob/$vobFamily/bld/wuce/ver; echo $cmbpPart->{bldrev} > bldrev\" $nBView");
	system("$ct setview -exe \"cd /vob/$vobFamily/bld/wuce/ver; echo -n \"\" > extra \" $nBView");
	info("$ct setview -exe \"cd /vob/$vobFamily/bld/wuce/ver; $ct ci -nc -iden sysrel iter prodver bldrev sys prod bld extra 2>&1 \" $nBView");
	$out = `$ct setview -exe \"cd /vob/$vobFamily/bld/wuce/ver; $ct ci -nc -iden sysrel iter prodver bldrev sys prod bld extra 2>&1 \" $nBView`;
	($out =~ /cleartool: Error/) && fatal($out);
	(&isScmDebug()) && debug("..sUpdateNBVer end!");
}

sub sTurnOffNBuild
{
	my ($ins) = @_;
	(&isScmDebug()) && debug("...sTurnOffNBuild start...");
	my $cronBak = "$cronDir/$host.cron.backup";
	my $cron = "$cronDir/$host.cron";
	system("crontab -l > $cronBak");
	system("crontab -l > $cron");
	&commentLineInFile($cron, $ins->{nBCronPat});
	my $out = `crontab $cron`;
    (&isNotBlank($out)) && fatal($out);
    system("crontab -l|grep \"$ins->{nBCronPat}\"");
	(&isScmDebug()) && debug("...sTurnOffNBuild end...");
}

sub sLockTargetIntBr
{
	my ($ins) = @_;
	(&isScmDebug()) && debug("...sLockTargetIntBr start...");
	&iLock('brtype', $ins->{targetIntBr}, $ins->{mgVob}, $ins->{nBView});
	(&isScmDebug()) && debug("...sLockTargetIntBr end");
}

sub sBuild
{
	my ($ins) = @_;
	info("instance: $ins");
	info("sBuild invoked");
}

sub sCreateBldLb
{
	my ($ins) = @_;

	(&isScmDebug()) && debug("...sCreateBldLb start...");
	iCheckConditions($ins);
	iLbType($ins, $ins->{cmdBView}, $ins->{targetIntLb});
	$ins->{cmdAttrName} = 'state';
	$ins->{cmdAttrValue} = 'createdBldLb';
	sUpdateAttr($ins);
	(&isScmDebug()) && debug("...sCreateBldLb end...");
}

sub sLabelTargetIntBr
{
	
}

sub sIncreNBVer
{
	
}

sub sGenCrStat
{
	
}

sub sGrantOkMergeToInt
{
	
}

sub sMergeIntToRelMain
{
	
}

sub sCreateRelLb
{
	
}

sub sLabelRelMain
{
	
}

sub sMkPrjDevPrjScm
{
	
}

sub iRun
{
	my ($instance, $step) = @_;
	&info(qq($SEDNMAIL $SMTP_SERVER $MAILFROM $SCM_MAIL_GROUP));
	&info($bmcInstance->{$instance});
	&fatal("Invalid instance [$instance]") if not exists($bmcInstance->{$instance});
	&$step($instance);
}

1;

