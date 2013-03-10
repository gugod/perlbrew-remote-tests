#!/usr/bin/env perl
use v5.14;
package main;
use FindBin '$RealBin';
use lib "$RealBin/lib";
use DigitalOcean;
use List::MoreUtils qw(first_value);
use Net::OpenSSH;
use IO::All;

die "Missing digitaloceal keys\n" unless $ENV{DIGITALOCEAN_CLIENT_KEY} && $ENV{DIGITALOCEAN_API_KEY};

my $ocean = DigitalOcean->new(
    client_key => $ENV{DIGITALOCEAN_CLIENT_KEY},
    api_key    => $ENV{DIGITALOCEAN_API_KEY}
);

my $perlbrew_test_droplet = first_value { $_->{name} eq "perlbrew-test" } @{ $ocean->droplets };

unless ($perlbrew_test_droplet) {
    die "Did not find a perlbrew-test droplet.\n"
}

my $ssh_host = $perlbrew_test_droplet->{ip_address};
say "# ssh root\@$ssh_host";

my $ssh = Net::OpenSSH->new(
    $ssh_host,
    user => "root",
    master_opts => [
        -o => "UserKnownHostsFile /dev/null",
        -o => "StrictHostKeyChecking no",
    ]
);

$ssh->error and die $ssh->error;

# centos specific
if ($ssh->capture("which cc") !~ m!/cc\n!s) {
    say "+++ Installing cc";
    $ssh->system("yum install -y gcc");
}
if ($ssh->capture("which make") !~ m!/make\n!s) {
    say "+++ Installing make";
    $ssh->system("yum install -y make")
}
if ($ssh->capture("which perl") !~ m!/perl\n!s) {
    say "+++ Installing vendor perl";
    $ssh->system("yum install -y perl")
}

## perlbrew bootstraping
if ($ssh->scp_put("remote-perlbrew-installation.sh")) {
    my $output = $ssh->capture("bash -xv remote-perlbrew-installation.sh 2>&1");
    io("out/remote-perlbrew-installation.log")->assert->print($output);
}
else {
    die "Failed to put perlbrew-installation.sh to the remote";
}

## perl installation
if ($ssh->scp_put("remote-perl-installation.sh")) {
    my $output = $ssh->capture("bash -xv remote-perl-installation.sh 2>&1");
    io("out/remote-perl-installation.log")->assert->print($output);
}
else {
    die "Failed to put perlbrew-installation.sh to the remote";
}
