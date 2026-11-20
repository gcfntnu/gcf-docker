#!/usr/bin/env python3
"""Smoke test of a built library with miRge3 0.1.4 (the gcf-workflows quantification image).

Writes a synthetic FASTQ of known composition from the library's own sequences, runs miRge3 with
the options gcf-workflows uses (--gff-out --isoform-entropy --AtoI --spikeIn, --tRNA-frag for
human) for miRBase and MirGeneDB, as uid 1000 with a read-only root filesystem, and checks:
  * exact reads of three plain miRNAs are counted under their names;
  * reads of a SNP allele (.SNPA) are counted under the miRNA's base name (merges);
  * reads of a group of identical sequences are counted under the group name;
  * spike-in and mature tRNA reads reach the annotation report;
  * human (--tRNA-frag): reads equal to a nuclear, a mitochondrial and a trailer (tRF-1) cluster
    are counted under the cluster's merge group in tRF.Counts.csv;
  * mouse, rat: a read inside a mitochondrial tRNA and a 3' read ending in the CCA tail of a tRNA
    whose GtRNAdb sequence ends in CCA are counted as mature tRNA (gcf-docker#53);
  * reads from the two longest rRNAs (28S, 18S; at least 1,500 nt, else the test stops) are counted
    as rRNA (gcf-docker#54).

Usage: tests/smoke_mirge3.py --lib DIR (the dir holding <org>/) --org human|mouse|rat --out DIR
       [--image quay.io/biocontainers/mirge3:0.1.4--pyh7cba7a3_0]
"""
import argparse
import csv
import os
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
import mirge3_lib as m  # noqa: E402

ADAPTER = 'TGGAATTCTCGGGTGCCAAGG'  # Illumina TruSeq small RNA 3' adapter
QUAL = 'I'


def pick(lib, org, db):
    """Expected {name in miR.Counts.csv: reads} and the reads to write."""
    root = Path(lib) / org
    mature = m.read_fasta(root / 'fasta.Libs' / f'{org}_mature_{db}.fa')
    groups = [line.rstrip('\n').split(',') for line in open(root / 'annotation.Libs' / f'{org}_merges_{db}.csv')]
    in_group = {x for g in groups for x in g[1:]} | {x.split('.SNP')[0] for g in groups for x in g[1:]}
    seq_count = {}
    for _, s in mature:
        seq_count[s] = seq_count.get(s, 0) + 1
    pseudo = dict(m.read_fasta(root / 'fasta.Libs' / f'{org}_mirna_SNP_pseudo_{db}.fa'))
    reads, expected = [], {}
    plain = [(n, s) for n, s in mature if n not in in_group and seq_count[s] == 1 and 19 <= len(s) <= 24][:3]
    for i, (n, s) in enumerate(plain):
        reads += [s] * (20 + 5 * i)
        expected[n] = 20 + 5 * i
    snp = next(g for g in groups if len(g) > 2 and all(x.startswith(g[0] + '.SNP') for x in g[1:]))
    reads += [pseudo[snp[0] + '.SNPA']] * 10   # alternative allele -> base name
    expected[snp[0]] = 10
    ident = next((g for g in groups if '/' in g[0] and not any('.SNP' in x for x in g[1:])), None)
    if ident:
        reads += [pseudo[g] for g in [ident[0]]] * 12
        expected[ident[0]] = 12
    return reads, expected, snp, ident


def write_fastq(path, reads, extra):
    with open(path, 'w') as fh:
        for i, s in enumerate(reads + extra):
            r = s + ADAPTER
            fh.write(f'@r{i}\n{r}\n+\n{QUAL * len(r)}\n')


def bowtie_inspect(image, lib, org, index):
    out = subprocess.run(['docker', 'run', '--rm', '--user', f'{os.getuid()}:{os.getgid()}', '-v', f'{lib}:/mirgelib:ro',
                          image, 'bowtie-inspect', f'/mirgelib/{org}/index.Libs/{org}_{index}'],
                         check=True, capture_output=True, text=True).stdout
    recs, name = [], None
    for line in out.splitlines():
        if line.startswith('>'):
            name = line[1:]
            recs.append([name, ''])
        else:
            recs[-1][1] += line.strip()
    return recs


def near(read, seqs):
    """Windows of seqs within 1 mismatch of read, on either strand (miRge3 aligns tRNA with 1 mismatch)."""
    hits = 0
    for q in (read, m.revcomp(read)):
        for s in seqs:
            for i in range(len(s) - len(q) + 1):
                if sum(a != b for a, b in zip(q, s[i:i + len(q)])) <= 1:
                    hits += 1
    return hits


