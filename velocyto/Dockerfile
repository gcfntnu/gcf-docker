FROM gcfntnu/python-base-conda:3.7

RUN conda install numpy \
 scipy \
 cython \
 numba \
 matplotlib \
 scikit-learn \
 h5py \
 click \
 R \
 rpy2 \
 pytables \
 numba \
 pysam \
 loompy \
 louvain \
 scanpy 

# Install dependencies using pip
RUN pip install -U --no-deps velocyto scvelo