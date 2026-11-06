FROM gcfntnu/python-base-conda:3.12

ENV STAR_VERSION=2.7.11b
ENV SPLITCODE_VERSION=0.31.6
ENV SPLITP_VERSION=0.2.0

RUN apt-get update && \
    apt-get install --yes --no-install-recommends libgomp1 && \
    rm -rf /var/lib/apt/lists/*

RUN conda install --quiet --yes \
    splitcode=$SPLITCODE_VERSION \
    splitp=$SPLITP_VERSION  \
    cutadapt \
    bbmap \
    star=$STAR_VERSION && \
    conda clean --all --yes

WORKDIR /tmp

RUN git clone --branch ${STAR_VERSION} --depth 1 https://github.com/alexdobin/STAR.git
RUN chmod -R 755 STAR/extras/ && cp STAR/extras/scripts/* /usr/bin/
RUN rm -rf STAR