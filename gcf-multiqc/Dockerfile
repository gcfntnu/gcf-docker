FROM python:3.11-slim@sha256:673719e071ecf27434fd2635bbd8d00f49f4fdd81f243143438a42ced8bedf60

LABEL org.opencontainers.image.title="GCF MultiQC" \
      org.opencontainers.image.description="Upstream MultiQC 1.35 with GCF reporting compatibility extensions" \
      org.opencontainers.image.source="https://github.com/gcfntnu/gcf-multiqc" \
      org.opencontainers.image.revision="fb2489428bef8ac182e9ba460e66af1dc6ed47b5" \
      org.opencontainers.image.version="1.35-gcf0.1.0-rc1" \
      org.opencontainers.image.licenses="GPL-3.0-or-later"

# Lock targets CPython 3.11 on Linux amd64, including the build backend.
COPY requirements.lock /opt/gcf-multiqc/requirements.lock
RUN python -m pip install --no-cache-dir --only-binary=:all: --require-hashes \
      -r /opt/gcf-multiqc/requirements.lock

# Source archive and checksum are immutable release inputs; no moving fork branch.
ADD --checksum=sha256:4cf2007026b8951dfcce86ad7ac2d96846fa87a257d0bd828d3365d968dd2a70 \
    https://github.com/gcfntnu/gcf-multiqc/archive/fb2489428bef8ac182e9ba460e66af1dc6ed47b5.tar.gz \
    /tmp/gcf-multiqc.tar.gz
RUN python -m pip install --no-cache-dir --no-deps --no-build-isolation /tmp/gcf-multiqc.tar.gz \
    && python -m pip check \
    && rm /tmp/gcf-multiqc.tar.gz

COPY files/logo_ntnu.png /opt/images/logo_ntnu.png
ENV PYTHONUNBUFFERED=1
WORKDIR /work

# No ENTRYPOINT: preserve the existing container-wrapper command convention.
CMD ["multiqc", "--help"]
