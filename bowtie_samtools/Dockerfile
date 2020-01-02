FROM gcfntnu/python-base-conda:3.7

ENV BOWTIE_VER 1.2.3
ENV SAMTOOLS_VER 1.10

RUN apt-get update 

RUN conda install --quiet --yes \
    bowtie=$BOWTIE_VER \
    samtools=$SAMTOOLS_VER && \
    conda clean -tipsy
