FROM gcfntnu/python-base-conda:4.8.2

ENV BWA_VER 0.7.17
ENV SAMTOOLS_VER 1.11

RUN mamba install --quiet --yes \
    bwa=$BWA_VER \
    samtools=$SAMTOOLS_VER && \
    mamba clean --all
