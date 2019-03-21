FROM debian:stretch-slim

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
    libc6-dev \
    man-db \
    autoconf \
    git \
    curl \
    wget \
    locales \
    zip \
    unzip \
    pkg-config && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN dpkg-reconfigure locales && \
    locale-gen C.UTF-8 && \
    /usr/sbin/update-locale LANG=C.UTF-8

ENV LC_ALL C.UTF-8