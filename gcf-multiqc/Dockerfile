FROM python:3.11-slim@sha256:673719e071ecf27434fd2635bbd8d00f49f4fdd81f243143438a42ced8bedf60 AS runtime

# Kaleido's bundled renderer needs these shared libraries and actual fonts.
# The flat-report regression runs inside the built image before publication.
RUN apt-get update \
    && apt-get install -y --no-install-recommends procps libnss3 libexpat1 fonts-dejavu-core \
    && rm -rf /var/lib/apt/lists/*

# Lock targets CPython 3.11 on Linux amd64, including the build backend.
COPY requirements.lock /opt/gcf-multiqc/requirements.lock
RUN python -m pip install --no-cache-dir --only-binary=:all: --require-hashes \
      -r /opt/gcf-multiqc/requirements.lock

FROM runtime AS plugin-build

# Source archive and checksum are immutable release inputs; no moving fork branch.
ADD --checksum=sha256:24fb1d53dfb14b98e37cdb6e13fd06ce8b2271279038ab3aea34f1f4b1127b41 \
    https://github.com/gcfntnu/gcf-multiqc/archive/4625e75315f5c89475af5ce70313642f4154ce40.tar.gz \
    /tmp/gcf-multiqc.tar.gz
RUN python -m pip wheel --no-cache-dir --no-deps --no-build-isolation \
      --wheel-dir /dist /tmp/gcf-multiqc.tar.gz

# Copy only the built distribution, keeping source archives and test fixtures
# out of the published image layers as well as its final filesystem.
FROM runtime

LABEL org.opencontainers.image.title="GCF MultiQC" \
      org.opencontainers.image.description="Upstream MultiQC 1.35 with GCF reporting compatibility extensions" \
      org.opencontainers.image.source="https://github.com/gcfntnu/gcf-multiqc" \
      org.opencontainers.image.revision="4625e75315f5c89475af5ce70313642f4154ce40" \
      org.opencontainers.image.version="1.35-gcf0.1.0-rc4" \
      org.opencontainers.image.licenses="GPL-3.0-or-later"

COPY --from=plugin-build /dist/ /tmp/gcf-wheel/
RUN python -m pip install --no-cache-dir --no-deps /tmp/gcf-wheel/*.whl \
    && python -m pip check \
    && rm -rf /tmp/gcf-wheel

COPY files/logo_ntnu.png /opt/images/logo_ntnu.png
ENV PYTHONUNBUFFERED=1
WORKDIR /work

# No ENTRYPOINT: preserve the existing container-wrapper command convention.
CMD ["multiqc", "--help"]
