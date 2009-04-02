#!perl

use strict;
use warnings;
use POE::Filter::DHCPd::Lease;
use POE;
use Test::More tests => 1;

my $filter = POE::Filter::DHCPd::Lease->new;

ok($filter, "filter created");