def trf_reads(mature, pre, lib, org, avoid_read):
    """[(merge group, cluster, sequence, reads)] for a nuclear, a mitochondrial and a trailer cluster
    whose sequence occurs once (within 1 mismatch, both strands) in all tRNA sequences, on a tRNA that
    is no duplicate (miRge3 picks the one-hit tRNA among duplicates at random), in a merge group that
    `avoid_read` cannot reach. Trailer reads must end in T (summary.py: re.search('T{3,}$'))."""
    ann = Path(lib) / org / 'annotation.Libs'
    seqs = list(mature.values()) + list(pre.values())
    dup = {x for line in list(open(ann / f'{org}_trna_deduplicated_list.csv'))[1:]
           for x in line.rstrip('\n').split(',')[1].split('/')}
    group_of = {}
    for line in open(ann / f'{org}_tRF_merges.csv'):
        g, members = line.rstrip('\n').split(',', 1)
        group_of.update((c, g) for c in members.split('/'))
    reached = {n for n, s in list(mature.items()) + list(pre.items()) if near(avoid_read, [s])}
    blocked = {group_of[c] for c in group_of if c.split('_Cluster')[0] in reached}
    rows = [line.rstrip('\n').split(',') for line in list(open(ann / f'{org}_tRF_infor.csv'))[1:]]
    kinds = (('nuclear', lambda t: t in mature and not t.startswith('trnaMT'), ''),
             ('mito', lambda t: t.startswith('trnaMT'), ''),
             ('trailer', lambda t: t.startswith('pre_'), 'TTTT'))
    picks = []
    for kind, ok, tail in kinds:
        for r in rows:
            c, seq, t = r[0], r[4], r[0].split('_Cluster')[0]
            if (ok(t) and t not in dup and 16 <= len(seq) <= 30 and seq.endswith(tail)
                    and group_of[c] not in blocked and near(seq, seqs) == 1):
                picks.append((group_of[c], c, seq, kind))
                blocked.add(group_of[c])
                break
        else:
            sys.exit(f'smoke test: no usable {kind} tRF cluster in {ann}')
    return [(g, c, s, n) for (g, c, s, _), n in zip(picks, (14, 9, 11))]


def mt_cca_reads(mature):
    """mouse, rat (gcf-docker#53): (tRNA, read, copies) for a 30 nt read inside a mitochondrial tRNA,
    and for the 3' 22 nt of a nuclear tRNA ending in CCACCA (GtRNAdb sequence ending in CCA, plus the
    added tail)."""
    mt = [(n, s) for n, s in mature.items() if n.startswith('trnaMT_')]
    cca = [(n, s) for n, s in mature.items() if not n.startswith('trnaMT_') and s.endswith('CCACCA')]
    if not mt or not cca:
        sys.exit(f'smoke test: {len(mt)} mitochondrial tRNAs, {len(cca)} ending in CCACCA in the mature tRNA index')
    return [(mt[0][0], mt[0][1][10:40], 8), (cca[0][0], cca[0][1][-22:], 7)]


def rrna_reads(image, lib, org):
    """gcf-docker#54: [(rRNA, read, copies)] for a 25 nt read from each of the two longest records of the rRNA
    index, which must be 18S/28S-sized (Ensembl alone gives human only 5S/5.8S)."""
    long = sorted((r for r in bowtie_inspect(image, lib, org, 'rrna') if len(r[1]) >= 1500), key=lambda r: -len(r[1]))
    if len(long) < 2:
        sys.exit(f'smoke test: {len(long)} rRNAs of 1,500 nt or more (18S, 28S) in the {org} rRNA index')
    return [(long[0][0].split()[0], long[0][1][600:625], 6), (long[1][0].split()[0], long[1][1][600:625], 5)]


