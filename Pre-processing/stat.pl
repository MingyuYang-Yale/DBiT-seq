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
        sample  <sample>
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

open LOG,">$outdir/$sample/$sample.log" or die $!;
print LOG "$sample statistics begin at: ".`date`;

chomp (my $file = `ls $indir/$sample/*R2_001.fastq.gz`);

my $primer = "CAAGCGTTGGCTTCTCGCATCT";
my $linker = "ATCCACGTGCTTGAGAGGCCAGAGCATTCG";

chomp (my $barcodefile = `ls /gpfs/ysm/project/my393/Spatial_multi_omics/Our/00.database/barcode.xls`);
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

my ($all_num,$exact_primer_num,$mismatch_primer_num,$exact_linker_num,$mismatch_linker_num,$numA,$numB,$numAB) = (0) x 8;

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

        #----------- Primer --------#
    	if($line_2 =~/^$primer/)
    	{
        	$exact_primer_num ++ ;
#        	print OUT_exact_primer "$line_1\n";
#               print OUT_exact_primer "$line_2\n";
#        	print OUT_exact_primer "$line_3\n";
#        	print OUT_exact_primer "$line_4\n";
        }

	else
	{
        	my @p =split '', $primer;
        	my @t =split '', $line_2;

        	my $flag_primer = 0;
        	for my $i(0..0)
        	{
        		my $ne_p = 0 ;
                	for my $j(0..@p-1)
        		{
                		$ne_p ++ if($p[$j] ne $t[$i+$j]);
                        	last if ($ne_p > 4);
        		}
                	if($ne_p <=4)
                	{
                        	my $value_p = substr($line_2,$i,22);
                        	$mismatch_primer_num ++;
                	#        print OUT_mismatch_4_primer "$line_1\t$i\t$value_p\n";
                	#        print OUT_mismatch_4_primer "$line_2\n";
                	#        print OUT_mismatch_4_primer "$line_3\n";
                	#        print OUT_mismatch_4_primer "$line_4\n";
                	}
        	}
	}
	#----------- remove linker --------#
    	if($line_2 =~/$linker/)
    	{   
		$exact_linker_num ++ ;
#        	print OUT_exact_linker "$line_1\n";
#   		print OUT_exact_linker "$line_2\n";
#        	print OUT_exact_linker "$line_3\n";
#        	print OUT_exact_linker "$line_4\n";
	}
	else
	{
		my @l =split '', $linker;
		my @t =split '', $line_2;
		for my $i(0..@t-30)
		{
      			my $ne_l = 0 ; 
			for my $j(0..@l-1) 
      			{   
        			$ne_l ++ if($l[$j] ne $t[$i+$j]);
				last if ($ne_l > 3);
      			}	
			if($ne_l <=3)
			{
				my $value_l = substr($line_2,$i,30);
				$mismatch_linker_num ++;
				last;
	#			print OUT_mismatch_linker "$line_1\t$i\t$value_l\n";
	#			print OUT_mismatch_linker "$line_2\n";
	#			print OUT_mismatch_linker "$line_3\n";
	#			print OUT_mismatch_linker "$line_4\n";
			}
		}
	}
	#-------------- Barcode --------------#
        my $valueA = substr($line_2,70,8);
        my $valueB = substr($line_2,32,8);
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
                $numAB++;
        }
}
close IN;


open OUT_1,">$outdir/$sample/barcodeA.stat.xls" or die $!;
open OUT_2,">$outdir/$sample/barcodeB.stat.xls" or die $!;

foreach my $key(sort {$barcodeA{$a}[1]<=>$barcodeA{$b}[1]} keys %barcodeA)
{
        print OUT_1 "$key\t$barcodeA{$key}[1]\t$barcodeA{$key}[0]\n";
}

foreach my $key(sort {$barcodeB{$a}[1]<=>$barcodeB{$b}[1]} keys %barcodeB)
{
        print OUT_2 "$key\t$barcodeB{$key}[1]\t$barcodeB{$key}[0]\n";
}


my $barcode_plot_A = <<FIGURE;
        data<-read.table("$outdir/$sample/barcodeA.stat.xls")
        pdf("$outdir/$sample/$sample.barcodeA.pdf",width=8,height=8)
	barplot(data[,3],col="blue",main="$sample Barcode A(1-50)")
	dev.off()
FIGURE

my $barcode_plot_B = <<FIGURE;
        data<-read.table("$outdir/$sample/barcodeB.stat.xls")
        pdf("$outdir/$sample/$sample.barcodeB.pdf",width=8,height=8)
        barplot(data[,3],col="blue",main="$sample Barcode B(1-50)")
        dev.off()
FIGURE
        open R,"|/gpfs/ysm/project/my393/software/R-3.5.3/mybuild/bin/R  --vanilla --slave" or die $!;
        print R $barcode_plot_A;
        print R $barcode_plot_B;
        close R;

#---------------------------------------------------#

my $primer_percentage = ($exact_primer_num + $mismatch_primer_num)*100/$all_num;
my $linker_percentage = ($exact_linker_num + $mismatch_linker_num)*100/$all_num;
my $barcode_percentage = $numAB*100/$all_num;

print LOG "SampleID\tTotal Reads\texact_primer\tmismatch_primer\tPercentage(%)\texact_linker\tmismatch_linker\tPercentage(%)\tBarcodeA\tBarcodeB\tBarcodeAB\tPercentage(%)\n";
print LOG "$sample\t$all_num\t$exact_primer_num\t$mismatch_primer_num\t";
printf LOG "%.2f",$primer_percentage;
print LOG "\t$exact_linker_num\t$mismatch_linker_num\t";
printf LOG "%.2f",$linker_percentage;
print LOG "\t$numA\t$numB\t$numAB\t";
printf LOG "%.2f","$barcode_percentage";
print LOG "\n";
print LOG "$sample statistics  end at: ".`date`;
