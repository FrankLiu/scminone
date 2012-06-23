## 26-Aug-2010 amd033 Modified for New WMX version Numbering:INDEV00175145 ##

## Need to use the following vars from the main:: package
use vars qw($BIN_DIR $CONFIG_DIR $DATA_DIR);

package BmcLib;

use XML::Simple;
use File::Copy;
use FileHandle;
use English;
use BmcVar;

use vars qw(@ISA @EXPORT @EXPORT_OK);
use Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(iRun);

sub cCheckBldView { 
  my ($ins, $index) = @_;

  ($bmcDebug) && print "...cCheckBldView start...\n";
  (iCheckView($ins->{cmdBView})) && die("$bmcErrorPrefix $ins->{cmdBView} doesn't exist");
  print "$bmcInfoPrefix Found view $ins->{cmdBView}\n";
  ($bmcDebug) && print "...cCheckBldView end!\n";

}

sub cCheckBScript {
  my ($ins, $index) = @_;

  ($bmcDebug) && print "...cCheckBScript start...\n";
  # transform BScript template with input build mode
  my $bScriptTmp = "$ins->{conditions}->[$index][2]/$ins->{conditions}->[$index][1]";
  my $bScriptTmpBk = "$ins->{conditions}->[$index][2]/$ins->{conditions}->[$index][1].bk" ;
  copy("$bScriptTmp", "$bScriptTmpBk");
  my $fh = new FileHandle;
  $fh->open("<$bScriptTmp") || die("$bmcErrorprefix cannot open file $bScriptTmp");
  my @insFile = <$fh>;
  $fh->close;
  foreach (@insFile){
    if ($_ =~ /OPT_TARGET_REPLACEMENT/) {
      $_ =~ s/OPT_TARGET_REPLACEMENT/$ins->{cmdBMode}/;
      last;
    }
  }
  # create temporary BScript for next copying to view area
  my $bScriptDel = "$ins->{conditions}->[$index][2]/$ins->{conditions}->[$index][1].$$"; 
  $fh->open(">$bScriptDel") || die("cannot open file $bScriptDel");
  foreach (@insFile) {
    print $fh "$_";
  }
  $fh->close;
  chmod(0755,$bScriptDel) || die("chmod failed on $bScriptDel"); # make it executable
  # copy BScript to view area
  print "$ct setview -exec \"/bin/cp -p $bScriptDel $ins->{sTool} 2>&1\" $ins->{cmdBView} 2>&1\n";
  my $out = `$ct setview -exec \"/bin/cp -p $bScriptDel $ins->{sTool} 2>&1\" $ins->{cmdBView} 2>&1`;
  ($out ne "") && die("$bmcErrorprefix $out");
  # delete temporary BScript
  unlink $bScriptDel || die("$bmcErrorprefix cannot delete $bScriptDel");
  ($bmcDebug) && print "...cCheckBScript end!\n";

}

sub cCheckBViewDS {
  my ($ins, $index) = @_;

  ($bmcDebug) && print "...cCheckBViewDS start...\n";
  print "/apps/internal/bin/myquota view|grep $ins->{conditions}->[$index][1]\n";
  my $measure = `/apps/internal/bin/myquota view|grep $ins->{conditions}->[$index][1]`;
  ($measure eq "") && die("$bmcErrorPrefix /apps/internal/bin/myquota view|grep $ins->{conditions}->[$index][1] returns empty string");
  my @measure = split '\s+',$measure;
  my $avail = $measure[2] - $measure[1];
  ( $avail > $ins->{conditions}->[$index][2]) || die("$avail < $ins->{conditions}->[$index][2]!");
  print "$bmcInfoPrefix $ins->{login} view quota available $avail K> $ins->{conditions}->[$index][2] K threshold\n";
  ($bmcDebug) && print "...cCheckBViewDS end!\n";

}

sub cCheckDDirDS {
  my ($ins, $index) = @_;

  ($bmcDebug) && print "...cCheckDDirDS start...\n";
  print "/bin/df -h $ins->{dailyDir}|grep $ins->{conditions}->[$index][1]\n";
  my $measure = `/bin/df -h $ins->{dailyDir}|grep $ins->{conditions}->[$index][1]`;
  ($measure eq "") && die("$bmcErrorPrefix /bin/df -h $ins->{dailyDir}|grep $ins->{conditions}->[$index][1] returns empty string");
  my @measure = split '\s+',$measure;
  my @avail = split 'G',$measure[3];
  ( $avail[0] > $ins->{conditions}->[$index][2]) || die("$avail[0] < $ins->{conditions}->[$index][2]!");
  print "$bmcInfoPrefix $ins->{login} $ins->{dailyDir} available $avail[0] G> $ins->{conditions}->[$index][2] G threshold\n";
  ($bmcDebug) && print "...cCheckDDirDS end!\n";

}

sub cCheckLogDir {
  my ($ins, $index) = @_;

  ($bmcDebug) && print "...cCheckLogDir start...\n";
  my $logDir = $ins->{$ins->{conditions}->[$index][1]};
  (-e $logDir) || die("$bmcErrorPrefix log directory $logDir doesn't exist");
  print "$bmcInfoPrefix Found log directory $logDir\n";
  ($bmcDebug) && print "...cCheckLogDir end!\n";
  return 0;

}

sub cCheckOkToMergeOnRelMain {
  my ($ins, $index) = @_;

  ($bmcDebug) && print "...cCheckOkToMergeOnRelMain start...\n";
  (iCheckView($commonView)) && die("$bmcErrorPrefix $commonView doesn't exist");
  my $out = `$ct setview -exe "cd /vob/$ins->{vobFamilyL}; $ct desc brtype:$ins->{targetRelMain}|grep $ins->{conditions}->[$index][1]" $commonView`;
  ($out =~ /$ins->{targetIntBr}/) || die("$bmcErrorPrefix no $ins->{conditions}->[$index][1] with $ins->{targetIntBr}");
  print "$out\n";
  ($bmcDebug) && print "...cCheckOkToMergeOnRelMain end!\n";
  return 0;
  
}

sub cCheckRelView {
  my ($ins, $index) = @_;

  ($bmcDebug) && print "...cCheckRelView start...\n";
  iCheckView($ins->{relView}) && iCreateTagView($ins->{relView}, $ins->{baseScmLb},$ins->{vobFamilyU});
  my $baseConfigSpec = iGetConfigSpec($ins->{targetIntBr});
  my $targetConfigSpec = "$::DATA_DIR/$ins->{series}/cs_$ins->{relView}";
  my $cmbpPart = iParseIntLb($ins->{name}, 'uc'); 
  iEdConfigSpec($baseConfigSpec, $targetConfigSpec, $ins->{targetIntBr}, $ins->{targetRelMain}, $cmbpPart->[3]);
  iSetCS($targetConfigSpec, $ins->{relView});
  ($bmcDebug) && print "...cCheckRelView end!\n";
  return 0;

}

sub cCheckState {
  my ($ins, $index) = @_;

  ($bmcDebug) && print "...cCheckState start...\n";
  ($ins->{state} =~ /$ins->{conditions}->[$index][1]/) || die("$bmcErrorPrefix $ins->{state} doesn't match $ins->{conditions}->[$index][1]!");
  print "$bmcInfoPrefix current \"state\" is \"$ins->{state}\"\n";
  ($bmcDebug) && print "...cCheckState end!\n";
  return 0;

}

sub cCheckTargetIntBr {
  my ($ins, $index) = @_;

  ($bmcDebug) && print "..cCheckTargetIntBr...\n";
  (iCheckView($commonView)) && die("$bmcErrorPrefix $commonView doesn't exist");
  my $output = `$ct setview -exe "cd /vob/$ins->{vobFamilyL}; $ct lslock brtype:$ins->{targetIntBr}" $commonView`;
  ($output =~ /$ins->{conditions}->[$index][1]/) || die("no match $ins->{conditions}->[$index][1]");
  print "$output\n";
  ($bmcDebug) && print "..cCheckTargetIntBr end!\n";
  return 0;
  
}

sub cCheckTargetIntLb {
  my ($ins, $index) = @_;

  ($bmcDebug) && print "...cCheckTargetIntLb start...\n";
  # we check view here because we won't catch setview error next
  (iCheckView($ins->{cmdBView})) && die("$bmcErrorPrefix $ins->{cmdBView} doesn't exist");
  my $targetIntLb = iGetViewVer($ins->{wuceProduct}, $ins->{cmdBView});
  print "$ct setview -exec \"cd /vob/$ins->{vobFamilyL}; $ct desc lbtype:$targetIntLb 2>&1 \" $ins->{cmdBView}\n";
  my $out = `$ct setview -exec \"cd /vob/$ins->{vobFamilyL}; $ct desc lbtype:$targetIntLb 2>&1 \" $ins->{cmdBView}`;
  ($out =~ /cleartool: Error/) || die("$bmcErrorPrefix $out");
  print "$bmcInfoPrefix it's good that $out";
  ($bmcDebug) && print "...cCheckTargetIntLb end!\n";

}

sub cCheckVobs {
  my ($ins, $index) = @_;

  ($bmcDebug) && print "...cCheckVobs start...\n";
  my $out;
  foreach my $vob (@{$ins->{rfVob}}) {
    $out = `$ct lsvob $vob->[1] 2>&1`;
    ($out =~ /cleartool: Error/) && die("$bmcErrorPrefix $out");
    if ($out =~ /^\*/){
      print "$bmcInfoPrefix already mounted $out";
      next;
    }
    print "$ct mount $vob->[1]\n";
    $out = `$ct mount $vob->[1] 2>&1`;
    ($out =~ /cleartool: Error/) && die("$bmcErrorPrefix $out");    
  }
  ($bmcDebug) && print "...cCheckVobs end!\n";

}

