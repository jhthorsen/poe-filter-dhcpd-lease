#!perl

use strict;
use warnings;
use POE::Filter::DHCPd::Lease;
use Test::More tests => 18;

my $filter  = POE::Filter::DHCPd::Lease->new;
my $datapos = 1 + tell DATA;
my $buffer;

for my $bufsize (16, 2048) {
    my $ctrl = 100;

    seek DATA, $datapos, 0;

    ok($bufsize, "> reading with bufsize $bufsize");

    while($ctrl--) {
        unless(defined read(DATA, $buffer, $bufsize)) {
            skip("read failed: $!", 3);
        }
        unless(length $buffer) {
            last;
        }

        $filter->get_one_start([$buffer]);

        while(1) {
            my $leases = $filter->get_one;

            last unless(@$leases);

            for my $lease (@$leases) {
                ok($lease->{'ip'}, "got lease for $lease->{'ip'}");
                is($lease->{'binding'}, 'free', "lease got free binding");
                is(length($lease->{'hw_ethernet'}), 17,
                    "lease for hw_ethernet: $lease->{'hw_ethernet'}"
                );
            }
        }
    }

    ok($ctrl, "control loop ended before being self destroyed");
    is($filter->get_pending, q(), "no more data in buffer");
}

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

