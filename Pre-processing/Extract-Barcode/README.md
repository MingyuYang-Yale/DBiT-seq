First, identify the linker sequence (a 30bp region between Barcode A and Barcode B). Once the linker is located, you can extract Barcode A and Barcode B by checking the 8bp sequences immediately before and after the linker.

Since the linker is 30bp long, we allow up to 3 mismatches for tolerance. You can run the extraction using the following command:

```
perl extract-linker.pl -indir ./ -outdir ./ -sample test
```
For this demonstration, we use a test dataset consisting of 10,000 reads, which is a subset of DBit-seq normal data.

Here is an example of the output:

<p><img src="https://github.com/MingyuYang-Yale/DBiT-seq/blob/master/Pre-processing/Extract-Barcode/result.png" alt="foo bar" title="train &amp; tracks" /></p>

As shown in the result, the start position of the linker varies, appearing at positions 39, 40, and 41 in the test dataset.

Once the linker is identified, Barcode A and Barcode B can be extracted by retrieving the 8bp sequences immediately before and after the linker.

To extract the barcodes, run:
```
perl extract-barcodes-withlinker.pl -indir ./ -outdir ./ -sample test
```
After running the script, you will find the output file:

A log file containing details number of barcode B and barcode B will also be generated in the output directory:

<p><img src="https://github.com/MingyuYang-Yale/DBiT-seq/blob/master/Pre-processing/Extract-Barcode/stat.png" alt="foo bar" title="train &amp; tracks" /></p>
