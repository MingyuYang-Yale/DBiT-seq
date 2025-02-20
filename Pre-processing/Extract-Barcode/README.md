First, identify the linker sequence (a 30bp region between Barcode A and Barcode B). Once the linker is located, you can extract Barcode A and Barcode B by checking the 8bp sequences immediately before and after the linker.

Since the linker is 30bp long, we allow up to 3 mismatches for tolerance. You can run the extraction using the following command:

```
perl extract-linker.pl -indir ./ -outdir ./ -sample test
```

Here is an example of the output:

<p><img src="https://github.com/MingyuYang-Yale/DBiT-seq/blob/master/Pre-processing/Extract-Barcode/result.png" alt="foo bar" title="train &amp; tracks" /></p>

As shown in the result, the start position of the linker varies, appearing at positions 39, 40, and 41 in the test dataset.

Then we can extract the barcode A and B before and after the linker:
```
perl step2-extract-barcode-ab-withlinker.pl -indir ./ -outdir ./ -sample test
```
<p><img src="https://github.com/MingyuYang-Yale/DBiT-seq/blob/master/Pre-processing/Extract-Barcode/stat.png" alt="foo bar" title="train &amp; tracks" /></p>