def main():
    p = argparse.ArgumentParser()
    p.add_argument('--lib', required=True)
    p.add_argument('--org', required=True)
    p.add_argument('--out', required=True)
    p.add_argument('--image', default='quay.io/biocontainers/mirge3:0.1.4--pyh7cba7a3_0')
    a = p.parse_args()
    lib, out = Path(a.lib).resolve(), Path(a.out).resolve()
    out.mkdir(parents=True, exist_ok=True)
    spike = bowtie_inspect(a.image, lib, a.org, 'spike-in')[0][1]
    mature = dict(bowtie_inspect(a.image, lib, a.org, 'mature_trna'))
    trna = next(iter(mature.values()))[:30]
    trf = []
    if a.org == 'human':
        trf = trf_reads(mature, dict(bowtie_inspect(a.image, lib, a.org, 'pre_trna')), lib, a.org, trna)
        for g, c, s, n in trf:
            print(f'tRF read {s} ({c}, group {g}) x {n}')
    mt_cca = mt_cca_reads(mature) if a.org != 'human' else []
    for c, s, n in mt_cca:
        print(f'tRNA read {s} ({c}) x {n}')
    rrna = rrna_reads(a.image, lib, a.org)
    for c, s, n in rrna:
        print(f'rRNA read {s} ({c}) x {n}')
    n_mature = 12 + sum(n for g, c, s, n in trf if not c.startswith('pre_')) + sum(n for c, s, n in mt_cca)
    n_primary = sum(n for g, c, s, n in trf if c.startswith('pre_'))
    failures = []
    for db in ('miRBase', 'MirGeneDB'):
        reads, expected, snp, ident = pick(lib, a.org, db)
        extra = ([spike] * 15 + [trna] * 12 + [s for g, c, s, n in trf for _ in range(n)]
                 + [s for c, s, n in mt_cca for _ in range(n)] + [s for c, s, n in rrna for _ in range(n)])
        fq = out / f'smoke_{db}.fastq'
        write_fastq(fq, reads, extra)
        run = out / f'run_{db}'
        run.mkdir(exist_ok=True)
        args = ['--gff-out', '--isoform-entropy', '--AtoI', '--spikeIn'] + (['--tRNA-frag'] if a.org == 'human' else [])
        cmd = ['docker', 'run', '--rm', '--user', f'{os.getuid()}:{os.getgid()}', '--read-only', '--tmpfs', '/tmp',
               '-v', f'{lib}:/mirgelib:ro', '-v', f'{out}:/out', '-w', '/out', a.image,
               'miRge3.0', '--samples', f'/out/{fq.name}', '--adapter', ADAPTER, '--mir-DB', db,
               '--libraries-path', '/mirgelib', '--organism-name', a.org, *args, '--threads', '4',
               '--outDir', f'/out/{run.name}']
        res = subprocess.run(cmd, capture_output=True, text=True)
        (out / f'run_{db}.log').write_text(res.stdout + res.stderr)
        if res.returncode != 0:
            failures.append(f'{db}: miRge3 exited {res.returncode} (log {out}/run_{db}.log)')
            continue
        result = next(run.glob('miRge*'))
        counts = {r['miRNA']: float(r[fq.stem]) for r in csv.DictReader(open(result / 'miR.Counts.csv'))}
        for name, n in expected.items():
            got = counts.get(name)
            status = 'ok' if got == n else 'FAIL'
            print(f'{a.org} {db}: {name}: expected {n}, got {got} {status}')
            if got != n:
                failures.append(f'{db}: {name} expected {n}, got {got}')
        report = list(csv.DictReader(open(result / 'annotation.report.csv')))[0]
        checks = ([('Spike-in', 15), ('mature tRNA Reads', n_mature), ('rRNA Reads', sum(n for c, s, n in rrna))]
                  + ([('primary tRNA Reads', n_primary)] if trf else []))
        for col, n in checks:
            key = next((k for k in report if k.lower().startswith(col.lower())), None)
            got = float(report[key]) if key else None
            print(f'{a.org} {db}: annotation {key}: expected {n}, got {got} {"ok" if got == n else "FAIL"}')
            if got != n:
                failures.append(f'{db}: {col} expected {n}, got {got}')
        for f in ('sample_miRge3.gff', 'a2IEditing.report.newform.csv', 'isomirs.csv'):
            if not (result / f).exists():
                failures.append(f'{db}: {f} missing')
        if trf:
            if not (result / 'tRF.Counts.csv').exists():
                failures.append(f'{db}: tRF.Counts.csv missing')
                continue
            tcounts = {r['entry name']: float(r[fq.stem]) for r in csv.DictReader(open(result / 'tRF.Counts.csv'))}
            for g, c, s, n in trf:
                got = tcounts.get(g)
                print(f'{a.org} {db}: tRF group {g} ({c}): expected {n}, got {got} {"ok" if got == n else "FAIL"}')
                if got != n:
                    failures.append(f'{db}: tRF group {g} expected {n}, got {got}')
    if failures:
        sys.exit('smoke test FAILED:\n  ' + '\n  '.join(failures))
    print(f'smoke test {a.org}: ok')


if __name__ == '__main__':
    main()
