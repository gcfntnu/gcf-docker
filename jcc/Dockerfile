
FROM rocker/tidyverse:3.5.1

# use C.UTF-8 locale 
ENV LANG=C.UTF-8 LC_ALL=C.UTF-8

RUN apt-get update --fix-missing && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
    bzip2 \
    ca-certificates \
    build-essential \
    fonts-dejavu \
    libudunits2-dev \
    gfortran \
    git \
    unzip \
    python-dev \
    python-pip \
    python-virtualenv && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN ln -s /bin/tar /bin/gtar
RUN R --slave -e "options(unzip='/usr/bin/unzip')"
RUN R --slave -e "devtools::install_github(repo = 'csoneson/jcc')"
