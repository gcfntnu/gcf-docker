FROM gcfntnu/python-base-conda:3.7

RUN conda install --quiet --yes \
  perl-module-build \
  perl-config-simple \
  perl-file-which \
  perl-list-moreutils \
  perl-statistics-descriptive \
  perl-statistics-lite \
  perl-parallel-forkmanager \
  perl-bio-db-hts \
  perl-bioperl && \
  conda clean --all

WORKDIR /opt
RUN git clone https://github.com/tjparnell/biotoolbox.git
RUN cd biotoolbox && perl Build.PL && ./Build && ./Build install
