FROM gcfntnu/python-base-conda:4.8.2

ENV STAR_VERSION 2.7.5c

RUN mamba install --quiet --yes \
    star=$STAR_VER && \
    mamba clean -ai