sub iCheckConditions {
  my ($ins, $log) = @_;

  ($bmcInternalDebug) && print "...iCheckConditions start ...\n";
  # $index identify the condition in the condition list
  my $index = 0;
  for my $row (@{$ins->{conditions}}) {
    # cn = $row->[0] pattern = $row->[1]\n";
    my $fn = $row->[0];
    &$fn($ins, $index, $log);
    $index++;
  }
  ($bmcInternalDebug) && print "...iCheckConditions end!\n";

}

sub iCheckLog {
  my ($log, $checkMessage) = @_;

  ($bmcInternalDebug) && print "...iCheckLog start...\n";
  (-e $log) || die("bmcErrorPrefix $log doesn't exist");
  my $found = 'n';
  my @out = `/usr/bin/tail -$bmcLogCnt $log`;
  foreach (@out) {
    print "$_";
    if ($_ =~ /$checkMessage/) {
      $found = "y";
    }
  }
  ($found eq "n") && die("$bmcErrorPrefix no $checkMessage found inside $log!");
  print "$bmcInfoPrefix Found $checkMessage inside $log\n";
  ($bmcInternalDebug) && print "...iCheckLog end!\n";

}

sub iCheckView {
  my ($viewTag) = @_;

 ($bmcInternalDebug) &&  print "...iCheckView start...\n";
  my $out = `$ct lsview $viewTag 2>&1`;
  ($out =~ /cleartool: Error/) && return 1; # viewTag doesn't exist
  return 0; # viewTag exists

}

sub iCreateInsRef {
  my ($series, $ins, $ste, $att, $vie, $mod) = @_;

  ($bmcInternalDebug) && print "...iCreateInsRef start...\n";
  my $configFile = "$::DATA_DIR/$series/${ins}.ins";
  (-e $configFile) || die("$bmcErrorPrefix $configFile doesn't exist");
  my $configRef = XML::Simple::XMLin($configFile);
  ($configRef->{name} eq $ins) || die("cannot find $ins in $configFile!");

  my (%ins, @mgVob, @lbVob,@rfVob,@cond);
  # obtain vob information
  for my $vob (@{$configRef->{vob}}) {
    my @row;
    push @row, $vob->{vn};
    push @row, $vob->{vTag};
    push @row, $vob->{vMerge};
    push @row, $vob->{vMgLogMsg};
    push @row, $vob->{vLabel};
    push @row, $vob->{vLbPath};
    push @row, $vob->{vRefer};
    push @row, $vob->{vLockExp};
    if ($vob->{vMerge} eq 'y') {
      push @mgVob, \@row;
    }
    if ($vob->{vLabel} eq 'y') {
      push @lbVob, \@row;
    }
    if ($vob->{vRefer} eq 'y') {
      push @rfVob, \@row;
    }
  }
  $ins{mgVob} = \@mgVob;
  $ins{lbVob} = \@lbVob;
  $ins{rfVob} = \@rfVob;

  # obtain build mode information
  for my $bm (@{$configRef->{buildMode}}) {
    $ins{$bm->{bn}} = $bm->{bv};
  }

  # obtain step information
  my $foundSte = "n";
  my $type = ref $configRef->{step};
  #print "root step: $type\n";
  for my $step (@{$configRef->{step}}) {
	$type = ref $step;
	#print "leave step: $type: $step->{sn}\n";
	if ($step->{sn} eq $ste) {
	  $foundSte = "y";
	  $ins{"step"} = $step->{sn};
	  # obtain step parameters
	  $ins{"sTool"} = $step->{sTool}; 
	  $ins{"sType"} = $step->{sType}; 
	  $ins{"sTarget"} = $step->{sTarget}; 
	  # obtain step conditions
	  if (defined $step->{condition}) {
	    #$type = ref $step->{condition};
	    #print "root condition: $type\n";
	    for my $cond (@{$step->{condition}}) {
	      #$type = ref $cond;
	      #print "leave condition: $type\n";
	      #print "$cond->{cn},$cond->{pattern}\n";
	      my @row;
	      push @row, $cond->{cn};
	      push @row, $cond->{pattern};
	      (defined $cond->{threshold}) && push @row, $cond->{threshold};
	      push @cond,\@row;
	    }
	    $ins{"conditions"} =\@cond;
	  }
	  last;
	}
	
  }
  ($foundSte eq "y") || die("$bmcErrorPrefix No $ste found inside $configFile!");

  # store login for step reference
  $ins{"login"} = $login;

  # obtain instance information
  $ins{"name"} = $configRef->{name};
  $ins{"state"} = $configRef->{state};
  $ins{"baseScmLb"} = $configRef->{baseScmLb};
  $ins{"targetRelMain"} = $configRef->{targetRelMain};
  $ins{"targetScmLb"} = $configRef->{targetScmLb};
  $ins{"targetScmBl"} = $configRef->{targetScmBl};
  $ins{"predScmBl"} = $configRef->{predScmBl};
  $ins{"baseIntLb"} = $configRef->{baseIntLb};
  $ins{"targetIntBr"} = $configRef->{targetIntBr}; # wmx-capc_r3.0_bld-1.26.00
  $ins{"targetIntLb"} = $configRef->{targetIntLb}; # WMX-CAPC_R3.0_BLD-1.26.00
  $ins{"targetIntBl"} = $configRef->{targetIntBl}; 
  $ins{"predIntBl"} = $configRef->{predIntBl}; 
  $ins{"cqProd"} = $configRef->{cqProd};

  my $cmbpPart = iParseIntLb($ins{targetIntLb}, 'lc');
  $ins{"series"} = $series;
  $ins{"crStatBr"} = ($ins{targetIntBr} =~ /bld/)? "$ins{series}-$cmbpPart->[5]": $ins{targetIntBr};
  $ins{"relView"} = "$ins{series}-$bmc-ecloud-rel";

  $ins{"nBView"} = $configRef->{nBView};
  $ins{"okCronCnt"} = $configRef->{okCronCnt};
  $ins{"nBCronCnt"} = $configRef->{nBCronCnt};
  $ins{"rvCronCnt"} = $configRef->{rvCronCnt};
  $ins{"nBCronPat"} = $configRef->{nBCronPat};
  $ins{"wuceProduct"} = $configRef->{wuceProduct};
  $ins{"vobFamilyL"} = $configRef->{vobFamilyLower};
  $ins{"vobFamilyU"} = uc $configRef->{vobFamilyLower};
  $ins{"buildPool"} = $configRef->{buildPool};
  $ins{"builder"} = $configRef->{builder};
  $ins{"defaultBMode"} = $configRef->{defaultBMode};
  $ins{"dailyDir"} = $configRef->{dailyDir};
  $ins{"crStatDir"} = $configRef->{crStatDir};
  $ins{"recipient"} = $configRef->{recipient};
  #$ins{"crStatFolder"} = $configRef->{crStatFolder};
  
  ($login =~ /$ins{builder}/) || die("$bmcErrorPrefix Invalid user $login is detected! You have to be $ins{builder} to run the instance");
  ($host =~ /$ins{buildPool}/) || die("$bmcErrorPrefix Invalid host $host is detected! You have to login $ins{buildPool} to run the instance");
  
  $ins{"baseIntLbDir"} = "$configRef->{dailyDir}/$configRef->{baseIntLb}";
  $ins{"dailyLog"} = "$configRef->{dailyDir}/log";

  # store step related command line information
  my @attr = split /=/, $att;
  $ins{"cmdAttrName"} = $attr[0];
  $ins{"cmdAttrValue"} = $attr[1];
  if ($vie eq 'noUse') {
    $ins{"cmdBView"} = $ins{nBView};
  }
  else {
    $ins{"cmdBView"} = $vie;
  }
  if ($mod eq 'noUse') {
    $ins{"cmdBModeName"} = $ins{defaultBMode};
  }
  else {
    $ins{"cmdBModeName"} = $mod;
  }
  $ins{"cmdBMode"} =  $ins{$ins{cmdBModeName}};

  ($bmcInternalDebug) && print "...iCreateInsRef end!\n";
  return(\%ins);

}

sub iCreateTagView {
  my ($viewTag, $baseLine, $vobFamilyU, $option) = @_;

  ($bmcInternalDebug) && print "...iCreateTagView start...\n";
  if (defined $option) {    
    print "$mkView $option -tag $viewTag -b $baseLine -v $vobFamilyU -mknt\n";
    system("$mkView $option -tag $viewTag -b $baseLine -v $vobFamilyU -mknt") && die("$bmcErrorPrefix $mkView $option -tag $viewTag -b $baseLine -v $vobFamilyU -mknt");
  }
  else {
    print "$mkView -tag $viewTag -b $baseLine -v $vobFamilyU -mknt\n";
    system("$mkView -tag $viewTag -b $baseLine -v $vobFamilyU -mknt") && die("$bmcErrorPrefix $mkView $option -tag $viewTag -b $baseLine -v $vobFamilyU -mknt");
  }
  ($bmcInternalDebug) && print "...iCreateTagView end!\n";

}

