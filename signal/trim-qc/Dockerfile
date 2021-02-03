FROM gcfntnu/python-base-conda:4.8.2

COPY trim_qc.yaml /tmp/env.yaml

RUN mamba install --quiet --yes -c bioconda -c conda-forge fastqc=0.11.9 trim-galore=0.6.5 kraken2=2.0.9beta 


