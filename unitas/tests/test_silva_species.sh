#!/usr/bin/env bash
# Synthetic check of unitas_silva_species.awk: selects by NCBI taxid (not organism name), joins
# multi-line sequences, writes DNA letters in FASTA order, and fails without a match, with an entry
# missing from the FASTA, or without -v taxid/unit.
# Usage: tests/test_silva_species.sh [awk]   (default: awk; run with mawk and gawk where available)
set -euo pipefail
read -r -a AWK <<< "${1:-awk}"
here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
prog=$here/../unitas_silva_species.awk
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
fail() { echo "FAIL (${AWK[*]}): $*" >&2; exit 1; }

# SILVA 132 taxmap layout: NCBI taxid last, with a leading space; one entry listed twice
printf 'primaryAccession\tstart\tstop\tpath\torganism_name\ttaxid\n' > "$tmp/taxmap"
printf '%s\t%s\t%s\t%s\t%s\t%s\n' \
    B2 10 17 'Eukaryota;Metazoa;' 'Homo sapiens (human)' ' 9606' \
    A1 1 12 'Eukaryota;Metazoa;' 'Homo sapiens (human)' ' 9606' \
    C3 1 4 'Bacteria;Tenericutes;' 'Homo sapiens' ' 2093' \
    D4 1 4 'Eukaryota;Metazoa;' 'Mus musculus (house mouse)' ' 10090' \
    A1 1 12 'Eukaryota;Metazoa;' 'Homo sapiens (human)' ' 9606' >> "$tmp/taxmap"
cat > "$tmp/silva.fa" <<'EOF'
>A1.1.12 Eukaryota;Opisthokonta;Holozoa;Metazoa (Animalia);Homo sapiens (human)
ACGUAC
guacgu
>C3.1.4 Bacteria;Tenericutes;Mollicutes;Mycoplasma
UUUU
>D4.1.4 Eukaryota;Mus musculus (house mouse)
GGGG
>B2.10.17 Eukaryota;Homo sapiens (human)
AAAAUUUU
EOF
cat > "$tmp/expected.fa" <<'EOF'
>rRNA|SSU:A1.1.12
ACGTACGTACGT
>rRNA|SSU:B2.10.17
AAAATTTT
EOF
"${AWK[@]}" -v taxid=9606 -v unit=SSU -f "$prog" "$tmp/taxmap" "$tmp/silva.fa" > "$tmp/out.fa" 2> "$tmp/err" \
    || fail "human SSU: $(cat "$tmp/err")"
diff -u "$tmp/expected.fa" "$tmp/out.fa" || fail "human SSU output"
grep -q '2 SSU sequences for taxid 9606' "$tmp/err" || fail "no count message: $(cat "$tmp/err")"

printf '>rRNA|LSU:D4.1.4\nGGGG\n' > "$tmp/expected.fa"
"${AWK[@]}" -v taxid=10090 -v unit=LSU -f "$prog" "$tmp/taxmap" "$tmp/silva.fa" 2> /dev/null | diff -u "$tmp/expected.fa" - \
    || fail "mouse LSU output"

if "${AWK[@]}" -v taxid=10116 -v unit=SSU -f "$prog" "$tmp/taxmap" "$tmp/silva.fa" > /dev/null 2> "$tmp/err"; then
    fail "no matching taxid succeeded"
fi
grep -q 'no SSU entries with NCBI taxid 10116' "$tmp/err" || fail "no-match message: $(cat "$tmp/err")"

grep -v -e '^>B2' -e '^AAAAUUUU' "$tmp/silva.fa" > "$tmp/short.fa"
if "${AWK[@]}" -v taxid=9606 -v unit=SSU -f "$prog" "$tmp/taxmap" "$tmp/short.fa" > /dev/null 2> "$tmp/err"; then
    fail "entry missing from the FASTA succeeded"
fi
grep -q 'B2.10.17 is in the taxmap but not in the FASTA' "$tmp/err" || fail "missing-entry message: $(cat "$tmp/err")"

for args in "-v unit=SSU" "-v taxid=9606" "-v taxid=9606 -v unit=5S"; do
    # shellcheck disable=SC2086
    if "${AWK[@]}" $args -f "$prog" "$tmp/taxmap" "$tmp/silva.fa" > /dev/null 2>&1; then fail "'$args' succeeded"; fi
done
echo ok