sub iDAndC {
  my ($series, $ins, $ste, $att, $vie, $mod) = @_;

  ($bmcInternalDebug) && print "...iDAndC start...\n";
  my $configFile = "$::CONFIG_DIR/$phaseTmpFile";
  (-e $configFile) || die("$bmcErrorPrefix $configFile doesn't exist");
  my $configRef = XML::Simple::XMLin($configFile);

  # obtain phase information
  my %ins;
  my $foundSte = "n";
  for my $phase (@{$configRef->{phase}}) {
    if ($phase->{sn} eq $ste) {
      $foundSte = "y";
      $ins{"step"} = $phase->{sn};
      $ins{"sTool"} = $phase->{sTool}; 
      $ins{"sType"} = $phase->{sType}; 
      $ins{"sTarget"} = $phase->{sTarget}; 
      last;
    }
  }
  ($foundSte eq "y") || die("$bmcErrorPrefix No $ste found inside $configFile!");
  ($ins{sType} ne "composite") && die("$bmcErrorPrefix $ins{sType} and $ins->{step} not match");
  my @target = split /\s/, $ins{sTarget};
  ($#target == 0) && die("$bmcErrorPrefix $ins{sType} and $ins{sTarget} not match");

  my $insName;
  if ($ste eq "pStartNextInt") {
    $insName = iGenNextInsName($ins); # next int cycle
  }
  else {
    $insName = $ins; # this int cycle
  }

  # deal with multiple targets
  for my $target (@target) {
    iRun($insName, $target, 'noUse', 'noUse', 'noUse', 'noUse');
  }
  ($bmcInternalDebug) && print "...iDAndC end\n";

}

sub iEdConfigSpec {
  my ($baseConfigSpec, $targetConfigSpec, $baseBr, $targetBr, $sysRel) = @_;

  ($bmcInternalDebug) && print "...edConfigSpec start...\n";
  my $fh = new FileHandle;
  $fh->open("<$baseConfigSpec") || die("$bmcErrorPrefix cannot open file $baseConfigSpec");
  my @baseConfigSpec = <$fh>;
  chomp(@baseConfigSPec);
  $fh->close;
  my @relConfigSpec;
  ((defined $baseBr) && (defined $targetBr) && (defined $sysRel)) || die("$bmcErrorPrefix $baseBr, $targetBr, $sysRel need to have value");
  # edit the config_spec
  foreach my $rule (@baseConfigSpec) {
    # replace integration branch with release main branch
    $rule =~ s/$baseBr/$targetBr/;
    # remove release main/0 rule
    if ($rule =~ /element \* ...\/$targetBr\/0/) {
      next;
    }
	# amd033 - 12May-2010 keep the release rule.
    push @relConfigSpec, $rule;
  }
  $fh->open(">$targetConfigSpec") || die("cannot open file $targetConfigSpec");
  foreach (@relConfigSpec) {
    print $fh "$_";
  }
  $fh->close;
  ($bmcInternalDebug) && print "...edConfigSpec end!\n";

}

sub iGetConfigSpec {
  my ($viewTag) = @_;

  my $viewPath = iGetViewPath($viewTag);
  chomp($viewPath);
  return "$viewPath/config_spec";

}

sub iGenIns {
  my ($series, $ins, $state, $keptBaseIntLb) = @_; # wmx-ap_r2.0_bld-1.09.00

  ($bmcInternalDebug) && print "...iGenIns start...\n";
  # combine 3 templates to form an instance template
  my $cmbpPart = iParseIntLb($ins, 'uc');
  my $ccProd = $cmbpPart->[1];
#amd033-Modify for new numbering
  my $baseIter = $cmbpPart->[5];
  my $baseProdVer = $cmbpPart->[6];
  if(iCheckNewNumberCondition($cmbpPart)){
    $baseIter = $cmbpPart->[5] - 1;
    if ($baseIter < 0) {
       die("$bmcErrorPrefix invalid instance $ins");
    }
  }
  else{
    $baseProdVer = $cmbpPart->[6] - 1;
    if ($baseProdVer < 0) {
       die("$bmcErrorPrefix invalid instance $ins");
    }
    elsif ($baseProdVer =~ /^\d$/) {
       $baseProdVer = '0' . $baseProdVer;
    }
  }
  my $baseScmLb = "$cmbpPart->[0]-$cmbpPart->[1]_$cmbpPart->[2]$cmbpPart->[3]_$scmCntPart{$cmbpPart->[4]}-$baseIter.$baseProdVer.$cmbpPart->[7]";
  my $targetScmLb = "$cmbpPart->[0]-$cmbpPart->[1]_$cmbpPart->[2]$cmbpPart->[3]_$scmCntPart{$cmbpPart->[4]}-$cmbpPart->[5].$cmbpPart->[6].$cmbpPart->[7]";
  
  my $baseIntLb = (defined $keptBaseIntLb)? $keptBaseIntLb:$ins; # used by sUpdateIns
  my $targetIntLb = $ins;
  my $targetIntBr = lc $targetIntLb;

  my $mainTmp = "$::CONFIG_DIR/$cmbpPart->[0]-$cmbpPart->[1]_$cmbpPart->[2]$cmbpPart->[3]_$cmbpPart->[4].template";  
  my $fh = new FileHandle;
  $fh->open("<$mainTmp") || die("$bmcErrorPrefix cannot open file $mainTmp");
  my @mainTmp = <$fh>;
  $fh->close;
  my $cqProd = 'n';
  foreach (@mainTmp) {
    if ($_ =~ /cqProd=\"(.*)\"/) {
      $cqProd = $1;
      next;
    }
  }
  ($cqProd eq "n") && die("$bmcErrorPrefix not found cqProd attribute in $mainTmp");
  my $targetIntBl = "$cmbpPart->[0]-${cqProd}_$cmbpPart->[2]$cmbpPart->[3]_$cmbpPart->[4]-$cmbpPart->[5].$cmbpPart->[6].$cmbpPart->[7]";
  my $predIntBl = "$cmbpPart->[0]-${cqProd}_$cmbpPart->[2]$cmbpPart->[3]_$cmbpPart->[4]-${baseIter}.${baseProdVer}.$cmbpPart->[7]";
  my $targetScmBl = "$cmbpPart->[0]-${cqProd}_$cmbpPart->[2]$cmbpPart->[3]_$scmCntPart{$cmbpPart->[4]}-$cmbpPart->[5].$cmbpPart->[6].$cmbpPart->[7]";
  my $predScmBl = "$cmbpPart->[0]-${cqProd}_$cmbpPart->[2]$cmbpPart->[3]_$scmCntPart{$cmbpPart->[4]}-${baseIter}.${baseProdVer}.$cmbpPart->[7]";
  
  my $builder = 'n';
  foreach (@mainTmp) {
    if ($_ =~ /builder=\"(.*)\"/) {
      $builder = $1;
      next;
    }
  }
  ($builder eq "n") && die("$bmcErrorPrefix not found builder attribute in $mainTmp");
  ($login =~ /$builder/) || die("$bmcErrorPrefix Invalid user $login is detected! You have to be $builder to run the instance");
  my $buildPool = 'n';
  foreach (@mainTmp) {
    if ($_ =~ /buildPool=\"(.*)\"/) {
      $buildPool = $1;
      next;
    }
  }
  ($buildPool eq "n") && die("$bmcErrorPrefix not found builder attribute in $mainTmp");
  ($host =~ /$buildPool/) || die("$bmcErrorPrefix Invalid host $host is detected! You have to login $buildPool to run the instance");

  foreach (@mainTmp) {
    $_ =~ s/name_REPLACEMENT/$ins/;
    $_ =~ s/state_REPLACEMENT/$state/;
    $_ =~ s/baseScmLb_REPLACEMENT/$baseScmLb/;
    $_ =~ s/targetScmLb_REPLACEMENT/$targetScmLb/;
    $_ =~ s/targetScmBl_REPLACEMENT/$targetScmBl/;
    $_ =~ s/baseIntLb_REPLACEMENT/$baseIntLb/;
    $_ =~ s/targetIntBr_REPLACEMENT/$targetIntBr/;
    $_ =~ s/targetIntLb_REPLACEMENT/$targetIntLb/;
    $_ =~ s/targetIntBl_REPLACEMENT/$targetIntBl/;
    $_ =~ s/predIntBl_REPLACEMENT/$predIntBl/;
    $_ =~ s/predScmBl_REPLACEMENT/$predScmBl/;
  }

  my $productTmp = "$::CONFIG_DIR/$cmbpPart->[0]-$cmbpPart->[1].template";
  $fh->open("<$productTmp") || die("$bmcErrorPrefix cannot open file $productTmp");
  my @productTmp = <$fh>;
  $fh->close;

  my $stepTmp = "$::CONFIG_DIR/$stepTmpFile";
  $fh->open("<$stepTmp") || die("$bmcErrorPrefix cannot open file $stepTmp");
  my @stepTmp = <$fh>;
  $fh->close;

  if (!-e "$::DATA_DIR/$series") {
    mkdir "$::DATA_DIR/$series" || die("$bmcErrorPrefix mkdir $::DATA_DIR/$series,0775 failed");
  }
  my $insFile = "$::DATA_DIR/$series/$ins.ins";
  $fh->open(">$insFile") || die("$bmcErrorPrefix cannot open file $insFile");
  for ( my $index = 0; $index < $#mainTmp; $index++) { # $#array returns the subscript of the last of element in the array 
    print $fh "$mainTmp[$index]";
    ($bmcInternalDebug) && print "$mainTmp[$index]";
  }
  foreach (@productTmp) {
    print $fh "$_";
    ($bmcInternalDebug) && print "$_";
  }
  foreach (@stepTmp) {
    print $fh "$_";
    ($bmcInternalDebug) && print "$_";
  }
  ($bmcInternalDebug) && print "$mainTmp[$#mainTmp]";
  print $fh "$mainTmp[$#mainTmp]";
  $fh->close;
  chmod(0664,$insFile);

  print "$bmcInfoPrefix $::DATA_DIR/$series/$ins.ins is generated\n";
  ($bmcInternalDebug) && print "...iGenIns end!\n";

}

sub iGenNextInsName {
  my ($ins) = @_;

  ($bmcInternalDebug) && print "...iGenNextInsName start...\n";
  # make sure the passed instance exists
  # not able to do these check due to $ins is simple
  
  # generate next instance name
  my $cmbpPart = iParseIntLb($ins, 'uc');
#amd033-Modify for new numbering
  my $nextIter = $cmbpPart->[5];
  my $nextProdVer = $cmbpPart->[6];
  if(iCheckNewNumberCondition($cmbpPart)){
    $nextIter = $cmbpPart->[5] + 1;
  }else{	 
	$nextProdVer = $cmbpPart->[6] + 1;
	if ($nextProdVer =~ /^\d$/) {
	  $nextProdVer = '0' . $nextProdVer;
	}
  }
  my $nextIns = "$cmbpPart->[0]-$cmbpPart->[1]_$cmbpPart->[2]$cmbpPart->[3]_$cmbpPart->[4]-$nextIter.$nextProdVer.$cmbpPart->[7]";
  print "$bmcInfoPrefix next instance $nextIns\n";
  ($bmcInternalDebug) && print "...iGenNextInsName end!\n";
  return $nextIns;
}

sub iGenPrevCMBPMData {
  my ($mData,$case) = @_;

  # generate previous Br/Lb/Bl
  my $cmbpPart = iParseIntLb($mData, $case);
  my $prevProdVer = $cmbpPart->[6];
  my $prevIter = $cmbpPart->[5];
  if(iCheckNewNumberCondition($cmbpPart)){
	$prevIter = $cmbpPart->[5] - 1;
  }else {
	  $prevProdVer = $cmbpPart->[6] - 1;
	  if ($prevProdVer =~ /^\d$/) {
	    $prevProdVer = '0' . $prevProdVer;
      }
  }  
  return "$cmbpPart->[0]-$cmbpPart->[1]_$cmbpPart->[2]$cmbpPart->[3]_$cmbpPart->[4]-$prevIter.$prevProdVer.$cmbpPart->[7]";

}

sub iGetViewPath {
  my ($viewTag) = @_;

  my $viewPath = `$ct lsview -long $viewTag|grep 'Global path'|cut -d' ' -f5`;
  chomp($viewPath);
  (-e $viewPath) || die("$bmcErrorPrefix $viewPath doesn't exist!");
  return $viewPath;

}

sub iGetViewVer {
  my ($wuceProduct, $viewTag) = @_;
  
  ($bmcInternalDebug) && print "...iGetViewVer start...\n";
  (iCheckView($viewTag)) && die("$bmcErrorprefix $viewTag doesn't exist");
  my $tool = "$wuceBin/cmbp_label";
  print "$ct setview -exe \"$tool $wuceProduct|tail -1\" $viewTag\n";
  my $cmbpLabel = `$ct setview -exe \"$tool $wuceProduct|tail -1\" $viewTag`;
  chomp($cmbpLabel);
  ($bmcDebug) && print "..iGetViewVer end!\n";
  return $cmbpLabel;

}

sub iLbType {
  my ($ins, $lbView, $targetLb) = @_;

  ($bmcInternalDebug) && print "...iLbType start...\n";
  # start labeling through 2 dimention vob array: 
  # $vob->[0]=vn,$vob->[1]=vTag,$vob->[2]=vMerge,$vob->[3]=vMgLogMsg,$vob->[4]=vLabel,$vob->[5]=vLbPath,$vob->[6]=vRefer,$vob->[7]=vLockExp
  my ($vob, $labelLog);
  for $vob (@{$ins->{lbVob}}) {
    $labelLog = "$ins->{baseIntLbDir}/$targetLb.mklabel.$vob->[0]";
    print "$ct setview -exe \"cd $vob->[5]; $ct mklbtype -nc $targetLb >> ${labelLog} 2>&1\" $lbView\n";
    system("$ct setview -exe \"cd $vob->[5]; $ct mklbtype -nc $targetLb >> ${labelLog} 2>&1\" $lbView");
    #print "$ct setview -exe \"cd $vob->[5]; $ct mklabel -nc -recurse $targetLb . >> ${labelLog} 2>&1\" $lbView\n";
    #system("$ct setview -exe \"cd $vob->[5]; $ct mklabel -nc -recurse $targetLb . >> ${labelLog} 2>&1\" $lbView");
  }
  # check log and lock label through vobList
  #for $vob (@{$ins->{lbVob}}) {
  #  $labelLog = "$ins->{baseIntLbDir}/$targetLb.mklabel.$vob->[0]";
  #  iCheckLog($labelLog, $vob->[5], 10);
  #}
  ($bmcInternalDebug) && print "...iLbType end!\n";

}

sub iLabel {
  my ($ins, $lbView, $targetLb) = @_;

  ($bmcInternalDebug) && print "...iLabel start...\n";
  # start labeling through 2 dimention vob array: 
  # $vob->[0]=vn,$vob->[1]=vTag,$vob->[2]=vMerge,$vob->[3]=vMgLogMsg,$vob->[4]=vLabel,$vob->[5]=vLbPath,$vob->[6]=vRefer,$vob->[7]=vLockExp
  my ($vob, $labelLog);
  for $vob (@{$ins->{lbVob}}) {
    $labelLog = "$ins->{baseIntLbDir}/$targetLb.mklabel.$vob->[0]";
    #print "$ct setview -exe \"cd $vob->[5]; $ct mklbtype -nc $targetLb >> ${labelLog} 2>&1\" $lbView\n";
    #system("$ct setview -exe \"cd $vob->[5]; $ct mklbtype -nc $targetLb >> ${labelLog} 2>&1\" $lbView");
    print "$ct setview -exe \"cd $vob->[5]; $ct mklabel -nc -recurse $targetLb . >> ${labelLog} 2>&1\" $lbView\n";
    system("$ct setview -exe \"cd $vob->[5]; $ct mklabel -nc -recurse $targetLb . >> ${labelLog} 2>&1\" $lbView");
  }
  # check log and lock label through vobList
  #for $vob (@{$ins->{lbVob}}) {
  #  $labelLog = "$ins->{baseIntLbDir}/$targetLb.mklabel.$vob->[0]";
  #  iCheckLog($labelLog, $vob->[5], 10);
  #}
  ($bmcInternalDebug) && print "...iLabel end!\n";

}

sub iLock {
  my ($vobList, $metaType, $mtName) = @_;

  ($bmcInternalDebug) && print "...ilock start...\n";
  (iCheckView($commonView)) && die("$bmcErrorPrefix $commonView doesn't exist");
  for my $vob (@{$vobList}) {
    print "$ct setview -exec \"cd $vob->[1]; $ct lock -nuser $vob->[7] $metaType:$mtName\" $commonView\n";
    $out = `$ct setview -exec \"cd $vob->[1]; $ct lock -nuser $vob->[7] $metaType:$mtName 2>&1\" $commonView`;
    if ($out =~ /cleartool: Error/) {
      unless ($out =~ /Object is already locked/) {
	die("$bmcErrorPrefix $ct lock -nuser $vob->[7] $metaType:$mtName");
      }
    }
    system("$ct setview -exe \"cd $vob->[1]; $ct lslock $metaType:$mtName\" $commonView");
  }
  ($bmcInternalDebug) && print "...ilock end!\n";

}

sub iMkPrjDevPrj {
  my ($ins, $targetLb) = @_;

  ($bmcInternalDebug) && print "...iMkPrjDevPrj start...\n";
  (iCheckView($commonView)) && die("$bmcErrorPrefix $commonView doesn't exist");
  # read base *.prj file
  my $basePrj = "$prjDir/$ins->{vobFamilyU}_projects/$ins->{baseIntLb}.prj";
  my $fh = new FileHandle;
  $fh->open("<$basePrj") || die("cannot open file $basePrj");
  my @basePrj = <$fh>;
  $fh->close;

  # make change to the *.prj file
  foreach (@basePrj){
    $_ =~ s/$ins->{baseIntLb}/$targetLb/;
  }

  # create target *.proj file
  my $targetPrj = "$prjDir/$ins->{vobFamilyU}_projects/$targetLb.prj";
  (-e $targetPrj) && copy("$targetPrj", "$targetPrj.$bmc");
  $fh->open(">$targetPrj") || die("cannot open file $targetPrj");
  foreach (@basePrj) {
    print $fh "$_";
  }
  $fh->close;
  print "$bmcInfoPrefix $targetPrj is created\n";

  # create devProject attribute
  my $mkattr = "$::BIN_DIR/my_mkattr";
  my $out;
  $out = `$ct setview -exe \"cd /vob/$ins->{vobFamilyL}; $ct desc lbtype:$targetLb 2>&1\" $commonView`;
  ($out =~ /cleartool: Error/) && die("$bmcErrorPrefix $targetLb doesn't exist");
  print "$ct setview -exe \"$mkattr $ct $ins->{vobFamilyL} $targetLb\" $commonView\n";
  $out = `$ct setview -exe \"$mkattr $ct $ins->{vobFamilyL} $targetLb 2>&1\" $commonView`;
  ($out =~ /cleartool: Error/) && die("$bmcErrorPrefix mkattr");
  system("$ct setview -exe \"cd /vob/$ins->{vobFamilyL}; $ct desc lbtype:$targetLb\" $commonView");
  ($bmcInternalDebug) && print "...iMkPrjDevPrj end!\n";

}

sub iParseIntLb {
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
    my @cmbpPart;
    push @cmbpPart, $parts0[0]; # $sys
    push @cmbpPart, $parts0[1]; # $prod
    push @cmbpPart, $r; # r or R
    push @cmbpPart, $parts1[1]; # $sysRel without r/R
    push @cmbpPart, $parts2[0]; # $bld
    push @cmbpPart, $parts21[0]; # $iter
    push @cmbpPart, $parts21[1]; # $prodVer
    push @cmbpPart, $parts21[2]; # $bldRev
    return \@cmbpPart;
  }
  else {
    return "invalid format $cmbpName";
  }
  
}

