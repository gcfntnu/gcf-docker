FROM gcfntnu/python-base-conda:4.10.3

ENV R_VER 4.1.1

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    fonts-dejavu \
    libxml2-dev \
    unixodbc \
    unixodbc-dev \
    gfortran \
    gcc && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

RUN mamba install --quiet --yes -v -v \
    mscorefonts \
    font-ttf-ubuntu \
    r-base==$R_VER \
    r-rcurl \
    r-xml \
    r-cairo \
    r-optparse \
    r-tidyverse \
    r-devtools \
    r-ggplot2 \
    r-ggpubr \
    r-biocmanager && \
    mamba clean -a

RUN ln -s /bin/tar /bin/gtar
RUN R --slave -e "options(unzip='/usr/bin/unzip')"