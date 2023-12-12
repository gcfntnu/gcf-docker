FROM frolvlad/alpine-glibc:alpine-3.18_glibc-2.34

ENV CONDA_VERSION latest
ENV CONDA_MD5 718259965f234088d785cad1fbd7de03

ENV PYTHONDONTWRITEBYTECODE=true

RUN apk add --no-cache wget bzip2 bash \
    && addgroup -S anaconda \
    && adduser -D -u 10151 anaconda -G anaconda \
    && wget --quiet https://repo.continuum.io/miniconda/Miniconda3-$CONDA_VERSION-Linux-x86_64.sh \
    && mv Miniconda3-$CONDA_VERSION-Linux-x86_64.sh miniconda.sh \
    && sh ./miniconda.sh -b -p /opt/conda \
    && ln -s /opt/conda/etc/profile.d/conda.sh /etc/profile.d/conda.sh \
    && echo ". /opt/conda/etc/profile.d/conda.sh" >> /home/anaconda/.profile \
    && echo "conda activate base" >> /home/anaconda/.profile \
    && /opt/conda/bin/conda install -y python=3.9 \
    && /opt/conda/bin/conda install --freeze-installed tini -y \
    && find /opt/conda/ -follow -type f -name '*.a' -delete \
    && find /opt/conda/ -follow -type f -name '*.pyc' -delete \
    && /opt/conda/bin/conda clean -afy \
    && chown -R anaconda:anaconda /opt/conda \
    && apk del wget bzip2

USER anaconda:anaconda
WORKDIR /home/anaconda/

COPY start.sh /usr/local/bin/

ENTRYPOINT ["/opt/conda/bin/tini", "-g", "--", "/usr/local/bin/start.sh"]
CMD ["/bin/bash", "-i"]