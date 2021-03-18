#!/usr/bin/perl
use warnings;
use strict;
use SVG;
use Data::Dumper;

my $pwidth = 1200;
my $pheight = 1200;

#my $svg = SVG->new('width',$pwidth,'height',$pheight);

my %hash;
my $max = 0;
my %selected;

open IN,"$ARGV[0]" or die $!; #50t_stdata.updated.tsv
<IN>;
while(<IN>)
{
	chomp;
	my @array = split /\t/,$_;
	my @pos = split /x/,$array[0];
	$hash{$array[0]}[0] = $pos[0];#x
	$hash{$array[0]}[1] = $pos[1];#y
}
close IN;

my ($cnt,$x,$y) = (0,0,0);

my $flank_x = 100;
my $flank_y = 100;

#
my $num = 0;
open IN,"$ARGV[1]" or die $!;#selected_spot_under_tissue.svg
while(<IN>)
{
	
	chomp;
	if($_ =~/x="(\S+)" y="(\S+)" class/)
	{
		$selected{$num}[0] = $1;
		$selected{$num}[1] = $2;
		$num ++;
	}
}


foreach my $key(keys %hash)
{
	$x = $hash{$key}[0];
	$y = $hash{$key}[1];
	#my $degree = $hash{$key}[3]/$max;
	#$svg->rect(x=>($flank_x + $x*20),y=>($flank_y+$y*20),width=>10,height=>10,fill=>"white");
	#$svg->rect(x=>($flank_x + ($x-1)*20),y=>($flank_y+($y-1)*20),width=>10,height=>10,'opacity',$degree,fill=>"red");

	foreach my $key(keys %selected)
	{
		if($selected{$key}[0] == ($flank_x + ($x-1)*20) && $selected{$key}[1] == ($flank_y+($y-1)*20))
		{
			print "$x\t$y\n";
		}

	}
}

#print $svg->xmlify();
