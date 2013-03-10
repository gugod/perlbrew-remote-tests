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
    say "+++ perlbrew-test already activated";
    say Mojo::JSON->encode( $perlbrew_test_droplet );
}
else {
    say "+++ Create perlbrew-test droplet";

    my $image_centos63 = first_value { $_->{name} eq "CentOS 6.3 x64" } @{ $ocean->images };

    $perlbrew_test_droplet = $ocean->new_droplet(
        name => "perlbrew-test",
        size_id => $ocean->size_id_512mb,
        region_id => $ocean->region_id_amsterdam,
        image_id  => $image_centos63->{id},
        ssh_key_ids => (join "," => map { $_->{id} } @{$ocean->ssh_keys})
    );

    say "+++ created";
    say Mojo::JSON->encode($perlbrew_test_droplet);
}
