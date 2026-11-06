FROM gcfntnu/r-base-conda:4.5.3

# Default R container of gcf-workflows. R packages are pinned in env.yml; the resolved
# environment of the published build is listed in packages.txt. Publish every rebuild under a
# new tag (4.5.3-1, 4.5.3-2, ...) and never overwrite an existing one.
ENV R_DEFAULT_BUILD=4.5.3

COPY env.yml /tmp/env.yml
RUN conda env update --name base --file /tmp/env.yml && \
    rm /tmp/env.yml && \
    conda clean --all --yes

RUN test "$(Rscript -e 'cat(as.character(getRversion()))')" = "${R_VER}" && \
    ! conda list 2>&1 | grep -qi "error while loading" && \
    Rscript -e 'for (p in c("argparse", "optparse", "tidyverse", "data.table", "ggpubr", "Cairo", "hdf5r", "RCurl", "XML")) suppressPackageStartupMessages(library(p, character.only = TRUE)); stopifnot(capabilities("cairo")); cat("R", as.character(getRversion()), "tidyverse", as.character(packageVersion("tidyverse")), "\n")'
