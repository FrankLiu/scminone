#!/usr/bin/perl -w

package Clearcase;

use vars qw(@ISA @EXPORT @EXPORT_OK);
use Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(
	iParseLabel 
	iVobExists iViewExists iLabelInView iVersionInView iIntBranchInView iViewGlobalPath iViewConfigSpec
	iMountVob iMklbtype iMklabel iLock iDescribeLbtype iMkattr 
	iMkview iScBRMerge iGrantOkToMerge iSubtractOkToMerge iMergestat
	
);

use vars qw($cwdir);
BEGIN {
use File::Basename;
$cwdir = dirname($0);
}

use Common;
use Mailiter;

#load required Env vars
my $CONFIG_DIR = "$cwdir/../conf";
eval  {
  require "$CONFIG_DIR/site.cfg";
};
if ($@) {
	error( "Site Config File eval error. Error in SCM scripts installation. Contact your SCM admin:\n" );
	exit(2);
};

sub iParseLabel
{
	my ($cmbpName, $case) = @_;
	# The input label should have cmbp format
	my $r;
	if ($case eq 'lc') {
		$cmbpName = lc $cmbpName;
		$r = 'r';
	}
	else {
		$cmbpName = uc $cmbpName;
		$r = 'R';
	}
	if (($cmbpName =~ /$cmbpMeta/) && ($cmbpName =~ /r|R/)) {
		my @parts = split '_', $cmbpName; #$parts[0]=wmx-ap,[1]=r2.0,[2]=bld-1.09.00
		my @parts0 = split '-', $parts[0]; # $parts0[0]=wmx,[1]=capc
		my @parts1 =split /$r/, $parts[1]; # $parts1[0]="",[1]=2.0
		my @parts2 =split '-', $parts[2]; # $parts2[0]=bld, [1]=1.09.00
		my @parts21 = split '\.', $parts2[1]; # $parts21[0]=1,[1]=09,[2]=00
		
		my %label = ();
		$label->{sys} = $parts0[0];
		$label->{prod} = $parts0[0];
		$label->{r} = $r;
		$label->{sysrel} = $parts1[1];
		$label->{bld} = $parts2[0];
		$label->{iter} = $parts21[0];
		#From WMX5.0, the release label is change to WMX-AP_R5.0_BLD-45.00.00, the latest 2 numbers is used for patch label
		if(int(&firstLetter($label->{sysrel})) > 4){ #WMX5.0, 6.0,...
			$label->{prodver} = $parts21[0]; 
			$label->{bldrev} = $parts21[1];
		}
		else{ #WMX2.5, WMX3.1, WMX4.0
			$label->{prodver} = $parts21[1];
			$label->{bldrev} = $parts21[2];
		}
		if($label->{bld} =~ /INT/){
			$label->{patchrev} = $parts21[2];
		}
		return \%label;
	}
	else {
		return "invalid format $cmbpName";
	}
}

sub iVobExists
{
	my $vob = shift;
	my $viewname = `$ct lsvob -s $vob 2>&1`;
	($out =~ /cleartool: Error/) && return 0; # vob doesn't exist
	return 1;
}

sub iViewExists
{
	my $viewTag = shift;
	my $viewname = `$ct lsview -s $viewTag 2>&1`;
	($out =~ /cleartool: Error/) && return 0; # viewTag doesn't exist
	return 1;
}

sub iLabelInView
{
	my ($wuceProduct, $viewTag) = @_;
	my $label = `$ct setview -exe \"$wuceBin/cmbp_label $wuceProduct|tail -1\" $viewTag`;
	chomp($label);
	return $label;
}
*iVersionInView = *iLabelInView;

sub iIntBranchInView
{
	my ($viewTag) = shift;
	my $viewConfigSpec = &iViewConfigSpec($viewTag);
	my $intBr = &readLineInFile($viewConfigSpec, /^mkbranch /);
	chomp($intBr);
	$intBr =~ s/^mkbranch\s+//;
	return $intBr;
}

sub iViewGlobalPath
{
	my $viewTag = shift;
	my $viewPath = `$ct lsview -long $viewTag|grep 'Global path'|cut -d' ' -f5`;
	chomp($viewPath);
	(-e $viewPath) || die("$viewPath doesn't exist!");
	return $viewPath;
}

sub iViewConfigSpec {
  my ($viewTag) = @_;
  my $viewPath = &iViewGlobalPath($viewTag);
  chomp($viewPath);
  return "$viewPath/config_spec";
}

sub iMountVob
{
	my $vob = shift;
	system("$ct mount $vob 2>&1");
	info("mounted vob: $vob");
}

