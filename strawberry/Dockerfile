FROM debian:jessie-slim

MAINTAINER Arnar Flatberg <arnar.flatberg@ntnu.no>

ENV STRAWBERRY_VERSION 1.0.2

RUN set -ex

RUN apt-get update && apt-get install -y --no-install-recommends wget samtools && \
    mkdir -p /home/bin && cd /home/bin && \
    wget --no-check-certificate https://github.com/ruolin/strawberry/releases/download/$STRAWBERRY_VERSION/strawberry && \
    chmod +x strawberry && \
    apt-get clean 

ENV PATH /home/bin:${PATH}