#!/usr/bin/perl -w

##########################################################
### TODO: to be refactoring to make it more object-orient
use Net::FTP;
use ncs::Common;
use ncs::Mailer;
use ncs::core::Mailiter;
use ncs::SR4ncs;

our @mail_messages = ();
#store merged status
our ($passnums,$failnums,$errornums) = (0,0,0);
our @merged_messages = (), @merged_results = ();

sub send_mail
{
    my ($subject) = @_;
	sub prepare_mail{
		$log->info("prepare mail contents...");
		#build email
		build_email();
		eval{
			if(&need_merge_mails()){
				&merge_emails();
			}
		};
		if($@){
			$log->error("merge emails failed due to: $@");
			&terminate_ncs();
		}
	}
    $log->info("===============send normal mail===============");
    &prepare_mail();
	return if(!&is_sendmail_enabled());
	#record project before send email out
    &record_project();
	eval{
		my $mailer = &new_mailer();
		$mailer->subject(&build_mail_subject($subject));
		my $test_report = $props->get("ncs.mail.store");
		#test report
		if(&need_merge_mails()){
			$test_report = $props->get("ncs.mail.merged", "mail_merged.html");
		}
		my $test_report_store = "$store_dir/$latest_project_label/$test_report";
		#mailbody for no coverage report
		my $mailbody=qq{
			<body>
			Here's <i>NCS</i> report:<br/>
			Test Report: <a href='cid:$test_report'>$test_report</a>
			</body>
		};
		#print coverage
		my $print_coverage = $props->get("ncs.option.print_coverage", 0);
		#coverage report
		my $cov_report = $props->get("ncs.coverage.store", "Coverage_full.csv");
		my $cov_report_store = "$store_dir/$latest_project_label/$cov_report";
		if($print_coverage){
			$mailbody=qq{
				<body>
				Here's <i>NCS</i> report: <br/>
				Test Report: <a href='cid:$test_report'>$test_report</a><br/>
				Coverage Report: <a href='cid:$cov_report'>$cov_report</a>
				</body>
			};
		}
		$mailer->mailbody("text/html", $mailbody);
		$mailer->attach("text/html", $test_report_store, $test_report);
		$mailer->attach("text/csv", $cov_report_store, $cov_report) if $print_coverage;
		#send mail
        $mailer->send();
		$log->info("The mail $subject has been sent out!");
    };
    if($@){
        $log->error("Cannot send email due to $@.");
    }
}

sub send_inform
{
	my ($subject, @messages) = @_;
	$log->info("===============send error mail===============");
	return if(!&is_sendmail_enabled());
	eval{
		my $mailer = &new_mailer($TRUE);
		$mailer->subject(&build_mail_subject($subject));
		unshift(@messages, "<div class='error'>");
		push(@messages, "</div>");
		unshift(@messages, &build_email_header());
		push(@messages, &build_email_footer());
		my $content = join('', @messages);
		$mailer->mailbody('text/html', qq{ $content });
		#send mail
        $mailer->send();
		$log->info("The mail $subject has been sent out!");
    };
    if($@){
        $log->error("Cannot send email due to $@.");
    }
}

sub is_sendmail_enabled
{
	my $enable_sendmail = $props->get("ncs.option.enable_sendmail", "0");
    $log->debug("enable_sendmail: $enable_sendmail");
    if(!$enable_sendmail){#disabled sendmail
        $log->warn("sendmail is disabled, NCS will ignore it!!");
        return 0;
    }
	return 1;
}

sub build_mail_subject
{
	my ($subject) = @_;
	$log->info("build mail subject with input [$subject]...");
	if(!defined($subject)){ $subject = $latest_project_label; }
	my $mailsubject = $props->get("ncs.mail.subject");
	$subject = "$mailsubject $subject";
	$log->info("mail subject is: $subject");
	return $subject;
}

