#!/usr/bin/env bash
# Synthetic check of the downloads in unitas_build_refdump.sh: only release-specific miRBase URLs are
# requested, the release is required, an unavailable release fails, and the release and file
# checksums are recorded in the dump; piRNA clusters come from piRNAclusterDB and SILVA 132 from
# SILVA, md5-checked (a wrong md5 fails), and only tRF-1 and tRNA leaders from the static dump.
# The dump is rejected for ncRNA names from an unpatched unitas.pl (gcfntnu/gcf-docker#56).
# A fake curl (tests/fake_curl) serves tiny files and logs the requested URLs; a fake unitas.pl
# writes a minimal dump.
# No network, no UNITAS.
# Usage: tests/test_build_refdump_mirbase.sh
set -euo pipefail
here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
script=$here/../unitas_build_refdump.sh
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
fail() { echo "FAIL: $*" >&2; exit 1; }

mkdir -p "$tmp/static"
cat > "$tmp/fake_unitas.pl" <<'EOF'
#!/usr/bin/env bash
# fake unitas.pl -refdump -species S -mirror M: a dump with the files the builder checks;
# FAKE_UNITAS_NCRNA (printf %b) replaces ncRNA.fas
species=$3 d=UNITAS_refdump_$3
mkdir -p "$d"
for f in db_versions.info ncRNA.fas cDNA.fas tRF-1.fas tRNA_leader.fas miRBase_mature piRclDB \
         miRBase_hairpin_Human.fas miRBase_hairpin_non-Human.fas; do printf '>x\nACGT\n' > "$d/$f"; done
[[ -z ${FAKE_UNITAS_NCRNA:-} ]] || printf '%b' "$FAKE_UNITAS_NCRNA" > "$d/ncRNA.fas"
EOF
printf '>tRNA|tRF-1_>#297\nACGT\n>tRNA|tRF-1_x\nACGT\n' > "$tmp/static/tRF-1.fas"   # rat-like '>' inside a name
printf '>s\nACGT\n' > "$tmp/static/tRNA_leader.fas"
cat > "$tmp/static/db_versions.info" <<'EOF'
tRF-1 sequence data version/date: ......... 09.04.2019 (dd.mm.yyyy)
tRNA-leader sequence data version/date: ... 09.04.2019 (dd.mm.yyyy)
EOF

# The fakes are exported functions, not files on PATH: /tmp may be noexec (docker --tmpfs), and a
# skipped fake would let the builder download the real data or run the real unitas.pl.
export FAKE_CURL=$here/fake_curl FAKE_UNITAS=$tmp/fake_unitas.pl
curl() { bash "$FAKE_CURL" "$@"; }
unitas.pl() { bash "$FAKE_UNITAS" "$@"; }
export -f curl unitas.pl
build() {  # name args...: runs the builder, logs to $tmp/<name>.{out,urls}
    local name=$1; shift
    export FAKE_CURL_LOG=$tmp/$name.urls; : > "$FAKE_CURL_LOG"
    bash "$script" --species homo_sapiens --static-dir "$tmp/static" --ensembl-release 116 \
        --outdir "$tmp/$name" "$@" > "$tmp/$name.out" 2>&1
}

# Pinned release: only release-specific miRBase URLs, release and checksums recorded.
build ok --mirbase-release 23.1 --workdir "$tmp/ok.work" || fail "build with --mirbase-release 23.1 failed: $(tail -3 "$tmp/ok.out")"
[[ -s $tmp/ok.urls ]] || fail "the fake curl was not used"
dump=$tmp/ok/UNITAS_refdump_homo_sapiens
mb=https://www.mirbase.org/download_version_files/23.1
grep 'mirbase\.org' "$tmp/ok.urls" > "$tmp/ok.mirbase" || true
printf '%s\n' "$mb/mature.fa" "$mb/hairpin.fa" | diff -u - "$tmp/ok.mirbase" || fail "unexpected miRBase URLs"
printf 'database\trelease\nmirbase\t23.1\n' | diff -u - "$dump/gcf_mirna_db.tsv" || fail "gcf_mirna_db.tsv"
for f in mature hairpin; do
    awk -F'\t' -v f="$f.fa" -v u="$mb/$f.fa" '$1 == f && $2 == u && length($3) == 64 && $3 ~ /^[0-9a-f]+$/ { ok = 1 } END { exit !ok }' \
        "$dump/gcf_sources.tsv" || fail "gcf_sources.tsv has no $mb/$f.fa row with a SHA-256"
