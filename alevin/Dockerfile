FROM gcfntnu/python-base-conda:3.7

ENV SCANPY_VER 1.4
ENV SALMON_VER 0.13.1

RUN conda install --quiet --yes \
    scanpy=$SCANPY_VER \
    salmon=$SALMON_VER \
    gffread \
    gtfparse \
    argparse && \
    conda clean -tipsy

RUN pip --no-cache-dir install vpolo 