sub new_mailer
{
	my ($inform) = @_;
	#initialize mailer
	my $mailserver = $props->get("ncs.mail.server");
	my $mailfrom = $props->get("ncs.mail.from");
	my $tolist = $props->get("ncs.mail.tolist");
	$tolist = $props->get("ncs.mail.informlist") if($inform); 
	my @mailto = split(/[\s,;]+/, $tolist);
	$log->info("create new mailer");
	$log->debug("mailserver: $mailserver");
	$log->debug("mailfrom: $mailfrom");
	$log->debug("tolist: @mailto");
	my $mailer = ncs::core::Mailiter->new($mailserver,$mailfrom,@mailto);
    return $mailer;
}

sub record_project
{
	$log->info("record project start...");
    if(!$props->get("ncs.option.enable_sendmail", 0)){
		$log->warn("this script is not the main one, will ignore record project!");
		$log->warn("ignored record project: $latest_project_label");
		return;
	}
	if($props->get("ncs.option.run_with_cs", 0)){
		$log->warn("this script is run with config-spec, will ignore record project!");
		$log->warn("ignored record project: $latest_project_label");
		return;
	}
    if(!(-e $tested_projects)){ system("touch $tested_projects"); }
	if(&contains_in_file($tested_projects, $latest_project_label)){
		$log->warn("project $latest_project_label has been recorded before!");
        return;
    }
	if(@test_results > 0){ #project is tested
		$log->info("project $latest_project_label is tested");
		my ($prate,$frate) = (0.00,0.00);
		if(($passnums + $failnums + $errornums) > 0){ #testing includes multi-parts
			$log->debug("project includes multi-parts");
			$log->debug("passnums: $passnums, failnums: $failnums, errornums: $errornums");
			($prate,$frate) = &parse_testrate($passnums,$failnums,$errornums);
		}
		else{ #testing includes only one-part
			$log->debug("project only have 1 part");
			$log->debug("passnum: $passnum, failnum: $failnum, errornum: $errornum");
			($prate,$frate) = &parse_testrate($passnum, $failnum, $errornum);
		}
		$log->info("$latest_project_label passrate:$prate, failrate: $frate");
		system("echo $latest_project_label $prate $frate >> $tested_projects");
	}
	else{ #project is not tested
		$log->info("project $latest_project_label is blocked");
		system("echo $latest_project_label BLOCK >> $tested_projects");
	}
	$log->info("record project end.");
}

sub build_email_header
{
	$log->info("build email header...");
	my $mailsubject = $props->get("ncs.mail.subject");
	my $title = "$mailsubject $latest_project_label";
	$log->info("mail title: $title");
	return (
		'<html>','<head>',
		"<title>$title</title>",
        '<style type="text/css">',
        'body{color: black;width:960px;}',
        'div.part{margin-top: 20px; width: 500px; font-weight: bold; background: #eee;cursor:pointer;}',
		'div.part_content{display:none;}',
		'#mergestat{margin-top: 20px;font-size: 80%;}',
		'#ncsreport span{width: 500px; font-weight: bold; background: #eee;cursor:pointer;}',
		'#ncssrlist span{width: 500px; font-weight: bold; background: #eee;cursor:pointer;}',
		'#srlist{display:block; margin:5px 1px; border-collapse:collapse;font-size: 80%;}',
		'#srlist td {border:#000000 1px solid;}',
		'div.test_summary{}',
		'div.test_particular{margin-top: 20px; width: 360px; background: #eee;cursor:pointer;}',
		'div.test_results{display:none}',
        'span.error{color: red;}',
        'span.failed{color: red;}',
        'span.pass{color: blue;}',
		'#footer{margin-top: 20px;}',
		'#hover_content{position:absolute; z-index:99; display:none; background-color: 76A4FB;}',
        '</style>',
		'</head>','<body>',
        '<h3>CoSim Nightly Script</h3>',
		'<div id="hover_content"></div>');
}

