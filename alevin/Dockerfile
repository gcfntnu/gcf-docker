FROM gcfntnu/python-base-conda:4.10.3

ENV SCANPY_VER 1.7.2
ENV SALMON_VER 1.6.0

RUN conda install --quiet --yes mamba

RUN mamba install --quiet --yes \
    scanpy=$SCANPY_VER \
    salmon=$SALMON_VER \
    gffread \
    gtfparse 

RUN pip --no-cache-dir install vpolo 

