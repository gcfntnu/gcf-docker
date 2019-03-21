FROM gcfntnu/python-base:3.7

LABEL \
  author="Arnar Flatberg" \
  maintainer="arnar.flatberg@ntnu.no"

RUN \
  apt-get update && apt-get install -y --no-install-recommends \
  g++ && \
  rm -rf /var/lib/apt/lists/*

RUN pip install git+https://github.com/flatberg/MultiQC.git
