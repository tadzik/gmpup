#!/usr/bin/env perl
use 5.010;
use strict;
use warnings;
use LWP::Simple;
use File::Path 'make_path', 'remove_tree';
use File::Basename;
use Getopt::Long;

my $destdir = 'ports';
my $list    = 'gmpup.lst';

sub porturl {
    my ($overlay, $port) = @_;
    return 'http://gentoo-overlays.zugaina.org/'
           . $overlay . '/portage/' . $port . '/';
}

sub filelist {
    my $url  = shift;
    my @files;
    my $html = get $url;
    unless (defined $html) {
        warn "Unable to fetch $url";
        return;
    }
    for my $href ($html =~ /href="([^"]+)"/g) {
        # skip links to upper directories
        # and the zugaina.org specific urls
        if (index($url, $href) != -1 or $href =~ /^\?/) {
            #say "Skipping $href";
            next;
        }
        # probably a directory
        if ($href =~ m[/$]) {
            push @files, map { "$href$_" } filelist("$url/$href");
        } else {
            push @files, $href;
        }
    }
    return @files;
}

sub MAIN {
    GetOptions(
        "list=s"    => \$list,
        "destdir=s" => \$destdir,
    );
    open(my $fh, '<', $list) or die $!;
    while (<$fh>) {
        my ($overlay, $port) = split /\s+/, $_;
        next unless $port ne "";
        my $baseurl = porturl($overlay, $port);
        my @targets = filelist($baseurl);
        my $where = "$destdir/$port";
        remove_tree $where;
        for (@targets) {
            make_path dirname "$where/$_";
            getstore "$baseurl/$_", "$where/$_";
            say "$where/$_";
        }
    }
    close $fh;
}

MAIN();
