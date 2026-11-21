#!/usr/bin/env bash
# The parallel oligomap (mirflowz/oligomap, installed as /opt/conda/bin/oligomap) against the real one
# (/opt/conda/bin/oligomap.real), inside the image as gcf-workflows runs it (non-root user, read-only
# root filesystem). Synthetic target and queries: exact, one-mismatch and one-deletion hits, a query
# with 150 hits, queries without hits.
#   - raw output and -r report byte-identical to one run, for 1, 2, 4 and 16 parts (16 is more than
#     the target has sequences), with and without -s, with and without OLIGOMAP_SPLIT_DIR;
#   - the cache: reused by a later call, made once by concurrent calls, --split-only;
#   - a one-sequence target runs whole; -m and a bad OLIGOMAP_JOBS are refused; a failing part fails
#     the wrapper (the real oligomap returns 0 on some errors); no temporary folders are left.
# Usage: tests/test_oligomap_split.sh [image]
set -euo pipefail
image=${1:-gcfntnu/mirflowz:0.10.0-1}
docker run --rm --user "$(id -u):$(id -g)" --read-only --tmpfs /tmp -e HOME=/tmp -e TMPDIR=/tmp/tmp \
    -w /tmp "$image" bash -c '
set -euo pipefail
mkdir -p /tmp/tmp && cd /tmp
REAL=/opt/conda/bin/oligomap.real
checks=0
fail() { echo "FAIL: $*" >&2; exit 1; }
python - <<"PY"
import random, textwrap
random.seed(7)
rnd = lambda n: "".join(random.choice("ACGT") for _ in range(n))
wrap = lambda name, seq: ">" + name + "\n" + "\n".join(textwrap.wrap(seq, 60)) + "\n"
queries = [rnd(22) for _ in range(40)]
many = "GATTACAGATTACAGATTACAT"
seqs = []
for i in range(9):
    s = rnd(random.choice([400, 1500, 4000, 9000]))
    for q in random.sample(queries, 8):
        m = list(q)
        kind = random.random()
        if kind < 0.3:
            m[9] = "A" if m[9] != "A" else "G"   # one mismatch
        elif kind < 0.45:
            del m[12]                             # one deletion
        k = random.randrange(len(s))
        s = s[:k] + "".join(m) + s[k:]
    if i == 4:
        s += "".join(rnd(40) + many for _ in range(150))
    seqs.append(wrap("seq{}".format(i), s))
open("t.fa", "w").write("".join(seqs))
open("one.fa", "w").write(seqs[2])
names = ["{}-{}".format(i + 1, i % 4 + 1) for i in range(len(queries) + 1)]
open("q.fa", "w").write("".join(">{}\n{}\n".format(n, q) for n, q in zip(names, queries + [many])))
open("bad.fa", "w").write(">long\n" + rnd(1200) + "\n" + seqs[0])
PY
grep -q . t.fa && [ "$(grep -c "^>" t.fa)" -eq 9 ] || fail "test data"

for mode in "" "-s"; do
    "$REAL" t.fa q.fa $mode -r real$mode.rep > real$mode.out
    hits=$(grep -c " nc) " real$mode.out || true)
    [ "$hits" -gt 150 ] || fail "too few hits in the reference run ($hits)"
    for jobs in 1 2 4 16; do
        for cache in "" /tmp/cache; do
            OLIGOMAP_JOBS=$jobs OLIGOMAP_SPLIT_DIR=$cache oligomap t.fa q.fa $mode -r w.rep > w.out
            cmp -s real$mode.out w.out || fail "output differs: jobs=$jobs mode=[$mode] cache=[$cache]"
            cmp -s real$mode.rep w.rep || fail "report differs: jobs=$jobs mode=[$mode] cache=[$cache]"
            checks=$((checks + 2))
        done
    done
done
[ "$(ls /tmp/cache | wc -l)" -eq 3 ] || fail "expected one cache entry per number of parts above 1: $(ls /tmp/cache)"
before=$(stat -c %Y /tmp/cache/*/complete | sort | tr "\n" " ")
OLIGOMAP_JOBS=4 OLIGOMAP_SPLIT_DIR=/tmp/cache oligomap t.fa q.fa -r w.rep > w.out
[ "$before" = "$(stat -c %Y /tmp/cache/*/complete | sort | tr "\n" " ")" ] || fail "cache not reused"
for f in /tmp/cache/*/parts.tsv; do
    awk -F"\t" "NR > 1 { n += \$2 } END { exit !(n == 9) }" "$f" || fail "$f does not cover the 9 sequences"
done
checks=$((checks + 2))

for i in 1 2 3 4; do
    OLIGOMAP_JOBS=3 OLIGOMAP_SPLIT_DIR=/tmp/conc oligomap t.fa q.fa -r c$i.rep > c$i.out &
done
wait
[ "$(ls /tmp/conc | wc -l)" -eq 1 ] && [ -z "$(ls -A /tmp/conc | grep "^\.split" || true)" ] || fail "concurrent calls: $(ls -A /tmp/conc)"
for i in 1 2 3 4; do cmp -s real.out c$i.out && cmp -s real.rep c$i.rep || fail "concurrent call $i differs"; done
OLIGOMAP_JOBS=5 OLIGOMAP_SPLIT_DIR=/tmp/only oligomap --split-only t.fa > only.txt
[ -f "$(cat only.txt)/complete" ] && [ "$(ls "$(cat only.txt)"/*.fa | wc -l)" -le 5 ] || fail "--split-only"
checks=$((checks + 3))

"$REAL" one.fa q.fa -r one.rep > one.out
OLIGOMAP_JOBS=8 oligomap one.fa q.fa -r w.rep > w.out
cmp -s one.out w.out && cmp -s one.rep w.rep || fail "one-sequence target"
rc=0; OLIGOMAP_JOBS=4 oligomap t.fa q.fa -m 10 -r w.rep > w.out 2> err.txt || rc=$?
[ $rc -eq 2 ] && grep -q "not supported" err.txt || fail "-m not refused (rc $rc)"
rc=0; OLIGOMAP_JOBS=two oligomap t.fa q.fa > w.out 2> err.txt || rc=$?
[ $rc -eq 2 ] || fail "bad OLIGOMAP_JOBS accepted"
rc=0; OLIGOMAP_JOBS=4 oligomap bad.fa q.fa -r w.rep > w.out 2> err.txt || rc=$?
[ $rc -ne 0 ] || fail "a failing part did not fail the wrapper"
[ -z "$(ls /tmp/tmp)" ] || fail "temporary folders left: $(ls /tmp/tmp)"
checks=$((checks + 5))
echo "ok: $checks checks"
'
