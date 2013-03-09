#!/usr/bin/env perl
use v5.14;
package main;
use FindBin '$RealBin';
use lib "$RealBin/lib";
use DigitalOcean;
use List::MoreUtils qw(first_value);

die "Missing digitaloceal keys\n" unless $ENV{DIGITALOCEAN_CLIENT_KEY} && $ENV{DIGITALOCEAN_API_KEY};

my $ocean = DigitalOcean->new(
    client_key => $ENV{DIGITALOCEAN_CLIENT_KEY},
    api_key    => $ENV{DIGITALOCEAN_API_KEY}
);

my $perlbrew_test_droplet = first_value { $_->{name} eq "perlbrew-test" } @{ $ocean->droplets };

if ($perlbrew_test_droplet) {
    say "+++ Destroying the perlbrew-test droplet";
    $ocean->destroy_droplet( droplet_id => $perlbrew_test_droplet->{id} );

}
else {
    say "--- Did not find perlbrew-test droplet";
}
