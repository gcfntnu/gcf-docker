FROM ubuntu:22.04

RUN set -ex
ENV TZ=Europe/Oslo
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

RUN apt-get update && apt-get install -y --no-install-recommends \
    python3-dev \
    autotools-dev \
    openssh-client \
    libicu-dev \
    libbz2-dev \
    make \
    automake \
    cmake \
    gcc \
    build-essential \
    gfortran \
    haskell-stack \
    g++ \
    cpp \
    zlib1g-dev \
    libc6-dev \
    libcairo2-dev \
    libpango1.0-dev \
    man-db \
    autoconf \
    git \
    curl \
    wget \
    locales \
    zip \
    unzip \
    ca-certificates \
    subversion \
    pip \
    pkg-config && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*
