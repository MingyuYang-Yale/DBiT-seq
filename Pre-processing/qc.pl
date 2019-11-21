#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;
use PerlIO::gzip;


#--------------------------help and options guide--------------------------#
my $usage = <<USAGE;
Usage
	perl	$0
	indir	<the inout father dir of the samples>
	outdir	<the output father dir of the samples>
	sample	<sample>
	quality <solexa-quals/phred64-quals> [ default 33 ]
	end     <Single end = 1/Pair end = 2> [ default 2 ]
	N_rate  <N_rate> [ default 0.1 ]
	Qmin    <Qmin> [ default (quality + 5) ]
	Qrate   <Qrate> [ default 0.5 ]
USAGE

my ($indir,$outdir,$insertsize,$quality,$end,$N_rate,$Qmin,$Qrate,$help);
GetOptions(
    "indir=s"=>\$indir,
    "outdir=s"=>\$outdir,
	"insertsize=s"=>\$insertsize,
	"quality=i"=>\$quality,
	"end=s"=>\$end,
    "N_rate:i"=>\$N_rate,
    "Qmin:i"=>\$Qmin,
    "Qrate:i"=>\$Qrate,
    "h:s" => \$help,
);
die $usage if $help;
die $usage unless  $indir && $outdir && $insertsize;
#--------------------------help and options guide--------------------------#


#-default parameters value

$quality ||= 33;
$N_rate ||= 0.1;
$Qmin ||= ($quality + 5);
$Qrate ||= 0.5;
$end ||=2;


#-trim && create the dir if not exists

$indir = trim_slash($indir);
$outdir = trim_slash($outdir);
`mkdir $outdir/$sample` unless(-d "$outdir/$sample");


#-create the Log file

open LOG,">$outdir/$sample/log" or die $!;
print LOG "$sample filter begin at: ".`date`;
print STDERR "$sample filter begin at: ".`date`;


#-get the adapters list

#open Adapter,"/gpfs/ysm/project/my393/Our/00.bin/adapter.list" or die $!; 
open Adapter,"/gpfs/ysm/project/my393/Spatial_multi_omics/Our/00.bin/adapter.list" or die $!;
my @adapter;
while(<Adapter>){chomp;push(@adapter,$_);}

#-the common global variabes 

my ($total_reads,$total_bases,$remanent_reads,$remanent_bases,$without_adapter_reads,$read1_length,$read2_length,$adapter_num,$remove_N_num,$low_quality_num) = (0) x 10;
my (%hash_base,%hash_quality);

my ($gc_1,$Q20_1,$Q30_1,$error_1) = (0) x 4;

#-for end pair sequencing only

my ($gc_2,$Q20_2,$Q30_2,$error_2,$remove_duplication_num) = (0) x 5;
my %duplication;

#-get the $Q20 and $Q30

my ($Q20,$Q30);
($quality == 64) ? (($Q20,$Q30) = (84,94)) : (($Q20,$Q30) = (53,63));


#__________________________________________________________processing begin_______________________________________________________________#


#____________________________________for the default pair end sequencing______________________________________#

if ($end == 2) {

	#-get the input files

	#chomp (my $file_1 = `ls $indir/$insertsize/*1_sequence.fq.gz`);
	chomp (my $file_1 = `ls $indir/$insertsize/*R1_001.fastq.gz`);
	#chomp (my $file_2 = `ls $indir/$insertsize/*2_sequence.fq.gz`);
	chomp (my $file_2 = `ls $indir/$insertsize/*R2_001.fastq.gz`);

	#-open the input files

	open IN_1,"<:gzip","$file_1" or die $!;
	open IN_2,"<:gzip","$file_2" or die $!;

	#-open the output files

	open OUT_1,">:gzip","$outdir/$insertsize/$insertsize.R1.clean.fq.gz" or die $!;
	open OUT_2,">:gzip","$outdir/$insertsize/$insertsize.R2.clean.fq.gz" or die $!;
	

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
		
		#count the total reads number && get the length of the first read

		$total_reads++;
		($read1_length = length($line1_2)) if ($read1_length == 0);
		($read2_length = length($line2_2)) if ($read2_length == 0);
		
		#-remove adapter
		
		my $remove_a1 = remove_adapter($line1_2);
		my $remove_a2 = remove_adapter($line2_2);
		if ($remove_a1 or $remove_a2){
			$adapter_num++;
			next;
		}
	
		#-count bases at each site && count N content higher than %10
		
		my $remove_n1 = count_bases($line1_2,0);
		my $remove_n2 = count_bases($line2_2,$read2_length);
		($remove_N_num++) if($remove_n1 or $remove_n2);

		#-count the quality at each site && count the low quality

		my $low1 = count_quality($line1_4,\$Q20_1,\$Q30_1,0);
		my $low2 = count_quality($line2_4,\$Q20_2,\$Q30_2,$read2_length);
		($low_quality_num++) if($low1 or $low2);

		#-count the duplication

	#	my $rm_duplication = remove_duplication($line1_2,$line2_2);
	#	($remove_duplication_num++) if($rm_duplication);
		#-remove N content higher than %10

		if ($remove_n1 or $remove_n2){
			next;
		}
		
		#-remove the low quality 

		if ($low1 or $low2) {
			next;
		}

		#-remove duplication
		
	#	if ($rm_duplication){
	#		next;
	#	}

		#-count the remanent reads number
		
		$remanent_reads++;

		#out put the remanent reads

		print OUT_1 "$line1_1\n$line1_2\n$line1_3\n$line1_4\n";
    	print OUT_2 "$line2_1\n$line2_2\n$line2_3\n$line2_4\n";
	}
	
	#-caculate the reads without adapter
	
	$without_adapter_reads = $total_reads - $adapter_num;
	
	#-close the file handle

	close IN_1;close IN_2;close OUT_1;close OUT_2;

	#---------------------------------read in done----------------------------#
	

	#-----------------get the information from the variables------------------#

	
	#-get the total error rate && ouput the mean quality and error rate at each site

	error_rate(2);

	#-get the GC content && output the base frequency at each site
	
	gc_content(2);
	
	#-caculate a set of important rates && ouput them
	
	caculate_rates(2);


	#-----------------get the information from the variables done--------------#
}

