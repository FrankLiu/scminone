#!/usr/bin/perl -w 

my $latest_project_label='WMX-AP_R5.0_BLD-1.20.01';
my $compile_process="/opt/apps/MT/bin/pduconvert +XIDNUMBER +UMB-OPTIONALS +DEBUG /vob/wibb_bts/bts_doc/ICD/bts_icd/isl/components/SM/pkg_SM_msgs.pdu INTERFACE=ttcn3 ENCODING=iDEN MSGDIRECTION=inverted TAU-VERSION=G2-2.7 >/tmp/ncslog/sm/$latest_project_label/buildlog/compile_isl.log 2>&1";
my $a = eval('$compile_process');
print "process: $a \n";
print "system('$a')\n";
system('/opt/apps/MT/bin/pduconvert +XIDNUMBER +UMB-OPTIONALS +DEBUG /vob/wibb_bts/bts_doc/ICD/bts_icd/isl/components/SM/pkg_SM_msgs.pdu INTERFACE=ttcn3 ENCODING=iDEN MSGDIRECTION=inverted TAU-VERSION=G2-2.7 >/tmp/ncslog/sm/WMX-AP_R5.0_BLD-1.20.01/buildlog/compile_isl.log 2>&1');

