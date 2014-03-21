#!/usr/bin/env perl
use v5.14;
use strict;
use warnings;
use Data::Dumper qw(Dumper);

use File::Basename qw(fileparse basename);
use File::Path qw(mkpath);
use File::Spec qw(catdir);
use Getopt::Long qw(GetOptions);
use JSON qw(decode_json);
use URI::Escape::JavaScript qw(unescape);

use CoGe::Accessory::Notebook qw( create_notebook );
use CoGeX;

our ($LOG, $DEBUG, $PAGE, $P, $db, $host, $port, $user, $pass, $config,
     $name, $description, $version, $type, $userid, $restricted, @ITEMS);

GetOptions(
    "userid|uid=s"      => \$userid, # User creating the notebook

    # General configuration options
    "log=s"             => \$LOG,
    "config|cfg=s"      => \$config,

    # Notebook options
    "page=s"            => \$PAGE, # The reference page
    "name|n=s"          => \$name,
    "type|t=s"          => \$type,
    "description|d=s"   => \$description,
    "restricted|r=s"    => \$restricted,
);

$| = 1;

die "ERROR: user id not specified use userid" unless $userid;
die "ERROR: no items found" unless @ARGV;
die "ERROR: notebook name not specified" unless $name;

sub setup {
    $P    = CoGe::Accessory::Web::get_defaults($config);
    $db   = $P->{DBNAME};
    $host = $P->{DBHOST};
    $port = $P->{DBPORT};
    $user = $P->{DBUSER};
    $pass = $P->{DBPASS};

    # Items being added to the notebook
    @ITEMS = @ARGV;

    my $connstr = "dbi:mysql:dbname=$db;host=$host;port=$port;";
    return CoGeX->connect( $connstr, $user, $pass );
}

sub parse_files {
    my @logs = @_;
    my @ids;
    my $node_types = CoGeX::node_types();

    for my $log (@logs) {
        open( my $fh, $log );

        while (<$fh>) {
            if ( $_ =~ /experiment id: (\d+)/i ) {
                #XXX: Hard code to experiment
                push @ids, [$1, $node_types->{experiment}];
            }
            elsif ( $_ =~ /log: error/i ) {
                return;
            }
        }

        close($fh);
    }

    return @ids;
}

sub main {
    my $coge = setup();
    die "ERROR: couldn't connect to the database" unless $coge;

    my $user = $coge->resultset("User")->find($userid);
    die "ERROR: user could not be found for id: $userid" unless $user;

    my @ids = parse_files(@ITEMS);

    my $notebook = create_notebook(
        db         => $coge,
        user       => $user,
        name       => $name,
        desc       => $description,
        type_id    => $type,
        item_list  => \@ids,
        restricted => $restricted);

    exit(-1) unless $notebook;

    open(my $fh, ">>", $LOG);
    say $fh "notebook id: " . $notebook->id;
    close($fh);
}

main;