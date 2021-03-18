#!/usr/bin/perl
use warnings;
use strict;
use SVG;
use Data::Dumper;

my $pwidth = 1200;
my $pheight = 1200;

my $svg = SVG->new('width',$pwidth,'height',$pheight);

my %hash;
my $max = 0;

open IN,"$ARGV[0]" or die $!; #50t_stdata.updated.tsv
<IN>;
while(<IN>)
{
	chomp;
	my @array = split /\t/,$_;
	my @pos = split /x/,$array[0];
	$hash{$array[0]}[0] = $pos[0];#x
	$hash{$array[0]}[1] = $pos[1];#y
	for(my $i=1;$i<@array;$i++)
	{
		if($array[$i] > 0)
		{
			$hash{$array[0]}[2] ++;#genes
			$hash{$array[0]}[3] += $array[$i];#counts
		}
		
	} 
	if($hash{$array[0]}[2] > $max)
	{
		$max = $hash{$array[0]}[2];
	}
}
close IN;

my ($cnt,$x,$y) = (0,0,0);

my $flank_x = 100;
my $flank_y = 100;

$svg->rect(x=>100,y=>100,width=>990,height=>990,fill=>"black");

#foreach my $x(1..51)
#{
#	$svg->rect(x=>($flank_x + ($x-1)*20 - 10),y=>$flank_y,width=>10,height=>1000,fill=>"black");
#}

#foreach my $y(1..51)
#{
#	$svg->rect(x=>$flank_x ,y=>($flank_y + ($y-1)*20 - 10),width=>1000,height=>10,fill=>"black");
#}

foreach my $key(keys %hash)
{
	$x = $hash{$key}[0];
	$y = $hash{$key}[1];
	my $degree = $hash{$key}[2]/$max;
	#$svg->rect(x=>($flank_x + $x*20),y=>($flank_y+$y*20),width=>10,height=>10,fill=>"white");
	$svg->rect(x=>($flank_x + ($x-1)*20),y=>($flank_y+($y-1)*20),width=>10,height=>10,'opacity',$degree,fill=>"red");
}

print $svg->xmlify();
