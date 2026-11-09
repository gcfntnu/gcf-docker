#!/usr/bin/env python3
"""Smoke test of a built library with miRge3 0.1.4 (the gcf-workflows quantification image).

Writes a synthetic FASTQ of known composition from the library's own sequences, runs miRge3 with
the options gcf-workflows uses (--gff-out --isoform-entropy --AtoI --spikeIn, --tRNA-frag for
human) for miRBase and MirGeneDB, as uid 1000 with a read-only root filesystem, and checks:
  * exact reads of three plain miRNAs are counted under their names;
  * reads of a SNP allele (.SNPA) are counted under the miRNA's base name (merges);
  * reads of a group of identical sequences are counted under the group name;
  * spike-in and mature tRNA reads reach the annotation report.

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
    trna = bowtie_inspect(a.image, lib, a.org, 'mature_trna')[0][1][:30]
    failures = []
    for db in ('miRBase', 'MirGeneDB'):
        reads, expected, snp, ident = pick(lib, a.org, db)
        extra = [spike] * 15 + [trna] * 12
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
        for col, n in (('Spike-in', 15), ('mature tRNA Reads', 12)):
            key = next((k for k in report if k.lower().startswith(col.lower())), None)
            got = float(report[key]) if key else None
            print(f'{a.org} {db}: annotation {key}: expected {n}, got {got} {"ok" if got == n else "FAIL"}')
            if got != n:
                failures.append(f'{db}: {col} expected {n}, got {got}')
        for f in ('sample_miRge3.gff', 'a2IEditing.report.newform.csv', 'isomirs.csv'):
            if not (result / f).exists():
                failures.append(f'{db}: {f} missing')
    if failures:
        sys.exit('smoke test FAILED:\n  ' + '\n  '.join(failures))
    print(f'smoke test {a.org}: ok')


if __name__ == '__main__':
    main()
