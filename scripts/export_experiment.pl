#!/usr/bin/perl -w

use strict;
use Data::Dumper;
use CoGeX;
use File::Basename;
use File::Path;
use File::Spec;
use Getopt::Long;
use URI::Escape::JavaScript qw(unescape);

our ( $eid, $include_metadata, $config, $workdir, $filename, $annotations,
      $P, $db, $host, $port, $user, $pass);

GetOptions(
    "eid=i"             => \$eid,
    "output=s"          => \$filename,
    "directory|dir=s"   => \$workdir,
    "annotations|a=s"   => \$annotations,

    # Database params
    "host|h=s"          => \$host,
    "port|p=s"          => \$port,
    "database|db=s"     => \$db,
    "user|u=s"          => \$user,
    "password|pw=s"     => \$pass,

    # Or use configuration
    "config=s" => \$config
);

$| = 1;

mkpath($workdir, 0, 0755) unless -r $workdir;

my $logfile = File::Spec->catdir($workdir, "$filename.log");
open (my $logh, ">", $logfile) or die "Error opening log file";

if ($config) {
    $P    = CoGe::Accessory::Web::get_defaults($config);
    $db   = $P->{DBNAME};
    $host = $P->{DBHOST};
    $port = $P->{DBPORT};
    $user = $P->{DBUSER};
    $pass = $P->{DBPASS};
}

if (not $eid) {
    say $logh "log: error: experiment not specified use eid";
    exit(-1);
}

if (not $filename) {
    say $logh "log: error: output file not specified use output";
    exit(-1);
}

my $connstr = "dbi:mysql:dbname=$db;host=$host;port=$port;";
my $coge = CoGeX->connect( $connstr, $user, $pass );
#$coge->storage->debugobj(new DBIxProfiler());
#$coge->storage->debug(1);

unless ($coge) {
    say $logh "log: error: couldn't connect to database";
    exit(-1);
}
my $archive = File::Spec->catdir($workdir, $filename);
my $resdir = $P->{RESOURCESDIR};
my $experiment = $coge->resultset('Experiment')->find($eid);

my @file_list = export_annotations();
copy_readme();
my $info = export_info();

my $files = $experiment->storage_path;
my $cmd = "tar -czf $archive --exclude=log.txt --directory $files .";
$cmd .= " --directory $workdir";
$cmd .= " $info " . join " ", @file_list;
$cmd .= " README.txt";

my $result = system($cmd) unless -r $archive;

sub copy_readme {
    my $readme = File::Spec->catdir(($workdir, "README.txt"));
    system("cp $resdir/experiment.README.txt $readme");
}

sub export_info {
    my $info_file = File::Spec->catdir($workdir, "info.csv");

    unless (-r $info_file) {
        my $res = ($experiment->restricted) ? "true" : "false";
        my $types = join ",", $experiment->types;
        my $notebooks = join ",", $experiment->notebooks;

        open(my $fh, ">", $info_file);
        say $fh qq{"Name","} . $experiment->name . '"';
        say $fh qq{"Description","} . $experiment->description . '"';
        say $fh qq{"Genome","} . $experiment->genome->info . '"';
        say $fh qq{"Source","} . $experiment->source->info . '"';
        say $fh qq{"Version","} . $experiment->version . '"';
        say $fh qq{"Types","} . qq{$types"};
        say $fh qq{"Notebooks","} . qq{$notebooks"};
        say $fh qq{"Restricted","} . qq{$res"};
        close($fh);
    }

    return basename($info_file);
}

sub export_annotations {
    my @files = ();
    my $annotation_file = File::Spec->catdir($workdir, "annotations.csv");
    push @files, basename($annotation_file);

    unless (-r $annotation_file) {
        open(my $fh, ">", $annotation_file);

        foreach my $a ( $experiment->annotations ) {
            my $group = (
                defined $a->type->group
                ? $a->type->group->name . ',' . $a->type->name
                : $a->type->name
            );

            my $info = $a->info;
            my $url = defined($a->link) ? $a->link : "";

            # Escape quotes
            $info =~ s/"/\"/g;

            if ($a->image) {
                my $filename = $a->image->filename;
                my $img =  File::Spec->catdir($workdir, $filename);

                eval {
                    open(my $imh, ">", $img) or die "image=$filename could not be generated";
                    print $imh $a->image->image;
                    close($imh);

                    push @files, $filename;
                };

                say $logh "log: error: $@" if ($@);
                say $fh qq{"$group","$info","$url","$filename"};
            } else {
                say $fh qq{"$group","$info","$url"};
            }
        }
        close($fh);
    }

    return @files;
}

