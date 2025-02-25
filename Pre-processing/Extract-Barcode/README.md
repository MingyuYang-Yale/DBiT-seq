To extract Barcode A and Barcode B based on patterns rather than fixed positions, we first identify the linker sequence—a 30bp region located between the two barcodes. Once the linker is located, Barcode A and Barcode B can be extracted by retrieving the 8bp sequences immediately before and after the linker.

Since the linker is 30bp long, we allow up to 3 mismatches for tolerance. You can run the extraction using the following command:

```
conda create -y -n PERLLIB
```
```
conda activate PERLLIB
```
```
conda install -y bioconda::perl-perlio-gzip
```
```
perl extract-linker.v2.pl -indir ./ -outdir ./ -sample test
```

For this demonstration, we use a test dataset consisting of 10,000 reads, which is a subset of DBit-seq normal data.

Example output:
<p><img src="https://github.com/MingyuYang-Yale/DBiT-seq/blob/master/Pre-processing/Extract-Barcode/step1-output.png" alt="foo bar" title="train &amp; tracks" /></p>

- ```test.with.linker.R1.fq.gz``` and ```test.with.linker.R2.fq.gz``` is the Read2 with identified linker.

- ```test.without.linker.R1.fq.gz``` and ```test.without.linker.R2.fq.gz``` is the Read2 without identifiled linker, actually we can use this information to dig more to chat what happpend with this waste data.

In test.with.linker.R2.fq.gz file:

<p><img src="https://github.com/MingyuYang-Yale/DBiT-seq/blob/master/Pre-processing/Extract-Barcode/result.png" alt="foo bar" title="train &amp; tracks" /></p>

As shown in the result, the start position of the linker varies, appearing at positions 39, 40, and 41 in the test dataset.

Once the linker position is identified, the 8bp sequences immediately before and after the linker can be extracted and compared with our barcode sequences.

To extract the barcodes, run:
```
perl extract-barcodes-withlinker.v2.pl -indir ./ -outdir ./ -sample test
```
After running the scripts, you will find the following output files:
<p><img src="https://github.com/MingyuYang-Yale/DBiT-seq/blob/master/Pre-processing/Extract-Barcode/step2-output.png" alt="foo bar" title="train &amp; tracks" /></p>
 
- ```test.barcodes.R1.fq.gz``` and ```test.barcodes.R2.fq.gz``` contain the Reads with both barcode A and B.
- ```test.st.R1.fq.gz``` and ```test.st.R2.fq.gz``` is the st-pipeline ready files. 

  
A log file containing details number of barcode A and barcode B will also be generated in the output directory:

<p><img src="https://github.com/MingyuYang-Yale/DBiT-seq/blob/master/Pre-processing/Extract-Barcode/stat.png" alt="foo bar" title="train &amp; tracks" /></p>
