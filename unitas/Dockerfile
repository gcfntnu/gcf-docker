FROM gcfntnu/build-base

ENV UNITAS_VERSION 1.7.0
ENV PATH /opt/unitas/:$PATH

RUN apt-get update --fix-missing &&  apt-get install -y \
    bzip2 \
    perl \
    libarchive-extract-perl \
    cpanminus \
    gcc-multilib \
    dos2unix \
    sed && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN cpanm install LWP::Simple \
    File::Path \
    Archive::Zip \
    File::Copy \
    File::Basename \
    Getopt::Long \
    Archive::Extract \
    Scalar::Util


RUN wget --quiet http://www.smallrnagroup.uni-mainz.de/software/unitas_${UNITAS_VERSION}.zip
RUN unzip unitas_${UNITAS_VERSION}.zip -d /opt && rm unitas_${UNITAS_VERSION}.zip

WORKDIR /opt/unitas

RUN dos2unix unitas_${UNITAS_VERSION}.pl
RUN sed 's/head>30/head>1000/' unitas_${UNITAS_VERSION}.pl > unitas_${UNITAS_VERSION}.pl.mod
RUN sed -s 's/head,0,27/head,0,1000/' unitas_${UNITAS_VERSION}.pl.mod > unitas_${UNITAS_VERSION}.pl.mod2
RUN ln -s unitas_${UNITAS_VERSION}.pl.mod2 unitas.pl
RUN chmod +755 /opt/unitas/unitas*
