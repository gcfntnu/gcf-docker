#!/usr/bin/env bash
# Smoke test of the tiny-count image as gcf-workflows runs it (non-root user, read-only root filesystem):
# collapse synthetic, already-trimmed reads with tiny-collapse, align them with Bowtie 1 (exact, all
# alignments, SAM straight from Bowtie), and count them with tiny-count against a miRBase-style GFF3.
#
# The synthetic genome has three miRNAs:
# - syn-miR-A (MIMAT9000001) on the + strand of chr1;
# - syn-miR-B (MIMAT9000002) at two loci with the same hairpin, chr1 + and chr2 - (the second locus is
#   ID MIMAT9000002_1, as miRBase names it), so its reads map twice and are divided between the loci;
# - syn-miR-C (MIMAT9000003) on the - strand of chr2, so the 5' shifts and 3' extensions must follow the strand.
#
# Rules: mature miRNA features, 5' end at -1, 0 or +1 of the annotated end, up to 4 nt beyond the 3' end,
# sense strand, 16-28 nt (three "5' anchored" rules with shifts, one per 5' offset).
# Expected: MIMAT9000001 17 (10 canonical, 4 with 2 nt more at the 3' end, 3 starting 1 nt later; not the
# 2 reads starting 2 nt later or the 2 antisense reads), MIMAT9000002 and MIMAT9000002_1 3 each (6 reads
# divided by genomic hits), MIMAT9000003 10 (5 canonical, 3 with 2 nt more at the 3' end, 2 starting 1 nt
# earlier). 3 reads with a non-templated 3' base do not align with -v 0.
# Usage: tests/smoke_tiny_count.sh [image] [workdir]
# Each run writes to a new run.XXXXXX folder in workdir (default: a new temporary folder), so a reused workdir
# cannot pass on an earlier run's tables.
set -euo pipefail
image=${1:-gcfntnu/tiny-count:1.6.0-1}
work=${2:-$(mktemp -d)}
mkdir -p "$work"
run=$(mktemp -d "$(cd "$work" && pwd)/run.XXXXXX")   # absolute: docker -v takes a bare name for a named volume
docker run --rm --user "$(id -u):$(id -g)" --read-only --tmpfs /tmp -e HOME=/tmp \
    -v "$run:/work" -w /work "$image" bash -c '
set -euo pipefail
python - <<PY
import random
random.seed(1)
rnd = lambda n: "".join(random.choice("ACGT") for _ in range(n))
rc = lambda s: s[::-1].translate(str.maketrans("ACGT", "TGCA"))
hp = lambda: rnd(20) + rnd(22) + rnd(30)                 # hairpin; mature 5p arm at 20..42
hp_a, hp_b, hp_c = hp(), hp(), hp()
mat = lambda h: h[20:42]
chr1 = rnd(300) + hp_a + rnd(300) + hp_b + rnd(300)
chr2 = rnd(300) + rc(hp_b) + rnd(300) + rc(hp_c) + rnd(300)
open("genome.fa", "w").write(">chr1\n%s\n>chr2\n%s\n" % (chr1, chr2))
# GFF3 as miRBase writes it: 1-based, primary transcript and mature miRNA with Derives_from.
rows = []
def add(chrom, strand, hstart, mi, name, mimat, mid):
    hend = hstart + 72 - 1
    rows.append((chrom, ".", "miRNA_primary_transcript", hstart, hend, ".", strand, ".", "ID=%s;Alias=%s;Name=%s" % (mi, mi, name.replace("miR", "mir"))))
    s, e = (hstart + 20, hstart + 41) if strand == "+" else (hend - 41, hend - 20)
    rows.append((chrom, ".", "miRNA", s, e, ".", strand, ".", "ID=%s;Alias=%s;Name=%s;Derives_from=%s" % (mid, mimat, name, mi)))
add("chr1", "+", 301, "MI9000001", "syn-miR-A", "MIMAT9000001", "MIMAT9000001")
add("chr1", "+", 301 + 72 + 300 + 1 - 1, "MI9000002", "syn-miR-B", "MIMAT9000002", "MIMAT9000002")
add("chr2", "-", 301, "MI9000003", "syn-miR-B", "MIMAT9000002", "MIMAT9000002_1")
add("chr2", "-", 301 + 72 + 300, "MI9000004", "syn-miR-C", "MIMAT9000003", "MIMAT9000003")
with open("mirna.gff3", "w") as fh:
    fh.write("##gff-version 3\n")
    fh.writelines("\t".join(map(str, r)) + "\n" for r in rows)
a, b, c = mat(hp_a), mat(hp_b), mat(hp_c)
tail = next(n for n in "ACGT" if n != hp_a[42])  # non-templated
reads = ([a] * 10 + [a + hp_a[42:44]] * 4 + [a[1:]] * 3 + [a[2:]] * 2 + [rc(a)] * 2 + [a + tail] * 3
         + [b] * 6 + [c] * 5 + [c + hp_c[42:44]] * 3 + [hp_c[19] + c] * 2)
with open("reads.fastq", "w") as fh:
    for i, s in enumerate(reads):
        fh.write("@r%d\n%s\n+\n%s\n" % (i, s, "I" * len(s)))
PY
cat > features.csv <<CSV
Select for...,with value...,Classify as...,Source Filter,Type Filter,Hierarchy,Overlap,Mismatches,Strand,5'"'"' End Nucleotide,Length
all,all,miRNA,,miRNA,1,"5'"'"' anchored, -1, 4",,sense,all,16-28
all,all,miRNA,,miRNA,1,"5'"'"' anchored, 0, 4",,sense,all,16-28
all,all,miRNA,,miRNA,1,"5'"'"' anchored, 1, 4",,sense,all,16-28
CSV
printf "Input Files,Sample/Group Name,Replicate Number,Control,Normalization\nS1.sam,S1,1,,\n" > samples.csv
# tiny-count requires every Paths File key, also those only the full pipeline uses.
cat > paths.yml <<YML
samples_csv: samples.csv
features_csv: features.csv
gff_files:
- path: mirna.gff3
  alias: [Name]
run_directory: run_directory
tmp_directory:
ebwt: genome
reference_genome_files:
adapter_fasta:
plot_style_sheet:
YML
tiny-collapse -i reads.fastq -o S1
bowtie-build -q genome.fa genome
bowtie -x genome -f S1_collapsed.fa -v 0 --all --best --strata --reorder --no-unal --sam --seed 0 S1.sam 2> bowtie.log
# tiny-count exits 0 after some errors, so its log and output are checked too (the Python check below).
tiny-count -pf paths.yml -o syn > tiny-count.log 2>&1 || { cat tiny-count.log; exit 1; }
if grep -q Traceback tiny-count.log; then cat tiny-count.log; exit 1; fi
'
python3 - "$run" <<'PY'
import csv, sys
from pathlib import Path
work = Path(sys.argv[1])
# standalone runs write to tiny-count_<timestamp>/ with the timestamp in the file names
found = sorted(work.glob('tiny-count_*/syn_*_feature_counts.csv'))
assert len(found) == 1, 'expected one feature counts table, found {}'.format(found)
table = list(csv.DictReader(open(found[0])))
counts = {row['Feature ID']: float(row['S1_rep_1']) for row in table}
expected = {'MIMAT9000001': 17, 'MIMAT9000002': 3, 'MIMAT9000002_1': 3, 'MIMAT9000003': 10}
print('feature counts:', counts)
assert counts == expected, 'expected {}'.format(expected)
print('OK: canonical reads, 3\' extensions and 5\' shifts counted once on both strands; multimappers divided by loci')
PY