#____________________________________for the default pair end sequencing done______________________________________#



#__________________________________________for the single end sequencing___________________________________________#

else {
	
	#-get the input files

	#chomp (my $file = `ls $indir/$insertsize/*1_sequence.fq.gz`);
	chomp (my $file = `ls $indir/$insertsize/*1_001.fastq.gz`);

	#-open the input files

	open IN_1,"<:gzip","$file" or die $!;

	#-open the output files
	
	open OUT_1,">:gzip","$outdir/$insertsize/$insertsize.clean.fq.gz" or die $!;

	#---------------------------read in the reads information-----------------------#

	while (1) {
	
		#-get the reads and corresponding information in each 4 lines

		my $line1 = <IN_1>;
		my $line2 = <IN_1>;
		my $line3 = <IN_1>;
		my $line4 = <IN_1>;

		#check the end of the file
	
		last unless (defined($line1));
		chomp ($line1,$line2,$line3,$line4);
		
		#count the total reads number && get the length of the first read

		$total_reads++;
		($read2_length = length($line2)) if ($read2_length == 0);

		#-remove adapter

		if (remove_adapter($line2)){
			$adapter_num++;
			next;
		}
		
		#-count bases at each site && count N content higher than %10
		
		my $remove_n1 = count_bases($line2,0);
		($remove_N_num++) if($remove_n1);

		#-count the quality at each site && count the low quality

		my $low1 = count_quality($line4,\$Q20_1,\$Q30_1,0);
		($low_quality_num++) if($low1);

		#-remove N content higher than %10

		if ($remove_n1){
			next;
		}

		#-remove the low quality 

		if ($low1) {
			next;
		}

		#-count the remanent reads number
	
		$remanent_reads++;

		#out put the remanent reads

		print OUT_1 "$line1\n$line2\n$line3\n$line4\n";
	}

	#-caculate the reads without adapter
	
	$without_adapter_reads = $total_reads - $adapter_num;

	#-close the file handle

	close IN_1;close OUT_1;

	#---------------------------------read in done----------------------------#
	

	#-----------------get the information from the variables------------------#
	
	#-get the total error rate && ouput the mean quality and error rate at each site

	error_rate(1);

	#-get the GC content && output the base frequency at each site

	gc_content(1);

	#-caculate a set of important rates && ouput them

	caculate_rates(1);

	#-----------------get the information from the variables done--------------#
}


#__________________________________________for the single end sequencing done_______________________________________#


#_______________________________________________plot the figures____________________________________________________#