sub iRun {
  my ($ins, $ste, $att, $vie, $mod) = @_;

  ($bmcInternalDebug) && print "...iRun...\n";
  my $cmbpPart = iParseIntLb($ins, 'lc');  
  my $series = "$cmbpPart->[0]-$cmbpPart->[1]_$cmbpPart->[2]$cmbpPart->[3]_$cmbpPart->[4]";
  if ($ste eq "sGenIns") { 
    &$ste($series, $ins, $ste, $att, $vie, $mod); # go to sGenIns() step
  }
  elsif ($ste =~ /^p/) {
    iDAndC($series, $ins, $ste, $att, $vie, $mod); # go to composite phase - iDAndC()
  }
  else {
    my $insRef = iCreateInsRef($series, $ins, $ste, $att, $vie, $mod); # go to iCreateInsRef()
    &$ste($insRef); # go to atomic step
  }
  ($bmcInternalDebug) && print "...iRun end!\n";

}

sub iSetCS {
  my ($configSpec, $viewTag) = @_;

  ($bmcInternalDebug) && print "...iSetCS start...\n";
  (-e $configSpec) || die("$configSpec doesn't exist!");
  iCheckView($viewTag) && die("$viewTag doesn't exist!");

  print "$ct setview -exe \"$ct setcs $configSpec\" $viewTag\n";
  system("$ct setview -exe \"$ct setcs $configSpec\" $viewTag");
  $? && die("cannot $ct setview -exe \"$ct setcs $configSpec\" $viewTag");
  print "$ct catcs -tag $viewTag\n";
  system("$ct catcs -tag $viewTag");
  ($bmcInternalDebug) && print "...iSetCS end!\n";
}

