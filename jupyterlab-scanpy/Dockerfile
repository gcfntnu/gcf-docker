# JupyterLab on gcfntnu/scanpy:1.12.3 (build 1.12.3-1). gcf-workflows runs its singlecell `notebook:`
# rules (key jupyter-scanpy) and their nbconvert HTML exports in this image.
#
# The base's Python packages are kept exactly: everything is installed with pip constrained to them,
# and R (for the IRkernel) lives in its own conda environment. The build fails if scanpy, anndata,
# pandas or numpy differ from the base. (1.12.3 used `conda install` into the pip-managed
# environment, which replaced the base's pandas 3.0.5 with 2.3.3.)
#
# Snakemake runs `notebook:` jobs by executing the notebook here with a `snakemake` object pickled by
# the outer Snakemake; the notebook unpickles it with the snakemake installed in this image. So
# SNAKEMAKE_VER must equal the Snakemake version gcf-workflows runs (9.7.1): with 9.26.1 (the 1.12.3
# image) or 7.15.2 a 9.7.1 notebook job fails with "Can't get attribute ... on <module 'snakemake.io'>".
# Rebuild under a new tag when gcf-workflows changes its Snakemake version.
FROM gcfntnu/scanpy:1.12.3@sha256:b386644bbe0ec72ea9b55fd4da9bf03f676b8247d1b89959dadce4c85e9ff309

ARG SNAKEMAKE_VER=9.7.1
ENV JUPYTERLAB_SCANPY_BUILD=1.12.3-1 \
    SNAKEMAKE_VER=${SNAKEMAKE_VER} \
    SCANPY_BASE_VERSIONS="scanpy==1.12.3 anndata==0.13.3.post0 pandas==3.0.5 numpy==2.5.2"

COPY requirements.txt /tmp/requirements.txt
RUN pip list --format=freeze > /opt/scanpy-base-packages.txt \
    && pip install --no-cache-dir -c /opt/scanpy-base-packages.txt \
        "snakemake==${SNAKEMAKE_VER}" -r /tmp/requirements.txt \
    && rm /tmp/requirements.txt

# R kernel in its own environment
COPY env-r.yml /tmp/env-r.yml
RUN conda env create --file /tmp/env-r.yml \
    && rm /tmp/env-r.yml \
    && ln -s /opt/miniconda3/envs/r/bin/R /opt/miniconda3/envs/r/bin/Rscript /usr/local/bin/ \
    && Rscript -e 'IRkernel::installspec(user = FALSE)' \
    && conda clean -afy

RUN pip list --format=freeze > /tmp/packages.txt \
    && for p in ${SCANPY_BASE_VERSIONS} "snakemake==${SNAKEMAKE_VER}"; do grep -qixF "$p" /tmp/packages.txt || { echo "expected $p" >&2; exit 1; }; done \
    && rm /tmp/packages.txt \
    && python -c "import scanpy, anndata, matplotlib, seaborn, nbconvert, papermill, snakemake" \
    && jupyter kernelspec list | grep -qw python3 \
    && jupyter kernelspec list | grep -qw ir

RUN mkdir /tmp/work
WORKDIR /tmp/work

CMD ["jupyter-lab", "--allow-root", "--port", "8888", "--no-browser"]