sub build_test_summary
{
    my ($pass,$fail,$error) = @_;
	$log->info("build test summary...");
    my $total = $pass+$fail+$error;
    my $passrate = 0;
    if($total > 0){ $passrate = $pass/$total; }
    my $prate = sprintf("%.2f", $passrate*100)."%";
    my $fail_style = ''; if($fail > 0){$fail_style = 'failed';}
    my $error_style = '';if($error > 0){$error_style = 'error';}
	#build test summary
    my @summary = ();
    push(@summary, "Summary:");
    push(@summary, "total - $total");
    push(@summary, "passed - <span class='pass'>$pass</span>");
    push(@summary, "failed - <span class='$fail_style'>$fail</span>");
    push(@summary, "error - <span class='$error_style'>$error</span>");
    push(@summary, "pass rate in the log - $prate");
	$log->info("Test summary: total[$total], passed[$pass], failed[$fail], error[$error], passrate[$prate]");
	my $line_sep = $props->get("ncs.mail.line_sep","\n");
	@summary = map($_.$line_sep, @summary);
	splice(@summary, 0, 0, '<div class="test_summary">');
	push(@summary, '</div>');
    return @summary;
}
sub build_mergestat
{
	$log->info("build mergestat...");
	my $mergestat = $props->get("ncs.tool.mergestat");
	my $line_sep = $props->get("ncs.mail.line_sep","<br/>");
	$branch = qx{$cleartool catcs|grep '^mkbranch'|cut -f2 -d' '};
	chomp($branch);
	$mergestat_name = "mergestat_$branch";
	$mergestat_store = "$store_dir/$latest_project_label/mergestat_$branch";
	if(!(-e $mergestat_store)){
		$log->info("mergestat file not exist, need to generated!");
		$log->debug("cd /vob/wibb_bts; $mergestat -a -l -s -b $branch > $mergestat_name");
		system("cd /vob/wibb_bts; $mergestat -a -l -s -b $branch > $mergestat_name");
		$log->debug("cp /vob/wibb_bts/$mergestat_name $mergestat_store");
		system("cp /vob/wibb_bts/$mergestat_name $mergestat_store");
	}
	my @mergestats = read_as_array($mergestat_store);
	@mergestats = map($_.$line_sep, @mergestats);
	$log->info("mergestat is store at $mergestat_store");
	#$log->debug("@mergestats\n");
	unshift(@mergestats, ("<div id='mergestat'>",
		"CRs Integrated to Baseline", "<br/>", 
		"---------------------------<br/>"));
	push(@mergestats, ("</div>"));
	return @mergestats;
}
sub build_link
{
	$log->info("build links...");
	my $sr_link = $props->get("ncs.mail.sr_link");
	my $r_link = $props->get("ncs.mail.report_link");
	my $line_sep = $props->get("ncs.mail.line_sep","<br/>");
	my @links = ();
	push(@links, "<p>Please refer to <a href=$sr_link title=$sr_link>$sr_link</a> for CoSim SR list.$line_sep");
	push(@links, "Please refer to <a href=$r_link title=$r_link>$r_link</a> for CoSim NCS status report.$line_sep");
	push(@links, '<div id="ncsreport"></div>');
	return @links;
}
sub build_srlist
{
	$log->info("build sr list...");
	my $sr_file = $props->get("ncs.test.sr_mapping_file");
	my $sr_sheet = $props->get("ncs.test.sr_worksheet", 'WMX5.0');
	my $sr4ncs = ncs::SR4ncs->new($sr_file);
	my @header = $sr4ncs->headline($sr_sheet);
	my @latestSrlist = $sr4ncs->latestSrlist($sr_sheet);
	my @srtable = ();
	push(@srtable, '<div id="ncssrlist"><table id="srlist">');
	push(@srtable, '<tr style="background-color:#eee;">');
	foreach $h (@header){ push(@srtable, "<td>$h</td>"); }
	push(@srtable, '</tr>');
	$log->debug("latest sr list size:".scalar(@latestSrlist));
	foreach $sr (reverse(@latestSrlist)){
		push(@srtable, '<tr>');
		foreach $h (@header){ my $elem = $sr->{$h}||""; push(@srtable, "<td>$elem</td>"); }
		push(@srtable, '</tr>');
	}
	push(@srtable, '<tr>');
	push(@srtable, '<td colspan='.scalar(@header).'>');
	push(@srtable, '<b>Summary of all CoSim SRs: </b>');
	foreach $status ('Originated','Assessed','Study','Performed','Closed'){
		my @srlistStatus = $sr4ncs->srlistBy($sr_sheet, '#Status', $status);
		$log->debug("$status sr: ".scalar(@srlistStatus));
		if($status eq 'Closed'){push(@srtable, "$status [".scalar(@srlistStatus)."]");}
		else{push(@srtable, "$status [".scalar(@srlistStatus)."], ");}
	}
	push(@srtable, '</td></tr>');
	push(@srtable, '</table></div>');
	return @srtable;
}

