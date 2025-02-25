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

chomp (my $file1 = `ls $indir/$sample/$sample.with.linker.R1.fq.gz`);
chomp (my $file2 = `ls $indir/$sample/$sample.with.linker.R2.fq.gz`);

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

open OUT_1,">:gzip","$outdir/$sample/$sample.barcodes.R1.fq.gz" or die $!;
open OUT_2,">:gzip","$outdir/$sample/$sample.barcodes.R2.fq.gz" or die $!;

open OUT_st_1,">:gzip","$outdir/$sample/$sample.st.R1.fq.gz" or die $!;
open OUT_st_2,">:gzip","$outdir/$sample/$sample.st.R2.fq.gz" or die $!;


open IN_1,"<:gzip","$file1" or die $!;
open IN_2,"<:gzip","$file2" or die $!;
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

	my @tmp = split /\t/,$line2_1;
	my $linker_pos = $tmp[1];
	my $pos_barcodeA = 70 + $linker_pos - 40;
	my $pos_barcodeB = 32 + $linker_pos - 40; 
	
	my $pos_UMI = $pos_barcodeB - 10; 

	my $valueA = substr($line2_2,$pos_barcodeA,8);
	my $valueB = substr($line2_2,$pos_barcodeB,8);
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
	
		print OUT_1 "$line1_1\n$line1_2\n$line1_3\n$line1_4\n";
		print OUT_2 "$line2_1\n$line2_2\n$line2_3\n$line2_4\n";

		# ouput the st-pipeline ready files below
		my $UMI = substr($line2_2,$pos_UMI,10);
                my $UMI_Q = substr($line2_4,$pos_UMI,10);
                my $valueA_Q = substr($line2_4,$pos_barcodeA,8);
                my $valueB_Q = substr($line2_4,$pos_barcodeB,8);
		my @header_split_1 = split / /,$line1_1;
                my @header_split_2 = split / /,$line2_1;
                my @header_split_1_Q = split / /,$line1_3;
                my @header_split_2_Q = split / /,$line2_3;
                #attention ,switch reads here
                print OUT_st_2 "$header_split_1[0]\n$line1_2\n$header_split_1_Q[0]\n$line1_4\n";
                print OUT_st_1 "$header_split_2[0]\n$valueB$valueA$UMI\n$header_split_2_Q[0]\n$valueB_Q$valueA_Q$UMI_Q\n";
	}
}
close IN;
close OUT_1;
close OUT_2;
close OUT_st_1;
close OUT_st_2;

open OUT_stat_1,">$outdir/$sample/barcodeA.stat.xls" or die $!;
open OUT_stat_2,">$outdir/$sample/barcodeB.stat.xls" or die $!;

foreach my $key(keys %barcodeA)
{
	print OUT_stat_1 "$key\t$barcodeA{$key}[1]\t$barcodeA{$key}[0]\n";
}
print LOG "Barcode A : $numA\n";

foreach my $key(keys %barcodeB)
{
        print OUT_stat_2 "$key\t$barcodeB{$key}[1]\t$barcodeB{$key}[0]\n";
}
print LOG "Barcode B : $numB\n";

print LOG "Barcode A&B: $num\n";

close OUT_stat_1;
close OUT_stat_2;
close LOG;
