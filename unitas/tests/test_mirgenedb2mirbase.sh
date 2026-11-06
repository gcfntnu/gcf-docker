#!/usr/bin/env bash
# Synthetic check of unitas_mirgenedb2mirbase.awk.
# Usage: tests/test_mirgenedb2mirbase.sh [awk]   (default: awk; run with mawk and gawk where available)
set -euo pipefail
read -r -a AWK <<< "${1:-awk}"   # e.g. "busybox awk"
here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
prog=$here/../unitas_mirgenedb2mirbase.awk
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
fail() { echo "FAIL (${AWK[*]}): $*" >&2; exit 1; }

printf '# comment\nhsa\tHomo sapiens\nmmu\tMus musculus\ncpi\tChrysemys picta bellii\n' > "$tmp/species.tsv"
cat > "$tmp/mat.fa" <<'EOF'
>Hsa-Let-7-P1b_5p
UGAGGUAGGAGGUUGUAUAGUU
>Mmu-Mir-1-P1_3p
UGGAAUGUAAAGAAGUAUGUAU
EOF
printf '>Hsa-Let-7-P1b_3p*\r\nCUAUACGGCCUCCUAGCUUUCC\r\n' > "$tmp/star.fa"
cat > "$tmp/pre.fa" <<'EOF'
>Hsa-Let-7-P1b_pre
UGAGGUAGGAGGUUGUAUAGUUGAGGAGGACACCCAAGGAG
AUCACUAUACGGCCUCCUAGCUUUCC
>Cpi-Let-7-P1b_pre
UGAGGUAGUAGGUUGUAUAGUU
EOF
cat > "$tmp/expected-mature.fa" <<'EOF'
>Hsa-Let-7-P1b_5p Hsa-Let-7-P1b_5p Homo sapiens Let-7-P1b-5p
UGAGGUAGGAGGUUGUAUAGUU
>Mmu-Mir-1-P1_3p Mmu-Mir-1-P1_3p Mus musculus Mir-1-P1-3p
UGGAAUGUAAAGAAGUAUGUAU
>Hsa-Let-7-P1b_3p* Hsa-Let-7-P1b_3p* Homo sapiens Let-7-P1b-3p
CUAUACGGCCUCCUAGCUUUCC
EOF
cat > "$tmp/expected-hairpin.fa" <<'EOF'
>Hsa-Let-7-P1b_pre Hsa-Let-7-P1b_pre Homo sapiens Let-7-P1b stem-loop
UGAGGUAGGAGGUUGUAUAGUUGAGGAGGACACCCAAGGAGAUCACUAUACGGCCUCCUAGCUUUCC
>Cpi-Let-7-P1b_pre Cpi-Let-7-P1b_pre Chrysemys picta_bellii Let-7-P1b stem-loop
UGAGGUAGUAGGUUGUAUAGUU
EOF

run() { "${AWK[@]}" -v species="$tmp/species.tsv" -f "$prog" "$@"; }
run -v kind=mature "$tmp/mat.fa" "$tmp/star.fa" > "$tmp/mature.fa" 2> "$tmp/err" || fail "mature exited $?"
diff -u "$tmp/expected-mature.fa" "$tmp/mature.fa" || fail "mature FASTA differs"
grep -qx 'converted 3' "$tmp/err" || fail "mature stderr: $(cat "$tmp/err")"
run -v kind=hairpin "$tmp/pre.fa" > "$tmp/hairpin.fa" 2> "$tmp/err" || fail "hairpin exited $?"
diff -u "$tmp/expected-hairpin.fa" "$tmp/hairpin.fa" || fail "hairpin FASTA differs"
grep -qx 'converted 2' "$tmp/err" || fail "hairpin stderr: $(cat "$tmp/err")"

# Data errors exit 1, usage errors exit 2.
expect() {  # status description input kind
    local want=$1 what=$2 input=$3 kind=$4 got
    set +e; run -v kind="$kind" "$input" > /dev/null 2>&1; got=$?; set -e
    [[ $got -eq $want ]] || fail "$what exited $got, expected $want"
}
printf '>Xyz-Mir-1_5p\nACGU\n' > "$tmp/unknown.fa";   expect 1 "unknown species" "$tmp/unknown.fa" mature
printf '>Hsa-Mir-1_pre\nACGU\n' > "$tmp/pre-as-mat.fa"; expect 1 "precursor as mature" "$tmp/pre-as-mat.fa" mature
printf '>Hsa-Mir-1_5p\nACGU\n' > "$tmp/mat-as-pre.fa";  expect 1 "mature as precursor" "$tmp/mat-as-pre.fa" hairpin
printf '>Hsa-Mir-1_5p\n>Hsa-Mir-2_5p\nACGU\n' > "$tmp/empty.fa"; expect 1 "record without sequence" "$tmp/empty.fa" mature
printf '>Hsa-Mir-1_5p\n' > "$tmp/empty-last.fa";        expect 1 "last record without sequence" "$tmp/empty-last.fa" mature
printf '>Mir1_5p\nACGU\n' > "$tmp/noprefix.fa";         expect 1 "ID without species code" "$tmp/noprefix.fa" mature
expect 2 "unknown kind" "$tmp/mat.fa" other
set +e
"${AWK[@]}" -v kind=mature -f "$prog" "$tmp/mat.fa" > /dev/null 2>&1; [[ $? -eq 2 ]] || fail "missing species= did not exit 2"
"${AWK[@]}" -v kind=mature -v species="$tmp/none.tsv" -f "$prog" "$tmp/mat.fa" > /dev/null 2>&1; [[ $? -eq 2 ]] || fail "missing species file did not exit 2"
set -e
echo "ok (${AWK[*]})"