sub build_script
{
	my $show_chart = $props->get("ncs.mail.show_chart",1);
	my $chart_js = $props->get("ncs.mail.chart_js");
	$log->info("build chart start...");
	$log->info("ncs.mail.show_chart=${show_chart}");
	if(!$show_chart || (! -e $chart_js)){ return; }
	sub prj_modtime{
		my ($lbl, $format) = @_;
		if(&is_empty($format)){ $format = "%Y-%m-%d %H:%M:%S"; }
		return &format_time($format,localtime(&file_modtime("$store_dir/$lbl")));
	};
	sub build_prjs_ts{
		my @prjs_ts = ();
		my @prjs = &read_as_array($tested_projects);chomp(@prjs);
		my $prjlen = @prjs;
		my $i = 0;
		push(@prjs_ts, 'var prjs_ts = [');
		foreach $prj (@prjs){
			my $line = '';
			#$log->debug("line: $prj");
			next if $prj =~ /^\s*$/;
			if($prj =~ /BLOCK/){
				my ($lbl,$block) = split(/[\s:;,]+/, $prj, 2);
				my $modtime = &prj_modtime($lbl);
				$line = "{label:'".$lbl."',pass:'',fail:'',block:'100',modtime:'".$modtime."'}";
			}
			else{#tested project
				my ($lbl,$prate,$frate) = split(/[\s:;,]+/, $prj, 3);
				my $modtime = &prj_modtime($lbl);
				$line = "{label:'".$lbl."', pass:'".($prate||0.00)."',fail:'".($frate||0.00)."',modtime:'".$modtime."'}";
			}
			if($i < ($prjlen-1)){ $line .= ','; }
			#$log->debug("add line: $line");
			push(@prjs_ts, $line);
			$i++;
		}
		push(@prjs_ts, '];');
		return @prjs_ts;
	};
	my @script = ();
	push(@script, '<script src="http://www.google.com/jsapi"></script>');
	push(@script, '<script language="javascript" type="text/javascript">');
	if(-e $chart_js){
		push(@script, build_prjs_ts());
		my @chartjs = read_as_array($chart_js); chomp(@chartjs);
		push(@script, @chartjs);
	}
	push(@script, '</script>');
	$log->info("build chart end.");
	return @script;
}

sub build_email_footer
{
	$log->info("build email footer...");
	my $line_sep = $props->get("ncs.mail.line_sep","<br/>");
    return ("<div id='footer'>",
		"Sincerely yours,",$line_sep,
		"CoSim Nightly Script",
		"</div>",
		"</body>","</html>");
}

