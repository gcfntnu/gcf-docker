FROM gcfntnu/r-base-conda:4.5.3

ENV ORTHOGENE_BUILD=1.16.1

ARG ORTHOGENE_VERSION=1.16.1
ARG SCHARD_COMMIT=f9c30c25a192175a1e6523e32f0e2047de1e8685

# Keep R and conda of gcfntnu/r-base-conda:4.5.3 (an unpinned install can upgrade conda and
# break its bundled plugins).
RUN conda install --quiet --yes \
    conda=26.7.1 \
    r-base=${R_VER} \
    bioconductor-orthogene=${ORTHOGENE_VERSION} \
    bioconductor-rhdf5 \
    r-argparse \
    r-remotes && \
    conda clean --all --yes

RUN Rscript -e "remotes::install_github('cellgeni/schard@${SCHARD_COMMIT}', dependencies=FALSE, upgrade='never')"

RUN ! conda list 2>&1 | grep -qi "error while loading" && \
    test "$(Rscript -e 'cat(as.character(getRversion()))')" = "${R_VER}" && \
    Rscript -e "stopifnot(packageVersion('orthogene') == '${ORTHOGENE_VERSION}'); library(orthogene); library(schard); library(argparse); library(Matrix); library(rhdf5)"
