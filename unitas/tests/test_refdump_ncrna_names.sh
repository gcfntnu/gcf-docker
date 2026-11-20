#!/usr/bin/env bash
# ncRNA names in a dump built by the real unitas.pl -refdump (gcfntnu/gcf-docker#56): runs
# unitas_build_refdump.sh with the fake curl (tests/fake_curl) serving a synthetic Ensembl ncRNA
# FASTA, and the unitas.pl on PATH. Run it inside the image; without unitas.pl it skips.
#   - a record without gene_symbol is named by its transcript ID, without the FASTA '>';
#   - a gene's further transcripts keep the gene ID (<symbol>-<gene>_(n)), so two genes sharing a
#     symbol keep separate records (the unpatched <symbol>-(n) key merged their sequences);
#   - miRNA records are left out.
# Usage: docker run --rm --user 1000:1000 --read-only --tmpfs /tmp -v "$PWD/unitas:/src:ro" \
#            gcfntnu/unitas:<tag> bash /src/tests/test_refdump_ncrna_names.sh
set -euo pipefail
here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
script=$here/../unitas_build_refdump.sh
command -v unitas.pl > /dev/null || { echo "skip: no unitas.pl on PATH (run in the image)"; exit 0; }
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
fail() { echo "FAIL: $*" >&2; exit 1; }

mkdir -p "$tmp/static"
# The fake curl is an exported function, not a file on PATH: /tmp may be noexec (docker --tmpfs),
# and a skipped fake would let the builder download the real data.
export FAKE_CURL=$here/fake_curl
curl() { bash "$FAKE_CURL" "$@"; }
export -f curl
for f in tRF-1.fas tRNA_leader.fas; do printf '>s\nACGT\n' > "$tmp/static/$f"; done
cat > "$tmp/static/db_versions.info" <<'EOF'
tRF-1 sequence data version/date: ......... 09.04.2019 (dd.mm.yyyy)
tRNA-leader sequence data version/date: ... 09.04.2019 (dd.mm.yyyy)
EOF
h() {  # transcript gene biotype [symbol]: an Ensembl 116 ncRNA header
    printf '>%s ncrna chromosome:GRCh38:1:1:100:1 gene:%s gene_biotype:%s transcript_biotype:%s%s description:x\n' \
        "$1" "$2" "$3" "$3" "${4:+ gene_symbol:$4}"
}
{
    h ENST00000000001.1 ENSG00000000001.1 lncRNA LINCX; printf 'AAAAACCCCC\nAAAAA\n'
    h ENST00000000002.1 ENSG00000000001.1 lncRNA LINCX; printf 'AAAAAGGGGG\n'
    h ENST00000000003.1 ENSG00000000002.1 lncRNA LINCX; printf 'CCCCCTTTTT\n'
    h ENST00000000004.1 ENSG00000000002.1 lncRNA LINCX; printf 'GGGGGTTTTT\n'
    h ENST00000000005.1 ENSG00000000005.1 lncRNA; printf 'ACGTACGTAC\n'
    h ENST00000000006.1 ENSG00000000006.1 miRNA MIRX; printf 'UUUUUUUUUU\n'
} > "$tmp/ncrna.fa"

export FAKE_CURL_LOG=$tmp/urls FAKE_NCRNA=$tmp/ncrna.fa
: > "$FAKE_CURL_LOG"
if ! bash "$script" --species homo_sapiens --static-dir "$tmp/static" --ensembl-release 116 \
        --mirbase-release 23.1 --workdir "$tmp/work" --outdir "$tmp/out" > "$tmp/out.log" 2>&1; then
    found=$tmp/work/run/UNITAS_refdump_homo_sapiens/ncRNA.fas
    [[ -s $found ]] && { echo "ncRNA.fas lncRNA/miRNA records:"; grep -A1 -E '^>(lncRNA|miRNA)\|' "$found" | grep -v '^--$'; } >&2
    fail "build failed: $(tail -2 "$tmp/out.log")"
fi
grep -q 'ncrna/Homo_sapiens.GRCh38.ncrna.fa.gz$' "$FAKE_CURL_LOG" || fail "the fake curl was not used"
dump=$tmp/out/UNITAS_refdump_homo_sapiens
awk '/^>/ { name = substr($0, 2); next } { seq[name] = seq[name] $0 } END { for (n in seq) print n "\t" seq[n] }' \
    "$dump/ncRNA.fas" | grep -E '^(lncRNA|miRNA)\|' | sort > "$tmp/got.tsv"
printf '%s\t%s\n' \
    'lncRNA|ENST00000000005.1-ENSG00000000005.1' ACGTACGTAC \
    'lncRNA|LINCX-ENSG00000000001.1' AAAAACCCCCAAAAA \
    'lncRNA|LINCX-ENSG00000000001.1_(2)' AAAAAGGGGG \
    'lncRNA|LINCX-ENSG00000000002.1' CCCCCTTTTT \
    'lncRNA|LINCX-ENSG00000000002.1_(2)' GGGGGTTTTT | sort > "$tmp/want.tsv"
diff -u "$tmp/want.tsv" "$tmp/got.tsv" || fail "ncRNA.fas lncRNA/miRNA records differ from the expected names and sequences"
echo ok
