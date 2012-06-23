#!/usr/bin/perl -w

use ncs::Sendmail;

local $mailserver="de01exm68.ds.mot.com";
local @mailto=split(/[\s,;]+/,'cwnj74@motorola.com,cwnj74@motorola.com');
local $mailfrom='cwnj74@motorola.com';
local $subject="[SFM Cosim nightly script]";
local @body=("Lower mine, please.<br/>", "Thanks!");

# use strict;

# my $r_mail = 'cwnj74@motorola.com';
# my $s_mail = 'cwnj74@motorola.com';
# my $subject = 'Test';

# open(MAIL,'|/usr/lib/sendmail -t');
# select(MAIL);

# print<<"END_TAG";
# To: $r_mail
# From: $s_mail
# Subject: $subject
# Content-type:text/html;charset="gb2312"

# <html><body><a href="www.google.cn">ÓÊ¼þÄÚÈÝ</a></body></html>

# END_TAG

#sendmail(1, *mailto, $mailfrom, $subject, @body);
#sendmail2(1, *mailto, $mailfrom, $subject, 'test.html');
sendmail_smtp(1, $mailserver, *mailto, $mailfrom, $subject, @body);
#sendmail_smtp2(1, $mailserver, *mailto, $mailfrom, $subject, 'test.html');
print("mail has been sent to @mailto\n");
