#!/usr/bin/perl -w

use ncs::core::Mailiter;

$mailserver="de01exm68.ds.mot.com";
@mailto=('cwnj74@motorola.com', 'tonyliu2005@gmail.com');
$mailfrom='cwnj74@motorola.com';
$subject="[SM Cosim nightly script]";
$type='text/html';
$filename='SM Cosim Nightly Script 5.0 WMX-AP_R5.0_BLD-1.26.04.htm';
$mailbody=qq{
	<body>
	Here's <i>NCS</i> report:
	<a href='cid:$filename'>$filename</a>
	</body>
	};
$mailiter = ncs::core::Mailiter->new($mailserver,$mailfrom,@mailto);
$mailiter->subject($subject);
$mailiter->mailbody($type, $mailbody);
$mailiter->attach($type,$filename,$filename);
$mailiter->send();
print("mail [$subject] is sent to @mailto");
