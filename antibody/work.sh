#!/bin/bash
#SBATCH --partition=scavenge
#SBATCH --mail-type=END
#SBATCH -o S.SRR3382388.sra.%j.out
#SBATCH -e S.SRR3382388.sra.%j.err
#SBATCH --mail-user=mingyu.yang@yale.edu
#SBATCH --job-name=genomeGenerate
#SBATCH --ntasks=1 --cpus-per-task=16
#SBATCH --mem-per-cpu=4g 
#SBATCH --time=120:00:00

/gpfs/ysm/project/my393/software/STAR/source/STAR --runThreadN 16 --runMode genomeGenerate --genomeDir /gpfs/ysm/project/my393/database/antibody/StarIndex --genomeFastaFiles /gpfs/ysm/project/my393/database/antibody/antibody.fa --sjdbGTFfile /gpfs/ysm/project/my393/database/antibody/genecode.gtf --genomeSAindexNbases 3

