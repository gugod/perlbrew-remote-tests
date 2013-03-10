#!/usr/bin/env perl
use v5.14;
package main;
use FindBin '$RealBin';
use lib "$RealBin/lib";
use List::MoreUtils qw(first_value);
use Net::OpenSSH;
use IO::All;

my $ssh_host = $ARGV[0] or die "ssh_host is required.";

say "# ssh $ssh_host";

my $ssh = Net::OpenSSH->new(
    $ssh_host,
    master_opts => [
        -o => "UserKnownHostsFile /dev/null",
        -o => "StrictHostKeyChecking no",
    ]
);

$ssh->error and die $ssh->error;

sub remote_run_script {
    my ($script_file) = @_;
    die "There is no such script file: <$script_file>" unless -f $script_file;

    if ($ssh->scp_put($script_file)) {
        my $local_log = $script_file =~ s![^a-zA-Z0-9]!_!gr;
        my $log_io = io("out/${local_log}.log")->assert;
        my $output = $ssh->capture("bash -xv $script_file 2>&1");
        $log_io->print($output);
    }
    else {
        die "Failed to put $script_file to remote\n";
    }
}

remote_run_script "remote-perlbrew-installation.sh";
remote_run_script "remote-perl-installation.sh";
