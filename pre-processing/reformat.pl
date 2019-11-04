#!/usr/bin/perl 
use strict;
use warnings;
use Getopt::Long;
use File::Basename;
use PerlIO::gzip;

my $usage=<<USAGE;
Usage
        perl $0
        indir   <indir>
        outdir  <out_dir>
        insertsize <insertsize>
USAGE

my ($indir,$outdir,$insertsize,$help);
GetOptions(
    "indir=s"=>\$indir,
    "outdir=s"=>\$outdir,
    "insertsize=s"=>\$insertsize,
);

die $usage if $help;
die $usage unless  $indir && $outdir && $insertsize;

`mkdir $outdir/$insertsize` unless(-d "$outdir/$insertsize");

open LOG,">$outdir/$insertsize/log" or die $!;
print LOG "$insertsize filter primer begin at: ".`date`;

chomp (my $file2 = `ls $indir/$insertsize/*R2_001.fastq.gz`);
chomp (my $file1 = `ls $indir/$insertsize/*R1_001.fastq.gz`);

chomp (my $barcodefile = `ls /gpfs/ysm/project/my393/Spatial_multi_omics/Our/00.database/barcode.xls`);

my $num = 0;
my $numA = 0;
my $numB = 0;
my %barcodeA;
my %barcodeB;
open IN,"$barcodefile" or die $!;
while(<IN>)
{
	chomp;
	my @array = split /\t/,$_;
	$barcodeA{$array[0]}[0] = 0;
	$barcodeB{$array[0]}[0] = 0;
	$barcodeA{$array[0]}[1] = $array[1];
	$barcodeB{$array[0]}[1] = $array[1];
}
close IN;

open IN_1,"<:gzip","$file1" or die $!;
open IN_2,"<:gzip","$file2" or die $!;

open OUT_1,">:gzip","$outdir/$insertsize/$insertsize.R1.fastq.gz" or die $!;
open OUT_2,">:gzip","$outdir/$insertsize/$insertsize.R2.fastq.gz" or die $!;

open OUT_3,">:gzip","$outdir/$insertsize/$insertsize.used.original.R1.fastq.gz" or die $!;
open OUT_4,">:gzip","$outdir/$insertsize/$insertsize.used.original.R2.fastq.gz" or die $!;

open OUT_5,">:gzip","$outdir/$insertsize/$insertsize.useless.R1.fastq.gz" or die $!;
open OUT_6,">:gzip","$outdir/$insertsize/$insertsize.useless.R2.fastq.gz" or die $!;


        #---------------------------read in the reads information-----------------------#

while (1) {

                #-get the reads and corresponding information in each 4 lines

	my $line1_1 = <IN_1>;
	my $line1_2 = <IN_1>;
	my $line1_3 = <IN_1>;
	my $line1_4 = <IN_1>;

	my $line2_1 = <IN_2>;
	my $line2_2 = <IN_2>;
	my $line2_3 = <IN_2>;
	my $line2_4 = <IN_2>;

                #check the end of the file

	last unless (defined($line1_1) and defined($line2_1));
	chomp ($line1_1,$line1_2,$line1_3,$line1_4,$line2_1,$line2_2,$line2_3,$line2_4);
	
	my $valueA = substr($line2_2,70,8);
	my $valueB = substr($line2_2,32,8);
	my $flagA =0;
	my $flagB =0;
	if(exists $barcodeA{$valueA})
	{
		$numA ++;
		$barcodeA{$valueA}[0] ++;
		$flagA = 1;
	}
	if(exists $barcodeB{$valueB})
        {
                $numB ++;
                $barcodeB{$valueB}[0] ++;
                $flagB = 1;
        }

	if($flagA == 1 && $flagB == 1)
	{
		my $UMI = substr($line2_2,22,10);
		my $UMI_Q = substr($line2_4,22,10);
		my $valueA_Q = substr($line2_4,70,8);
		my $valueB_Q = substr($line2_4,32,8);
		my @header_split_1 = split / /,$line1_1;
		my @header_split_2 = split / /,$line2_1;
		my @header_split_1_Q = split / /,$line1_3;
                my @header_split_2_Q = split / /,$line2_3;
		#attention ,switch reads here
		print OUT_2 "$header_split_1[0]\n$line1_2\n$header_split_1_Q[0]\n$line1_4\n";
		print OUT_1 "$header_split_2[0]\n$valueB$valueA$UMI\n$header_split_2_Q[0]\n$valueB_Q$valueA_Q$UMI_Q\n";
		
		print OUT_3 "$line1_1\n$line1_2\n$line1_3\n$line1_4\n";
		print OUT_4 "$line2_1\n$line2_2\n$line2_3\n$line2_4\n";
		$num++;
	}
	else	
	{
		print OUT_5 "$line1_1\n$line1_2\n$line1_3\n$line1_4\n";
		print OUT_6 "$line2_1\n$line2_2\n$line2_3\n$line2_4\n";
	}
}
close IN;

my $title = "BarcodeA\tBarcodeB\tBarcodeAB\n";
my $output1 = "$numA\t$numB\t$num\n";
printf LOG $title;
printf LOG $output1;
print LOG "$insertsize filter primer end at: ".`date`;
