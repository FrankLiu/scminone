#!/usr/bin/perl -w

package ncs::core::Component;

our $VERSION = 1.01;

sub new
{
	my ($pkg, $name, @actions) = @_;
	bless{
		_name => $name,
		_actions => \@actions,
		_debug => 0
	}, $pkg;
}

sub name
{
	my ($pkg, $name) = @_;
	if(defined($name)){
		$pkg->{_name} = $name;
	}
	else{
		return $pkg->{_name};
	}
}

sub actions
{
	my ($pkg, @actions) = @_;
	if(@actions){
		$pkg->{_actions} = \@actions;
	}
	else{
		return @{$pkg->{_actions}};
	}
}

sub add_actions
{
	my ($pkg, @actions) = @_;
	push(@{$pkg->{_actions}}, @actions);
}

sub add_action
{
	my ($pkg, $action) = @_;
	push(@{$pkg->{_actions}}, $action);
}

sub invoke_action
{
	my ($pkg, $action, @params) = @_;
	print("$pkg->$action('@params');");
	eval("$pkg->$action('@params');");
	if($@){
		warn("invoke action '$action' failure!");
	}
}

sub debug
{
    my $pkg = shift;
    my $msg  = join('', @_);
    my ($self, $file, $line) = caller();

    unless ($msg =~ /\n$/) {
        $msg .= (&isdebugon())
            ? " at $file line $line\n"
            : "\n";
    }

    print STDERR "[$self] $msg";
}

sub debugon
{
	my $pkg = shift;
	$pkg->{_debug} = 1;
}
sub debugoff
{
	my $pkg = shift;
	$pkg->{_debug} = 0;
}
sub isdebugon
{
	my ($pkg) = @_;
	if($pkg->{_debug}){
		return 1;
	}
	return 0;
}

#------------------------------------------------------------------------
# module_version()
#
# Returns the current version number.
#------------------------------------------------------------------------

sub module_version {
    my $pkg = shift;
    my $class = ref $pkg || $pkg;
    no strict 'refs';
    return ${"${class}::VERSION"};
}

1;
__END__
