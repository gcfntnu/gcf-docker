#!/usr/bin/env python3
"""Compare a new library with an old one (e.g. the miRge3 SourceForge library).

Per database: mature miRNAs kept (same name and sequence), changed sequence, renamed (same
sequence, other name), dropped and added; SNP variants and merge groups; and per bowtie index the
number of sequences (bowtie-inspect -n in the given image).

Usage: tests/compare_libraries.py --old DIR --new DIR --org human|mouse|rat [--image IMAGE]
       (DIR holds <org>/)
"""
import argparse
import os
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
import mirge3_lib as m  # noqa: E402


def mature(root, org, db):
    return dict(m.read_fasta(Path(root) / org / 'fasta.Libs' / f'{org}_mature_{db}.fa'))


def count_index(image, root, org, name):
    p = Path(root) / org / 'index.Libs' / f'{org}_{name}.1.ebwt'
    if not p.exists():
        return None
    out = subprocess.run(['docker', 'run', '--rm', '--user', f'{os.getuid()}:{os.getgid()}', '-v',
                          f'{Path(root).resolve()}:/libs:ro', image, 'bowtie-inspect', '-n',
                          f'/libs/{org}/index.Libs/{org}_{name}'], check=True, capture_output=True, text=True)
    return len(out.stdout.splitlines())


def main():
    p = argparse.ArgumentParser()
    p.add_argument('--old', required=True)
    p.add_argument('--new', required=True)
    p.add_argument('--org', required=True)
    p.add_argument('--image', default='quay.io/biocontainers/mirge3:0.1.4--pyh7cba7a3_0')
    a = p.parse_args()
    o = a.org
    for db in ('miRBase', 'MirGeneDB'):
        old, new = mature(a.old, o, db), mature(a.new, o, db)
        by_seq_new = {}
        for n, s in new.items():
            by_seq_new.setdefault(s, []).append(n)
        kept = [n for n in old if n in new and old[n] == new[n]]
        changed = [n for n in old if n in new and old[n] != new[n]]
        gone = [n for n in old if n not in new]
        renamed = [n for n in gone if old[n] in by_seq_new]
        dropped = [n for n in gone if old[n] not in by_seq_new]
        old_seqs = set(old.values())
        added = [n for n in new if n not in old and new[n] not in old_seqs]
        print(f'{o} {db}: old {len(old)}, new {len(new)} mature; kept {len(kept)}, sequence changed '
              f'{len(changed)}, renamed {len(renamed)}, dropped {len(dropped)}, added {len(added)}')
        for label, names, show in (('renamed', renamed, lambda n: f'{n} -> {"/".join(by_seq_new[old[n]])}'),
                                   ('dropped', dropped, str), ('added', added, str), ('changed', changed, str)):
            if names:
                print(f'  {label} (first 5): ' + ', '.join(show(n) for n in names[:5]))
        for f in (f'{o}_mirna_SNP_pseudo_{db}.fa',):
            for tag, root in (('old', a.old), ('new', a.new)):
                names = [h for h, _ in m.read_fasta(Path(root) / o / 'fasta.Libs' / f)]
                groups = sum(1 for _ in open(Path(root) / o / 'annotation.Libs' / f'{o}_merges_{db}.csv'))
                print(f'  {tag}: SNP alleles {sum(1 for n in names if ".SNP" in n and not n.endswith(".SNPC"))}, '
                      f'miRNAs with SNPs {sum(1 for n in names if n.endswith(".SNPC"))}, merge groups {groups}')
    names = ['hairpin_miRBase', 'hairpin_MirGeneDB', 'mirna_miRBase', 'mirna_MirGeneDB', 'mature_trna',
             'pre_trna', 'mrna', 'ncrna_others', 'rrna', 'snorna', 'spike-in']
    print(f'{o} index sequences (old -> new): ' + ', '.join(
        f'{n} {count_index(a.image, a.old, o, n)} -> {count_index(a.image, a.new, o, n)}' for n in names))


if __name__ == '__main__':
    main()
