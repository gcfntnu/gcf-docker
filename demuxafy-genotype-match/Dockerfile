FROM rocker/r-ver:4.4.1

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        libcurl4-openssl-dev \
        libssl-dev \
        libxml2-dev \
        libfontconfig1-dev \
        libfreetype6-dev \
        libpng-dev \
        libtiff5-dev \
        libjpeg-dev \
        libharfbuzz-dev \
        libfribidi-dev \
        libgit2-dev && \
    rm -rf /var/lib/apt/lists/*

RUN R -e "install.packages(c( \
        'argparse', \
        'dplyr', \
        'tidyr', \
        'readr', \
        'tibble', \
        'vcfR', \
        'BiocManager' \
    ), repos='https://cloud.r-project.org')" && \
    R -e "BiocManager::install('ComplexHeatmap', ask=FALSE, update=FALSE)"

COPY Assign_Indiv_by_Geno_droplet.R /usr/local/bin/Assign_Indiv_by_Geno.R

RUN chmod +x /usr/local/bin/Assign_Indiv_by_Geno.R

ENTRYPOINT []