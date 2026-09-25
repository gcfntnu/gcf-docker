FROM gcfntnu/build-base:22.04

ENV BCL_CONVERT_VERSION=4.2.4

RUN apt-get update --fix-missing && apt-get install -y alien && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

COPY files/bcl-convert-$BCL_CONVERT_VERSION-2.el7.x86_64.rpm /tmp/
RUN alien -i /tmp/bcl-convert-$BCL_CONVERT_VERSION-2.el7.x86_64.rpm
