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

my ($all_num,$linker_num) = (0) x 2;
open LOG,">$outdir/$sample/log" or die $!;
print LOG "$sample filter linker begin at: ".`date`;

chomp (my $file = `ls $indir/$sample/*R2.fastq.gz`);

open OUT_1,">:gzip","$outdir/$sample/$sample.with_linker.fq.gz" or die $!;
open OUT_2,">:gzip","$outdir/$sample/$sample.without.linker.fq.gz" or die $!;

my $linker = "ATCCACGTGCTTGAGAGGCCAGAGCATTCG";
open IN,"<:gzip","$file" or die $!;

while(1)
{   
   	my $line_1 = <IN>;
   	my $line_2 = <IN>;
   	my $line_3 = <IN>;
   	my $line_4 = <IN>;

   	last unless(defined $line_1);
   	chomp ($line_1,$line_2,$line_3,$line_4);
	$all_num ++;	
	
	my @t =split '', $linker;
	my @t1 =split '', $line_2;

	my $flag_1 = 0;
	for my $i(0..@t1-30)
	{
      		my $ne = 0 ; 
		for my $j(0..@t-1) 
      		{   
        		$ne++ if($t[$j] ne $t1[$i+$j]);
			last if ($ne > 3);
      		}	
		if($ne <=3)
		{
			my $value = substr($line_2,$i,30);
			$linker_num ++;
			print OUT_1 "$line_1\t$i\t$value\n";
			print OUT_1 "$line_2\n";
			print OUT_1 "$line_3\n";
			print OUT_1 "$line_4\n";
			$flag_1 = 1;
			last;
		}
	}
	next if ($flag_1 == 1);
	print OUT_2 "$line_1\n";
	print OUT_2 "$line_2\n";
	print OUT_2 "$line_3\n";
	print OUT_2 "$line_4\n";
}
close IN;
close OUT_1;
close OUT_2;

#---------------------------------------------------#
print LOG "all_num : $all_num\n";
print LOG "linker_num : $linker_num\n";
print LOG "$sample filter linker end at: ".`date`;
