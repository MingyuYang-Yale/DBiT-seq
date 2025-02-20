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
        sample <sample>
USAGE

my ($indir,$outdir,$sample,$help);
GetOptions(
    "indir=s"=>\$indir,
    "outdir=s"=>\$outdir,
    "sample=s"=>\$sample,
);

die $usage if $help;
die $usage unless  $indir && $outdir && $sample;

`mkdir $outdir/$sample` unless(-d "$outdir/$sample");

chomp (my $file = `ls $indir/$sample/$sample.with.linker.fq.gz`);
chomp (my $barcodefileA = `ls /gpfs/gibbs/pi/fan/my393/01.DBiT-seq_cell_paper_2020.bin/00.database/barcodeA.xls`);
chomp (my $barcodefileB = `ls /gpfs/gibbs/pi/fan/my393/01.DBiT-seq_cell_paper_2020.bin/00.database/barcodeB.xls`);
my $num = 0;
my $numA = 0;
my $numB = 0;
my %barcodeA;
my %barcodeB;

open IN,"$barcodefileA" or die $!;
while(<IN>)
{
	chomp;
	my @array = split /\t/,$_;
	$barcodeA{$array[0]}[0] = 0;
	$barcodeA{$array[0]}[1] = $array[1];
}
close IN;

open IN,"$barcodefileB" or die $!;
while(<IN>)
{
        chomp;
        my @array = split /\t/,$_;
        $barcodeB{$array[0]}[0] = 0;
        $barcodeB{$array[0]}[1] = $array[1];
}
close IN;

open LOG,">>$outdir/$sample/log" or die $!;

open OUT,">:gzip","$outdir/$sample/$sample.barcodes.fq.gz" or die $!;
open IN,"<:gzip","$file" or die $!;
while(1)
{
        my $line_1 = <IN>;
        my $line_2 = <IN>;
        my $line_3 = <IN>;
        my $line_4 = <IN>;
	
	last unless(defined $line_1);
        chomp ($line_1,$line_2,$line_3,$line_4);
	
	my @tmp = split /\t/,$line_1;
	my $linker_pos = $tmp[1];
	my $pos_barcodeA = 70 + $linker_pos - 40;
	my $pos_barcodeB = 32 + $linker_pos - 40; 

	my $valueA = substr($line_2,$pos_barcodeA,8);
	my $valueB = substr($line_2,$pos_barcodeB,8);
	my $flagA =0;
	my $flagB =0;
	foreach my $key(keys %barcodeA)
	{
		if($key eq $valueA)
		{
			$numA ++;
			$barcodeA{$key}[0] ++;
			$flagA = 1;
		}
	}
	foreach my $key(keys %barcodeB)
        {
                if($key eq $valueB)
                {
                        $numB ++;
                        $barcodeB{$key}[0] ++;
			$flagB = 1;
                }
        }
	if($flagA == 1 && $flagB == 1)
	{
		$num++;
		print OUT "$line_1\n";
       		print OUT "$line_2\n";
        	print OUT "$line_3\n";
        	print OUT "$line_4\n";
	}
}
close IN;

open OUT_1,">$outdir/$sample/barcodeA.stat.xls" or die $!;
open OUT_2,">$outdir/$sample/barcodeB.stat.xls" or die $!;

foreach my $key(keys %barcodeA)
{
	print OUT_1 "$key\t$barcodeA{$key}[1]\t$barcodeA{$key}[0]\n";
}
print LOG "Barcode A : $numA\n";

foreach my $key(keys %barcodeB)
{
        print OUT_2 "$key\t$barcodeB{$key}[1]\t$barcodeB{$key}[0]\n";
}
print LOG "Barcode B : $numB\n";

print LOG "Barcode A&B: $num\n";

