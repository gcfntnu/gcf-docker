FROM gcfntnu/python-base-conda:3.12

# R from conda-forge. Stay on R 4.5 until bioconda's Bioconductor packages and conda-forge's
# r-* packages are built for R 4.6 (as of November 2026 they are built for 4.5 only).
ENV R_VER=4.5.3
ENV R_HOME=/opt/miniconda3/lib/R

RUN apt-get update && \
    apt-get install --yes --no-install-recommends libgomp1 && \
    rm -rf /var/lib/apt/lists/*

# Keep the conda of gcfntnu/python-base-conda:3.12; without this pin the install upgrades conda
# and breaks its bundled conda-anaconda-tos and conda-anaconda-telemetry plugins.
RUN conda install --quiet --yes \
    conda=26.7.1 \
    r-base=${R_VER} \
    r-biocmanager && \
    conda clean --all --yes

RUN test "$(Rscript -e 'cat(as.character(getRversion()))')" = "${R_VER}" && \
    ! conda list 2>&1 | grep -qi "error while loading" && \
    Rscript -e 'library(BiocManager); cat("BiocManager", as.character(packageVersion("BiocManager")), "\n")'
