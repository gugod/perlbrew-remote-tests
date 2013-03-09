#!/usr/bin/env perl
use v5.14;

package DigitalOcean;
use Moo;
use Mojo::JSON;
use Mojo::UserAgent;
use URI::Query;

use List::MoreUtils qw(first_value);

has client_key => (
    is => "ro",
    required => 1
);

has api_key => (
    is => "ro",
    required => 1
);

has url_base => (
    is => "ro",
    default => sub {
        'https://api.digitalocean.com'
    }
);

sub send_request {
    state $ua =  Mojo::UserAgent->new;

    my ($self, $path, @params) = @_;

    my $query_string = URI::Query->new(
        client_id => $self->client_key,
        api_key   => $self->api_key,
        @params
    )->stringify;

    my $url = $self->url_base . "/" . $path . "/?$query_string";
    my $tx = $ua->get($url);

    unless ($tx->success) {
        die "API Request Failed: $url\n\t" . join("\n\t", $tx->error);
    }

    my $rx = $tx->res->json();

    die "API $path returned status is not OK:\n\t" . $tx->res->content
        unless $rx->{status} eq "OK";

    return $rx;
}

sub regions {
    my $self = shift;
    my $response = $self->send_request("regions");
    my $regions = $response->{regions};
    die "Did not get regions in the response body\n" unless @$regions;
    return $regions;
}

sub sizes {
    my $self = shift;
    my $response = $self->send_request("sizes");
    my $sizes = $response->{sizes};
    die "Did not get sizes in the response body\n" unless @$sizes;
    return $sizes;
}

sub images {
    my $self = shift;
    my $response = $self->send_request("images");
    my $images = $response->{images};
    die "Did not find images in the response body\n" unless @$images;
    return $images;
}

sub ssh_keys {
    my $self = shift;
    my $response = $self->send_request("ssh_keys");
    my $keys = $response->{ssh_keys};
    die "Did not get ssh_keys in the response body\n" unless @$keys;
    return $keys;
}

sub region_id_amsterdam {
    my $self = shift;
    my $region_amsterdam = first_value { $_->{name} =~ m!Amsterdam! } @{ $self->regions };
    die "Cannot find a region for Amsterdam" unless $region_amsterdam;
    return $region_amsterdam->{id};
}

sub size_id_512mb {
    my $self = shift;
    my $size_512mb = first_value { $_->{name} eq "512MB" } @{ $self->sizes };
    die "Cannot find a size for 512MB" unless $size_512mb;
    return $size_512mb->{id};
}

sub droplets {
    my $self = shift;
    my $response = $self->send_request("droplets");
    die "Did not get droplets in the response body\n" unless exists $response->{droplets};

    return $response->{droplets};
}

sub new_droplet {
    my $self = shift;
    my %args = @_;

    die unless $args{name} && $args{size_id} && $args{region_id} && $args{image_id};

    my $response = $self->send_request(
        "droplets/new",
        %args
    );

    my $droplet = $response->{droplet};
    die "new_droplet did not return a droplet\n" unless $droplet;
    return $droplet;
}

sub destroy_droplet {
    my $self = shift;
    my %args = @_;
    die unless $args{droplet_id};
    my $response = $self->send_request("droplets/$args{droplet_id}/destroy");
    return $response;
}

package main;
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

    $ocean->destroy_droplet( droplet_id => $perlbrew_test_droplet->{id} );

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