sub build_email
{
	$log->info("build email start...");
    my $log_dir = $props->get("ncs.log.dir");
    my $line_sep = $props->get("ncs.mail.line_sep","\n");
	my $enable_sendmail = $props->get("ncs.option.enable_sendmail", "0");
    #push header messages 
    push(@mail_messages, build_email_header());
	push(@mail_messages, build_link());
	push(@mail_messages, build_srlist());
    my $workview = qx{$cleartool pwv -s};
    push(@mail_messages, (
        "host: $HOST_NAME / ".&ip($HOST_NAME)."$line_sep",
        "  os: $OS_NAME$line_sep", 
        "view: $workview$line_sep"
    ));
    if(@err_messages > 0){
        foreach $err (@err_messages){
            push(@mail_messages, "<span class='error'>$err</span>$line_sep");
        }
    }  
    if(@build_results > 0){
        #build mail message
        push(@mail_messages, "$line_sep");
        push(@mail_messages, "Results of compilation:$line_sep");
        push(@mail_messages, "--------------------------$line_sep");
		my $loguri = "http://".&ip($HOST_NAME)."/ncslog/$latest_project_label/buildlog";
        push(@mail_messages, "Please find build log @ <a href='$loguri'>$loguri</a>$line_sep");
        push(@mail_messages, @build_results);
    }
    if(@test_results > 0){
        push(@mail_messages, "$line_sep");
        push(@mail_messages, "Results of test execution:$line_sep");
        push(@mail_messages, "--------------------------$line_sep");
		my $loguri = "http://".&ip($HOST_NAME)."/ncslog/$latest_project_label/testlog";
        push(@mail_messages, "Please find test log @ <a href='$loguri'>$loguri</a>$line_sep");
        
        #add Summary to mail messages
        push(@mail_messages, build_test_summary($passnum,$failnum,$errornum));
        #add Particulars to mail message
        push(@mail_messages, '<div class="test_particular">Particulars(click to check test results):</div>');
		splice(@test_results, 0, 0, '<div class="test_results">');
		push(@test_results, '</div>');
        push(@mail_messages, @test_results);
    }
	#push mergestat::Do we need push mergestat in every mail? remember it spent much time and unstable!!
	push(@mail_messages, build_mergestat()) if $enable_sendmail;
    #push end messages 
    push(@mail_messages, build_email_footer());
	#push script
	push(@mail_messages, build_script());
	$log->info("build email end...");
    #store email to local
    my $mail_store = $props->get('ncs.mail.store');
    store_email($mail_store, @mail_messages);
    return @mail_messages;
}

sub store_email
{
    my ($mail_store, @messages) = @_;
	my $mail_store_orig = $mail_store;
    $mail_store = "$store_dir/$latest_project_label/$mail_store";
    $log->info("Store mail message to file: $mail_store");
    save_array_to_file($mail_store, @messages);
    $log->info("Stored mail message to file: $mail_store");
	#upload mail to ftp server if turn on the ftp sync method
	my $sync_mails_option = $props->get('ncs.option.sync_mails', 'locally');
	if($sync_mails_option eq 'ftply'){
		$log->info("NCS will use ftp to sync mails");
		#sync mails with ftp service
		my $ftp = &initialize_ftp();
		#prepare dir
		my $sync_dir = $props->get("ncs.ftp.sync_mails_dir");
		$ftp->cwd($sync_dir);
		my @prjs = $ftp->ls("-t $latest_project_label");
		if(@prjs == 0){$ftp->mkdir($latest_project_label);}
		$ftp->put($mail_store, "$sync_dir/$latest_project_label/$mail_store_orig");
		$log->info("upload mail to $sync_dir/$latest_project_label/$mail_store_orig");
		$ftp->quit();
	}
}

sub sync_mails
{
	$log->info("start to synchronize emails...");
	my $sync_mails_option = $props->get('ncs.option.sync_mails', 'locally');
	$log->info("sync mails with option: $sync_mails_option");
	local @email_depends = split(/[\s,;]+/, $props->get("ncs.mail.depends"));
	sub sync_mails_locally{
		#sync mails with server sync-up service
		foreach $mail (@email_depends){
			$log->info("check if email [$mail] exists?");
			while(!(-e "$store_dir/$latest_project_label/$mail")){
				#wait for other NCS scripts finished
				$log->info("sleep for 60 seconds for check $mail...");
				sleep(60);
				#check ncs timeout before go to next case
				&check_ncstimeout();
			}
			$log->info("found email [$mail] exists!");
		}
	};
	sub sync_mails_ftply{
		#sync mails with ftp service
		my $sync_dir = $props->get("ncs.ftp.sync_mails_dir");
		foreach $mail (@email_depends){
			$log->info("check if email [$mail] exists?");
			my $ftp = &initialize_ftp();
			while(!($ftp->nlist("$sync_dir/$latest_project_label/$mail"))){
				#wait for other NCS scripts finished
				$log->info("sleep for 180 seconds for check $mail...");
				sleep(180);
			}
			$ftp->get("$sync_dir/$latest_project_label/$mail", "$store_dir/$latest_project_label/$mail");
			$ftp->quit();
			$log->info("found email [$mail] exists!");
		}
	};
	sub sync_mails_mailly{
		#sync mails with mail service
		#TODO:
	};
	
	$log->info("waiting for other NCS scripts to finish....");
	$log->info("waiting for depends mails: @email_depends");
	eval{eval("sync_mails_".$sync_mails_option);};
	if($@){
		$log->error("sync mails error: $@");
		&terminate_ncs();
		exit 1;
	}
	$log->info("all of NCS scripts finished now.");
	$log->info("finished synchronize emails.");
	sleep(30);
}

