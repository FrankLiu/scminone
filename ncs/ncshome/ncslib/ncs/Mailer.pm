#!/usr/bin/perl -w

package ncs::Mailer;

use Net::SMTP;

use vars qw(@ISA @EXPORT @EXPORT_OK);
use Exporter;
@ISA = qw(Exporter);
@EXPORT_OK = qw(send send2 smtp smtp2);

sub new
{
    my $self = shift;
    my $this = {};
    my ($mailserver,$from,@tolist) = @_;
    $this->{'mailserver'} = $mailserver; #print("mail server: ".$this->{'mailserver'}."\n");
    $this->{'from'} = $from;  #print("mail from: ".$this->{'from'}."\n");
    #local $rtolist = \@tolist; print("to list: @$rtolist\n");
    $this->{'tolist'} = \@tolist;
    #print("to list: @tolist\n");
    #print("to list: @{$this->{'tolist'}}\n");
    bless $this;
    return $this;
}

#Function for sending mail with an MTA like sendmail
sub send
{
    my ($class, $ishtml, $subject, @body)=@_;
    open(MAIL,'|/usr/lib/sendmail -t') || die "Can't start sendmail.: $!";
    print MAIL<<"END_OF_HEADER";
To: @{$class->{'tolist'}}
From: $class->{'from'}
Subject: $subject
END_OF_HEADER
    print MAIL "Content-Type: text/html\n" if($ishtml);
    print MAIL "\n";
    foreach $line_item (@body){
        print MAIL "$line_item\n";
    }
    print MAIL "\n";
    close(MAIL);
}

sub send2
{
    my ($class, $ishtml, $subject, $textfile)=@_;
    open (BODYFILE, "<$textfile") || die ("Could not open file");
    my @body = <BODYFILE>;
    close(BODYFILE);
    $class->send($ishtml, $subject, @body);
}

sub smtp
{
   my ($class, $ishtml, $subject, @body)=@_;
   my $smtp = Net::SMTP->new($class->{'mailserver'});
   die "Could not open connection: $!" if (! defined $smtp);
    
   $smtp->mail($class->{'from'});
   #local @tolist = @{$class->{'tolist'}}; print("@tolist \n");
   $smtp->to(@{$class->{'tolist'}});
   $smtp->data();
   $smtp->datasend("To: ".join(",", @{$class->{'tolist'}})."\n");
   $smtp->datasend("From: $class->{'from'}\n");
   $smtp->datasend("Subject: $subject\n");
   $smtp->datasend("Content-Type: text/html\n") if($ishtml);
   foreach (@body) {
      $smtp->datasend("$_\n");
   }
   $smtp->datasend("\n");
   $smtp->dataend();
   $smtp->quit;
}

#read content from text file
sub smtp2
{
    my ($class, $ishtml, $subject, $textfile)=@_;
    open (BODYFILE, "<$textfile") || die ("Could not open file");
    my @body = <BODYFILE>;
    close(BODYFILE);
    $class->smtp($ishtml, $subject, @body);
}

1;
__END__

use ncs::Mailer;

$mailserver="de01exm68.ds.mot.com";
@mailto=('cwnj74@motorola.com','cwnj74@motorola.com');
$mailfrom='cwnj74@motorola.com';
$subject="[SM Cosim nightly script]";
@body=("Lower mine, please.", "Thanks!");

$mailer = ncs::Mailer->new($mailserver,$mailfrom,@mailto);
$mailer->send(1, $subject, @body);
$mailer->send2(1, $subject, 'mail.msg');
$mailer->smtp(1, $subject, @body);
$mailer->smtp2(1, $subject, 'mail.msg');

