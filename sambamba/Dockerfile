FROM gcfntnu/python-base-conda:3.7

ENV SAMBAMBA_VER 0.7

RUN conda install --quiet --yes \
    sambamba=$SAMBAMBA_VER \
    argparse && \
    conda clean -tipsy
