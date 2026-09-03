FROM gcfntnu/r-base-conda:4.5.3

ARG ORTHOGENE_VERSION=1.16.1
ARG SCHARD_COMMIT=f9c30c25a192175a1e6523e32f0e2047de1e8685

RUN conda install --quiet --yes \
    bioconductor-orthogene=${ORTHOGENE_VERSION} \
    bioconductor-rhdf5 \
    r-argparse \
    r-remotes && \
    conda clean --all --yes

RUN Rscript -e "remotes::install_github('cellgeni/schard@${SCHARD_COMMIT}', dependencies=FALSE, upgrade='never')"

RUN Rscript -e "stopifnot(packageVersion('orthogene') == '${ORTHOGENE_VERSION}'); library(orthogene); library(schard); library(argparse); library(Matrix); library(rhdf5)"
