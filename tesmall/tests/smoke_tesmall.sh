#!/usr/bin/env bash
# Smoke test of the TEsmall image as gcf-workflows runs it (non-root user, read-only root filesystem):
# builds a tiny synthetic TEsmall database (two chromosomes with one miRNA hairpin each, a rDNA and a tDNA
# sequence, empty TE/exon/intron/piRNA_cluster BEDs), then counts synthetic, already-trimmed reads.
# - With --no-trim, the reads of a mature miRNA that begins with ATC (the end of TEsmall's built-in 5'
#   adapter) reach the alignment unchanged, and both miRNAs get all their reads.
# - Without it, TEsmall's 5' trim removes the ATC from those reads (here they still count for the miRNA,
#   since TEsmall's 90% overlap is measured on the read, but on a real genome a shorter read can map to
#   more places or fall below the minimum length).
# Usage: tests/smoke_tesmall.sh [image] [workdir]
set -euo pipefail
image=${1:-gcfntnu/tesmall:2.1.0-1}
work=${2:-$(mktemp -d)}
mkdir -p "$work"
docker run --rm --user "$(id -u):$(id -g)" --read-only --tmpfs /tmp -e HOME=/tmp \
    -v "$work:/work" -w /work "$image" bash -c '
set -euo pipefail
python - <<PY
import random
random.seed(1)
rnd = lambda n: "".join(random.choice("ACGT") for _ in range(n))
mir_a = "ATCACATTGCCAGGGATTTCCA"      # begins with ATC
mir_b = "TAGCTTATCAGACTGATGTTGA"
chr1 = rnd(300) + rnd(20) + mir_a + rnd(30) + rnd(300)
chr2 = rnd(300) + rnd(20) + mir_b + rnd(30) + rnd(300)
import os
d = "db/genomes/synthetic_test"
os.makedirs(d + "/sequence/bowtie_index"); os.makedirs(d + "/annotation")
open(d + "/sequence/genome.fa", "w").write(">chr1\n%s\n>chr2\n%s\n" % (chr1, chr2))
open(d + "/sequence/rDNA.fa", "w").write(">rDNA\n%s\n" % rnd(500))
open(d + "/sequence/tDNA.fa", "w").write(">tRNA-Gly-GCC-1-1:chr9:1-73:+\n%s\n" % (rnd(70) + "CCA"))
a0, b0 = 320, 320
bed = lambda rows: "".join("\t".join(map(str, r)) + "\n" for r in rows)
open(d + "/annotation/miRNA.bed", "w").write(bed([("chr1", a0, a0 + 22, "syn-miR-A", 0, "+"), ("chr2", b0, b0 + 22, "syn-miR-B", 0, "+")]))
open(d + "/annotation/hairpin.bed", "w").write(bed([("chr1", 300, 372, "syn-mir-A", 0, "+"), ("chr2", 300, 372, "syn-mir-B", 0, "+")]))
for name in ("structural_RNA", "exon", "TE", "intron", "piRNA_cluster"):
    open(d + "/annotation/%s.bed" % name, "w").write("")
reads = [mir_a] * 10 + [mir_b] * 5
with open("reads.fastq", "w") as fh:
    for i, s in enumerate(reads):
        fh.write("@r%d\n%s\n+\n%s\n" % (i, s, "I" * len(s)))
PY
d=db/genomes/synthetic_test/sequence
for n in genome rDNA tDNA; do samtools faidx $d/$n.fa; bowtie-build -q $d/$n.fa $d/bowtie_index/$n; done
run() { rm -rf "$1" && mkdir "$1" && cd "$1" && TEsmall -f ../reads.fastq -l S1 -g synthetic_test --dbfolder ../db --verbose 0 $2 && cd ..; }
run notrim --no-trim
run trim ""
count() { awk -F"\t" -v f="$2" "\$1 == f && \$2 == \"miRNA\" {print \$3}" "$1/count_summary.txt"; }
a_notrim=$(count notrim syn-miR-A); b_notrim=$(count notrim syn-miR-B); a_trim=$(count trim syn-miR-A)
echo "--no-trim: syn-miR-A ${a_notrim:-0}, syn-miR-B ${b_notrim:-0}; default trimming: syn-miR-A ${a_trim:-0}"
[ "${a_notrim:-0}" = 10 ] && [ "${b_notrim:-0}" = 5 ] || { echo "FAIL: --no-trim counts"; exit 1; }
reads() { awk "NR % 4 == 2" "$1/S1.trimmed2.fastq" | sort | uniq -c | awk "{print \$1 \":\" \$2}" | tr "\n" " "; }
echo "reads aligned, --no-trim: $(reads notrim)"
echo "reads aligned, default:   $(reads trim)"
[ "$(reads notrim)" = "10:ATCACATTGCCAGGGATTTCCA 5:TAGCTTATCAGACTGATGTTGA " ] || { echo "FAIL: --no-trim changed reads"; exit 1; }
[ "$(reads trim)" = "10:ACATTGCCAGGGATTTCCA 5:TAGCTTATCAGACTGATGTTGA " ] || { echo "FAIL: expected the built-in 5\x27 trim to cut ATC"; exit 1; }
grep -q "Total reads processed: *15" notrim/S1.cutadapt1.log || { echo "FAIL: cutadapt1.log"; exit 1; }
echo "OK"
'