sub iSwapView {
  my ($keptTag, $baseLine, $intRefView, $vobFamilyU, $pathTag, $pathTagSec, $pathTag3rd) = @_;

  ($bmcInternalDebug) && print "...iSwapView start...\n";
  # make sure the execution is not inside any view
  my $currView = `$ct pwv|grep 'Set view'|cut -f2 -d':'`;
  ($currView =~ /NONE/) || die("$bmcErrorPrefix exit view $currView");

  # obtain $intRefView config_spec, the most important thing before any tag swap, may save it to the config dir
  my $intRefConfig = iGetConfigSpec($intRefView);

  # start the "keptTag" swap process if needed
  my $prevPathTag;
  if (iCheckView($keptTag) ==0) {
    # always use $keptTagPath[-1] as $prevPathtag to keep consistency
    my $keptTagPath = iGetViewPath($keptTag);
    my @keptTagPath = split '/', $keptTagPath;
    
    if (iCheckView($keptTagPath[-1])) {
      $prevPathTag = $keptTagPath[-1];
    }
    else {
      $prevPathTag = $pathTag . '-1st-baseline';
    }

    # make keptTag available for reuse
    print "$ct mktag -view -tag $prevPathTag $keptTagPath\n";
    system("$ct mktag -view -tag $prevPathTag $keptTagPath") && die("$bmcErrorPrefix $ct mktag -view -tag $prevPathTag $keptTagPath fail");
    print "$ct rmtag -view $keptTag\n";
    system("$ct rmtag -view $keptTag") && die("$bmcErrorPrefix $ct rmtag -view $keptTag fail");
  }

  # determine nextPathTag and make sure that $pathTag, $pathTagSec, and $pathTag3rd are not the same
  ($pathTag eq $pathTagSec || $pathTag eq $pathTag3rd || $pathTagSec eq $pathTag3rd) && die("$bmcErrorPrefix $pathTag,$pathTagSec,and $pathTag3rd are same");
  my $nextPathTag;
  if (iCheckView($pathTag)) {
    $nextPathTag = $pathTag;
  }
  elsif (iCheckView($pathTagSec)) {
    $nextPathTag = $pathTagSec;
  }
  elsif (iCheckView($pathTag3rd)) {
    $nextPathTag = $pathTag3rd;
  }
  else {
    die("$bmcErrorPrefix view $pathTag, $pathTagSec, and $pathTag3rd exist");
  }

  # create $nextPathTag
  iCreateTagView($nextPathTag,$baseLine,$vobFamilyU);

  # reuse $keptTag
  my $nextPathTagPath = iGetViewPath($nextPathTag);
  print "$ct mktag -view -tag $keptTag $nextPathTagPath\n";
  system("$ct mktag -view -tag $keptTag $nextPathTagPath") && die("$bmcErrorPrefix $ct mktag -view -tag $keptTag $nextPathTagPath");
  print "$ct rmtag -view $nextPathTag\n";
  system("$ct rmtag -view $nextPathTag") && die("$bmcErrorPrefix $ct rmtag -view $nextPathTag");
  iSetCS($intRefConfig, $keptTag);

  # display to-be-removed tmp views
  if (defined $prevPathTag) {
    print "$bmcInfoPrefix Please remove the following view before next integration baseline starts\n";
    system("$ct lsview $prevPathTag");
  }
  ($bmcInternalDebug) && print "...iSwapView end!\n";

}

sub iTurnOffCron {
  my ($cronPat, $cronCnt) = @_;
  
  ($bmcInternalDebug) && print "...iTurnOffCron start...\n";
  my $found = 0;
  my @cron = `crontab -l 2>&1`;
  if ($cron[0] =~ /no crontab/) {
    print "$bmcInfoPrefix $cron[0]\n";
  }
  else {
    my $fh = new FileHandle;
    # make a copy of current cron job
    my $cronBk = "$cronDir/$host.cron.backup";
    $fh->open(">$cronBk") || die("$bmcErrorPrefix cannot open file $cronBk");
    foreach (@cron) {
      print $fh "$_";
    }
    $fh->close;
    # add comment
    foreach (@cron) {
      if (($_ =~ /^\d/) && ($_ =~ /$cronPat/)) {
	$_ =~ s/^(\d.*)/\#$1/;
	$found++;
      }
    }
    if ($found == $cronCnt) { # activate the new cron
      my $cronNew = "$cronDir/$host.cron";
      $fh->open(">$cronNew") || die("$bmcErrorPrefix cannot open file $cronNew");
      foreach (@cron) {
	print $fh "$_";
      }
      $fh->close;
      print "crontab $cronNew\n";
      my $out = `crontab $cronNew`;
      ($out ne "") && die("$bmcErrorPrefix $out");
      system("crontab -l|grep \"$cronPat\"");
    }
    else {
      print "$bmcInfoPrefix $found not match $cronCnt\n";
    }
  }
  ($bmcInternalDebug) && print "...iTurnOffCron end!\n";

}

