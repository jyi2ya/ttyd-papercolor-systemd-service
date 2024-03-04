#!/usr/bin/env perl
use 5.020;
use utf8;
use warnings;
use autodie;
use feature qw/signatures postderef/;
no warnings qw/experimental::postderef/;
use open qw(:std :utf8);

use JSON qw/to_json from_json/;

sub slurp ($path) {
    local $/ = undef;
    open my $f, '<', $path;
    scalar <$f>
}

my $theme = from_json slurp './00-papercolor-windows-terminal.json';
my @dropped_keys = qw/name/;

my %renamed_keys = (
    brightPurple => 'brightMagenta',
    purple => 'magenta',
    cursorColor => 'cursor',
);

my %mapped_keys = (
    cursor => 'cursorAccent',
    background => 'selectionForeground',
    selectionBackground => 'selectionInactiveBackground',
);

while (my ($wt_key, $xt_key) = each %renamed_keys) {
    $theme->{$xt_key} = $theme->{$wt_key};
    delete $theme->{$wt_key};
}

delete $theme->{$_} for @dropped_keys;

while (my ($key_from, $key_to) = each %mapped_keys) {
    $theme->{$key_to} = $theme->{$key_from};
}

my $theme_json = to_json $theme;

my @params;

open STDIN, '<', '03-ttyd-options.txt';
push @params, grep { !/^\s*$/ } map { s/#.*//s; s/(^\s*)|(\s*$)//gs; $_ } <>;

open STDIN, '<', './01-options.conf';
push @params,
map { "-t '$_'" }
"theme=$theme_json", grep { !/^\s*$/ } map { s/#.*//s;s/(^\s*)|(\s*$)//gs; $_ } <>;

my $binpath = '/usr/local/bin/ttyd';
my $cmdline = join ' ', $binpath, @params, '/bin/login';

my $service = slurp '02-service-template.service';
$service =~ s/\Q{{cmdline}}\E/$cmdline/gs;

print $service;
