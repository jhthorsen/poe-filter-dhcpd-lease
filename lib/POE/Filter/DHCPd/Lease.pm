package POE::Filter::DHCPd::Lease;

=head1 NAME

POE::Filter::DHCPd::Lease - parses leases from isc dhcpd leases file

=head1 VERSION

0.0502

=cut

use strict;
use warnings;
use base qw/POE::Filter/;
use Time::Local;
use constant BUFFER => 0;
use constant LEASE  => 1;
use constant DONE   => "\a";

our $VERSION = '0.0502';
our $DATE    = qr# (\d{4})/(\d\d)/(\d\d) \s (\d\d):(\d\d):(\d\d) #mx;
our $START   = qr#^ lease \s ([\d\.]+) \s \{ #mx;
our $END     = qr# } [\n\r]+ #mx;
our %PARSER  = (
    starts      => qr/ starts  \s\d+\s (.+) /mx,
    ends        => qr/ ends    \s\d+\s (.+) /mx,
    binding     => qr/ binding \s state \s (.+) /mx,
    hw_ethernet => qr/ hardware \s ethernet \s (.+) /mx,
    remote_id   => qr/ option \s agent.remote-id  \s (.+) /mx,
    circuit_id  => qr/ option \s agent.circuit-id \s (.+) /mx,
    hostname    => qr/ client-hostname \s "([^"]+)" /mx,
);

=head1 METHODS

=head2 new

 my $filter = POE::Filter::DHCPd::Lease->new;

=cut

sub new {
    my $class = shift;
    return bless [ q(), undef ], $class;
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

    return;
}

=head2 get_one

 $leases = $self->get_one;

C<$leases> is an array-ref, containing zero or one leases.

 starts      => epoch value
 ends        => epoch value
 binding     => "active" or "free"
 hw_ethernet => 12 chars, without ":"
 hostname    => the client hostname
 circuit_id  => circuit id from relay agent (option 82)
 remote_id   => remote id from relay agent (option 82)

=cut

sub get_one {
    my $self = shift;

    if(!$self->[LEASE]) {
        if($self->[BUFFER] =~ s/$START//) {
            $self->[LEASE] = { ip => $1 };
        }
    }

    if($self->[LEASE]) {
        for my $k (keys %PARSER) {
            if($self->[BUFFER] =~ s/\s*$PARSER{$k};[\n\r]*//) {
                $self->[LEASE]{$k} = $1;
            }
        }
        if($self->[BUFFER] =~ s/.*?$END//s) {
            $self->[LEASE]{DONE()} = 1;
        }
    }

    if($self->[LEASE] and $self->[LEASE]{DONE()}) {
        delete $self->[LEASE]{DONE()};
        my $lease = delete $self->[LEASE];

        for my $k (qw/starts ends/) {
            next unless($lease->{$k});
            if(my @values = $lease->{$k} =~ $DATE) {
                $values[1]--; # decrease month
                $lease->{$k} = timelocal(reverse @values);
            }
        }

        if(my $mac =  _mac($lease->{'hw_ethernet'})) {
            $lease->{'hw_ethernet'} = $mac;
        }

        return [ $lease ];
    }

    return [];
}

sub _mac {
    my $str = shift or return;

    $str =  join "", map { sprintf "%02s", $_ } split /:/, $str;
    $str =~ tr/[0-9a-fA-F]//cd;

    return length $str == 12 ? lc($str) : undef;
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

Jan Henning Thorsen, C<< <jhthorsen-at-cpan-org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2007 Jan Henning Thorsen, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
