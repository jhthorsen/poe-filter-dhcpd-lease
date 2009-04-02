package POE::Filter::DHCPd::Lease;

=head1 NAME

POE::Filter::DHCPd::Lease - parses leases from isc dhcpd leases file

=head1 VERSION

0.01

=cut

use strict;
use warnings;
use base qw/POE::Filter/;
use constant BUFFER => 0;
use constant LEASE  => 1;
use constant DONE   => "\a";

our $VERSION = "0.01";
our $START   = qr{^lease\s([\d\.]+)};
our $END     = qr{^\}$};
our %PARSER  = (
    starts      => qr{^\W+starts\s\d+\s(.+)},
    ends        => qr{^\W+ends\s\d+\s(.+)},
    hw_ethernet => qr{^\W+hardware\sethernet\s(.+)},
    remote_id   => qr{^\W+option\sagent.remote-id\s(.+)},
    binding     => qr{^\W+binding\sstate\s(.+)},
    hostname    => qr{^\W+client-hostname\s\"([^"]+)\"},
    circuit_id  => qr{^\W+option\sagent.circuit-id\s(.+)},
);


=head1 METHODS

=head2 new

 my $filter = POE::Filter::DHCPd::Lease->new();

=cut

sub new {
    my $class = shift;
    my $self  = [ q(), undef ]; # [ BUFFER(), LEASE() ]

    return $self;
}

=head2 get_one_start

 $self->get_one_start($stream);

C<$stream> is an array-ref of data, that will eventually be parsed into a
qualified lease, returned by L<get()> or L<get_one>.

=cut

sub get_one_start {
    my $self = shift;
    my $data = shift; # array-ref of data

    $self->[BUFFER] .= join "", @$data;

    if(!defined $self->[LEASE] and $self->[BUFFER] =~ s/$START//) {
        $self->[LEASE] = { ip => $1 };
    }

    if($self->[LEASE]) {
        for my $k (keys %PARSER) {
            $self->[BUFFER] =~ s/$PARSER{$k}// and $self->[LEASE]{$k} = $1;
        }
        if($self->[BUFFER] =~ /$END/) {
            $self->[LEASE]{DONE()} = 1;
        }
    }

    return;
}

=head2 get_one

 $leases = $self->get_one;

C<$leases> is an array-ref, containing zero or one leases.

 starts      => start data of lease
 ends        => the lease expire data
 binding     => either "active" or "free"
 hw_ethernet => ethernet address
 hostname    => the client hostname
 circuit_id  => circuit id from relay agent (option 82)
 remote_id   => remote id from relay agent (option 82)

=cut

sub get_one {
    my $self = shift;

    if($self->[LEASE] and $self->[LEASE]{DONE()}) {
        delete $self->[LEASE]{DONE()};
        return [ delete $self->[LEASE] ];
    }

    return [];
}

=head2 get

See L<POE::Filter>.

=head2 put

Returns an empty string. Should not be used.

=cut

sub put {
    return q();
}

=head2 get_pending

 my $buffer = $self->get_pending;

Returns any data left in the buffer.

=cut

sub get_pending {
    return shift->[BUFFER];
}

=head1 AUTHOR

Jan Henning Thorsen << jhthorsen-at-cpan-org >>

=cut

1;
