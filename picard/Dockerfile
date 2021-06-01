FROM gcfntnu/python-base-conda:4.8.2

ENV PICARD_VER 2.21.5
ENV GATK4_VER 4.2.0.0 

RUN apt-get update --fix-missing && apt-get install -y libxext6

RUN mamba install --quiet --yes \
    picard=$PICARD_VER \
    gatk4=$GATK_VER \
    openssl \
    xorg-libxtst \
    samtools && \
    mamba clean --all