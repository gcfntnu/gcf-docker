FROM gcfntnu/python-base-conda:3.11

LABEL \
  author="Arnar Flatberg" \
  maintainer="arnar.flatberg@ntnu.no"

RUN mkdir /opt/images
ADD files/logo_ntnu.png /opt/images/logo_ntnu.png

RUN \
  apt-get update && apt-get install -y --no-install-recommends \
  g++ && \
  rm -rf /var/lib/apt/lists/*

RUN conda install -y pandas

ARG MULTIQC_BRANCH=bfq-dev
ADD https://api.github.com/repos/gcfntnu/MultiQC/git/refs/heads/$MULTIQC_BRANCH multiqc_version
RUN pip install https://github.com/gcfntnu/MultiQC/archive/$MULTIQC_BRANCH.zip
