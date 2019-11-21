# DBiT-seq

This is a public repository for all code connected to DBiT-Seq (microfluidic Deterministic Barcoding in Tissue for spatial omics sequencing).

**Please cite**: Yang et al. High-Spatial-Resolution Multi-Omics Atlas Sequencing of Mouse Embryos via Deterministic Barcoding in Tissue. bioRxiv 2019: doi: https://doi.org/10.1101/788992.

## Schematic workflow

<p><img src="https://github.com/MingyuYang-Yale/DBiT-seq/blob/master/workflow.png" alt="foo bar" title="train &amp; tracks" /></p>

All raw and processed files are available at GEO **(GSE137986)**

## Pre-processing
This is [code](https://github.com/MingyuYang-Yale/DBiT-seq/tree/master/Pre-processing) for quality control and reformating the read file for compatibility with st-pipeline.

In our datasets, read2 contains the barcode and UMI, so we need to reformat the read file for compatibility with st-pipeline.
<p><img src="https://github.com/MingyuYang-Yale/DBiT-seq/blob/master/Pre-processing/schematic.png" alt="foo bar" title="train &amp; tracks" /></p>

To reformat the read file, run

```
perl reformat.pl -indir 01.rawdata -outdir 02.reformatdata -sample 10t
```
To run the st-pipeline to get the matrix file, run:

```
sample=$1
FW=/02.effectivedata/$sample/$sample.R1.fastq.gz
RV=/02.effectivedata/$sample/$sample.R2.fastq.gz
MAP=/database/GRCm38_86/StarIndex
ANN=/database/GRCm38_86/gencode.vM11.annotation.gtf
CONT=/database/GRCm38_86/ncRNA/StarIndex
ID=barcodes.xls
OUTPUT=/03.stpipeline/$sample
mkdir -p /03.stpipeline/$sample
TMP=/03.stpipeline/$sample/tmp
mkdir -p /03.stpipeline/$sample/tmp
EXP=$sample

st_pipeline_run.py \
  --output-folder $OUTPUT \
  --temp-folder $TMP \
  --umi-start-position 16 \
  --umi-end-position 26 \
  --ids $ID \
  --ref-map $MAP \
  --ref-annotation $ANN \
  --expName $EXP \
  --htseq-no-ambiguous \
  --verbose \
  --mapping-threads 16 \
  --log-file $OUTPUT/${EXP}_log.txt \
  --two-pass-mode \
  --no-clean-up \
  --contaminant-index $CONT \
  --disable-clipping \
  --min-length-qual-trimming 30 \
  $FW $RV

```

## Differential expression
This is [code](https://github.com/MingyuYang-Yale/DBiT-seq/tree/master/Differential%20expression) for differential expression analysis.

Figure 2G: use the “st_qa.py” scripts in st-pipeline to do the quality assemssment

Figure 3B: Spatially variable genes generated by SpatialDE was used to conduct the clustering analysis, Non-negative matrix factorization(NMF) was performed using the NNLM pacakges in R, after the raw values were log-transformed, we chose k of 11 for the mouse embryo DBiT-seq transcriptome data obtained at a 50μm pixel size. For each pixel, the largest factor loading from NMF was used to assign cluster membership. NMF clustering of pixels was plotted by tSNE using the package “Rtsne” in R. 

