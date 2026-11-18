#!/usr/bin/env bash
# Synthetic check of the downloads in unitas_build_refdump.sh: only release-specific miRBase URLs are
# requested, the release is required, an unavailable release fails, and the release and file
# checksums are recorded in the dump; piRNA clusters come from piRNAclusterDB and SILVA 132 from
# SILVA, md5-checked (a wrong md5 fails), and only tRF-1 and tRNA leaders from the static dump.
# A fake curl serves tiny files and logs the requested URLs; a fake unitas.pl writes a minimal dump.
# No network, no UNITAS.
# Usage: tests/test_build_refdump_mirbase.sh
set -euo pipefail
here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
script=$here/../unitas_build_refdump.sh
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
fail() { echo "FAIL: $*" >&2; exit 1; }

mkdir -p "$tmp/bin" "$tmp/static"
cat > "$tmp/bin/curl" <<'EOF'
#!/usr/bin/env bash
# fake curl: logs the URL, writes a tiny file to -o, fails (like curl -f) for release 99.9;
# <url>.md5 is the md5 of <url>'s content (wrong when FAKE_BAD_MD5 is set)
out= url=
while (( $# )); do case $1 in -o) out=$2; shift 2 ;; --retry) shift 2 ;; -*) shift ;; *) url=$1; shift ;; esac; done
echo "$url" >> "$FAKE_CURL_LOG"
[[ $url == */download_version_files/99.9/* ]] && exit 22
emit() { if [[ -n $out ]]; then cat > "$out"; else cat; fi; }
content() {
    case $1 in
        *Ref_tax_silva.fasta.gz) printf '>X1.1.8 Eukaryota;Homo sapiens (human)\nACGU\nACGU\n>Y1.1.4 Bacteria;Escherichia coli\nUUUU\n' | gzip -n ;;
        *taxmap_embl_*_ref_132.txt.gz)
            printf 'primaryAccession\tstart\tstop\tpath\torganism_name\ttaxid\nX1\t1\t8\tEukaryota;\tHomo sapiens (human)\t 9606\nY1\t1\t4\tBacteria;\tEscherichia coli\t 562\n' | gzip -n ;;
        *.fa.gz) printf '>ENST1 ncrna\nACGT\n' | gzip -n ;;
        */mature.fa) printf '>hsa-let-7a-5p MIMAT0000062 Homo sapiens let-7a-5p\nUGAGGUAGUAGGUUGUAUAGUU\n' ;;
        */hairpin.fa) printf '>hsa-let-7a-1 MI0000060 Homo sapiens let-7a-1 stem-loop\nUGGGAUGAGGUAGUAGGUUGUAUAGUUUUAGGGUCACACCCACCACUGGGAGAUAACUAUACAAUCUACUGUCUUUCCUA\n' ;;
        *tRNAs.fa) printf '>Homo_sapiens_tRNA-Ala-AGC-1-1\nGGGGGTGTAGCTCAG\n' ;;
        *piRNAclusters.fasta) printf '>Hsap_0001 4:10087069..10432971\nTTAGGGTTCAG\n' ;;
        *) printf '<html>Version 22.1</html>\n' ;;
    esac
}
if [[ $url == *.md5 ]]; then
    if [[ -n ${FAKE_BAD_MD5:-} ]]; then echo "00000000000000000000000000000000  x" | emit
    else printf '%s  %s\n' "$(content "${url%.md5}" | md5sum | cut -d' ' -f1)" "$(basename "${url%.md5}")" | emit; fi
else
    content "$url" | emit
fi
EOF
cat > "$tmp/bin/unitas.pl" <<'EOF'
#!/usr/bin/env bash
# fake unitas.pl -refdump -species S -mirror M: a dump with the files the builder checks
species=$3 d=UNITAS_refdump_$3
mkdir -p "$d"
for f in db_versions.info ncRNA.fas cDNA.fas tRF-1.fas tRNA_leader.fas miRBase_mature piRclDB \
         miRBase_hairpin_Human.fas miRBase_hairpin_non-Human.fas; do printf '>x\nACGT\n' > "$d/$f"; done
EOF
chmod +x "$tmp/bin/curl" "$tmp/bin/unitas.pl"
for f in tRF-1.fas tRNA_leader.fas; do printf '>s\nACGT\n' > "$tmp/static/$f"; done
cat > "$tmp/static/db_versions.info" <<'EOF'
tRF-1 sequence data version/date: ......... 09.04.2019 (dd.mm.yyyy)
tRNA-leader sequence data version/date: ... 09.04.2019 (dd.mm.yyyy)
EOF

export PATH=$tmp/bin:$PATH
build() {  # name args...: runs the builder, logs to $tmp/<name>.{out,urls}
    local name=$1; shift
    export FAKE_CURL_LOG=$tmp/$name.urls; : > "$FAKE_CURL_LOG"
    bash "$script" --species homo_sapiens --static-dir "$tmp/static" --ensembl-release 116 \
        --outdir "$tmp/$name" "$@" > "$tmp/$name.out" 2>&1
}

# Pinned release: only release-specific miRBase URLs, release and checksums recorded.
build ok --mirbase-release 23.1 --workdir "$tmp/ok.work" || fail "build with --mirbase-release 23.1 failed: $(tail -3 "$tmp/ok.out")"
dump=$tmp/ok/UNITAS_refdump_homo_sapiens
mb=https://www.mirbase.org/download_version_files/23.1
grep 'mirbase\.org' "$tmp/ok.urls" > "$tmp/ok.mirbase" || true
printf '%s\n' "$mb/mature.fa" "$mb/hairpin.fa" | diff -u - "$tmp/ok.mirbase" || fail "unexpected miRBase URLs"
printf 'database\trelease\nmirbase\t23.1\n' | diff -u - "$dump/gcf_mirna_db.tsv" || fail "gcf_mirna_db.tsv"
for f in mature hairpin; do
    awk -F'\t' -v f="$f.fa" -v u="$mb/$f.fa" '$1 == f && $2 == u && $3 ~ /^[0-9a-f]{64}$/ { ok = 1 } END { exit !ok }' \
        "$dump/gcf_sources.tsv" || fail "gcf_sources.tsv has no $mb/$f.fa row with a SHA-256"
done
grep -q 'build UNITAS_refdump_homo_sapiens (.*, miRBase 23.1)' "$tmp/ok.out" || fail "build log does not name miRBase 23.1"

# piRNA clusters and SILVA come from their public sources, recorded with checksums; SILVA is reduced
# to the species (taxid 9606) in the old server's layout; only tRF-1 and tRNA leaders are static.
silva=https://ftp.arb-silva.de/release_132/Exports
for u in https://www.pirnaclusterdb.org/data/FASTA/Homo_sapiens.piRNAclusters.fasta \
         "$silva/SILVA_132_SSURef_tax_silva.fasta.gz" "$silva/taxonomy/taxmap_embl_ssu_ref_132.txt.gz" \
         "$silva/SILVA_132_LSURef_tax_silva.fasta.gz" "$silva/taxonomy/taxmap_embl_lsu_ref_132.txt.gz"; do
    awk -F'\t' -v u="$u" '$2 == u && $3 ~ /^[0-9a-f]{64}$/ { ok = 1 } END { exit !ok }' "$dump/gcf_sources.tsv" \
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
echo ok
