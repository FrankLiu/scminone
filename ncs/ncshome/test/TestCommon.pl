#/usr/lib/perl -w

use ncs::Common;

# my @mail_contents = read_range_as_array('mail.msg',13,-8);
# save_array_to_file('mail.tmp1.msg', @mail_contents);
# my @mail_contents2 = read_as_array('mail.msg');
# my $mail_len = @mail_contents2;
# save_array_to_file('mail.tmp2.msg', @mail_contents2[13..($mail_len-8)]);
# my $diff = qx{diff 'mail.tmp1.msg' 'mail.tmp2.msg'};
# if(!$diff){
	# print "test for read_range_as_array finished successfully!\n";
# }

# my @mail_content3 = copy_to_array('mail.msg', 'host: ', '<p>');
# save_array_to_file('mail.tmp3.msg', @mail_content3);
# $diff = qx{diff 'mail.tmp1.msg' 'mail.tmp3.msg'};
# if(!$diff){
	# print "test for copy_to_array finished successfully!\n";
# }

# system("rm -f mail.tmp*.msg");

my $basename = &bname('./mail.msg');
my $dirname = &dname('./mail.msg');
print "basename: $basename, dirname: $dirname\n";

my $pass = &search_num_in_file('mail.msg', 'passed');
my $failed = &search_num_in_file('mail.msg', 'failed');
my $error = &search_num_in_file('mail.msg', 'error');
print "passed=$pass,failed=$failed,error=$error\n";

my $contains_license_issue = &contains_in_file('compile_model.log', 'TAU-G2-UML-BASE|TAU-G2-TTCN3-BASE');
if($contains_license_issue){print "compile_model.log contains license issue: TAU-G2-UML-BASE|TAU-G2-TTCN3-BASE\n";}

my $contains_mergestat = &contains_in_file("mail.msg", "<div id='mergestat'>");
if($contains_mergestat){print "mail.msg contains mergestat\n";}

my $contains_footer = &contains_in_file("mail.msg", "<div id='footer'>");
if($contains_footer){print "mail.msg contains footer\n";}

my $lpl = 'WMX-AP_R5.0_BLD-1.26.01';
&add_status_to_prj("projects.txt", "$lpl", "FINISHED");
&replace_status_to_prj("projects.txt", "$lpl", "FINISHED", "BLOCK");
my $lpl_status = &get_status_of_prj("projects.txt", $lpl); print("$lpl status: $lpl_status\n");
print("$lpl contains in file: ".&contains_in_file("projects.txt", "$lpl")."\n");
&remove_status_to_prj("projects.txt", "$lpl", "BLOCK");
$lpl_status = &get_status_of_prj("projects.txt", $lpl); print("$lpl status: $lpl_status\n");

my ($spent_hr,$spent_mm,$spent_sec) = &count_time(1279981827, 1279982178);
print "spent $spent_hr hours, $spent_mm minutes, $spent_sec seconds\n";
($spent_hr,$spent_mm,$spent_sec) = &count_time(1279981827, 1279992178);
print "spent $spent_hr hours, $spent_mm minutes, $spent_sec seconds\n";

my $template = '/opt/apps/MT/bin/pduconvert +XIDNUMBER +UMB-OPTIONALS +DEBUG /vob/wibb_bts/bts_doc/ICD/bts_icd/isl/components/SM/pkg_SM_msgs.pdu INTERFACE=ttcn3 ENCODING=iDEN MSGDIRECTION=inverted TAU-VERSION=G2-2.7 >/tmp/ncslog/sm/$latest_project_label/buildlog/compile_isl.log 2>&1';
my $parse_params = {
	'latest_project_label' => 'WMX-AP_R5.0_BLD-1.20.01'
};
my $parse_result = &parse_template($template, $parse_params);
print "parsed result: \n $parse_result\n";

my $sr_mappings = &parse_mapping('sm50_sr_mappings.txt');
print "8911: ".$sr_mappings->{'8911'}."\n";
print "8915: ".$sr_mappings->{'8915'}."\n";
my $r_sr_mappings = &reverse_sr_mappings($sr_mappings);
$sr = $sr_mappings->{'8915'};
$tc_count = scalar(@{$r_sr_mappings->{$sr}});
print "$sr: $tc_count testcases related with this SR\n";
print "$sr: @{$r_sr_mappings->{$sr}} \n";
#print "reversed sr mappings: \n";
# while(($key,$vals) = each(%$r_sr_mappings)){
	# print "$key: @$vals\n"; 
# }

my $ip = &ip();
print "ip address: $ip\n";

&cleanup_dir_or_file("build");

my $str = "5215";
my $lstrip_str = &lstrip($str, 6, '&nbsp;');
print "lstriped string: $lstrip_str\n";

my $rstrip_str = &rstrip($str, 6, '.');
print "rstriped string: $rstrip_str\n";

my $modtime = &file_modtime('../ncslib');
print "file mod time: $modtime\n";
my $fmodtime = &format_time("%Y-%m-%d %H:%M:%S",localtime($modtime));
print "file formatted mod time: $fmodtime\n";

my ($prate,$frate) = &parse_testrate(201,7,0);
print "passrate: $prate, failrate: $frate\n";

my $isTrue = &isTrue('no');
print "isTrue: $isTrue\n";

my $is_blank = &is_blank('  ');
print "is blank: $is_blank\n";

my @suite = (2..51,73,74,75,83..106,112..114,10001..10007,10053,10054,10055,10063,10100,10101,10301,10302,10303,10304,10305,10306,10350,10351,10352,10353,10354,10401,10402,10403,10404,10405,10406,10407,10408,10409,10410,10411,10412,10413);
my $is_included = &included_in(2100, @suite);
print "2100 is included: $is_included\n";
$is_included = &included_in(10055, @suite);
print "10055 is included: $is_included\n";
