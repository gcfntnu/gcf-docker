FROM gcfntnu/python-base-conda:3.7

ENV TXIMPORT_VER 1.12.3
RUN conda install --quiet --yes \
    r-argparse \
    r-readr \
    r-matrix \
    bioconductor-dropletutils \
    bioconductor-tximport && \
    conda clean -tipsy
