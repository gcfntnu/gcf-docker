FROM gcfntnu/python-base-conda:4.8.2

ENV R_VER 4.0.3


RUN mamba install --quiet --yes \
    mscorefonts \
    r-base==$R_VER \
    r-optparse \
    r-essentials \
    r-tidyverse \
    r-devtools \
    r-biocmanager && \
    mamba clean -a

RUN ln -s /bin/tar /bin/gtar
RUN R --slave -e "options(unzip='/usr/bin/unzip')"