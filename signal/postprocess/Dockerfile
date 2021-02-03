FROM gcfntnu/python-base-conda:4.8.2

COPY postprocessing.yaml /tmp/env.yaml

RUN mamba env update \
    -f /tmp/env.yaml && \
    mamba clean --all