done
grep -q 'build UNITAS_refdump_homo_sapiens (.*, miRBase 23.1)' "$tmp/ok.out" || fail "build log does not name miRBase 23.1"
# The 45S pre-rRNA (gcfntnu/gcf-docker#61): the pinned RefSeq record, recorded with its SHA-256, added to ncRNA.fas.
efetch='https://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=nuccore&id=NR_046235.3&rettype=fasta&retmode=text'
grep -qxF "$efetch" "$tmp/ok.urls" || fail "the 45S pre-rRNA NR_046235.3 was not requested"
awk -F'\t' -v u="$efetch" '$1 == "NR_046235.3.fa" && $2 == u && length($3) == 64 { ok = 1 } END { exit !ok }' "$dump/gcf_sources.tsv" \
    || fail "gcf_sources.tsv has no NR_046235.3.fa row with a SHA-256"
tail -2 "$dump/ncRNA.fas" | diff -u - <(printf '>rRNA|45S_pre-rRNA-NR_046235.3\nTACCTGGTTGATCCTGCCAGTCGTACGACTCTTAGCGG\n') \
    || fail "ncRNA.fas does not end with the 45S pre-rRNA record"
grep -q '^masked ' "$dump/gcf_refdump.log" || fail "gcf_refdump.log does not report the snoRNA masking"

# piRNA clusters and SILVA come from their public sources, recorded with checksums; SILVA is reduced
# to the species (taxid 9606) in the old server's layout; only tRF-1 and tRNA leaders are static.
silva=https://ftp.arb-silva.de/release_132/Exports
for u in https://www.pirnaclusterdb.org/data/FASTA/Homo_sapiens.piRNAclusters.fasta \
         "$silva/SILVA_132_SSURef_tax_silva.fasta.gz" "$silva/taxonomy/taxmap_embl_ssu_ref_132.txt.gz" \
         "$silva/SILVA_132_LSURef_tax_silva.fasta.gz" "$silva/taxonomy/taxmap_embl_lsu_ref_132.txt.gz"; do
    awk -F'\t' -v u="$u" '$2 == u && length($3) == 64 && $3 ~ /^[0-9a-f]+$/ { ok = 1 } END { exit !ok }' "$dump/gcf_sources.tsv" \
        || fail "gcf_sources.tsv has no $u row with a SHA-256"
    grep -qx "$u.md5" "$tmp/ok.urls" || [[ $u == *pirnaclusterdb* ]] || fail "$u.md5 not fetched"
done
for unit in SSU LSU; do
    printf '>rRNA|%s:X1.1.8\nACGTACGT\n' "$unit" \
        | diff -u - "$tmp/ok.work/mirror/data/UNITAS/SILVA_rRNA/SILVA_${unit}_homo_sapiens.fasta" || fail "SILVA $unit selection"
    awk -F'\t' -v f="SILVA_rRNA.$unit" '$1 == f && $2 == "gcf:unitas_silva_species.awk taxid 9606" { ok = 1 } END { exit !ok }' \
        "$dump/gcf_sources.tsv" || fail "gcf_sources.tsv has no SILVA_rRNA.$unit row"
