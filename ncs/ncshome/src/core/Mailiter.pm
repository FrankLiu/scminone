#!/usr/bin/perl -w

use core::Component;
package core::Mailiter;
@ISA=qw(core::Component);

use MIME::Lite;

sub new
{
	my $pkg = shift;
	my $obj = $pkg->SUPER::new('core::Mailiter',('subject','mailbody','attach','unattach','unattachall','send'));
    my ($mailserver,$from,@tolist) = @_;
    $obj->{'mailserver'} = $mailserver;
    $obj->{'from'} = $from;
    $obj->{'tolist'} = join(',', @tolist);
    bless $obj;
}

sub mailfrom
{
	my ($self, $mailfrom) = @_;
	$self->{'from'} = $mailfrom;
}

sub mailto
{
	my ($self, @tolist) = @_;
	$self->{'tolist'} = join(',', @tolist);
}

sub mailcc
{
	my ($self, @cclist) = @_;
	$self->{'cclist'} = join(',', @cclist);
}

sub subject
{
	my ($self, $subject) = @_;
	$self->{'subject'} = $subject;
}
sub mailbody
{
	my ($self, $type, $mailbody) = @_;
	$self->{'mailbody'} = {'Type' => $type, 'Data' => $mailbody};
}

sub attach
{
	my ($self, $type, $path, $name) = @_;
	$self->{'attachcs'} = () if not $self->{'attachcs'};
	push(@{$self->{'attachcs'}}, 
		{ 'Type' => $type, 'Path' => $path, 'Filename' => $name, 'Disposition' => 'attachment'}
		);
}

sub unattach
{
	my ($self, $type, $path, $name) = @_;
	$self->{'attachcs'} = () if not $self->{'attachcs'};
	my @attached = ();
	my @unattached = ();
	foreach (@{$self->{'attachcs'}}){
		if(($_->{'Type'} eq $type) and ($_->{'Path'} eq $path) and ($_->{'Filename'} eq $name)){
			push(@unattached, $_);
		}
		else{
			push(@attached, $_);
		}
	}
	$self->{'attachcs'} = @attached;
	return @unattached;
}

sub unattachall
{
	my ($self, $type, $path, $name) = @_;
	$self->{'attachcs'} = ();
}

sub send
{
	my ($self)=@_;
	if($self->isdebugon()){
		print("mail server: ".$self->{'mailserver'}."\n");
		print("mail from: ".$self->{'from'}."\n");
		print("to list: ".$self->{'tolist'}."\n");
		print("cc list: ".$self->{'cclist'}."\n");
		print("subject: ".$self->{'subject'}."\n");
	}
	### Add parts (each "attach" has same arguments as "new"):
    my $msg = MIME::Lite->new(
        From    => $self->{'from'},
        To      => $self->{'tolist'},
        Cc      => $self->{'cclist'},
        Subject => $self->{'subject'},
        Type    =>'multipart/mixed'
    );

    ### Add parts (each "attach" has same arguments as "new"):
	$msg->attach(
		Type => $self->{'mailbody'}->{'Type'},
		Data => $self->{'mailbody'}->{'Data'});
    foreach (@{$self->{'attachcs'}}){
		$msg->attach(
			Type => $_->{'Type'},
			Path => $_->{'Path'},
			Filename => $_->{'Filename'},
			Disposition => $_->{'Disposition'}
		);
	}
    ### use Net:SMTP to do the sending
    $msg->send('smtp', $self->{'mailserver'}, Debug=>0);
}

1;