FROM gcfntnu/python-base-conda:4.9.2


RUN mamba install --quiet --yes \
  ucsc-addcols \
  ucsc-ameme \
  ucsc-autodtd \
  ucsc-autosql \
  ucsc-autoxml \
  ucsc-avecols \
  ucsc-axtchain \
  ucsc-axtsort \
  ucsc-axtswap \
  ucsc-axttomaf \
  ucsc-axttopsl \
  ucsc-bamtopsl \
  ucsc-bedclip \
  ucsc-bedcommonregions \
  ucsc-bedcoverage \
  ucsc-bedextendranges \
  ucsc-bedgeneparts \
  ucsc-bedgraphpack \
  ucsc-bedgraphtobigwig \
  ucsc-bedintersect \
  ucsc-beditemoverlapcount \
  ucsc-bedjointaboffset \
  ucsc-bedpileups \
  ucsc-bedremoveoverlap \
  ucsc-bedrestricttopositions \
  ucsc-bedsort \
  ucsc-bedtobigbed \
  ucsc-bedtogenepred \
  ucsc-bedtopsl \
  ucsc-bedweedoverlapping \ 
  ucsc-bigbedinfo \ 
  ucsc-bigbednameditems \ 
  ucsc-bigbedsummary \ 
  ucsc-bigbedtobed \ 
  ucsc-bigmaftomaf \ 
  ucsc-bigpsltopsl \ 
  ucsc-bigwigaverageoverbed \ 
  ucsc-bigwigcat \ 
  ea-utils \
  bedtools \
  slimfastq \
  sambamba \
  samtools \
  bedparse \
  gffutils \
  gffread \
  fastx_toolkit \
  fastq-tools \
  vcftools \
  fqtools \
  fastq_utils \
  fastq-multx \
  seqkit \
  gffcompare \
  biobambam \
  skewer \
  seqtk && \
  mamba clean -ai

#RUN mamba install -c pwwang bwtool