sub iMklbtype
{
	my ($lbtype, $vob, $view) = @_;
	system("$ct setview -exe \"cd $vob; $ct mklbtype -nc $lbtype 2>&1\" $view");
	info("created label type: $lbtype");
}

sub iMklabel
{
	my ($lbtype, $vob, $view, $labelLog) = @_;
	info("$ct setview -exe \"cd $vob; $ct mklabel -nc -recurse $lbtype . >> ${labelLog} 2>&1\" $view");
	system("$ct setview -exe \"cd $vob; $ct mklabel -nc -recurse $lbtype . >> ${labelLog} 2>&1\" $view");
}

sub iLock
{
	my ($metaType, $metaName, $vob, $view) = @_;
	info("$ct setview -exe \"cd $vob; $ct lslock $metaType:$metaName\" $view");
	system("$ct setview -exe \"cd $vob; $ct lslock $metaType:$metaName\" $view");
}

sub iDescribeLbtype
{
	my ($lbtype, $vob, $view) = @_;
	info("$ct setview -exe \"cd $vob; $ct desc lbtype:$lbtype\" $view");
	system("$ct setview -exe \"cd $vob; $ct desc lbtype:$lbtype\" $view");
}

sub iMkattr
{
	my ($lbtype, $metaAttr, $attrVal, $vob, $view) = @_;
	info("$ct mkattr -replace -nc $metaAttr \"$attrVal\" lbtype:$lbtype\@vob:$vob\" $view");
	system("$ct mkattr -replace -nc $metaAttr \"$attrVal\" lbtype:$lbtype\@vob:$vob\" $view");
}

sub iMkview
{
	my ($viewTag, $baseLine, $vobFamilyU, $option) = @_;

	(&isScmDebug()) && debug("...iMkview start...");
	my $mkView = "$cmbpBin/mkview";
	if(&isNotBlank($option)){    
		info("$mkView $option -tag $viewTag -b $baseLine -v $vobFamilyU -mknt");
		system("$mkView $option -tag $viewTag -b $baseLine -v $vobFamilyU -mknt") && fatal("$bmcErrorPrefix $mkView $option -tag $viewTag -b $baseLine -v $vobFamilyU -mknt");
	}
	else {
		info("$mkView -tag $viewTag -b $baseLine -v $vobFamilyU");
		system("$mkView -tag $viewTag -b $baseLine -v $vobFamilyU") && fatal("$bmcErrorPrefix $mkView -tag $viewTag -b $baseLine -v $vobFamilyU");
	}
	(&isScmDebug()) && debug("...iMkview end!");
}

sub iScBRMerge
{
	my ($branch, $intview, $vobFamilyU, $mergelog) = @_;
	(&isScmDebug()) && debug("...iScBRMerge start...");
	info("$ct setview -exe \"$cmbpBin/scBRMerge -f $branch -nong -v $vobFamilyU > $mergeLog 2>&1\" $intview");
	system("$ct setview -exe \"$cmbpBin/scBRMerge -f $branch -nong -v $vobFamilyU > $mergeLog 2>&1\" $intview");
	(&isScmDebug()) && debug("...iScBRMerge end!");
}

sub iGrantOkToMerge
{
	my ($branch, $intbranch, $vobFamilyU) = @_;
	(&isScmDebug()) && debug("...iGrantOkToMerge start...");
	info("$cmbpBin/scMergeList -add -f $branch -tbranch $intbranch -vfamily $vobFamilyU");
	system("$cmbpBin/scMergeList -add -f $branch -tbranch $intbranch -vfamily $vobFamilyU");
	(&isScmDebug()) && debug("...iGrantOkToMerge end!");
}

sub iSubtractOkToMerge
{
	my ($branch, $intbranch, $vobFamilyU) = @_;
	(&isScmDebug()) && debug("...iSubtractOkToMerge start...");
	info("$cmbpBin/scMergeList -sub -f $branch -tbranch $intbranch -vfamily $vobFamilyU");
	system("$cmbpBin/scMergeList -sub -f $branch -tbranch $intbranch -vfamily $vobFamilyU");
	(&isScmDebug()) && debug("...iSubtractOkToMerge end!");
}

sub iMergestat
{
	my ($baseline, $vobFamilyU) = @_;
	(&isScmDebug()) && debug("...iMergestat start...");
	info("$cmbpBin/mergeStat -b $baseline -v $vobFamilyU");
	system("$cmbpBin/mergeStat -b $baseline -v $vobFamilyU");
	(&isScmDebug()) && debug("...iMergestat end!");
}

1;