sub need_merge_mails
{
	$log->info("check if need merge emails...");
	return $FALSE if $isbuildfailed;
	my @email_depends = split(/[\s,;]+/, $props->get("ncs.mail.depends"));
	if(scalar(@email_depends) <= 0){
		$log->warn("No mails depends on current script to send!");
		$log->warn("No mails needs to merge!!");
		return $FALSE;
	}
	return $TRUE;
}

sub merge_emails
{
    $log->info("start to merge emails...");
    my $own_order = $props->get("ncs.mail.own_order", "END");
	my @email_depends = split(/[\s,;]+/, $props->get("ncs.mail.depends"));
	my $mail_store = $props->get('ncs.mail.store');
	my $merged_maile_store = $props->get('ncs.mail.merged');
	#waiting for mails synchronization
	&sync_mails();
    if($own_order eq "FIRST"){
        #unshift(@email_depends, $mail_store);
        splice (@email_depends, 0, 0, $mail_store);
    }
    else{ push(@email_depends, $mail_store);}
    my $i = 1;
    foreach $mail (@email_depends){
        &merge_single_email("$store_dir/$latest_project_label/$mail",$i);
        $i++;
    }
    #push the header messages into
    push(@merged_messages, &build_email_header());
    #add Summary to mail messages
    my $total = $passnums + $failnums + $errornums;
    if($total <= 0){
        $log->warn("No testcase is run!");
        $log->warn("The cause may be compile error or project is tested before!!");
        return $FALSE;
    }
    push(@merged_messages, &build_test_summary($passnums,$failnums,$errornums));
	push(@merged_messages, &build_link());
	push(@merged_messages, &build_srlist());
	my $partnum = @email_depends;
    push(@merged_messages, "There are $partnum parts running in different machines<br/>");
	#push merged results
    push(@merged_messages, @merged_results);
	#push mergestat:don't need build again, since it spent much time
	#push(@merged_messages, build_mergestat());
	$mail_store = "$store_dir/$latest_project_label/$mail_store";
	my @mergestats = &copy_to_array($mail_store, "<div id='mergestat'>", "<\/div>");
	push(@merged_messages, @mergestats);
    #push the footer messages into
    push(@merged_messages, &build_email_footer());
	#push script
	push(@merged_messages, build_script($TRUE));
    &store_email($merged_maile_store, @merged_messages);
    $log->info("finished merge emails.");
    return $TRUE;
}

sub merge_single_email
{
    my ($mail_store,$part_num) = @_;
    $log->info("merge single email: $mail_store");
    #merge statistics number
    my $pass_num = &search_num_in_file($mail_store, "passed");
    my $fail_num = &search_num_in_file($mail_store, "failed");
    my $error_num = &search_num_in_file($mail_store, "error");
    $log->info("passnum - $pass_num");
    $log->info("failnum - $fail_num");
    $log->info("errornum - $error_num");
    $passnums += $pass_num;
    $failnums += $fail_num;
    $errornums += $error_num;
    #headline for each part
    push(@merged_results, "<div class='part'>Part $part_num(toggle detail by click me)</div>");
    #merge contents
	#filter header message & footer message, just push test related messages into
	my $end_pattern = "<div id='footer'>";
	if(&contains_in_file($mail_store, "<div id='mergestat'>")){
		 $end_pattern = "<div id='mergestat'>";
	}
	my @mail_contents = &copy_to_array($mail_store, "host: ", $end_pattern);
	push(@merged_results, '<div class="part_content">');
    push(@merged_results, @mail_contents);
	push(@merged_results, '</div>');
    $log->info("merged single email: $mail_store");
}

1;

__END__
