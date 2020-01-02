FROM ubuntu:19.10

RUN set -ex

RUN apt-get update && apt-get install -y --no-install-recommends \
    make \
    automake \
    cmake \
    gcc \
    build-essential \
    gfortran \
    g++ \
    cpp \
    zlib1g-dev \
    libc6-dev \
    man-db \
    autoconf \
    git \
    curl \
    wget \
    locales \
    zip \
    unzip \
    ca-certificates \
    pkg-config && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*
