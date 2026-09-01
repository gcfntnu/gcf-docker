FROM ubuntu:22.04

ARG DEBIAN_FRONTEND=noninteractive
ARG HTSLIB_VERSION=1.22.1
ARG CELLSNP_LITE_VERSION=v1.2.4

RUN apt-get update && apt-get install -y --no-install-recommends \
        build-essential \
        autoconf \
        automake \
        libtool \
        pkg-config \
        ca-certificates \
        wget \
        git \
        zlib1g-dev \
        libbz2-dev \
        liblzma-dev \
        libcurl4-gnutls-dev \
        libssl-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /opt/src

# Build and install HTSlib.
# cellsnp-lite requires HTSlib >= 1.10.2; Bioconda's current cellsnp-lite
# recipe uses htslib 1.22.1, so this pins that version explicitly.
RUN wget -O htslib-${HTSLIB_VERSION}.tar.bz2 \
        https://github.com/samtools/htslib/releases/download/${HTSLIB_VERSION}/htslib-${HTSLIB_VERSION}.tar.bz2 \
    && tar -xjf htslib-${HTSLIB_VERSION}.tar.bz2 \
    && cd htslib-${HTSLIB_VERSION} \
    && ./configure --prefix=/usr/local \
    && make -j"$(nproc)" \
    && make install \
    && ldconfig \
    && cd /opt/src \
    && rm -rf htslib-${HTSLIB_VERSION} htslib-${HTSLIB_VERSION}.tar.bz2

# Build and install cellsnp-lite from the latest release tag.
RUN git clone --branch ${CELLSNP_LITE_VERSION} --depth 1 \
        https://github.com/single-cell-genetics/cellsnp-lite.git \
    && cd cellsnp-lite \
    && autoreconf -iv \
    && ./configure --prefix=/usr/local --with-htslib=/usr/local \
    && make -j"$(nproc)" \
    && make install \
    && cd /opt/src \
    && rm -rf cellsnp-lite \
    && ldconfig

WORKDIR /data

RUN cellsnp-lite --help >/dev/null

ENTRYPOINT ["cellsnp-lite"]
CMD ["--help"]