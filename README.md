# DBiT-seq

This is a public repository for all code connected to DBiT-Seq (microfluidic Deterministic Barcoding in Tissue for spatial omics sequencing).

**Please cite**: Yang et al. High-Spatial-Resolution Multi-Omics Atlas Sequencing of Mouse Embryos via Deterministic Barcoding in Tissue. bioRxiv 2019: doi: https://doi.org/10.1101/788992.

## Schematic workflow

<p><img src="https://github.com/MingyuYang-Yale/DBiT-seq/blob/master/workflow.png" alt="foo bar" title="train &amp; tracks" /></p>

All raw and processed files are available at GEO **(GSE137986)**

## Pre-processing
This is [code](https://github.com/MingyuYang-Yale/DBiT-seq/tree/master/Pre-processing) for reformating the read file for compatibility with st-pipeline.

Figure 2G: use the “st_qa.py” scripts in st-pipeline to do the quality assemssment

Figure 3B: Spatially variable genes generated by SpatialDE was used to conduct the clustering analysis, Non-negative matrix factorization(NMF) was performed using the NNLM pacakges in R, after the raw values were log-transformed, we chose k of 11 for the mouse embryo DBiT-seq transcriptome data obtained at a 50μm pixel size. For each pixel, the largest factor loading from NMF was used to assign cluster membership. NMF clustering of pixels was plotted by tSNE using the package “Rtsne” in R. 
