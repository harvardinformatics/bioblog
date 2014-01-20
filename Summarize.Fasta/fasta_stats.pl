#!/usr/bin/perl -w
use POSIX;
use Getopt::Long;
use strict;

# Defaults
my $ifile    = "";
my $bin_size = 200;
my $oname    = "stats";
my $help     = 0;

GetOptions(
  'i=s'   => \$ifile,
  'b:i'   => \$bin_size,
  'o:s'   => \$oname,
  'help!' => \$help,
) or $help = 1;

if ( $help || $ifile eq "" || $oname eq "" ) {
  print "Usage: ./fasta_stats.pl -i <fasta_file> -b <bin_size> -o <output_name>\n";
  print "       fasta_file    Fasta file for which statistics are calculated.\n";
  print "       bin_size      Default histrogram bin size is 200 (bp)\n";
  print "       output_name   String used to name output files. Default string is \"stats\" \n\n";
  exit(1);
}

my $seq = "";
my @lengths = ();
my $total_length = 0;
my %counts = ();
my $GCcount = 0;
my $Ncount = 0;
open(IN, "<$ifile") or die "Can't open file $ifile\n";
while (my $line = <IN>) {
  if ($line =~ m/^>/) {
    if ($seq ne "") {
      my $l = length($seq);
      push(@lengths, $l);
      $total_length += $l;
      $GCcount += ()= ($seq =~ m/[gc]/gi);
      $Ncount += ()= ($seq =~ m/n/gi);
      my $bin_num = floor($l/$bin_size);
      exists($counts{$bin_num}) ? $counts{$bin_num}++ : ($counts{$bin_num} = 0);
    }
    $seq = "";
  } elsif ($line =~ m/^([^>]\S+)$/i) { 
    $seq .= $1;
  }
}
close(IN);

if ($total_length == 0) { print STDERR "No sequences found."; exit(1) }

@lengths = reverse sort {$a <=> $b} @lengths;
#print join("\n", @lengths);

my $rsum = 0;
my $i = -1;
while ($rsum < $total_length/2) {
  $i++;
  $rsum += $lengths[$i];
}
my $N50 = $lengths[$i];

open(HIST, ">${oname}.hist.txt") or die "Can't open file: $!";
foreach my $bin_num (sort {$a <=> $b} keys %counts) {
  print HIST $bin_num*$bin_size, ":", ($bin_num+1)*$bin_size-1, "\t", $counts{$bin_num}, "\n";
}
close(HIST);

open(OUT, ">${oname}.summary.txt") or die "Can't open file: $!";
print(OUT "N50\t", $N50, "\n");
printf(OUT "Percent_GC\t%.2f\n", 100 * $GCcount/($total_length-$Ncount));
printf(OUT "Percent_N\t%.2f\n", 100 * $Ncount/$total_length);
print(OUT "Number_sequences\t", $#lengths+1, "\n");
printf(OUT "Average_length\t%.2f\n", $total_length/($#lengths+1));
print(OUT "Median_length\t", $lengths[floor($#lengths/2)], "\n");
print(OUT "Shortest_sequence\t", $lengths[$#lengths], "\n");
print(OUT "Longest_sequence\t", $lengths[0], "\n");
print(OUT "Total_length\t", $total_length, "\n");
close(OUT);
