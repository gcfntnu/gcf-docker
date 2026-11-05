#!/usr/bin/env bash
# Synthetic check of unitas_normalize_hairpin.awk (gcfntnu/gcf-docker#8).
# Usage: tests/test_normalize_hairpin.sh [awk]   (default: awk; run with mawk and gawk where available)
set -euo pipefail
read -r -a AWK <<< "${1:-awk}"   # e.g. "busybox awk"
here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
prog=$here/../unitas_normalize_hairpin.awk
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
fail() { echo "FAIL (${AWK[*]}): $*" >&2; exit 1; }

cat > "$tmp/hairpin.fa" <<'EOF'
>hsa-mir-1-1 MI0000001 Homo sapiens miR-1-1 stem-loop
ACGUACGUAC
GUACGU
>hsa-let-7a-1 MI0000002 Homo sapiens let-7a-1 stem-loop
UGAGGUAGUAGG
>hsa-mir-9001 MI0000003 Homo sapiens hsa-miR-9001 stem-loop
CCGGAAUU
>hsa-mir-9002 MI0000004 Homo sapiens hsa-miR-9001 stem-loop
CCGGAAUA
>rno-mir-9003 MI0000005 Rattus norvegicus rno-miR-9003 stem-loop
GGCCAAUU
>rno-mir-9004 MI0000006 Rattus norvegicus hsa-miR-9004 stem-loop
GGCCAAUA
>mmu-mir-9005 MI0000007 Mus musculus mmu- stem-loop
AAAA
EOF
cat > "$tmp/expected.fa" <<'EOF'
>hsa-mir-1-1 MI0000001 Homo sapiens miR-1-1 stem-loop
ACGUACGUAC
GUACGU
>hsa-let-7a-1 MI0000002 Homo sapiens let-7a-1 stem-loop
UGAGGUAGUAGG
>hsa-mir-9001 MI0000003 Homo sapiens miR-9001 stem-loop
CCGGAAUU
>hsa-mir-9002 MI0000004 Homo sapiens miR-9001 stem-loop
CCGGAAUA
>rno-mir-9003 MI0000005 Rattus norvegicus miR-9003 stem-loop
GGCCAAUU
>rno-mir-9004 MI0000006 Rattus norvegicus hsa-miR-9004 stem-loop
GGCCAAUA
>mmu-mir-9005 MI0000007 Mus musculus mmu- stem-loop
AAAA
EOF
printf 'hsa-mir-9001\thsa-miR-9001\tmiR-9001\nhsa-mir-9002\thsa-miR-9001\tmiR-9001\nrno-mir-9003\trno-miR-9003\tmiR-9003\n' \
    > "$tmp/expected.tsv"

"${AWK[@]}" -v report="$tmp/renamed.tsv" -f "$prog" "$tmp/hairpin.fa" > "$tmp/out.fa" 2> "$tmp/err" || fail "normalize exited $?"
diff -u "$tmp/expected.fa" "$tmp/out.fa" || fail "normalized FASTA differs"
diff -u "$tmp/expected.tsv" "$tmp/renamed.tsv" || fail "report differs"
grep -qx 'renamed 3' "$tmp/err" || fail "stderr: $(cat "$tmp/err")"

# Check mode: the input still has own-species prefixes, the output has none.
if "${AWK[@]}" -v mode=check -f "$prog" "$tmp/hairpin.fa" > "$tmp/check"; then fail "check passed on unnormalized input"; fi
[[ $(wc -l < "$tmp/check") -eq 3 ]] || fail "check reported $(wc -l < "$tmp/check") headers, expected 3"
"${AWK[@]}" -v mode=check -f "$prog" "$tmp/out.fa" > /dev/null || fail "check failed on normalized output"

# Usage errors exit 2.
set +e
"${AWK[@]}" -f "$prog" /dev/null 2> /dev/null; [[ $? -eq 2 ]] || fail "missing report= did not exit 2"
"${AWK[@]}" -v mode=other -f "$prog" /dev/null 2> /dev/null; [[ $? -eq 2 ]] || fail "unknown mode did not exit 2"
set -e
echo "ok (${AWK[*]})"
