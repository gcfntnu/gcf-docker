FROM gcfntnu/python-base-conda:4.8.2

COPY snp_mapping.yaml /tmp/env.yaml

RUN conda install --quiet --yes -c conda-forge -c bioconda bwa=0.7.17 samtools=1.7 bedtools=2.26.0 breseq=0.35.0 python=3.6.5

RUN pip install pysam


