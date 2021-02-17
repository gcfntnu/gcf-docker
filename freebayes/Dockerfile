FROM gcfntnu/python-base-conda:4.9.2

ENV FREEBAYES_VER 1.3.5
ENV SAMTOOLS_VER 1.11

RUN mamba install --quiet --yes \
    freebayes=$FREEBAYES_VER  \
    samtools=$SAMTOOLS_VER && \
    mamba clean --all
