#!/usr/bin/perl -w

use ncs::Mailer;

$mailserver="de01exm68.ds.mot.com";
@mailto=('cwnj74@motorola.com');
$mailfrom='cwnj74@motorola.com';
$subject="[SM Cosim nightly script]";
@body=("Lower mine, please.", "Thanks!");

$mailer = ncs::Mailer->new($mailserver,$mailfrom,@mailto);
#$mailer->send(1, $subject, @body);
#$mailer->send2(1, $subject, 'mail.msg');
#$mailer->smtp(1, $subject, @body);
#$mailer->smtp2(1, $subject, 'mail.msg');
$mailer->mimelite($subject);
