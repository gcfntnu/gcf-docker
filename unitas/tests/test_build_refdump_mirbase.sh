#!/usr/bin/env bash
# Synthetic check of the miRBase download in unitas_build_refdump.sh: only release-specific miRBase
# URLs are requested, the release is required, an unavailable release fails, and the release and
# file checksums are recorded in the dump. A fake curl serves tiny files and logs the requested URLs;
# a fake unitas.pl writes a minimal dump. No network, no UNITAS.
# Usage: tests/test_build_refdump_mirbase.sh
set -euo pipefail
here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
script=$here/../unitas_build_refdump.sh
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
fail() { echo "FAIL: $*" >&2; exit 1; }

mkdir -p "$tmp/bin" "$tmp/static"
cat > "$tmp/bin/curl" <<'EOF'
#!/usr/bin/env bash
# fake curl: logs the URL, writes a tiny file to -o, fails (like curl -f) for release 99.9
out= url=
while (( $# )); do case $1 in -o) out=$2; shift 2 ;; --retry) shift 2 ;; -*) shift ;; *) url=$1; shift ;; esac; done
echo "$url" >> "$FAKE_CURL_LOG"
[[ $url == */download_version_files/99.9/* ]] && exit 22
emit() { if [[ -n $out ]]; then cat > "$out"; else cat; fi; }
case $url in
    *.fa.gz) printf '>ENST1 ncrna\nACGT\n' | gzip -n | emit ;;
    */mature.fa) printf '>hsa-let-7a-5p MIMAT0000062 Homo sapiens let-7a-5p\nUGAGGUAGUAGGUUGUAUAGUU\n' | emit ;;
    */hairpin.fa) printf '>hsa-let-7a-1 MI0000060 Homo sapiens let-7a-1 stem-loop\nUGGGAUGAGGUAGUAGGUUGUAUAGUUUUAGGGUCACACCCACCACUGGGAGAUAACUAUACAAUCUACUGUCUUUCCUA\n' | emit ;;
    *tRNAs.fa) printf '>Homo_sapiens_tRNA-Ala-AGC-1-1\nGGGGGTGTAGCTCAG\n' | emit ;;
    *) printf '<html>Version 22.1</html>\n' | emit ;;
esac
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
for f in piRclDB tRF-1.fas tRNA_leader.fas SILVA_rRNA.SSU SILVA_rRNA.LSU; do printf '>s\nACGT\n' > "$tmp/static/$f"; done
cat > "$tmp/static/db_versions.info" <<'EOF'
piRNA cluster database version/date: ...... 24.05.2022 (dd.mm.yyyy)
tRF-1 sequence data version/date: ......... 09.04.2019 (dd.mm.yyyy)
tRNA-leader sequence data version/date: ... 09.04.2019 (dd.mm.yyyy)
SILVA rRNA (SSU) database version/date: ... Release 132
EOF

export PATH=$tmp/bin:$PATH
build() {  # name args...: runs the builder, logs to $tmp/<name>.{out,urls}
    local name=$1; shift
    export FAKE_CURL_LOG=$tmp/$name.urls; : > "$FAKE_CURL_LOG"
    bash "$script" --species homo_sapiens --static-dir "$tmp/static" --ensembl-release 116 \
        --outdir "$tmp/$name" "$@" > "$tmp/$name.out" 2>&1
}

# Pinned release: only release-specific miRBase URLs, release and checksums recorded.
build ok --mirbase-release 23.1 || fail "build with --mirbase-release 23.1 failed: $(tail -3 "$tmp/ok.out")"
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
