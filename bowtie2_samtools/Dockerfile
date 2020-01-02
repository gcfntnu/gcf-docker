FROM gcfntnu/python-base-conda:3.7

ENV BOWTIE2_VER 2.3.5
ENV SAMTOOLS_VER 1.10

RUN apt-get update 

RUN conda install --quiet --yes \
    bowtie2=$BOWTIE2_VER \
    samtools=$SAMTOOLS_VER && \
    conda clean -tipsy
