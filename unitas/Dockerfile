FROM gcfntnu/build-base:22.04

# unitas 1.8.0 with GCF fixes (image tag 1.8.0-4).
#   1.8.0-1: offline build and workflow fixes, see unitas-1.8.0-1.patch.
#   1.8.0-2: unitas_build_refdump.sh strips own species prefixes from miRBase hairpin names
#            (unitas_normalize_hairpin.awk, gcfntnu/gcf-docker#8). unitas.pl is unchanged.
#   1.8.0-3: unitas_build_refdump.sh --mirna-db mirgenedb builds dumps from MirGeneDB instead of
#            miRBase (unitas_mirgenedb2mirbase.awk, mirgenedb_species.tsv). unitas.pl is unchanged.
#   1.8.0-4: unitas_build_refdump.sh downloads miRBase from the release-specific URLs and requires
#            --mirbase-release; before, it took the current release and only used the option as a
#            label. unitas.pl is unchanged.
#
# The upstream host (www.smallrnagroup.uni-mainz.de) is gone, so the script and SeqMap are
# supplied locally in files/ (git-ignored; local builds only):
#   files/unitas_1.8.0.pl  copy from the published image:
#       docker create --name u gcfntnu/unitas:1.8.0 && docker cp u:/opt/unitas/unitas_1.8.0.pl files/ && docker rm u
#   files/seqmap.exe       SeqMap 1.0.13 x86-64 Linux build (needs glibc >= 2.29)
#
# Annotation runs are offline: provide UNITAS_refdump_<species> in the working directory;
# seqmap.exe is picked up from PATH. Reference downloads and -riborase exit with an error.
# -refdump only works with -mirror DIR (a local copy of the old server layout); use
# unitas_build_refdump.sh to build reference dumps from Ensembl, GtRNAdb and miRBase or MirGeneDB.

ENV UNITAS_VERSION=1.8.0
ENV UNITAS_BUILD=1.8.0-4
ARG UNITAS_PATCH=unitas-1.8.0-1.patch
ENV PATH=/opt/unitas:$PATH

RUN apt-get update --fix-missing && apt-get install -y \
    bzip2 \
    perl \
    libssl-dev \
    libarchive-extract-perl \
    cpanminus \
    gcc-multilib \
    dos2unix \
    patch \
    sed && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN cpanm LWP::Simple \
    LWP::UserAgent \
    Net::SSLeay \
    File::Path \
    Archive::Zip \
    File::Copy \
    File::Basename \
    Getopt::Long \
    Archive::Extract \
    LWP::Protocol::https \
    Scalar::Util

WORKDIR /opt/unitas
COPY files/unitas_${UNITAS_VERSION}.pl files/seqmap.exe ${UNITAS_PATCH} unitas_build_refdump.sh unitas_normalize_hairpin.awk \
     unitas_mirgenedb2mirbase.awk mirgenedb_species.tsv ./
RUN dos2unix unitas_${UNITAS_VERSION}.pl
# Legacy header-length patches (already present in the script from gcfntnu/unitas:1.8.0; no-ops then)
RUN sed -i 's/head>30/head>1000/; s/head,0,27/head,0,1000/' unitas_${UNITAS_VERSION}.pl
RUN patch unitas_${UNITAS_VERSION}.pl < ${UNITAS_PATCH} \
    && rm ${UNITAS_PATCH} \
    && perl -c unitas_${UNITAS_VERSION}.pl
RUN ln -s unitas_${UNITAS_VERSION}.pl unitas.pl \
    && chmod 755 /opt/unitas/unitas* /opt/unitas/seqmap.exe \
    && seqmap.exe 2>&1 | grep -q 'SeqMap: Short Sequence Mapping Tool' \
    && printf '>hsa-mir-1 MI1 Homo sapiens hsa-miR-1 stem-loop\nACGU\n' \
       | awk -v report=/dev/null -f unitas_normalize_hairpin.awk 2>/dev/null \
       | grep -qx '>hsa-mir-1 MI1 Homo sapiens miR-1 stem-loop' \
    && printf '>Hsa-Let-7-P1b_pre\nACGU\n' \
       | awk -v kind=hairpin -v species=mirgenedb_species.tsv -f unitas_mirgenedb2mirbase.awk 2>/dev/null \
       | grep -qx '>Hsa-Let-7-P1b_pre Hsa-Let-7-P1b_pre Homo sapiens Let-7-P1b stem-loop'
