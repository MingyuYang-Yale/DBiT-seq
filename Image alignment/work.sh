perl 1-position-matrix.pl 0725cL.tsv > 0725cL.svg
perl 2-position-under-tissure.pl 0725cL.tsv 0725cL.under.tissue.pixels-new.svg > 0725cL.under.tissue.positions.tsv
perl 3-expression-under-tissue.pl 0725cL.under.tissue.positions.tsv 0725cL.tsv > 0725cL.under.tissue.expression-matrix.tsv
