reference = "/staging/leuven/stg_00079/teaching/hg19_9/chr9.fa"

samples, = glob_wildcards("000.fastq/{sample}.fastq")

snpeff_jar = ("/data/leuven/306/vsc30690/miniconda3/"
              + "pkgs/snpeff-5.0-hdfd78af_1/share/snpeff-5.0-1/snpEff.jar")

snpeff_db_folder = "/staging/leuven/stg_00079/teaching/snpeff_db/"


rule all:
    input:
        fastqc_zip = expand("010.fastqc/{sample}_fastqc.zip",
                          sample=samples),
        vcf = "050.snpeff/snps.annotated.vcf",
	indelplot = "060.stats/indels.0.png"

rule fastqc:
    input:
        fq = "000.fastq/{sample}.fastq"

    output:
        zip = "010.fastqc/{sample}_fastqc.zip",
        html = "010.fastqc/{sample}_fastqc.html"

    shell:
        """
        echo "Input Fastq: {input.fq} "
        fastqc -o 010.fastqc {input.fq}
        """

rule bwa:
    input:
        fq = "000.fastq/{name}.fastq",

    output:
        bam = "020.bwa/{name}.bam",
        bai = "020.bwa/{name}.bam.bai",

    params:
        ref = reference,

    shell:
        """
        bwa mem {params.ref} {input.fq} \
            | samtools sort - \
            > {output.bam}
        samtools index {output.bam}
        """

rule variant_calling:
    input:
        ref = reference,
        bams = expand("020.bwa/{name}.bam", name=samples),

    output:
        vcf = "030.samtools/snps.vcf",

    shell:
        """
        bcftools mpileup -Ou -f {input.ref} {input.bams} \
             | bcftools call -mv -Ov -o {output.vcf}
        """


rule variant_cleanup:
    input:
        ref = reference,
        vcf = "030.samtools/snps.vcf"

    output:
        vcf = "040.cleaned/snps.cleaned.vcf"

    shell:
        """
        ( cat {input.vcf} \
           | vt decompose - \
           | vt normalize -n -r {input.ref} - \
           | vt uniq - \
           | vt view -f "QUAL>20" -h - \
           > {output.vcf} )
        """

rule snpeff:
    input:
        vcf = "040.cleaned/snps.cleaned.vcf",

    params:
        snpeff_db_folder = snpeff_db_folder,
        snpeff_jar = snpeff_jar,

    log:
        err = "050.snpeff/snakemake.err",

    output:
        vcf = "050.snpeff/snps.annotated.vcf",
        html = "050.snpeff/snpEff_summary.html",
        genetxt = "050.snpeff/snpEff_genes.txt",

    shell:
        """
        mkdir -p 050.snpeff

        java -Xmx4096m -jar \
            {params.snpeff_jar} eff GRCh38.99 \
            -dataDir {params.snpeff_db_folder} \
            {input.vcf} > {output.vcf}

        # move output files to the snpeff output folder
        mv snpEff_genes.txt snpEff_summary.html 050.snpeff
        """

rule stats:
    input:
        vcf = "050.snpeff/snps.annotated.vcf",

    output:
        stats = "060.stats/snps.stats",
        indelplot = "060.stats/indels.0.png",
	
    shell:
        """
        mkdir -p 060.stats

        bcftools stats -s - {input.vcf} > {output.stats}

        plot-vcfstats -P -p 060.stats {output.stats}
        """
