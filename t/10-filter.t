#!perl

use strict;
use warnings;
use POE::Filter::DHCPd::Lease;
use Test::More tests => 8;

my $filter = POE::Filter::DHCPd::Lease->new;
my $ctrl   = 100;
my $buffer;

while($ctrl--) {
    unless(defined read(DATA, $buffer, 16)) {
        die $!;
    }
    unless(length $buffer) {
        last;
    }

    $filter->get_one_start([$buffer]);
    my $lease = $filter->get_one;

    if(@$lease) {
        ok($lease->[0]{'ip'}, "got lease for $lease->[0]{'ip'}");
        is($lease->[0]{'binding'}, 'free', "lease got free binding");
        is(length($lease->[0]{'hw_ethernet'}), 17,
            "lease for hw_ethernet: $lease->[0]{'hw_ethernet'}"
        );
    }
}

ok($ctrl, "control loop ended before being self destroyed");
is($filter->get_pending, q(), "no more data in buffer");

__DATA__

lease 10.19.83.199 {
  starts 0 2008/07/13 19:42:32;
  ends 1 2008/07/14 19:42:32;
  tstp 1 2008/07/14 19:42:32;
  binding state free;
  hardware ethernet 00:11:33:55:66:11;
}

lease 10.19.83.198 {
  starts 5 2008/08/15 21:40:31;
  ends 6 2008/08/16 05:44:51;
  tstp 6 2008/08/16 05:44:51;
  binding state free;
  hardware ethernet aa:ff:33:55:22:11;
}

