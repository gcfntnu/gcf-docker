FROM gcfntnu/python-base-conda:3.7

ENV PICARD_VER 2.21.4
ENV GATK4_VER 4.1.4.1 

RUN apt-get update --fix-missing && apt-get install -y libxext6

RUN conda install --quiet --yes \
    picard=$PICARD_VER \
    gatk4=$GATK_VER \
    openssl=1.0 \
    xorg-libxtst \
    samtools && \
    conda clean -tipsy