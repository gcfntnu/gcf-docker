# Doublet detection for gcf-workflows singlecell (gcfntnu/gcf-docker#11).
#
# Built on gcfntnu/scanpy:1.12.3, so that it reads the .h5ad files the other single-cell images
# write (one scanpy/anndata version across the gcf-workflows images). The base's Python packages are
# kept exactly: doubletdetection is installed with pip constrained to them, and R lives in its own
# conda environment. The build fails if anndata, scanpy, pandas or numpy differ from the base.
#
#   Python: doubletdetection (run_doubletdetection.py), scanpy's Scrublet (run_scanpy_scrublet.py),
#           marsilea for the dashboard PDF of doublet_rank_aggr.py
#   R:      scds, scDblFinder, TENxIO, argparse (scds.R, scdblfinder.R)
#
# Resolved versions: packages.txt (Python, pip list) and r-packages.txt (R environment, conda list).
FROM gcfntnu/scanpy:1.12.3@sha256:b386644bbe0ec72ea9b55fd4da9bf03f676b8247d1b89959dadce4c85e9ff309

ENV DOUBLETDETECTION_VER=4.3.0.post1 \
    MARSILEA_VER=0.8.1 \
    DOUBLET_DETECTION_BUILD=4.3.0.post1 \
    SCANPY_BASE_VERSIONS="scanpy==1.12.3 anndata==0.13.3.post0 pandas==3.0.5 numpy==2.5.2"

RUN apt-get update && \
    apt-get install --yes --no-install-recommends libgomp1 && \
    rm -rf /var/lib/apt/lists/*

# Python: keep every package of the base at its version
RUN pip list --format=freeze > /opt/scanpy-base-packages.txt \
    && pip install --no-cache-dir -c /opt/scanpy-base-packages.txt \
        "doubletdetection==${DOUBLETDETECTION_VER}" "marsilea==${MARSILEA_VER}"

# R in its own environment
COPY env-r.yml /tmp/env-r.yml
RUN conda env create --file /tmp/env-r.yml \
    && rm /tmp/env-r.yml \
    && ln -s /opt/miniconda3/envs/r/bin/R /opt/miniconda3/envs/r/bin/Rscript /usr/local/bin/ \
    && conda clean -afy \
    && find /opt/miniconda3/ -follow -type f -name '*.a' -delete \
    && find /opt/miniconda3/ -follow -type f -name '*.js.map' -delete

# Build-time checks: the base's versions, the Python tools and the R packages
RUN pip list --format=freeze > /tmp/packages.txt \
    && for p in ${SCANPY_BASE_VERSIONS}; do grep -qixF "$p" /tmp/packages.txt || { echo "expected $p" >&2; exit 1; }; done \
    && rm /tmp/packages.txt \
    && python -c "import doubletdetection, scanpy as sc; from doubletdetection import BoostClassifier; assert callable(sc.external.pp.scrublet)" \
    && python -c "import marsilea, seaborn, scipy.stats; from marsilea.upset import UpsetData, Upset" \
    && Rscript -e 'for (p in c("argparse", "TENxIO", "scds", "scDblFinder", "SingleCellExperiment", "BiocParallel", "Matrix")) suppressPackageStartupMessages(library(p, character.only = TRUE))' \
    && Rscript -e 'library(argparse); invisible(ArgumentParser()$parse_args(character(0)))'
