#!/usr/bin/env perl
use 5.010;
use strict;
use warnings;
use LWP::Simple;
use File::Slurp 'slurp';
use File::Path 'make_path', 'remove_tree';
#
# WARNING: Ugly Perl
#

#my $basedir  = '/usr/local/portage';
my $basedir  = 'ports';
my $listfile = 'gmpup.lst';

sub sync {
    my ($name, $baseurl, $to) = @_;
    my $stuff = get $baseurl;
    unless ($stuff) {
        warn "Unable to get $baseurl";
        return;
    }
    my $where = "$to/$name";
    #say "REMOVING $where";
    remove_tree $where;
    for ($stuff =~ /href="([^"]+)"/g) {
        # skip these funky urls zugaina.org generates
        next if /^\?/;
        # skip links to upper directories.
        # Could have been written better, ETOOLAZY. Or FIXME
        next if m[^/];
        make_path $where;
        if (m[files/]) {
            make_path "$where/files";
            sync("$name/files", "$baseurl/files", $to);
            next;
        }
        say "$where/$_";
        getstore "$baseurl/$_", "$where/$_";
    }
}

my @lines = slurp $listfile;
for my $baseurl (@lines) {
    chomp $baseurl;
    my ($name) = $baseurl =~ m[([^/]+/[^/]+/?)$];
    unless ($name && $name ne "") {
        warn "Failed getting the package name from $baseurl";
        next;
    }
    sync $name, $baseurl, $basedir;
}