my $X_axis;
($end == 2) ? ($X_axis = $read2_length * 2) : ($X_axis = $read2_length);
my $vertical_bar;
($end == 2) ? ($vertical_bar = "abline(v=$read2_length,col='darkblue',lty=2)") : ($vertical_bar = "");
my $GC_figure = <<FIGURE;
	gc<-read.table("$outdir/$insertsize/$insertsize.GC")
	site<-gc[,1]
	base_a<-gc[,4]
	base_t<-gc[,7]
	base_g<-gc[,10]
	base_c<-gc[,13]
	base_n<-gc[,16]
	total_sites<-$X_axis
	half_sites<-$read2_length/2
	pdf("$outdir/$insertsize/$insertsize.GC.pdf",width=8,height=6)
	plot(site,base_a,xlim=c(0,total_sites),ylim=c(0,50),axes=FALSE,col="red",type="l",xlab="Position along reads",ylab="percent",main="Base percentage composition along reads",lty=1,lwd=1.5)
	lines(site,base_t,col="magenta",type="l",lty=2,lwd=1.5)
	lines(site,base_g,col="darkblue",type="l",lty=4,lwd=1.5)
	lines(site,base_c,col="green",type="l",lty=5,lwd=1.5)
	lines(site,base_n,col="cyan3",type="l",lty=6,lwd=1.5)
	legend("topright",legend=c("A","T","G","C","N"),col=c("red","magenta","darkblue","green","cyan3"),lty=c(1,2,4,5,6))
	$vertical_bar
	axis(side=1,at=seq(from=0,to=total_sites,by=half_sites))
	axis(side=2,at=seq(from=0,to=50,by=10))
	dev.off()
FIGURE
my $meanQ_errorR = <<FIGURE;
	table<-read.table("$outdir/$insertsize/$insertsize.mean_quality")
        site<-table[,1]
        quality<-table[,2]
        error<-table[,3]
        total_sites<-$X_axis
        pdf("$outdir/$insertsize/$insertsize.mean_quality.pdf",width=8,height=6)
        plot(site,quality,xlim=c(0,total_sites),ylim=c(0,40),axes=FALSE,col="red",type="p",pch=".",cex=1.5,xlab="Position along reads",ylab="Quality",main="Distribution of qualities")
        axis(side=1,at=seq(from=0,to=total_sites,by=20))
        axis(side=2,at=seq(from=0,to=40,by=10))
        abline(h=20,col="darkblue",lty=2)
        abline(v=seq(0,total_sites, by=10),col="darkblue",lty=3 )

        pdf("$outdir/$insertsize/$insertsize.ErrorRate.pdf",width=8,height=6)
        plot(site,error,xlim=c(0,total_sites),col="red",type="h",xlab="Position along reads",ylab="% Error-Rate")
        axis(side=1,at=seq(from=0,to=total_sites,by=20))
        abline(v=seq(0,total_sites, by=10),col="darkblue",lty=3 )
        dev.off()
FIGURE
        open R,"|/gpfs/ysm/project/my393/software/R-3.5.3/mybuild/bin/R  --vanilla --slave" or die $!;
        print R $GC_figure;
        print R $meanQ_errorR;
        close R;
#_______________________________________________plot the figures done_____________________________________________#



#__________________________________________________________processing done_______________________________________________________________#





#________________________________________________Subrutines begin___________________________________________________#

#-dir trimming

