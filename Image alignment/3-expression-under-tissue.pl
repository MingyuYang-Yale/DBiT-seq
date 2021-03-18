#!/usr/bin/perl
use warnings;
use strict;

my %selected;


open IN,"$ARGV[0]" or die $!;
while(<IN>)
{
        chomp;
        my @array = split /\t/,$_;
        $selected{"$array[0]x$array[1]"} = 1;
}
close IN;

open IN,"$ARGV[1]" or die $!; #50t_stdata.updated.tsv
my $header = <IN>;
print $header;
while(<IN>)
{
        chomp;
        my @array = split /\t/,$_;
        if(exists $selected{$array[0]})
        {
                print "$_\n";
        }
}
close IN;
