#!/usr/bin/perl -w

use strict;
use Data::Dumper;
use CoGeX;
use Getopt::Long;

my $connstr = 'dbi:mysql:dbname=genomes;host=biocon;port=3306';
my $coge = CoGeX->connect($connstr, 'cnssys', 'CnS' );

my ($org, $mask);

GetOptions ("m|mask" =>  \$mask,
            "o|org=s" => \$org,
	    );

($org) = $coge->resultset('Organism')->resolve($org);

my ($genomic_sequence_type) = $mask ? $coge->resultset('GenomicSequenceType')->resolve('masked') : $coge->resultset('GenomicSequenceType')->resolve('unmasked');

my @ds = $org->current_datasets(genomic_sequence_type=>$genomic_sequence_type);

foreach my $ds (sort @ds)
  {
    print STDERR "Working on: ".$ds->name,": ",$ds->description,"(version: ",$ds->version,")\n";
    foreach my $chr (sort $ds->get_chromosomes())
      {
	print STDERR "\tWorking on chromosome $chr\n";
	print $ds->fasta(chr=>$chr);
      }
  }
