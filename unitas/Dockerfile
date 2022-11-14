FROM gcfntnu/build-base

ENV UNITAS_VERSION 1.7.9
ENV PATH /opt/unitas/:$PATH

RUN apt-get update --fix-missing &&  apt-get install -y \
    bzip2 \
    perl \
    libssl-dev \
    libarchive-extract-perl \
    cpanminus \
    gcc-multilib \
    dos2unix \
    sed && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN cpanm install LWP::Simple \
    LWP::UserAgent \
    Net::SSLeay \
    File::Path \
    Archive::Zip \
    File::Copy \
    File::Basename \
    Getopt::Long \
    Archive::Extract \
    LWP::Protocol::https \
    Scalar::Util

WORKDIR /opt/unitas
RUN wget --no-check-certificate https://www.smallrnagroup.uni-mainz.de/software/unitas_${UNITAS_VERSION}.pl
RUN dos2unix unitas_${UNITAS_VERSION}.pl
RUN sed -i 's/head>30/head>1000/' unitas_${UNITAS_VERSION}.pl 
RUN sed -i 's/head,0,27/head,0,1000/' unitas_${UNITAS_VERSION}.pl
RUN sed -i 's/head,0,27/head,0,1000/' unitas_${UNITAS_VERSION}.pl
#RUN sed -i 's/ensemblgenomes_release\=35/ensemblgenomes_release\=52/' unitas_${UNITAS_VERSION}.pl
#RUN sed -i 's/ensembl_release\=88/ensembl_release\=105/' unitas_${UNITAS_VERSION}.pl
RUN ln -s unitas_${UNITAS_VERSION}.pl unitas.pl
RUN chmod +755 /opt/unitas/unitas*
