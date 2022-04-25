# Snakemake

Simple snakemake pipeline for SNP calling.

# Required tools: <br />
fastqc <br />
bwa mem <br />
samtools <br />
bcftools <br />
vt <br />
snpEff <br />


# Steps:
1. FASTQ Quality check: <br />
Run Snakefile_fastqc
2. Align the reads: <br />
Run Snakefile_bam
3. Create indici: <br />
Run Snakefile_bai <br />
# TODO: <br />
SNP Calling using bcftools <br />
SNP filtering & cleaning using vt <br />
Snp Annotation using SnpEff <br />
Merge snakefiles into one!
