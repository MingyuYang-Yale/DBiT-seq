There are two ways to get BarcodeA and BarcodeB based on patterns rather than fixed positions:

1. You can extract the linker (the strings between Barcode A and Barcode B, 30bp) first, then you can check the before 8bp and after 8bp, to extract the barcode A and B.
Since the linker is 30bp length, we can tolerate 3 mismatchs. you can run the code by the following command:
```
perl extract-linker-public.pl -indir ./ -outdir ./ -sample test
```
Here is the result:
<p><img src="https://github.com/MingyuYang-Yale/DBiT-seq/blob/master/Pre-processing/Extract-Barcode/result.png" alt="foo bar" title="train &amp; tracks" /></p>
you can see, the start position of the linker is different, you can find 39,40,41 in the test result
