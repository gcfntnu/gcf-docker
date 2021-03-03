FROM gcfntnu/python-base-conda:3.7

RUN set -ex

ENV SEQBUSTER_VER 3.5

RUN apt-get install libxml2-dev

RUN conda install --quiet --yes \
    mirtop \
    seqcluster \
    r-argparse \
    bioconductor-isomirs \
    seqbuster==$SEQBUSTER_VER && \
    conda clean -tipsy

RUN R --slave -e "BiocManager::install(rownames(installed.packages()), type='source', checkBuilt=TRUE)"
