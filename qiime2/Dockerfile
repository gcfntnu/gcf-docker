FROM qiime2/core:2019.4

RUN conda update conda

RUN /bin/bash -c "source activate /opt/conda/envs/qiime2-2019.4 && \
    conda config --add channels defaults && \
    conda config --add channels bioconda && \
    conda config --add channels conda-forge && \
    conda update --all"


RUN /bin/bash -c "source activate /opt/conda/envs/qiime2-2019.4 && conda install --force-reinstall biom-format"

RUN /bin/bash -c "source activate /opt/conda/envs/qiime2-2019.4 && conda install r-argparse"

COPY install_picrust2.sh .
RUN /bin/bash -c "source activate /opt/conda/envs/qiime2-2019.4 && ./install_picrust2.sh"

COPY install_qiime2R.sh .
RUN /bin/bash -c "source activate /opt/conda/envs/qiime2-2019.4 && ./install_qiime2R.sh"