use inc::Module::Install;

name     q(POE-Filter-DHCPd-Lease);
all_from q(lib/POE/Filter/DHCPd/Lease.pm);

requires      q(POE::Filter)         => 0;
test_requires q(Test::More)          => 0;

auto_install;
WriteAll;
