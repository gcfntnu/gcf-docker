FROM python:3.11-slim@sha256:673719e071ecf27434fd2635bbd8d00f49f4fdd81f243143438a42ced8bedf60

LABEL org.opencontainers.image.title="GCF MultiQC" \
      org.opencontainers.image.description="Upstream MultiQC 1.35 with GCF reporting compatibility extensions" \
      org.opencontainers.image.source="https://github.com/gcfntnu/gcf-multiqc" \
      org.opencontainers.image.revision="2f3544db306d81df7d392321a851cc914783c74f" \
      org.opencontainers.image.version="1.35-gcf0.1.0-rc1" \
      org.opencontainers.image.licenses="GPL-3.0-or-later"

# Lock targets CPython 3.11 on Linux amd64, including the build backend.
COPY requirements.lock /opt/gcf-multiqc/requirements.lock
RUN python -m pip install --no-cache-dir --only-binary=:all: --require-hashes \
      -r /opt/gcf-multiqc/requirements.lock

# Source archive and checksum are immutable release inputs; no moving fork branch.
ADD --checksum=sha256:5001dfcd33827c7c58539217738d223ddda4693cc47c90a05463dd80169dbf4b \
    https://github.com/gcfntnu/gcf-multiqc/archive/2f3544db306d81df7d392321a851cc914783c74f.tar.gz \
    /tmp/gcf-multiqc.tar.gz
RUN python -m pip install --no-cache-dir --no-deps --no-build-isolation /tmp/gcf-multiqc.tar.gz \
    && python -m pip check \
    && rm /tmp/gcf-multiqc.tar.gz

COPY files/logo_ntnu.png /opt/images/logo_ntnu.png
ENV PYTHONUNBUFFERED=1
WORKDIR /work

# No ENTRYPOINT: preserve the existing container-wrapper command convention.
CMD ["multiqc", "--help"]
