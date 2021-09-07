FROM gcfntnu/python-base-conda:4.10.3

ENV STAR_VERSION 2.7.9a

RUN mamba install --quiet --yes \
    star=$STAR_VER && \
    mamba clean -ai


WORKDIR /tmp
RUN git clone https://github.com/alexdobin/STAR.git
RUN chmod -R 755  STAR/extras/ && cp STAR/extras/scripts/* /usr/bin/
RUN rm -rf STAR