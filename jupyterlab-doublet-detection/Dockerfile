# JupyterLab on gcfntnu/doublet-detection; gcf-workflows runs doublet_rank_aggr.py in it.
# Python packages are pinned in requirements.txt and installed with pip constrained to the
# gcfntnu/scanpy base, so scanpy, anndata, pandas and numpy stay as in doublet-detection.
# The R kernel (IRkernel) goes into doublet-detection's R environment.
# Keep the FROM tag equal to the tag this image is published under (bin/build_tag_push_gcfntnu.sh
# builds both with the same tag).
FROM gcfntnu/doublet-detection:4.3.0.post1

COPY requirements.txt /tmp/requirements.txt
RUN pip install --no-cache-dir -c /opt/scanpy-base-packages.txt -r /tmp/requirements.txt \
    && rm /tmp/requirements.txt

RUN conda install --yes --quiet --name r r-irkernel=1.3.2 \
    && conda clean -afy \
    && Rscript -e 'IRkernel::installspec(user = FALSE)'

RUN pip list --format=freeze > /tmp/packages.txt \
    && for p in ${SCANPY_BASE_VERSIONS}; do grep -qixF "$p" /tmp/packages.txt || { echo "expected $p" >&2; exit 1; }; done \
    && rm /tmp/packages.txt \
    && python -c "import numpy, pandas, scipy.stats, matplotlib.pyplot, seaborn, marsilea, upsetplot, adjustText" \
    && jupyter kernelspec list | grep -qw ir \
    && jupyter kernelspec list | grep -qw python3

RUN mkdir /tmp/work
WORKDIR /tmp/work

CMD ["jupyter-lab", "--allow-root", "--port", "8888", "--no-browser"]
