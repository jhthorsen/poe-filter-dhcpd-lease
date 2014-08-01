#!perl

use strict;
use warnings;
use lib './lib';
use POE::Filter::DHCPd::Lease;
use Time::Local;
use Test::More;

my $filter  = POE::Filter::DHCPd::Lease->new;
my $buffer;

while(read(DATA, $buffer, 2048)) {

    $filter->get_one_start([$buffer]);

    while(1) {
        my $leases = $filter->get_one;

        last unless(@$leases);

        for my $lease (@$leases) {
            is($lease->{'binding'}, 'active', 'binding state active?');
            is($lease->{'next'}, 'free', 'next binding state free');
        }
    }
}

done_testing();

__DATA__

lease 10.19.83.199 {
  starts 0 2008/07/13 19:42:32;
  ends 1 2008/07/14 19:42:32;
  tstp 1 2008/07/14 19:42:32;
  binding state active;
  next binding state free;
#  binding state free;
  hardware ethernet 00:11:33:55:66:11;
}