done
grep -qE "piRclDB_date='[0-9]{2}\.[0-9]{2}\.20[0-9]{2}'" "$tmp/ok.work/mirror/data/UNITAS/URLs/gtRNAdb" || fail "no piRNA cluster date"
static_rows=$(cut -f2 "$dump/gcf_sources.tsv" | grep '^static:' | xargs -n1 basename | tr '\n' ' ')
[[ $static_rows == 'tRF-1.fas tRNA_leader.fas ' ]] || fail "static rows: $static_rows"
# A '>' inside a static name is removed and counted (gcfntnu/gcf-docker#56); other files are copied as they are.
printf '>tRNA|tRF-1_#297\nACGT\n>tRNA|tRF-1_x\nACGT\n' | diff -u - "$tmp/ok.work/mirror/data/UNITAS/tRF-1/homo_sapiens.tRF-1.fas" \
    || fail "static tRF-1 names"
cmp -s "$tmp/static/tRNA_leader.fas" "$tmp/ok.work/mirror/data/UNITAS/tRNA_leader/homo_sapiens.tRNA_leader.fas" || fail "tRNA leaders changed"
[[ $(cut -f1,2 "$dump/gcf_sources.tsv" | grep -c '^[^	]*	gcf:removed') == 1 ]] \
    && grep -q "^tRF-1.fas	gcf:removed '>' inside 1 names	" "$dump/gcf_sources.tsv" || fail "gcf_sources.tsv row for the stripped names"

# A SILVA download that does not match SILVA's md5 fails.
if FAKE_BAD_MD5=1 build badmd5 --mirbase-release 23.1; then fail "build with a wrong md5 succeeded"; fi
grep -q 'md5 differs from .*SILVA_132_SSURef_tax_silva.fasta.gz.md5' "$tmp/badmd5.out" || fail "bad md5: $(tail -2 "$tmp/badmd5.out")"

# Missing or malformed release: fails before any download.
for args in "" "--mirbase-release current" "--mirbase-release 23.1a"; do
    # shellcheck disable=SC2086
    if build bad $args; then fail "build with '${args:-no release}' succeeded"; fi
    grep -q -- '--mirbase-release' "$tmp/bad.out" || fail "'${args:-no release}': no --mirbase-release error: $(cat "$tmp/bad.out")"
    [[ ! -s $tmp/bad.urls ]] || fail "'${args:-no release}' downloaded: $(head -1 "$tmp/bad.urls")"
done

# Unavailable release: the download fails; no fallback to the current release.
if build gone --mirbase-release 99.9; then fail "build with an unavailable release succeeded"; fi
grep -q 'download failed: .*/download_version_files/99.9/mature.fa' "$tmp/gone.out" || fail "99.9: $(tail -2 "$tmp/gone.out")"
grep -q 'mirbase\.org/download/' "$tmp/gone.urls" && fail "99.9 fell back to the current release"
[[ ! -e $tmp/gone/UNITAS_refdump_homo_sapiens.tar.gz ]] || fail "99.9 wrote a dump"

# Names from an unpatched unitas.pl fail the build (gcfntnu/gcf-docker#56).
if FAKE_UNITAS_NCRNA='>lncRNA|>ENST1.1-ENSG1.1\nACGT\n' build gt --mirbase-release 23.1; then fail "a '|>' name passed"; fi
grep -q "headers with '>' after the first character.*lncRNA|>ENST1.1-ENSG1.1" "$tmp/gt.out" || fail "'|>': $(tail -2 "$tmp/gt.out")"
if FAKE_UNITAS_NCRNA='>lncRNA|LINCX-(2)\nACGT\n' build dup --mirbase-release 23.1; then fail "a '-(2)' name passed"; fi
grep -q 'names without the gene ID.*lncRNA|LINCX-(2)' "$tmp/dup.out" || fail "'-(2)': $(tail -2 "$tmp/dup.out")"
[[ ! -e $tmp/gt/UNITAS_refdump_homo_sapiens.tar.gz && ! -e $tmp/dup/UNITAS_refdump_homo_sapiens.tar.gz ]] || fail "a rejected dump was written"
FAKE_UNITAS_NCRNA='>lncRNA|LINCX-ENSG1.1_(2)\nACGT\n>lncRNA|ENST5.1-ENSG5.1\nACGT\n' build fixed --mirbase-release 23.1 \
    || fail "fixed names were rejected: $(tail -2 "$tmp/fixed.out")"
echo ok
