#!/usr/bin/perl -w

use core::Component;
package ncs::mail::Generator;
@ISA=qw(core::Component);

use util::Strings;
use util::Files;

sub new
{
	my ($pkg) = @_;
	my $obj = $pkg->SUPER::new('ncs::mail::Generator',('generate'));
    bless {
		_MAIL_CONTENT => ()
	},$obj;
    return $obj;
}

sub generate
{
	my ($obj,$title) = @_;
	my @mail = ();
	push(@mail, $obj->header());
	push(@mail, $obj->mainbody());
	push(@mail, $obj->copyright());
	push(@mail, $obj->footer());
	$obj->{_MAIL_CONTENT} = @mail;
	return $obj;
}

sub output
{
	my ($obj,$filename) = @_;
	util::Files::save_to_file($filename, $obj->{_MAIL_CONTENT});
}

######################################################
############# Template Methods: can be override
sub header
{
	my $obj = shift;
	my $title = $obj->{_TITLE};
	return qq(
		<html>
		<head>
		<title>${title}</title>
		<style type="text/css"> 
		body{color: black;}
		.part{margin-top: 20px; width: 600px; font-weight: bold; background: #eee;cursor:pointer;}
		.part_content{display:none;}
		#ncsreport span{width: 600px; font-weight: bold; background: #eee;cursor:pointer;}
		#ncssrlist span{width: 600px; font-weight: bold; background: #eee;cursor:pointer;}
		#srlist{display:block; margin:5px 1px; border-collapse:collapse;}
		#srlist td {border:#000000 1px solid;}
		.ncshostinfo{width:350px; background: #eee; border:gray 1px dashed;}
		.ncserrormsg{color: red;}
		.ncsbuildresult{margin-top: 20px; }
		.ncstestresult{margin-top: 20px; }
		.test_summary{}
		.test_particular{margin-top: 20px; width: 360px; background: #eee;cursor:pointer;}
		.test_results{display:none}
		.error{color: red;}
		.failed{color: red;}
		.pass{color: blue;}
		#mergestat{margin-top: 20px;}
		#mergestat span{width: 600px; font-weight: bold; background: #eee; cursor:pointer;}
		#footer{margin-top: 20px;}
		#hover_content{position:absolute; z-index:99; display:none; background-color: 76A4FB;}
		</style>
		</head>
		<body>
		<h3>CoSim Nightly Script</h3>
	);
}

sub footer
{
	my $obj = shift;
	return qq(
		<div id='footer'>
		Sincerely yours,
		<br/>
		CoSim Nightly Script
		</div>
		</body>
		</html>
	);
}

sub copyright
{
	my $obj = shift;
	return qq();
}

sub mainbody
{
	my $obj = shift;
	my @body = ();
	push(@body, $obj->_link());
	push(@body, $obj->_sr_table());
	push(@body, $obj->_ncs_chart());
	
}

#####################################################
################### Private Methods
sub _link
{
	my $obj = shift;
	$log->info("build links...");
	my $sr_link = $obj->{_SR_LINK};
	my $r_link = $obj->{_REPORT_LINK};
	return qq(
		<p>Please refer to <a href=$sr_link title=$sr_link>$sr_link</a> for CoSim SR list
		Please refer to <a href=$r_link title=$r_link>$r_link</a> for CoSim NCS status report
		<div id="ncsreport"></div>
	);
}

sub _sr_table
{
	my $obj = shift;
	my @header = $obj->srheader();
	my @latestSrlist = $obj->srlist();
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
	push(@srtable, $obj->srsummary()->to_str());
	push(@srtable, '</td></tr>');
	push(@srtable, '</table></div>');
	return qq(@srtable);
}

sub _ncs_chart
{
	
}

######################################################
############# Public Methods
sub title
{
	my ($obj,$title) = @_;
	if(defined($title)){
		$obj->{_TITLE} = $title;
	}
	else{
		return $obj->{_TITLE};
	}
}

sub srlink
{
	my ($obj,$srlink) = @_;
	if(defined($srlink)){
		$obj->{_SR_LINK} = $srlink;
	}
	else{
		return $obj->{_SR_LINK};
	}
}

sub reportlink
{
	my ($obj,$reportlink) = @_;
	if(defined($reportlink)){
		$obj->{_REPORT_LINK} = $reportlink;
	}
	else{
		return $obj->{_REPORT_LINK};
	}
}

sub srheader
{
	my ($obj,$srheader) = @_;
	if(defined($srheader)){
		$obj->{_SR_HEADER} = $srheader;
	}
	else{
		return $obj->{_SR_HEADER};
	}
}

sub srlist
{
	my ($obj,$srlist) = @_;
	if(defined($srlist)){
		$obj->{_SR_LIST} = $srlist;
	}
	else{
		return $obj->{_SR_LIST};
	}
}

sub srsummary
{
	my ($obj,$srsummary) = @_;
	if(defined($srsummary)){
		$obj->{_SR_SUMMARY} = $srsummary;
	}
	else{
		return $obj->{_SR_SUMMARY};
	}
}

