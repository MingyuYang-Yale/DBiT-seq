#!/usr/bin/perl 
use strict;
use warnings;
use Getopt::Long;
use File::Basename;
use PerlIO::gzip;

# Usage message for script execution

my $usage=<<USAGE;
Usage
	perl $0
	indir   <indir>
	outdir  <out_dir>
	sample <sample>
USAGE

# Declare variables for command-line arguments
my ($indir,$outdir,$sample,$help);
GetOptions(
	"indir=s"=>\$indir,
	"outdir=s"=>\$outdir,
	"sample=s"=>\$sample,
);

# Print usage and exit if missing required arguments
die $usage if $help;
die $usage unless  $indir && $outdir && $sample;

`mkdir $outdir/$sample` unless(-d "$outdir/$sample");

my ($all_num,$linker_num) = (0) x 2;
open LOG,">$outdir/$sample/log" or die $!;


chomp (my $file1 = `ls $indir/$sample/*R1.fastq.gz`);
chomp (my $file2 = `ls $indir/$sample/*R2.fastq.gz`);

# Open output files for reads with and without the linker sequence
open OUT_1_1,">:gzip","$outdir/$sample/$sample.with.linker.R1.fq.gz" or die $!;
open OUT_1_2,">:gzip","$outdir/$sample/$sample.with.linker.R2.fq.gz" or die $!;

open OUT_2_1,">:gzip","$outdir/$sample/$sample.without.linker.R1.fq.gz" or die $!;
open OUT_2_2,">:gzip","$outdir/$sample/$sample.without.linker.R2.fq.gz" or die $!;
# Define the linker sequence to search for
my $linker = "ATCCACGTGCTTGAGAGGCCAGAGCATTCG";

# Open input FASTQ file in gzip mode
open IN_1,"<:gzip","$file1" or die $!;
open IN_2,"<:gzip","$file2" or die $!;
# Read the FASTQ file in chunks of 4 lines (1 read per iteration)
while(1)
{   
   	my $line1_1 = <IN_1>;
   	my $line1_2 = <IN_1>;
   	my $line1_3 = <IN_1>;
   	my $line1_4 = <IN_1>;

	my $line2_1 = <IN_2>;
        my $line2_2 = <IN_2>;
        my $line2_3 = <IN_2>;
        my $line2_4 = <IN_2>;


	last unless (defined($line1_1) and defined($line2_1));
        chomp ($line1_1,$line1_2,$line1_3,$line1_4,$line2_1,$line2_2,$line2_3,$line2_4);

	$all_num ++;	
	
	my @t =split '', $linker;
	my @t1 =split '', $line2_2;

	my $flag_1 = 0;
	for my $i(0..@t1-30)
	{
      		my $ne = 0 ;# Mismatch counter 
		for my $j(0..@t-1) 
      		{   
        		$ne++ if($t[$j] ne $t1[$i+$j]);
			last if ($ne > 3); # Stop if more than 3 mismatches
      		}	
		if($ne <=3)# Linker found with at most 3 mismatches
		{
			my $value = substr($line2_2,$i,30);
			$linker_num ++;

			print OUT_1_1 "$line1_1\n";
                        print OUT_1_1 "$line1_2\n";
                        print OUT_1_1 "$line1_3\n";
                        print OUT_1_1 "$line1_4\n";

			print OUT_1_2 "$line2_1\t$i\t$value\n";
			print OUT_1_2 "$line2_2\n";
			print OUT_1_2 "$line2_3\n";
			print OUT_1_2 "$line2_4\n";
			$flag_1 = 1; # Set flag to indicate linker found
			last;
		}
	}
	 # If no linker found, write to "without linker" output file
	next if ($flag_1 == 1);
	
	print OUT_2_1 "$line1_1\n";
        print OUT_2_1 "$line1_2\n";
        print OUT_2_1 "$line1_3\n";
        print OUT_2_1 "$line1_4\n";

	print OUT_2_2 "$line2_1\n";
	print OUT_2_2 "$line2_2\n";
	print OUT_2_2 "$line2_3\n";
	print OUT_2_2 "$line2_4\n";
}
close IN_1;
close IN_2;
close OUT_1_1;
close OUT_1_2;
close OUT_2_1;
close OUT_2_2;

# Write summary statistics to log file
#---------------------------------------------------#
print LOG "all_num : $all_num\n";
print LOG "linker_num : $linker_num\n";