sub iTurnOnCron {
  my ($cronPat, $cronCnt) = @_;
  
  ($bmcInternalDebug) && print "...iTurnOnCron start...\n";
  my $found = 0;
  my @cron = `crontab -l 2>&1`;
  if ($cron[0] =~ /no crontab/) {
    print "$bmcInfoPrefix $cron[0]\n";
  }
  else {
    my $fh = new FileHandle;
    # make a copy of current cron job
    my $cronBk = "$cronDir/$host.cron.backup";
    $fh->open(">$cronBk") || die("$bmcErrorPrefix cannot open file $cronBk");
    foreach (@cron) {
      print $fh "$_";
    }
    $fh->close;
    # remove comment
    foreach (@cron) {
      if (($_ =~ /^\#/) && ($_ =~ /$cronPat/)) {
	$_ =~ s/^\#*(\d.*)/$1/;
	$found++;
      }
    }
    if ($found == $cronCnt) { # activate the new cron
      my $cronNew = "$cronDir/$host.cron";
      $fh->open(">$cronNew") || die("$bmcErrorPrefix cannot open file $cronNew");
      foreach (@cron) {
	print $fh "$_";
      }
      $fh->close;
      print "crontab $cronNew\n";
      my $out = `crontab $cronNew`;
      ($out ne "") && die("$bmcErrorPrefix $out");
      system("crontab -l|grep \"$cronPat\"");
    }
    else {
      print "$bmcInfoPrefix $found not match $cronCnt\n";
    }
  }
  ($bmcInternalDebug) && print "...iTurnOnCron end!\n";

}

sub sBlReport {
  my ($ins) = @_;

  ($bmcDebug) && print "...sBlReport start...\n";
  $out = `$ct setview -exe "cd /vob/$ins->{vobFamilyL}; $blreport $ins->{targetIntBl} 2>&1" $commonView 2>&1`;
  print "$out";
  ($bmcDebug) && print "...sBlReport end!\n";

}

sub sBuild {
  my ($ins) = @_;

  ($bmcDebug) && print "...sBuild start...\n";
  # setup build log and record build start time
  my $buildLog = "$ins->{dailyLog}/$ins->{cmdBView}.$ins->{cmdBModeName}.log";
  my $now = scalar localtime;
  my $fh = new FileHandle;
  $fh->open(">>$buildLog") || die("$bmcErrorPrefix cannot open file $buildLog");
  print $fh "$now inside sBuild\n";
  $fh->close;

  iCheckConditions($ins, $buildLog);

  # build start
  print "$ct setview -exe \"$ins->{sTool} >> $buildLog  2>&1\" $ins->{cmdBView} 2>&1\n";
  my $out = `$ct setview -exe \"$ins->{sTool} >> $buildLog  2>&1\" $ins->{cmdBView} 2>&1`;
  # try to catch setview error
  ($out =~ /cleartool: Error/) && die("$bmcErrorPrefix $out!");

  # for baseline build only
  print "cmdBModeName: $ins->{cmdBModeName}\n";
  if ($ins->{cmdBModeName} =~ /emakeBaseline/ || $ins->{cmdBModeName} =~ /noWinBldPkg/) {
    my @sTool = split /\//, $ins->{sTool};
    my $sToolF = $sTool[-1];
    my $buildErrorLog = "$ins->{baseIntLbDir}/$sToolF.bsf";
    (-e $buildErrorLog) || die("$bmcErrorPrefix $buildErrorLog doesn't exist");
     my $BSF_COUNT;
    if ($ins->{cmdBModeName} =~ /emakeBaseline/) {
      $BSF_COUNT=`cat $buildErrorLog | grep failures | cut -f1 -d' '`;
    }
    else {
      $BSF_COUNT = (lstat($buildErrorLog))[7];
    }
    chomp($BSF_COUNT);
    if ($BSF_COUNT eq '0') {
      $ins->{cmdAttrName} = 'state';
      $ins->{cmdAttrValue} = 'built';
      sUpdateAttr($ins);
    }
    else {      
      die("$bmcErrorPrefix Error count of $buildErrorLog is $BSF_COUNT and buildmode is $ins->{cmdBModeName}");
    }
  }
  ($bmcDebug) && print "...sBuild end!\n";

}

sub sCheckIns {
  my ($ins) = @_;

  ($bmcDebug) && print "...sCheckIns start...\n";
  my $insName = "$::DATA_DIR/$ins->{series}/$ins->{name}.ins";
  my $fh = new FileHandle;
  $fh->open("<$insName") || die("cannot open file $insName");
  my @insFile = <$fh>;
  $fh->close;
  foreach (@insFile){
    print $_;
  }
  ($bmcDebug) && print "...sCheckIns end!\n";
  
}

sub sCheckNBVer {
  my ($ins) = @_;

  ($bmcDebug) && print "...checkNBVer start...\n";
  my $cmbpLabel = iGetViewVer($ins->{wuceProduct}, $ins->{cmdBView});
  print "$cmbpLabel\n";
  ($bmcDebug) && print "..checkNBVer end!\n";

}

sub sCloseCr {
  my ($ins) = @_;

  ($bmcDebug) && print "...sCloseCr start...\n";
  my $out = `$ct setview -exe "cd /vob/$ins->{vobFamilyL}; $closecr -bl $ins->{targetIntBl} 2>&1" $commonView 2>&1`;
  print "$out";
  $out = `$ct setview -exe "cd /vob/$ins->{vobFamilyL}; $blreport $ins->{targetIntBl} 2>&1" $commonView 2>&1`;
  print "$out";
  ($bmcDebug) && print "...sCloseCr end!\n";

}

sub sCloseIntBl {
  my ($ins) = @_;

  ($bmcDebug) && print "...sCloseIntBl start...\n";
  my $out = `$ct setview -exe "cd /vob/$ins->{vobFamilyL}; $closebl $ins->{targetIntBl} 2>&1" $commonView 2>&1`;
  print "$out";
  ($bmcDebug) && print "...sCloseIntBl end!\n";

}

sub sCloseScmBl {
  my ($ins) = @_;

  ($bmcDebug) && print "...sCloseScmBl start...\n";
  my $out = `$ct setview -exe "cd /vob/$ins->{vobFamilyL}; $closebl $ins->{targetScmBl} 2>&1" $commonView 2>&1`;
  print "$out";
  ($bmcDebug) && print "...sCloseScmBl end!\n";

}

sub sCreateReminderCron {
  my ($ins) = @_;

  my $fh = new FileHandle;
  my @cron = `crontab -l 2>&1`;
  unless ($cron[0] =~ /no crontab/) {
    # make a copy of current cron job
    my $cronBk = "$cronDir/$host.cron.backup";
    $fh->open(">$cronBk") || die("$bmcErrorPrefix cannot open file $cronBk");
    foreach (@cron) {
      print $fh "$_";
    }
    $fh->close;
  }

  my $cronNew = "$cronDir/$host.cron";
  $fh->open(">$cronNew") || die("$bmcErrorPrefix cannot open file $cronNew");
  foreach (@cron) {
    print $fh "$_";
  }
  print $fh "\n#########################################\n";
  print $fh "# Baseline Engine View Removal Reminder\n";
  print $fh "#\n";
  print $fh "#0 9 * * 1,2,3,4,5 /mot/proj/wibb_bts2/bmc/test/bin/bmc -instance $ins->{targetIntLb} -step sRmViewReminder\n";
  $fh->close;
  print "crontab $cronNew\n";
  my $out = `crontab $cronNew`;
  ($out ne "") && die("$bmcErrorPrefix $out");
  system("crontab -l|grep \"$ins->{targetIntLb}\"");
}

sub sCreateTargetIntBr {
  my ($ins) = @_;

  ($bmcDebug) && print "...createTargetIntBr start...\n";
  if (iCheckView($ins->{targetIntBr})) {
    iCreateTagView($ins->{targetIntBr},$ins->{baseScmLb},$ins->{vobFamilyU}, '-share_vw');
  }
  else {
    print "$bmcInfoPrefix $ins->{targetIntBr} already exists!\n";
  }
  $ins->{cmdAttrName} = 'state';
  $ins->{cmdAttrValue} = 'created';
  sUpdateAttr($ins);
  ($bmcDebug) && print "...createTargetIntBr end!\n";
  
}

sub sGenCrStat {
  my ($ins) = @_;

  ($bmcDebug) && print "...sGenCrStat start...\n";
  my $crStatGen = "$::BIN_DIR/gen_crstat";
  print "$crStatGen -s $ins->{crStatBr} -d $ins->{crStatDir} -v $ins->{vobFamilyL} 2>&1\n";
  my $out = `$crStatGen -s $ins->{crStatBr} -d $ins->{crStatDir} -v $ins->{vobFamilyL} 2>&1`;
  if ($out ne "") {
    print "$bmcInfoPrefix $out\n";
  }
  else {
    print "$bmcInfoPrefix CR stat is generated at $ins->{crStatDir}\n";
  }
  ($bmcDebug) && print "...genCrStat end!\n";  

}

sub sGenIns {
  my ($series, $ins, $ste, $att, $vie, $mod) = @_;

  ($bmcDebug) && print "...sGenIns start...\n";
  # determine instance location
  my $insLoc = "$::DATA_DIR/$series/${ins}.ins";  
  if (-e "$insLoc") {
    print "$bmcInfoPrefix $insLoc exists\n";
  }
  else {
    iGenIns($series, $ins, 'generated');
  }
  ($bmcDebug) && print "...sGenIns end!\n";

}

sub sGrantOkMergeToInt {
  my ($ins) = @_;

  ($bmcDebug) && print "...grantOkMergeToInt start...\n";
  print "$scMergeList -add -f $ins->{targetIntBr} -tbranch $ins->{targetRelMain} -v $ins->{vobFamilyU}\n";
  system("$scMergeList -add -f $ins->{targetIntBr} -tbranch $ins->{targetRelMain} -v $ins->{vobFamilyU}") && die("$commonErrorPefix: $scMergeList");
  ($bmcDebug) && print "...grantOkMergeToInt end!\n";

}

sub sIncreNBVer {
  my ($ins) = @_;

  ($bmcDebug) && print "...sIncreNBVer start...\n";
  (iCheckView($ins->{cmdBView})) && die("$bmcErrorPrefix $ins->{cmdBView} doesn't exist");
  my $currNBVer = iGetViewVer($ins->{wuceProduct}, $ins->{cmdBView});
  my $cmbpPart = iParseIntLb($currNBVer, 'uc');
  my $nextBldRev = '01';
  my $out;
  my $incFile="bldrev"; 
  if(iCheckNewNumberCondition($cmbpPart)){
	  $incFile="prodver";
  }
  print "$ct setview -exe \"cd /vob/$ins->{vobFamilyL}/bld/wuce/ver; $ct co -nc $incFile 2>&1\" $ins->{cmdBView}\n";
  $out =`$ct setview -exe \"cd /vob/$ins->{vobFamilyL}/bld/wuce/ver; $ct co -nc $incFile 2>&1\" $ins->{cmdBView}`;
  ($out =~ /cleartool: Error/) && die("$bmcErrorPrefix $out");
  system("$ct setview -exe \"cd /vob/$ins->{vobFamilyL}/bld/wuce/ver; echo $nextBldRev > $incFile\" $ins->{cmdBView}");
  print "$ct setview -exe \"cd /vob/$ins->{vobFamilyL}/bld/wuce/ver; $ct ci -nc -iden $incFile 2>&1 \" $ins->{cmdBView}\n";
  $out = `$ct setview -exe \"cd /vob/$ins->{vobFamilyL}/bld/wuce/ver; $ct ci -nc -iden $incFile 2>&1 \" $ins->{cmdBView}`;
  ($out =~ /cleartool: Error/) && die("$bmcErrorPrefix $out");
  ($bmcDebug) && print "..sIncreNBVer end!\n";

}

sub iCheckNewNumberCondition{
  my ($cmbpPart) = @_;  
 ($bmcInternalDebug) &&  print "...iCheckNewNumberCondition start...\n";
  my $ccRel = $cmbpPart->[3];
  my $ccType = $cmbpPart->[4];
  ($bmcDebug) && print "..iCheckNewNumberCondition end!\n";
  return ($ccRel eq '5.0' && $ccType ne 'DEVINT'); 
}

sub sCreateRelLb {
  my ($ins) = @_;

  ($bmcDebug) && print "...createRelLb start...\n";
  iCheckConditions($ins);
  iLbType($ins, $ins->{relView}, $ins->{targetScmLb});
  $ins->{cmdAttrName} = 'state';
  $ins->{cmdAttrValue} = 'createdRelLb';
  sUpdateAttr($ins);
  ($bmcDebug) && print "...createRelLb end!\n";

}

sub sLabelRelMain {
  my ($ins) = @_;

  ($bmcDebug) && print "...labelRelMain start...\n";
  iCheckConditions($ins);
  iLabel($ins, $ins->{relView}, $ins->{targetScmLb});
  iLock($ins->{lbVob}, 'lbtype', $ins->{targetScmLb});
  $ins->{cmdAttrName} = 'state';
  $ins->{cmdAttrValue} = 'baselinedRel';
  sUpdateAttr($ins);
  ($bmcDebug) && print "...labelRelMain end!\n";

}

sub sCreateBldLb {
  my ($ins) = @_;

  ($bmcDebug) && print "...sCreateBLDLb start...\n";
  iCheckConditions($ins);
  iLbType($ins, $ins->{cmdBView}, $ins->{targetIntLb});
  $ins->{cmdAttrName} = 'state';
  $ins->{cmdAttrValue} = 'createdBldLb';
  sUpdateAttr($ins);
  ($bmcDebug) && print "...sCreateBLDLbr end!\n";

}

sub sLabelTargetIntBr {
  my ($ins) = @_;

  ($bmcDebug) && print "...labelTargetIntBr start...\n";
  iCheckConditions($ins);
  iLabel($ins, $ins->{cmdBView}, $ins->{targetIntLb});
  iLock($ins->{lbVob}, 'lbtype', $ins->{targetIntLb});
  $ins->{cmdAttrName} = 'state';
  $ins->{cmdAttrValue} = 'baselinedBld';
  sUpdateAttr($ins);
  ($bmcDebug) && print "...labelTargetIntBr end!\n";

}

sub sLinkIntBlP {
  my ($ins) = @_;

  ($bmcDebug) && print "...sLinkIntBlP start...\n";
  my $out = `$ct setview -exe "cd /vob/$ins->{vobFamilyL}; $linkbl $ins->{targetIntBl} -a -predecessor $ins->{predIntBl} 2>&1" $commonView 2>&1`;
  print "$out";
  ($bmcDebug) && print "...sLinkIntBlP end!\n";

}

sub sLinkScmBlP {
  my ($ins) = @_;

  ($bmcDebug) && print "...sLinkScmBlP start...\n";
  my $out = `$ct setview -exe "cd /vob/$ins->{vobFamilyL}; $linkbl $ins->{targetScmBl} -a -predecessor $ins->{predScmBl} 2>&1" $commonView 2>&1`;
  print "$out";
  ($bmcDebug) && print "...sLinkScmBlP end!\n";

}

sub sLinkScmBlC {
  my ($ins) = @_;

  ($bmcDebug) && print "...sLinkScmBlC start...\n";
  my $out = `$ct setview -exe "cd /vob/$ins->{vobFamilyL}; $linkbl $ins->{targetScmBl} -a -child $ins->{targetIntBl} 2>&1" $commonView 2>&1`;
  print "$out";
  ($bmcDebug) && print "...sLinkScmBlC end!\n";

}

sub sLoadCrStat {
  my ($ins) = @_;

  ($bmcDebug) && print "...loadCrStat start...\n";
  my $crStatLoad = "$::BIN_DIR/load_crstat";
  print "$crStatLoad -d $ins->{crStatDir} -c amd033 -fo $ins->{crStatFolder} 2>&1\n";
  my $out = `$crStatLoad -d $ins->{crStatDir} -c amd033 -fo $ins->{crStatFolder} 2>&1`;
  ($out ne "") && die("$bmcErrorprefix $out");
  ($bmcDebug) && print "...loadCrStat end!\n";  

}

sub sLockTargetIntBr {
  my ($ins) = @_;

  ($bmcDebug) && print "...lockTargetIntBr start...\n";
  iLock($ins->{mgVob}, 'brtype', $ins->{targetIntBr});
  ($bmcDebug) && print "...lockTargetIntBr end!\n";

}

sub sMergeIntToRelMain {
  my ($ins) = @_;

  ($bmcDebug) && print "...mergeIntToRelMain start...\n";
  iCheckConditions($ins);
  my ($vob,$mergeLog,$vFamU);
  for $vob (@{$ins->{mgVob}}) {
    $mergeLog = "$ins->{baseIntLbDir}/$ins->{targetIntBr}.scBRMerge.$vob->[0]";
    $vFamU = uc $vob->[0];
    print "$ct setview -exe \"$scBRMerge -f $ins->{targetIntBr} -nong -v $vFamU > ${mergeLog} 2>&1\" $ins->{relView}\n";
    system("$ct setview -exe \"$scBRMerge -f $ins->{targetIntBr} -nong -v $vFamU > ${mergeLog} 2>&1\" $ins->{relView}");
  }
  for $vob (@{$ins->{mgVob}}) {
    $mergeLog = "$ins->{baseIntLbDir}/$ins->{targetIntBr}.scBRMerge.$vob->[0]";
    iCheckLog($mergeLog, $vob->[3], 10);
  }
  $ins->{cmdAttrName} = 'state';
  $ins->{cmdAttrValue} = 'mergedToRelMain';
  sUpdateAttr($ins);
  ($bmcDebug) && print "...mergeIntToRelMain end!\n";

}

sub sMergeStat {
  my ($ins) = @_;

  ($bmcDebug) && print "...sMergeStat start...\n";
  print "$mergeStat -b $ins->{targetIntBr} -v $ins->{vobFamilyU}\n";
  system("$mergeStat -b $ins->{targetIntBr} -v $ins->{vobFamilyU}");
  $internalViewPattern = "$ins->{series}-$bmc-ecloud-*";
  my $out = `$ct lsview ${internalViewPattern} 2>&1`;
  ($out =~ /cleartool: Error/) && return 0;
  print "$bmcInfoPrefix Please remove the these temporary views before start integration:\n$out";  
  ($bmcDebug) && print "...sMergeStat end!\n";

}

sub sRmViewReminder {
  my ($ins) = @_;

  #($bmcDebug) && print "...sRmViewReminder start...\n";
  # check if there is tmp views left from last baseline
  $internalViewPattern = "$ins->{series}-$bmc-ecloud-*";
  my $out = `$ct lsview ${internalViewPattern} 2>&1`;
  ($out =~ /cleartool: Error/) && return 0;

  my $subject = "$bmcInfoPrefix Please remove following views before next baseline";
  my $file = "/tmp/$ins->{login}_bmc_sRmViewReminder";
  # make sure we have a new file everytime
  if (-e $file) {
    unlink($file);
  }
  my $fh = new FileHandle;
  $fh->open(">>$file") || die("cannot open file $file");
  print $fh "$bmcInfoPrefix Please remove following views before next baseline\n\n$out";
  chmod(0666,$file);
  $fh->close;
  # Email remove view reminder
  my $mail = `/bin/mail -s "$subject" $ins->{recipient} < $file`;
  
  #($bmcDebug) && print "...sRmViewReminder end!\n";

}

sub sMkPrjDevPrjInt {
  my ($ins) = @_;
  iMkPrjDevPrj($ins, $ins->{targetIntLb});

}

sub sMkPrjDevPrjScm {
  my ($ins) = @_;
  iMkPrjDevPrj($ins, $ins->{targetScmLb});
  
}

sub sSwapNBView {
  my ($ins) = @_;
  
  ($bmcDebug) && print "...sSwapNBView start...\n";
  my $pathTag = "$ins->{series}-$bmc-ecloud-nb-1";
  my $pathTagSec = "$ins->{series}-$bmc-ecloud-nb-2";
  my $pathTag3rd = "$ins->{series}-$bmc-ecloud-nb-3";
  # This section is for future build considerations
  my $viewTag;
  if ($ins->{cmdBView} eq "noUse") {
    $viewTag = $ins->{cmdBView};
  }
  else {
    $viewTag = $ins->{cmdBView};
  }
  # use $ins->{targetIntBr} as intRefView to pick up just-created integration branch/view
  iSwapView($viewTag, $ins->{baseScmLb}, $ins->{targetIntBr}, $ins->{vobFamilyU}, $pathTag, $pathTagSec, $pathTag3rd);
  ($bmcDebug) && print "...sSwapNBView end!\n";

}

sub sSwapWBView {
  my ($ins) = @_;
  
  ($bmcDebug) && print "...swapWBView start...\n";
  my $pathTag = "$ins->{series}-$bmc-ecloud-wb-1";
  my $pathTagSec = "$ins->{series}-$bmc-ecloud-wb-2";
  my $pathTag3rd = "$ins->{series}-$bmc-ecloud-wb-3";
  # This section is for future build considerations
  my $viewTag;
  if ($ins->{cmdBView} eq "noUse") {
    $viewTag = $ins->{cmdBView};
  }
  else {
    $viewTag = $ins->{cmdBView};
  }
  # use $ins->{cmdBView} as intRefView to pick up any config_spec change
  iSwapView($viewTag, $ins->{baseScmLb}, $ins->{cmdBView}, $ins->{vobFamilyU}, $pathTag, $pathTagSec, $pathTag3rd);
  ($bmcDebug) && print "...swapWBView end!\n";

}

sub sSynConfig {
  my ($ins) = @_;
  
  ($bmcDebug) && print "...sSynConfig start...\n";
  my $nBConfigSpec = iGetConfigSpec($ins->{nBView});
  iSetCS($nBConfigSpec, $ins->{targetIntBr});
  ($bmcDebug) && print "...sSynConfig end!\n";

}

sub sTurnOffNBuild {
  my ($ins) = @_;
  
  ($bmcDebug) && print "...sTurnOffNBuild start...\n";
  my $cronPat = $ins->{nBCronPat};
  my $cronCnt = $ins->{nBCronCnt};
  iTurnOffCron($cronPat, $cronCnt);
  ($bmcDebug) && print "...sTurnOffNBuild end!\n";

}

sub sTurnOffOkMergeToCr {
  my ($ins) = @_;
  
  ($bmcDebug) && print "...sTurnOffOkMergeToCr start...\n";
  my $cronPat = $ins->{targetIntBl};
  my $cronCnt = $ins->{okCronCnt};
  iTurnOffCron($cronPat, $cronCnt);
  ($bmcDebug) && print "...sTurnOffOkMergeToCr end!\n";

}

sub sTurnOffRVReminder {
  my ($ins) = @_;
  
  ($bmcDebug) && print "...sTurnOffRVReminder start...\n";
  my $cronPat = $ins->{targetIntLb};
  my $cronCnt = $ins->{okCronCnt};
  iTurnOffCron($cronPat, $cronCnt);
  ($bmcDebug) && print "...sTurnOffRVReminder end!\n";

}

sub sTurnOnNBuild {
  my ($ins) = @_;
  
  ($bmcDebug) && print "...sTurnOnNBuild start...\n";
  my $cronPat = $ins->{nBCronPat};
  my $cronCnt = $ins->{nBCronCnt};
  iTurnOnCron($cronPat, $cronCnt);
  ($bmcDebug) && print "...sTurnOnNBuild end!\n";

}

sub sTurnOnOkMergeToCr {
  my ($ins) = @_;
  
  ($bmcDebug) && print "...sTurnOnOkMergeToCr start...\n";
  my $cronPat = $ins->{targetIntBl};
  my $cronCnt = $ins->{okCronCnt};
  iTurnOnCron($cronPat, $cronCnt);
  ($bmcDebug) && print "...sTurnOnOkMergeToCr end!\n";

}

sub sTurnOnRVReminder {
  my ($ins) = @_;
  
  ($bmcDebug) && print "...sTurnOnRVReminder start...\n";
  my $cronPat = $ins->{targetIntLb};
  my $cronCnt = $ins->{okCronCnt};
  iTurnOnCron($cronPat, $cronCnt);
  ($bmcDebug) && print "...sTurnOnRVReminder end!\n";

}

sub sUpdateAttr {
  my ($ins) = @_;

  ($bmcDebug) && print "...sUpdateAttr start...\n";
  my $insName = "$::DATA_DIR/$ins->{series}/$ins->{name}.ins";
  my $insNameB = "$insName.$ins->{cmdAttrName}";
  (defined $ins->{$ins->{cmdAttrName}}) || die("$bmcErrorPrefix \"$ins->{cmdAttrName}\" is invalid attribute for instance \"$insName\"");
  if ($ins->{$ins->{cmdAttrName}} eq $ins->{cmdAttrValue}) {
    print "$bmcInfoPrefix The request update of \"$ins->{cmdAttrName}\" is same as current\n";
  }
  else {
    # more considerations on allowable state transitions
    copy("$insName", "$insNameB");
    my $fh = new FileHandle;
    $fh->open("<$insName") || die("cannot open file $insName");
    my @insFile = <$fh>;
    $fh->close;
    foreach (@insFile){
      if ($_ =~ /$ins->{cmdAttrName}=\"$ins->{$ins->{cmdAttrName}}\"/) {
	$_ =~ s/$ins->{cmdAttrName}=\"$ins->{$ins->{cmdAttrName}}\"/$ins->{cmdAttrName}=\"$ins->{cmdAttrValue}\"/;
        last;
      }
    }
    $fh->open(">$insName") || die("cannot open file $insName");
    foreach (@insFile) {
      print $fh "$_";
    }
    $fh->close;
  }
  print "$bmcInfoPrefix Current \"$ins->{cmdAttrName}\" is \"$ins->{cmdAttrValue}\"\n";
  ($bmcDebug) && print "...sUpdateAttr end!\n";
  
}

sub sUpdateIns {
  my ($ins) = @_;

  ($bmcDebug) && print "...updateIns start...\n";
  my $insName = "$::DATA_DIR/$ins->{series}/$ins->{name}.ins";
  my $insNameB = "$insName.updateIns" ;
  copy("$insName", "$insNameB");
  iGenIns($ins->{series}, $ins->{name}, $ins->{state}, $ins->{baseIntLb});
  print "$bmcInfoPrefix Current \"state\" is \"$ins->{state}\" and \"baseIntLb\" is \"$ins->{baseIntLb}\"\n";
  ($bmcDebug) && print "...updateIns end!\n";
  
}

sub sUpdateNBVer {
  my ($ins) = @_;

  ($bmcDebug) && print "...updateNBVer start...\n";
  (iCheckView($ins->{cmdBView})) && die("$bmcErrorPrefix $ins->{cmdBView} doesn't exist");
  my $cmbpPart = iParseIntLb($ins->{targetIntLb}, 'uc');
  my $out;
  print "$ct setview -exe \"cd /vob/$ins->{vobFamilyL}/bld/wuce/ver; $ct co -nc sysrel iter prodver bldrev sys prod bld extra 2>&1\" $ins->{cmdBView}\n";
  $out =`$ct setview -exe \"cd /vob/$ins->{vobFamilyL}/bld/wuce/ver; $ct co -nc sysrel iter prodver bldrev sys prod bld extra 2>&1\" $ins->{cmdBView}`;
  ($out =~ /cleartool: Error/) && die("$bmcErrorPrefix $out");
  system("$ct setview -exe \"cd /vob/$ins->{vobFamilyL}/bld/wuce/ver; echo $cmbpPart->[0] > sys \" $ins->{cmdBView}");
  system("$ct setview -exe \"cd /vob/$ins->{vobFamilyL}/bld/wuce/ver; echo $cmbpPart->[1] > prod \" $ins->{cmdBView}");
  system("$ct setview -exe \"cd /vob/$ins->{vobFamilyL}/bld/wuce/ver; echo $cmbpPart->[3] > sysrel \" $ins->{cmdBView}");
  system("$ct setview -exe \"cd /vob/$ins->{vobFamilyL}/bld/wuce/ver; echo $cmbpPart->[4] > bld \" $ins->{cmdBView}");
  system("$ct setview -exe \"cd /vob/$ins->{vobFamilyL}/bld/wuce/ver; echo $cmbpPart->[5] > iter \" $ins->{cmdBView}");
  system("$ct setview -exe \"cd /vob/$ins->{vobFamilyL}/bld/wuce/ver; echo $cmbpPart->[6] > prodver \" $ins->{cmdBView}");
  system("$ct setview -exe \"cd /vob/$ins->{vobFamilyL}/bld/wuce/ver; echo $cmbpPart->[7] > bldrev\" $ins->{cmdBView}");
  system("$ct setview -exe \"cd /vob/$ins->{vobFamilyL}/bld/wuce/ver; echo -n \"\" > extra \" $ins->{cmdBView}");
  print "$ct setview -exe \"cd /vob/$ins->{vobFamilyL}/bld/wuce/ver; $ct ci -nc -iden sysrel iter prodver bldrev sys prod bld extra 2>&1 \" $ins->{cmdBView}\n";
  $out = `$ct setview -exe \"cd /vob/$ins->{vobFamilyL}/bld/wuce/ver; $ct ci -nc -iden sysrel iter prodver bldrev sys prod bld extra 2>&1 \" $ins->{cmdBView}`;
  ($out =~ /cleartool: Error/) && die("$bmcErrorPrefix $out");
  ($bmcDebug) && print "..updateNBVer end!\n";

}

sub sUpdateOkMergeToCr {
  my ($ins) = @_;
  
  ($bmcDebug) && print "...sUpdateOkMergeToCr start...\n";
  my $found = 0;
  my @cron = `crontab -l 2>&1`;
  if ($cron[0] =~ /no crontab/) {
    print "$bmcInfoPrefix $cron[0]\n";
  }
  else {
    my $fh = new FileHandle;
    # make a copy of current cron job
    my $cronBk = "$cronDir/$host.cron.backup";
    $fh->open(">$cronBk") || die("$bmcErrorPrefix cannot open file $cronBk");
    foreach (@cron) {
      print $fh "$_";
    }
    $fh->close;
    my $prevIntBl = iGenPrevCMBPMData($ins->{targetIntBl}, 'uc');
    my $prevIntBr = iGenPrevCMBPMData($ins->{targetIntBr}, 'lc');
    # replace two items
    foreach (@cron) {
      if ($_ =~ /$prevIntBr/) {
	$_ =~ s/$prevIntBl/$ins->{targetIntBl}/;
	$_ =~ s/$prevIntBr/$ins->{targetIntBr}/;
	$found++;
      }
    }
    if ($found == $ins->{okCronCnt}) { # activate the new cron
      my $cronNew = "$cronDir/$host.cron";
      $fh->open(">$cronNew") || die("$bmcErrorPrefix cannot open file $cronNew");
      foreach (@cron) {
	print $fh "$_";
      }
      $fh->close;
      print "crontab $cronNew\n";
      my $out = `crontab $cronNew`;
      ($out ne "") && die("$bmcErrorPrefix $out");
      system("crontab -l|grep \"$ins->{targetIntBl}\"");
    }
    else {
      print "$bmcInfoPrefix $found not match $ins->{okCronCnt}\n";
    }
  }
  ($bmcDebug) && print "...sUpdateOkMergeToCr end!\n";

}

sub sUpdateRVReminder {
  my ($ins) = @_;
  
  ($bmcDebug) && print "...sUpdateRVReminder start...\n";
  my $found = 0;
  my @cron = `crontab -l 2>&1`;
  if ($cron[0] =~ /no crontab/) {
    print "$bmcInfoPrefix $cron[0]\n";
  }
  else {
    my $fh = new FileHandle;
    # make a copy of current cron job
    my $cronBk = "$cronDir/$host.cron.backup";
    $fh->open(">$cronBk") || die("$bmcErrorPrefix cannot open file $cronBk");
    foreach (@cron) {
      print $fh "$_";
    }
    $fh->close;
    my $prevIntLb = iGenPrevCMBPMData($ins->{targetIntLb}, 'uc');
    # replace two items
    foreach (@cron) {
      if ($_ =~ /$prevIntLb/) {
	$_ =~ s/$prevIntLb/$ins->{targetIntLb}/;
	$found++;
      }
    }
    if ($found == $ins->{rvCronCnt}) { # activate the new cron
      my $cronNew = "$cronDir/$host.cron";
      $fh->open(">$cronNew") || die("$bmcErrorPrefix cannot open file $cronNew");
      foreach (@cron) {
	print $fh "$_";
      }
      $fh->close;
      print "crontab $cronNew\n";
      my $out = `crontab $cronNew`;
      ($out ne "") && die("$bmcErrorPrefix $out");
      system("crontab -l|grep \"$ins->{targetIntLb}\"");
    }
    else {
      print "$bmcInfoPrefix $found not match $ins->{rvCronCnt}\n";
    }
  }
  ($bmcDebug) && print "...sUpdateRVReminder end!\n";

}

1;
