# gcf-docker

Dockerfiles for the container images of the Genomics Core Facility (GCF), NTNU, Trondheim.
The images are published by the [`gcfntnu` organization on Docker Hub](https://hub.docker.com/u/gcfntnu).
Most of them are used by [gcf-workflows](https://github.com/gcfntnu/gcf-workflows), which selects one image per key in its [`docker.config`](https://github.com/gcfntnu/gcf-workflows/blob/bfq-dev/docker.config).
That file is the record of which `gcfntnu` tags are in use.

- [Repository layout](#repository-layout)
- [Base images](#base-images)
- [Image catalogue](#image-catalogue)
- [Conventions](#conventions)
- [Building and publishing](#building-and-publishing)
- [Changing an image used by gcf-workflows](#changing-an-image-used-by-gcf-workflows)
- [Known gaps](#known-gaps)

## Repository layout

Each top-level directory builds one image, usually named `gcfntnu/<directory>`:

```
<image>/
  Dockerfile            # the current recipe
  Dockerfile-<tag>      # variants built under another tag (e.g. python-base-conda/Dockerfile-3.12)
  Dockerfile.<variant>  # alternative or older recipes (e.g. seurat/Dockerfile.dev, qiime2/Dockerfile.2019.10)
  env.yml, *.txt, ...   # files copied into the image: pinned environments, patches, helper scripts
  dependencies.txt      # optional: images built on this one, rebuilt with it by bin/build_tag_push_gcfntnu.sh
  files/                # local-only inputs that cannot be redistributed (git-ignored)
bin/
  build_tag_push_gcfntnu.sh   # build, tag and push the image of the current directory
```

- **Directory and image names mostly match.** The exceptions are `entrezdirect` (`gcfntnu/entrez_direct`), `bfq-plot` (`gcfntnu/bfq_plot`), `INSPEcT` (`gcfntnu/inspect`) and `signal/`, which holds one image per subdirectory, published as `gcfntnu/signal-*`.
- **`files/` is git-ignored.** It holds installers and data that may not be redistributed, such as the Cell Ranger tarball, the METAnnotatorX2 release, and the unitas script and SeqMap binary. The Dockerfile `COPY`s them from there, so these images build only where those files have been put in place. The Dockerfile or its header says what to put there.
- **Build logs (`*.log`) are git-ignored.** Write them next to the Dockerfile (see [Building and publishing](#building-and-publishing)).
- Some directories carry their own documentation, for example [gcf-multiqc/README.md](gcf-multiqc/README.md) and the header of [unitas/Dockerfile](unitas/Dockerfile).

## Base images

Most images build on a small set of GCF base images, so build and publish a base before the images that use it.

```
anaconda/miniconda ─► python-base-conda:<python> ─┬─► python-default:3.12-<n>
                                                  ├─► r-base-conda:<R> ─► r-default:<R>, sartools, orthogene, ...
                                                  └─► scanpy, star, psbio, vireo, mapmycells, ...
ubuntu:22.04 ─► build-base:22.04 ─► bcl-convert, cellranger, unitas, metannotatorx2, ...
```

| Image | Tags built from this repository | Notes |
| --- | --- | --- |
| `gcfntnu/python-base-conda` | `3.9` … `3.14`, from `Dockerfile-<python>`; `Dockerfile` is the same as `Dockerfile-3.14` | Miniconda (`anaconda/miniconda:26.5.3`; `3.9` uses `continuumio/miniconda3:23.10.0-1`) with one Python version, `pip` and `git`. Channels are `conda-forge`, `bioconda`, `defaults` with strict priority. Conda lives in `/opt/miniconda3`; `/opt/conda` is a symlink to it for tools that expect that path. Older tags named after the Miniconda version (`3.7`, `4.8.2`, `4.9.2`, `4.10.3`, `22.11.1`, `23.10.0-1`) were built from earlier revisions of this directory and are still the base of many older images. |
| `gcfntnu/r-base-conda` | the `R_VER` in the Dockerfile (currently `4.5.3`) | R and BiocManager from conda-forge on `python-base-conda:3.12`. |
| `gcfntnu/build-base` | `22.04` (older images use `16.04`, `20.04` and `latest`) | Ubuntu with compilers, CMake, autotools, Haskell Stack, `git`, `curl`, `wget` and common `-dev` libraries, for tools compiled from source. |
| `gcfntnu/python-default` | `3.12-<n>` | The `default` container of gcf-workflows. Every direct dependency is pinned in [python-default/env.yml](python-default/env.yml), and the resolved environment of the published build is in [python-default/packages.txt](python-default/packages.txt). |
| `gcfntnu/r-default` | the R version of its base | The `r-default` key of gcf-workflows: tidyverse, data.table, argparse/optparse, Cairo, hdf5r, RCurl, XML. |

`r-base`, `python-base`, `python2-base`, `python2-base-conda` and `alpine-conda` are legacy bases that only older images use.

## Image catalogue

The table lists every directory in the repository.
**Base** is the first `FROM` of the main Dockerfile.
**Used by gcf-workflows** shows the tag that gcf-workflows' [`docker.config`](https://github.com/gcfntnu/gcf-workflows/blob/bfq-dev/docker.config) selects on `bfq-dev`, or *digest* where it pins a digest.
A dash under **Image** means no published image was found for the directory on Docker Hub (as of November 2026).

### Base and default images

| Directory | Image | Base | Used by gcf-workflows | Description |
| --- | --- | --- | --- | --- |
| [build-base](build-base/) | `gcfntnu/build-base` | `ubuntu:22.04` |  | Ubuntu build toolchain (compilers, CMake, autotools) for tools built from source |
| [python-base-conda](python-base-conda/) | `gcfntnu/python-base-conda` | `anaconda/miniconda:${MINICONDA_VERSION}` |  | Miniconda with one Python version; strict conda-forge > bioconda > defaults channels |
| [r-base-conda](r-base-conda/) | `gcfntnu/r-base-conda` | `gcfntnu/python-base-conda:3.12` |  | R from conda-forge on `python-base-conda` |
| [python-default](python-default/) | `gcfntnu/python-default` | `gcfntnu/python-base-conda:3.12` | `3.12-1` | Default gcf-workflows container: pandas, polars, SciPy, PyArrow and friends, pinned in `env.yml` |
| [r-default](r-default/) | — | `gcfntnu/r-base-conda:4.5.3` | `4.5.3` | Default R container: tidyverse, data.table, argparse/optparse, Cairo, hdf5r |
| [r-base](r-base/) | `gcfntnu/r-base` | `bioconductor/bioconductor_docker:latest` |  | Legacy R base on `bioconductor/bioconductor_docker` |
| [python-base](python-base/) | `gcfntnu/python-base` | `python:3.9-slim` |  | Legacy `python:3.9-slim` base |
| [python2-base](python2-base/) | `gcfntnu/python2-base` | `python:2.7-slim` |  | Legacy Python 2.7 base |
| [python2-base-conda](python2-base-conda/) | `gcfntnu/python2-base-conda` | `continuumio/miniconda2:4.5.12` |  | Legacy Miniconda 2 base |
| [alpine-conda](alpine-conda/) | `gcfntnu/alpine-conda` | `frolvlad/alpine-glibc:alpine-3.18_glibc-2.34` |  | Conda on Alpine with glibc |

### Demultiplexing, FASTQ handling and QC

| Directory | Image | Base | Used by gcf-workflows | Description |
| --- | --- | --- | --- | --- |
| [bcl-convert](bcl-convert/) | `gcfntnu/bcl-convert` | `gcfntnu/build-base:22.04` | `4.2.4` | Illumina BCL Convert |
| [bcl2fastq](bcl2fastq/) | `gcfntnu/bcl2fastq` | `gcfntnu/build-base:latest` | `2.20.0` | Illumina bcl2fastq |
| [cutadapt](cutadapt/) | `gcfntnu/cutadapt` | `gcfntnu/python-base-conda:4.9.2` | `3.3` | Adapter trimming |
| [fastq_pair](fastq_pair/) | `gcfntnu/fastq_pair` | `gcfntnu/build-base:latest` | `0.3` | Re-pair paired-end FASTQ files |
| [bioseqzip](bioseqzip/) | `gcfntnu/bioseqzip` | `gcfntnu/build-base:20.04` |  | BioSeqZip FASTQ collapsing |
| [primerclip](primerclip/) | `gcfntnu/primerclip` | `gcfntnu/build-base:16.04` | `0.3.8` | Primer trimming for Swift amplicon panels |
| [fastv](fastv/) | `gcfntnu/fastv` | `gcfntnu/python-base-conda:4.8.2` | `0.8.1` | Viral sequence detection in FASTQ |
| [bfq-plot](bfq-plot/) | `gcfntnu/bfq_plot` | `gcfntnu/python-base-conda:3.7` | `0.1` | Plotting environment for BFQ QC figures |
| [multiqc](multiqc/) | `gcfntnu/multiqc` | `gcfntnu/python-base:3.9` |  | MultiQC (older GCF build) |
| [gcf-multiqc](gcf-multiqc/) | `gcfntnu/gcf-multiqc` | `python:3.11-slim (digest)` | `digest` | Upstream MultiQC with the GCF plugin; see [gcf-multiqc/README.md](gcf-multiqc/README.md) |

### Alignment, BAM and genome tools

| Directory | Image | Base | Used by gcf-workflows | Description |
| --- | --- | --- | --- | --- |
| [bowtie_samtools](bowtie_samtools/) | `gcfntnu/bowtie_samtools` | `gcfntnu/python-base-conda:3.7` | `1.2.3` | Bowtie + samtools |
| [bowtie2_samtools](bowtie2_samtools/) | `gcfntnu/bowtie2_samtools` | `gcfntnu/python-base-conda:3.7` | `2.3.5` | Bowtie 2 + samtools |
| [bwa_samtools](bwa_samtools/) | `gcfntnu/bwa_samtools` | `gcfntnu/python-base-conda:4.8.2` | `0.7.17` | BWA + samtools |
| [star](star/) | `gcfntnu/star` | `gcfntnu/python-base-conda:3.12` | `2.7.11b-2` | STAR aligner |
| [sambamba](sambamba/) | `gcfntnu/sambamba` | `gcfntnu/python-base-conda:3.12` | `1.0.1` | sambamba BAM processing |
| [picard](picard/) | `gcfntnu/picard` | `gcfntnu/python-base-conda:4.8.2` | `2.21.5` | Picard + GATK4 |
| [deeptools](deeptools/) | `gcfntnu/deeptools` | `continuumio/miniconda:4.5.12` |  | deepTools |
| [ucsc-scripts](ucsc-scripts/) | `gcfntnu/ucsc-scripts` | `gcfntnu/python-base-conda:3.7` | `latest` | UCSC Genome Browser command-line utilities |
| [gcf-bio](gcf-bio/) | `gcfntnu/gcf-bio` | `gcfntnu/python-base-conda:4.9.2` | `1.0` | General toolbox: UCSC utilities, samtools, bedtools, seqkit, seqtk, gffread, fastq tools and more |
| [bio-toolbox](bio-toolbox/) | `gcfntnu/bio-toolbox` | `gcfntnu/python-base-conda:3.7` |  | BioToolBox (Perl/BioPerl genomic data tools) |
| [entrezdirect](entrezdirect/) | `gcfntnu/entrez_direct` | `gcfntnu/python-base-conda:3.7` | `11.0` | NCBI Entrez Direct (E-utilities) |

### Bulk RNA-seq

| Directory | Image | Base | Used by gcf-workflows | Description |
| --- | --- | --- | --- | --- |
| [salmon](salmon/) | `gcfntnu/salmon` | `gcfntnu/python-base-conda:4.10.3` | `1.7.0` | Salmon transcript quantification |
| [tximport](tximport/) | `gcfntnu/tximport` | `gcfntnu/python-base-conda:4.10.3` | `1.20.0` | tximport/tximeta |
| [rnaseq](rnaseq/) | `gcfntnu/rnaseq` | `gcfntnu/r-base-conda:4.0.5` |  | Bioconductor RNA-seq analysis environment |
| [diff-exprs](diff-exprs/) | `gcfntnu/diff-exprs` | `gcfntnu/r-base-conda:4.0.5` |  | Differential expression environment (edgeR, DESeq2, sva, EnhancedVolcano) |
| [co-exprs](co-exprs/) | `gcfntnu/co-exprs` | `gcfntnu/r-base-conda:4.0.5` |  | Co-expression environment (GWENA, mixOmics, DESeq2) |
| [sartools](sartools/) | `gcfntnu/sartools` | `gcfntnu/r-base-conda:4.5.3` | `1.8.2` | SARTools differential analysis reports |
| [scallop](scallop/) | `gcfntnu/scallop` | `gcfntnu/python-base-conda:4.10.3` | `0.10.4` | Scallop transcript assembly |
| [taco](taco/) | `gcfntnu/taco` | `gcfntnu/python-base-conda:3.7` | `0.7.3` | TACO transcriptome meta-assembly |
| [strawberry](strawberry/) | — | `debian:jessie-slim` |  | Strawberry transcript assembly and quantification |
| [psiclass](psiclass/) | `gcfntnu/psiclass` | `gcfntnu/build-base:latest` |  | PsiCLASS transcript assembly |
| [transmeta](transmeta/) | `gcfntnu/transmeta` | `gcfntnu/build-base:22.04` |  | TransMeta transcript assembly |
| [yanagi](yanagi/) | `gcfntnu/yanagi` | `gcfntnu/python-base-conda:3.7` |  | Yanagi segment-based splicing analysis |
| [jcc](jcc/) | — | `rocker/tidyverse:3.5.1` |  | Junction coverage compatibility (JCC) scores |
| [proactiv](proactiv/) | `gcfntnu/proactiv` | `gcfntnu/r-base:4.0.0` |  | proActiv promoter activity |
| [superseq](superseq/) | — | `gcfntnu/r-base:3.6.0` |  | superSeq sequencing-depth analysis |
| [INSPEcT](INSPEcT/) | `gcfntnu/inspect` | `gcfntnu/r-base:4.2.0` |  | INSPEcT RNA dynamics |
| [arcashla](arcashla/) | `gcfntnu/arcashla` | `ubuntu:19.10` |  | arcasHLA HLA typing from RNA-seq |
| [sad](sad/) | — | `gcfntnu/build-base:latest` |  | SAD (Salmon Anomaly Detection) for unannotated transcripts |

### Single-cell and spatial

| Directory | Image | Base | Used by gcf-workflows | Description |
| --- | --- | --- | --- | --- |
| [cellranger](cellranger/) | `gcfntnu/cellranger` | `gcfntnu/build-base:22.04` | `10.0.0`, `digest` | 10x Genomics Cell Ranger |
| [cellranger-atac](cellranger-atac/) | `gcfntnu/cellranger-atac` | `gcfntnu/bcl2fastq:latest` | `2.0.0`, `digest` | 10x Genomics Cell Ranger ATAC |
| [spaceranger](spaceranger/) | `gcfntnu/spaceranger` | `gcfntnu/bcl2fastq:latest` | `1.3.0`, `digest` | 10x Genomics Space Ranger |
| [psbio](psbio/) | `gcfntnu/psbio` | `gcfntnu/python-base-conda:3.12` | `1.8.2` | Parse Biosciences split-pipe |
| [psbio-immune](psbio-immune/) | `gcfntnu/psbio-immune` | `gcfntnu/python-base-conda:3.12` | `digest` | Parse Biosciences split-pipe with immune profiling |
| [alevin](alevin/) | `gcfntnu/alevin` | `gcfntnu/python-base-conda:4.10.3` |  | Salmon alevin + scanpy |
| [velocyto](velocyto/) | `gcfntnu/velocyto` | `gcfntnu/python-base-conda:4.10.3` | `0.17.17` | velocyto RNA velocity |
| [scanpy](scanpy/) | `gcfntnu/scanpy` | `gcfntnu/python-base-conda:3.12` | `1.12.3` | Scanpy analysis environment |
| [scanpy-analyse](scanpy-analyse/) | — | `gcfntnu/scanpy:1.12.3` |  | Scanpy with extra R/analysis dependencies |
| [scasa](scasa/) | `gcfntnu/scasa` | `gcfntnu/r-base-conda:4.1.1` |  | Scasa isoform quantification |
| [doublet-detection](doublet-detection/) | `gcfntnu/doublet-detection` | `gcfntnu/python-base-conda:3.11` |  | Doublet detection (scrublet, DoubletDetection, scDblFinder, scds) |
| [solo-sc](solo-sc/) | `gcfntnu/solo-sc` | `nvidia/cuda:11.8.0-cudnn8-runtime-ubuntu22.04` |  | solo doublet detection (scvi-tools, GPU) |
| [empty_nn](empty_nn/) | `gcfntnu/empty_nn` | `rocker/r-ver:4.2.1` |  | EmptyNN empty-droplet detection |
| [cellbender](cellbender/) | `gcfntnu/cellbender` | `us.gcr.io/broad-dsde-methods/cellbender:0.3.2` | `latest` | CellBender ambient RNA removal |
| [scribe](scribe/) | `gcfntnu/scribe` | `gcfntnu/scanpy:1.4` |  | Scribe causal network inference |
| [gficf](gficf/) | — | `gcfntnu/r-base:3.6.1` |  | GF-ICF normalisation |
| [seurat](seurat/) | `gcfntnu/seurat` | `gcfntnu/r-base:3.6.0` | `dev-3.0.1` | Seurat (`Dockerfile.dev` builds the development tag) |
| [mapmycells](mapmycells/) | `gcfntnu/mapmycells` | `gcfntnu/python-base-conda:3.12` |  | Allen Institute MapMyCells cell-type mapping |
| [orthogene](orthogene/) | `gcfntnu/orthogene` | `gcfntnu/r-base-conda:4.5.3` | `1.12.0` | orthogene ortholog mapping |
| [trust4](trust4/) | `gcfntnu/trust4` | `gcfntnu/build-base:20.04` |  | TRUST4 TCR/BCR reconstruction |
| [cellsnp-lite](cellsnp-lite/) | `gcfntnu/cellsnp-lite` | `ubuntu:22.04` | `1.2.4` | cellsnp-lite allele counting |
| [vireo](vireo/) | `gcfntnu/vireo` | `gcfntnu/python-base-conda:3.12` | `0.5.9-gcf1` | vireo genotype demultiplexing |
| [souporcell](souporcell/) | `gcfntnu/souporcell` | `gcfntnu/python-base-conda:3.9` |  | souporcell genotype demultiplexing |
| [demuxalot](demuxalot/) | `gcfntnu/demuxalot` | `gcfntnu/python-base-conda:23.10.0-1` | `0.4.0` | demuxalot genotype demultiplexing |
| [scsplit](scsplit/) | `gcfntnu/scsplit` | `gcfntnu/python-base-conda:4.9.2` |  | scSplit genotype demultiplexing |
| [demuxafy-genotype-match](demuxafy-genotype-match/) | `gcfntnu/demuxafy-genotype-match` | `rocker/r-ver:4.4.1` | `1.0` | Match demultiplexed clusters to reference genotypes (Demuxafy) |

### Small RNA

| Directory | Image | Base | Used by gcf-workflows | Description |
| --- | --- | --- | --- | --- |
| [unitas](unitas/) | `gcfntnu/unitas` | `gcfntnu/build-base:22.04` | `1.8.0-1` | unitas small RNA annotation, offline build; see the Dockerfile header |
| [mirtrace](mirtrace/) | `gcfntnu/mirtrace` | `gcfntnu/python-base-conda:3.7` | `1.0.1` | miRTrace small RNA QC |
| [mirge](mirge/) | `gcfntnu/mirge` | `gcfntnu/python2-base-conda:2.7` |  | miRge (Python 2) |
| [mirge3](mirge3/) | `gcfntnu/mirge3` | `gcfntnu/python-base-conda:4.10.3` |  | miRge3 |
| [mirec](mirec/) | `gcfntnu/mirec` | `gcfntnu/python-base-conda:4.10.3` |  | miREC miRNA read error correction |
| [quickmirseq](quickmirseq/) | `gcfntnu/quickmirseq` | `gcfntnu/python-base-conda:3.7` |  | QuickMIRSeq |
| [seqbuster](seqbuster/) | `gcfntnu/seqbuster` | `gcfntnu/python-base-conda:3.7` |  | SeqBuster/miraligner |
| [manatee](manatee/) | `gcfntnu/manatee` | `gcfntnu/python-base-conda:4.10.3` |  | Manatee small RNA quantification |
| [mgcount](mgcount/) | `gcfntnu/mgcount` | `gcfntnu/python-base-conda:4.10.3` |  | MGcount total RNA-seq quantification including small RNAs |

### Metagenomics and microbiome

| Directory | Image | Base | Used by gcf-workflows | Description |
| --- | --- | --- | --- | --- |
| [bracken](bracken/) | `gcfntnu/bracken` | `staphb/kraken2:2.1.3` | `2.9` | Bracken abundance estimation on Kraken 2 |
| [kraken-biom](kraken-biom/) | `gcfntnu/kraken-biom` | `gcfntnu/python-base-conda:22.11.1` | `1.2.0` | kraken-biom BIOM tables |
| [krona](krona/) | `gcfntnu/krona` | `gcfntnu/python-base-conda:22.11.1` | `2.8.1-240201` | Krona charts |
| [qiime2](qiime2/) | `gcfntnu/qiime2` | `qiime2/core:2020.8` | `2019.10` | QIIME 2 (`Dockerfile.2019.10` builds the 2019.10 release) |
| [phyloseq](phyloseq/) | `gcfntnu/phyloseq` | `gcfntnu/r-base:4.1.2` | `1.28.0` | phyloseq |
| [metannotatorx2](metannotatorx2/) | `gcfntnu/metannotatorx2` | `gcfntnu/build-base:22.04` |  | METAnnotatorX2 (needs the release zip in `files/`) |

### Variants and SARS-CoV-2

| Directory | Image | Base | Used by gcf-workflows | Description |
| --- | --- | --- | --- | --- |
| [freebayes](freebayes/) | — | `gcfntnu/python-base-conda:4.9.2` |  | freebayes variant calling |
| [vcftools](vcftools/) | `gcfntnu/vcftools` | `gcfntnu/python-base-conda:23.10.0-1` | `1.18` | VCFtools |
| [signal](signal/) | `gcfntnu/signal-*` | `gcfntnu/python-base-conda:4.8.2` |  | SIGNAL SARS-CoV-2 pipeline steps, one image per subdirectory (`base`, `trim-qc`, `ivar`, `snp-mapping`, `assembly-qc`, `postprocess`), published as `signal-*` |
| [nextstrain](nextstrain/) | — | `gcfntnu/python-base-conda:4.8.2` |  | Nextstrain |

### Notebooks and other

| Directory | Image | Base | Used by gcf-workflows | Description |
| --- | --- | --- | --- | --- |
| [jupyterlab-base](jupyterlab-base/) | `gcfntnu/jupyterlab-base` | `gcfntnu/python-base-conda:4.8.2` |  | JupyterLab base |
| [jupyterlab-scanpy](jupyterlab-scanpy/) | `gcfntnu/jupyterlab-scanpy` | `gcfntnu/scanpy:latest` | `1.12.3` | JupyterLab on `scanpy` |
| [jupyterlab-rnaseq](jupyterlab-rnaseq/) | `gcfntnu/jupyterlab-rnaseq` | `gcfntnu/rnaseq:1.3` | `1.3` | JupyterLab on `rnaseq` |
| [jupyterlab-diff-exprs](jupyterlab-diff-exprs/) | `gcfntnu/jupyterlab-diff-exprs` | `gcfntnu/diff-exprs:1.3` | `1.2` | JupyterLab on `diff-exprs` |
| [jupyterlab-co-exprs](jupyterlab-co-exprs/) | `gcfntnu/jupyterlab-co-exprs` | `gcfntnu/co-exprs:1.0` | `1.0` | JupyterLab on `co-exprs` |
| [jupyterlab-doublet-detection](jupyterlab-doublet-detection/) | `gcfntnu/jupyterlab-doublet-detection` | `gcfntnu/doublet-detection:latest` |  | JupyterLab on `doublet-detection` |
| [jupyterlab-rnbeads](jupyterlab-rnbeads/) | `gcfntnu/jupyterlab-rnbeads` | `gcfntnu/rnbeads:2.12.2` |  | JupyterLab on `rnbeads` |
| [jupyterlab-singlecell](jupyterlab-singlecell/) | `gcfntnu/jupyterlab-singlecell` | `gcfntnu/jupyterlab-base:test2` |  | Legacy single-cell JupyterLab |
| [microbiome-nb](microbiome-nb/) | — | `gcfntnu/jupyterlab-base:0.1` |  | Microbiome R notebook environment |
| [sigma2-singleuser](sigma2-singleuser/) | `gcfntnu/sigma2-singleuser` | `jupyter/datascience-notebook:d400e383cc1d` |  | JupyterHub single-user notebook image with CUDA |
| [rnbeads](rnbeads/) | `gcfntnu/rnbeads` | `gcfntnu/r-base:4.1.2` |  | RnBeads DNA methylation analysis |
gcf-workflows also uses `gcfntnu/rapids-scanpy`, `gcfntnu/rockhopper` and `gcfntnu/ivar`, which have no directory in this repository. (`gcfntnu/ivar:1.3.1` is a different image from `gcfntnu/signal-ivar`.)
Other keys in its `docker.config` point to images outside `gcfntnu`, such as BioContainers and StaPH-B.

## Conventions

These apply to new and changed images. Older directories don't all follow them yet.

### Tags

- **Tag with the main tool's version**, as in `star:2.7.11b`, `sambamba:1.0.1` or `bcl-convert:4.2.4`. For base and environment images, tag with the language version (`python-base-conda:3.12`, `r-base-conda:4.5.3`).
- **Add a GCF build revision `-<n>`** when the image changes but the tool version doesn't, for example a patch, a dependency update or a fix in the recipe: `unitas:1.8.0-1`, `star:2.7.11b-2`, `python-default:3.12-1`. Older images use other suffixes (`vireo:0.5.9-gcf1`, `krona:2.8.1-240201`); keep those as they are.
- **Record the build in the image** with an `ENV`, for example `ENV UNITAS_BUILD=1.8.0-1` or `ENV PYTHON_DEFAULT_BUILD=3.12-1`, so that a running container can tell which recipe built it.
- **Check gcf-workflows' [`docker.config`](https://github.com/gcfntnu/gcf-workflows/blob/bfq-dev/docker.config) before reusing, overwriting or removing a tag.** It lists the `gcfntnu` tags and digests that the workflows select.
- **Never overwrite a published tag** that a merged workflow uses. Publish a new revision instead, and switch gcf-workflows to it deliberately. Avoid `latest` in anything a workflow selects.

### Versions and pinning

- **Pin the tool version in the Dockerfile**, normally as an `ENV` or `ARG` (`ENV STAR_VERSION=2.7.11b`, `ARG SPLITPIPE_VER=1.8.2`), and use it in the install command.
- **Pin whole environments in a file** when an image installs many packages, as `python-default/env.yml` and `doublet-detection/env.yml` do. Install them with `conda env update --name base --file env.yml`. Record the resolved environment of the published build, for example with `docker run --rm <image> conda list --export > packages.txt`.
- **Pin `conda` itself** in such files if the base's conda must not change: an unpinned `conda env update` can upgrade conda and break its bundled plugins (see `python-default/env.yml`).
- **Pin third-party bases** to a version or digest rather than `latest`, as `gcf-multiqc` does.

### Runtime

gcf-workflows runs the images through Snakemake with Singularity/Apptainer (`--use-singularity`). That means:

- The container runs as the calling user, not root, and the image filesystem is read-only. Don't write into the image at runtime, and don't depend on files owned by root being writable.
- Snakemake calls the tools directly, so `ENTRYPOINT` and `CMD` are not used. Put every tool on `PATH`.
- Install what the workflow rules call, including shell tools such as `wget`, `curl`, `unzip` or `pigz`, if a rule needs them inside the container.

### Build-time checks

End the Dockerfile with a cheap `RUN` that fails the build if the image is broken. For example, run the tool's `--version`, import the main Python packages, or check `command -v` for each required program. See `python-default/Dockerfile` and `unitas/Dockerfile`. A broken image then can't be pushed by accident.

## Building and publishing

There is no CI in this repository. A maintainer who is a member of the `gcfntnu` Docker Hub organization builds the images locally and pushes them (`docker login` as a member first).

### With `bin/build_tag_push_gcfntnu.sh`

The usual way is [bin/build_tag_push_gcfntnu.sh](bin/build_tag_push_gcfntnu.sh), run from the image's directory with a new, unused tag.
Maintainers usually keep it on their `PATH` as `~/bin/build_tag_push_gcfntnu.sh`. Make that a symlink to the repository copy, so the two cannot drift apart. From the repository root, run `ln -sf "$PWD/bin/build_tag_push_gcfntnu.sh" ~/bin/`.

```bash
cd star
../bin/build_tag_push_gcfntnu.sh 2.7.11b-3
```

The script:

1. builds `Dockerfile` with `--no-cache` as `gcfntnu/<directory>:<tag>` and `gcfntnu/<directory>:latest`, writing the output to `build.log`;
2. pushes the image with `docker push --all-tags gcfntnu/<directory>`;
3. if the directory has a `dependencies.txt`, does the same for each directory listed there, under the same tag (for example `scanpy/dependencies.txt` lists `jupyterlab-scanpy`, so `scanpy:1.12.3` also builds and pushes `jupyterlab-scanpy:1.12.3`).

It runs plain `docker`, so you need to be in the `docker` group, and it pushes with your own `docker login`. Set `DOCKER` to use another command, for example `DOCKER="sudo docker" ../bin/build_tag_push_gcfntnu.sh <tag>`; `sudo` then pushes with root's Docker login, not yours. It prints each command before running it and stops at the first failing build. Blank lines in `dependencies.txt` are skipped. Before running it:

- **The image name is the directory name.** Directories published under another name (`entrezdirect`, `bfq-plot`, `INSPEcT`, the `signal/*` images) need a manual build, as do variant Dockerfiles such as `python-base-conda/Dockerfile-3.12`, because the script always builds `Dockerfile`.
- **`--all-tags` pushes every local tag of the image.** If `docker image ls gcfntnu/<directory>` shows an old or locally modified tag, it will overwrite that tag on Docker Hub. Remove such local tags first.
- **Images listed in `dependencies.txt` keep the base tag written in their own `FROM`.** Update that `FROM` (for example `FROM gcfntnu/scanpy:1.12.3` in `jupyterlab-scanpy/Dockerfile`) to the new tag before running the script. Otherwise the dependent image is built on the old base but tagged with the new version.

### By hand

For other names, variant Dockerfiles, or when you don't want to push `latest`:

```bash
cd <image>
docker build --progress=plain -t gcfntnu/<image>:<tag> . 2>&1 | tee build.log
# variants: docker build -f Dockerfile-3.12 -t gcfntnu/python-base-conda:3.12 .

docker run --rm gcfntnu/<image>:<tag> <tool> --version   # smoke test
docker push gcfntnu/<image>:<tag>
docker buildx imagetools inspect gcfntnu/<image>:<tag>    # the published digest
```

### Either way

1. **Build the bases first.** If the image builds on a GCF base you changed, build and push that first, or build it locally under the same tag.
2. **Check the tag is free** before pushing, so an existing tag is not overwritten. `https://hub.docker.com/v2/repositories/gcfntnu/<image>/tags/<tag>` returns 404 for an unused tag.
3. **Smoke-test the image** with the tool's own command on a tiny synthetic input. For images that gcf-workflows runs, a test under Singularity/Apptainer as a non-root user is the closest match.
4. **Record the digest** in the pull request. Workflows that need a fixed artifact can pin it (`gcfntnu/<image>@sha256:...`).

## Changing an image used by gcf-workflows

1. **Branch from `master`** in this repository. Change the Dockerfile and its pinned files, and bump the tag or the `-<n>` revision.
2. **Build, test and push the new tag** with `bin/build_tag_push_gcfntnu.sh` or by hand (see above).
3. **Open a pull request here** describing the change, the new tag and digest, and how it was tested. Link the gcf-docker issue it closes.
4. **Switch gcf-workflows to the new tag** in a separate pull request against its `bfq-dev` branch, following its [CONTRIBUTING.md](https://github.com/gcfntnu/gcf-workflows/blob/bfq-dev/CONTRIBUTING.md). If workflow code must change to run on the new image, land that first and state the merge order in both pull requests.
5. **Run a real integration test** of the affected workflows on the new image before production promotion. The local checks in gcf-workflows are dry runs and unit tests: they don't execute the containers.

## Known gaps

As of November 2026:

- **`r-base-conda:4.5.3` and `r-default:4.5.3` are not published**, although the Dockerfiles build them and gcf-workflows' `r-default` key names `r-default:4.5.3`. No workflow rule uses that key yet. Images that build on `r-base-conda:4.5.3` (`r-default`, `sartools`, `orthogene`) need it built locally first, or published ([gcf-workflows#293](https://github.com/gcfntnu/gcf-workflows/issues/293)).
- **`gcfntnu/cellbrowser` is selected by gcf-workflows but has no directory here and no published image.** The only rules that use it are in a file the workflows never load ([gcf-workflows#292](https://github.com/gcfntnu/gcf-workflows/issues/292)).
- Many older images use bases that are no longer built from this repository (`python-base-conda:3.7`, `4.8.2`, `4.10.3` and others), unpinned `latest` bases, or tags without a recorded build revision. Rebuilding them from today's recipes may not reproduce the published image.
