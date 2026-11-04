FROM gcfntnu/build-base:22.04

# unitas 1.8.0 with GCF fixes (image tag 1.8.0-1), see unitas-1.8.0-1.patch.
#
# The upstream host (www.smallrnagroup.uni-mainz.de) is gone, so the script and SeqMap are
# supplied locally in files/ (git-ignored; local builds only):
#   files/unitas_1.8.0.pl  copy from the published image:
#       docker create --name u gcfntnu/unitas:1.8.0 && docker cp u:/opt/unitas/unitas_1.8.0.pl files/ && docker rm u
#   files/seqmap.exe       SeqMap 1.0.13 x86-64 Linux build (needs glibc >= 2.29)
#
# Annotation runs are offline: provide UNITAS_refdump_<species> in the working directory;
# seqmap.exe is picked up from PATH. Reference downloads and -riborase exit with an error.
# -refdump only works with -mirror DIR (a local copy of the old server layout); use
# unitas_build_refdump.sh to build reference dumps from Ensembl, GtRNAdb and miRBase.

ENV UNITAS_VERSION=1.8.0
ENV UNITAS_BUILD=1.8.0-1
ENV PATH=/opt/unitas:$PATH

RUN apt-get update --fix-missing && apt-get install -y \
    bzip2 \
    perl \
    libssl-dev \
    libarchive-extract-perl \
    cpanminus \
    gcc-multilib \
    dos2unix \
    patch \
    sed && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN cpanm LWP::Simple \
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
COPY files/unitas_${UNITAS_VERSION}.pl files/seqmap.exe unitas-${UNITAS_BUILD}.patch unitas_build_refdump.sh ./
RUN dos2unix unitas_${UNITAS_VERSION}.pl
# Legacy header-length patches (already present in the script from gcfntnu/unitas:1.8.0; no-ops then)
RUN sed -i 's/head>30/head>1000/; s/head,0,27/head,0,1000/' unitas_${UNITAS_VERSION}.pl
RUN patch unitas_${UNITAS_VERSION}.pl < unitas-${UNITAS_BUILD}.patch \
    && rm unitas-${UNITAS_BUILD}.patch \
    && perl -c unitas_${UNITAS_VERSION}.pl
RUN ln -s unitas_${UNITAS_VERSION}.pl unitas.pl \
    && chmod 755 /opt/unitas/unitas* /opt/unitas/seqmap.exe \
    && seqmap.exe 2>&1 | grep -q 'SeqMap: Short Sequence Mapping Tool'
