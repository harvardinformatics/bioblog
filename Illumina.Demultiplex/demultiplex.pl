#!/usr/local/bin/perl -w
#
#Author:
# Chris Williams
# Harvard Informatics And Scientific Applications
# http://informatics.fas.harvard.edu

# Demultiplex an Illumina fastq file 

use warnings FATAL => "all";
use strict;
use POSIX;
use Getopt::Long;
use Data::Dumper;
use List::MoreUtils qw(uniq);
use constant { true => 1, false => 0 };

my $fastq_file = "";
my $barcodes_file = "";
my $outdir = ".";
my $max_mismatches = 0;
my $filter_n = 0;
my $crop_n = 0;
my $help = 0;

Getopt::Long::GetOptions(
  'fastq=s'      => \$fastq_file,
  'barcodes=s'   => \$barcodes_file,
  'mismatches:i' => \$max_mismatches,
  'filter-n'     => \$filter_n,
  'crop-n'       => \$crop_n,
  'out:s'        => \$outdir,
  'help'         => \$help,
  'h'            => \$help,
  ) or die "Incorrect input! Use -h for usage.\n";

if ($help) {
  print "\nUsage: perl demultiplex.pl -fastq <fastq_file> -barcodes <barcodes_file> [Options]\n";
  print "Options:\n";
  print "  -fastq      The fastq file to be demultiplexed\n";
  print "  -barcodes   A tab-deliminted, two-column file of sample names and barcodes\n";
  print "  -mismatches Maximum number of mismatches to allow\n";
  print "  -out        Output directory";
  print "  -help|-h    Display usage information.\n";
  exit 0;
}

#Read in barcodes and sample names
open(BC, "<$barcodes_file") or die "Can't open file $barcodes_file\n";
my %bh = ();
my $ilength = -1;
while( my $line = <BC> ) {
  chomp($line);
  my ($sample, $barcode) = split("\t",$line);
  $barcode =~ s/[- ]//g;
  $bh{$barcode}{"sample"} = $sample;
  if ($ilength == -1) {
    $ilength = length($barcode);
  } elsif ( $ilength != length($barcode) ) {
    die "Error: Barcodes must have the same length"
  }
}
close(BC);

#Open an output file for each barcode, save handle
foreach my $barcode (keys %bh) {
  open( my $fh, ">", $outdir . "/" . $bh{$barcode}{"sample"} . "_" . $barcode . ".fastq") or die "Error: Coudln't open file for writing: $!";
  $bh{$barcode}{"filehandle"} = $fh;
}

open(FA, "<$fastq_file") or die "Can't open file $fastq_file\n";
my $i = 0;
my ($name, $read, $plus, $qual) = 0;
while( my $line = <FA> ) {
  $i++;
  chomp($line);
  if ($i % 4 == 1) {
    $name = $line;
  } elsif ($i % 4 == 2) {
    $read = $line;
  } elsif ($i % 4 == 3) {
    $plus = $line;
  } elsif ($i % 4 == 0) {
    $qual = $line;
    
    #file-read error checking
    if ($name eq "" || $read eq "" || $plus eq "" || $qual eq "" || $plus !~ m/^\+\s*$/) {
      die ("Error reading $fastq_file, line ~$i: Missing or extra line?\nName: $name\nRead: $read\n$plus\nQuality: $qual\n");
    } elsif (length($read) != length($qual)) {
      die ("Error reading $fastq_file, line $i: Unequal quality and read lengths:\nName: $name\nRead: $read\nQuality: $qual\n");
    }

    my $index_read = substr($name,-$ilength);
    my $num_hits = 0;
    my $barcode_hit = "";
    foreach my $barcode (keys %bh) { #see if index_read matches one or more barcodes
      if ( hd($barcode,$index_read) <= $max_mismatches ) {
	$barcode_hit = $barcode;
	$num_hits++;
      }
    }
    
    if ( $num_hits != 1 ) { #skip read if it did not map to exactly one barcode
      next;
    }

    if ($filter_n and $read =~ m/[nN]/) { #skip read if filter-n option was specified, and read contains an uncalled base
      next;
    }

    if ($crop_n) {  #if crop-n option was specified, crop read at first uncalled base
      $read =~ s/[nN].*$//;
    } 

    my $fh = $bh{$barcode_hit}{"filehandle"};
    print $fh "$name\n$read\n$plus\n$qual\n";
    
    $name = "";
    $read = "";
    $plus = "";
    $qual = "";
  }
}

close(FA);

#Close output files
foreach my $barcode (keys %bh) {
  my $fh = $bh{$barcode}{"filehandle"};
  close($fh);
}

exit 0;

sub hd { #calculate hamming distance
  my ($k,$l) = @_;
  my $len = length($k);
  my $num_mismatch = 0;

  for (my $i=0; $i<$len; $i++) {
    ++$num_mismatch if substr($k, $i, 1) ne substr($l, $i, 1);
  }
  return $num_mismatch;
}

