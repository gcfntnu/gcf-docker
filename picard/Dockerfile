FROM gcfntnu/python-base-conda:3.7

ENV PICARD_VER 2.18.27

RUN conda install --quiet --yes \
    picard=$PICARD_VER \
    openssl=1.0 \
    samtools && \
    conda clean -tipsy