sub trim_slash {
	my($dir) = @_;
	($dir =~ /\/$/) ? ($dir =~ s/\/$//) : ($dir = $dir);
	return $dir;
}


#-remove adapter

sub remove_adapter {
	my($seq) = @_;
	my $adapt = \@adapter;
	my $i = 0;
	while($i < @$adapt){
		if ($seq =~ /$$adapt[$i]/){
			return 1;
		}
		$i++;
	}	
	return 0;
}


#-remove duplication

sub remove_duplication{
	my($seq1,$seq2) = @_;
	(return 1) if (exists($duplication{"$seq1.$seq2"}));
	$duplication{"$seq1.$seq2"} = 1;
	return 0;
}


#-count the quality at each site && count the low quality

sub count_quality {
	my($seq,$Q_20,$Q_30,$start_site) = @_;
	my($i,$low_q_site,$base_quality) = (0) x 3;
	my $length = length($seq);
	while ($i < $length) {
		my $base_asc = substr($seq,$i,1);
		$base_quality = ord($base_asc);
		$hash_quality{$i+$start_site} += $base_quality;
		$low_q_site++ if ($base_quality <= $Qmin);
		$$Q_20++ if ($base_quality >= $Q20);
        $$Q_30++ if ($base_quality >= $Q30);
		$i++;
	}
	($low_q_site >= $length*$Qrate) ? (return 1) : (return 0);
}


#-count bases at each site

sub count_bases {
	my ($seq,$start_site) = @_;
	my $length = length($seq);
	my $i = 0;
	while ($i < $length) {
		my $base = substr($seq,$i,1);
		$hash_base{$i+$start_site}{$base}++;
		$i++;
	}
	my $N_num = ($seq =~ tr/N/N/) + 0;
	(return 1) if ($N_num >= $length * $N_rate);
	return 0;
}


#-get the total error rate && ouput the mean quality and error rate at each site

sub error_rate {
	my($end) = @_;
	open OUT_3,">$outdir/$insertsize/$insertsize.mean_quality" or die $!;
	my @keys = sort {$a<=>$b} keys %hash_quality;
	my $minus;
	($quality == 64) ? ($minus = 64) : ($minus = 33);
	my $i = 0;
	while ($i < @keys) {
		my $mean_quality = ($hash_quality{$keys[$i]}/$without_adapter_reads) - $minus;
		my $index = 0 -($mean_quality/10);
		my $error_rate = (10**$index)*100;
		if ($i < $read2_length){
			$error_1 += $error_rate; 
		}
		else {
			$error_2 += $error_rate; 
		}
		printf OUT_3 "%d\t%.5f\t%f\n",$keys[$i],$mean_quality,$error_rate;
		$i++;
	}
	close OUT_3;
}


#-get the GC content && output the base frequency at each site

sub gc_content {
	my($end) = @_;
	open OUT_4,">$outdir/$insertsize/$insertsize.GC" or die $!;
	my @keys = sort {$a<=>$b} keys %hash_base;
	my $i = 0;
	my @bases = qw/A T G C N/;
	while ($i < @keys) {
		print OUT_4 "$keys[$i]\t";
		my $j = 0;
		while ($j < @bases) {
			if (exists $hash_base{$keys[$i]}{$bases[$j]}) {
				my $frequency = ($hash_base{$keys[$i]}{$bases[$j]}/$without_adapter_reads)*100;
				printf OUT_4 "%s\t%d\t%.3f\t",$bases[$j],$hash_base{$keys[$i]}{$bases[$j]},$frequency;
			}
			else {
				print OUT_4 "$bases[$j]\t0\t0\t";
			}
			$j++;
		}
		print OUT_4 "\n";
		
		my ($g,$c) = (0) x 2;
		($g = $hash_base{$keys[$i]}{"G"}) if (exists($hash_base{$keys[$i]}{"G"}));
		($c = $hash_base{$keys[$i]}{"C"}) if (exists($hash_base{$keys[$i]}{"C"})); 
		($i < $read2_length) ? ($gc_1 += $g + $c) : ($gc_2 += $g + $c);
		$i++;
	}
	close OUT_4;
}


#-caculate a set of important rates && ouput them

sub caculate_rates{
	my($end) = @_;
	my ($gc_rate_2,$Q20_rate_2,$Q30_rate_2,$error_rate_2,$duplication_rate);
	$remanent_bases = $remanent_reads * $read2_length;
	$total_bases = $total_reads * $read2_length;
	my $without_adapter_bases = $without_adapter_reads * $read2_length;
	my $gc_rate_1 = ($gc_1/$without_adapter_bases)*100;
	my $Q20_rate_1 = ($Q20_1/$without_adapter_bases)*100;
	my $Q30_rate_1 = ($Q30_1/$without_adapter_bases)*100;
	my $error_rate_1 = $error_1/100;
	if ($end == 2) {
		$total_reads = $total_reads * 2;
		$total_bases = $total_reads * $read2_length;
		$remanent_reads = $remanent_reads * 2;
		$remanent_bases = $remanent_reads * $read2_length;
		$gc_rate_2 = ($gc_2/$without_adapter_bases)*100;		
		$Q20_rate_2 = ($Q20_2/$without_adapter_bases)*100;	
		$Q30_rate_2 = ($Q30_2/$without_adapter_bases)*100;		
		$error_rate_2 = $error_2/100;
		#$duplication_rate =  $remove_duplication_num*100/$without_adapter_reads;
	}
	
	my $title = "Raw reads\tRaw bases\tClean reads\tClean bases\tErrorRate\tQ20\tQ30\tGC content\n";
	#($end == 2) ? ($title .= "\tDuplicateRate\n") : ($title .= "\n");
	printf LOG $title;
	
	my $output1 = "$total_reads\t$total_bases\t$remanent_reads\t$remanent_bases\t";
	printf LOG $output1;
	
	if ($end == 2){
		printf LOG "%.2f;%.2f\t%.2f;%.2f\t%.2f;%.2f\t%.2f;%.2f\n",$error_rate_1,$error_rate_2,$Q20_rate_1,$Q20_rate_2,$Q30_rate_1,$Q30_rate_2,$gc_rate_1,$gc_rate_2;
	}
	else {
		printf LOG "%.2f\t%.2f\t%.2f\t%.2f\n",$error_rate_1,$Q20_rate_1,$Q30_rate_1,$gc_rate_1;
	}
	my $output2 = "N remove $remove_N_num\nQuality remove $low_quality_num\nAdapter remove $adapter_num\n";
	#($output2 .= "Duplication remove $remove_duplication_num\n") if ($end ==2); 
	printf LOG $output2;

	printf LOG "$sample filter end at: ".`date`;
	printf STDERR "$sample filter end at: ".`date`;
	close LOG;
}

#________________________________________________Subrutines done___________________________________________________#
