#!/usr/bin/env python3
"""Generators for miRge3 0.1.4 libraries (used by build_mirge3_lib.sh).

miRge-build only indexes the FASTA files it is given and copies the miRNA GFF. This module writes
the inputs it needs and the files it does not create, in the formats of the miRge3 SourceForge
libraries (2020):

  mirna         species mature/hairpin FASTA, mature BED (genomic, from the GFF), GFF copy
  mirna-finish  SNP variants, mirna index FASTA, SNP pseudo FASTA, merges, repeat-element list
  rmsk-bed      UCSC rmsk.txt.gz -> BED with UCSC-style transcript ids (repName, repName_dup1, ...)
  ncrna         Ensembl ncRNA and cDNA FASTA -> snoRNA (identical sequences collapsed), rRNA
                (rRNA and rRNA_pseudogene), others, mRNA (cDNA without rRNA_pseudogene)
  trna          GtRNAdb mature tRNAs (+CCA) and 100 nt genomic trailers (pre-tRNA)
  fasta-dna     FASTA to upper-case DNA with first-token names (spike-ins, mRNA)

Formats reproduced (from the SourceForge human library):
  * mirna index: every mature miRNA (or its SNP variants) with 2 nt upstream and 6 nt downstream
    flanks from its precursor (miRNA_miRge_format, as miRge-build).
  * SNP variants: <name>.SNPC is the reference allele; each alternative allele of each SNV inside
    the mature sequence is <name>.SNPA, .SNPB, .SNPD, ... (C skipped).
  * merges: one line per group, "<group>,<member>,<member>,...". A group is a miRNA with SNP
    variants (members: its variants) and/or miRNAs with identical mature sequences.
  * SNP pseudo FASTA: the mirna index records without flanks, plus one record per group (group
    name, reference sequence).
  * repetitive elements: '<miRNA>,gene_id "<repName>"; transcript_id "<id>";' per overlap.

Only the Python standard library is used, so the unit tests run without the image.
"""
import argparse
import gzip
import re
import sys
from collections import OrderedDict, defaultdict
from pathlib import Path

SNP_LETTERS = 'ABDEFGHIJKLMNOPQRSTUVWXYZ'  # C marks the reference allele
COMPLEMENT = str.maketrans('ACGTN', 'TGCAN')


def die(msg):
    sys.exit(f'mirge3_lib: {msg}')


def open_text(path):
    path = str(path)
    return gzip.open(path, 'rt') if path.endswith('.gz') else open(path)


def read_fasta(path):
    """[(header without '>', sequence)] in file order."""
    records, header, chunks = [], None, []
    with open_text(path) as fh:
        for line in fh:
            line = line.rstrip('\r\n')
            if line.startswith('>'):
                if header is not None:
                    records.append((header, ''.join(chunks)))
                header, chunks = line[1:], []
            elif line:
                if header is None:
                    die(f'{path}: sequence before the first header')
                chunks.append(line.strip())
    if header is not None:
        records.append((header, ''.join(chunks)))
    return records


def write_fasta(path, records):
    Path(path).parent.mkdir(parents=True, exist_ok=True)
    with open(path, 'w') as fh:
        for name, seq in records:
            fh.write(f'>{name}\n{seq}\n')


def to_dna(seq):
    return seq.upper().replace('U', 'T')


def revcomp(seq):
    return seq.translate(COMPLEMENT)[::-1]


def mirge_flanks(hairpin, mature):
    """(prefix, suffix) around the first occurrence of mature in hairpin, as miRge-build's
    miRNA_miRge_format (2 nt upstream, 6 nt downstream); None if mature is not in hairpin."""
    start = hairpin.find(mature)
    if start < 0:
        return None
    end = start + len(mature)
    return hairpin[:start][-2:], hairpin[end:][:6]


def gff_records(path):
    """(seqid, type, start, end, strand, {attr: value}) for each feature line."""
    out = []
    with open_text(path) as fh:
        for line in fh:
            if line.startswith('#') or not line.strip():
                continue
            f = line.rstrip('\n').split('\t')
            if len(f) < 9:
                die(f'{path}: not a GFF line: {line.strip()}')
            attrs = dict(kv.split('=', 1) for kv in f[8].strip().strip(';').split(';') if '=' in kv)
            out.append((f[0], f[2], int(f[3]), int(f[4]), f[6], attrs))
    return out


def mirgenedb_precursor(name):
    """Hsa-Let-7-P1b_5p / Hsa-Let-7-P1b_3p* -> Hsa-Let-7-P1b_pre."""
    return re.sub(r'_(5p|3p)\*?$', '_pre', name)


def strip_species_prefix(name):
    """hsa-miR-320b -> 320b, Hsa-Mir-430-P25_5p -> 430-P25_5p (for group names)."""
    return re.sub(r'^[A-Za-z]{3,4}-(miR|let|Mir|Let|mir)-', '', name)


def group_name(members):
    first = members[0]
    return '/'.join([first] + [strip_species_prefix(m) for m in members[1:]])


# --------------------------------------------------------------------------------------------
# mirna: species FASTA, mature BED, GFF copy
# --------------------------------------------------------------------------------------------

def cmd_mirna(args):
    lib, work, org, db = Path(args.lib), Path(args.work), args.org, args.db
    work.mkdir(parents=True, exist_ok=True)
    if db == 'miRBase':
        prefix = args.code + '-'
        recs = [(h.split()[0], h.split()[1], to_dna(s)) for h, s in read_fasta(args.mature) if h.startswith(prefix)]
        hairpin = [(h, to_dna(s)) for h, s in read_fasta(args.hairpin) if h.startswith(prefix)]
        # miRBase can give one name to different mature sequences (23.1: rno-miR-3084b-3p,
        # MIMAT0035742 and MIMAT0035744); those get the accession appended to stay unique.
        clash = {n for n, c in _counts(n for n, _, _ in recs).items() if c > 1}
        mature = [(f'{n}_{acc}' if n in clash else n, s) for n, acc, s in recs]
        accession = {acc: name for (_, acc, _), (name, _) in zip(recs, mature)}
        with open(work / f'{org}_mature_{db}.accessions.tsv', 'w') as fh:
            for acc, name in accession.items():
                fh.write(f'{acc}\t{name}\n')
        if clash:
            print(f'{db} {args.code}: names shared by different accessions, accession appended: '
                  f'{sorted(clash)}', file=sys.stderr)
    else:
        mature = [(h.split()[0], to_dna(s)) for f in [args.mature] + (args.star or []) for h, s in read_fasta(f)]
        hairpin = [(h.split()[0], to_dna(s)) for h, s in read_fasta(args.hairpin)]
        accession = None
    if not mature or not hairpin:
        die(f'no {args.code} {db} sequences (mature {len(mature)}, hairpin {len(hairpin)})')
    dup = [n for n, c in _counts(n for n, _ in mature).items() if c > 1]
    if dup:
        die(f'duplicate mature names: {dup[:5]}')
    names = {n for n, _ in mature}
    write_fasta(lib / 'fasta.Libs' / f'{org}_mature_{db}.fa', mature)
    write_fasta(work / f'{org}_hairpin_{db}.fa', hairpin)
    gff = gff_records(args.gff)
    bed, missing = [], set(names)
    for seqid, ftype, start, end, strand, attrs in gff:
        if ftype != 'miRNA':
            continue
        name = accession.get(attrs.get('ID')) if accession is not None else attrs.get('ID')
        if name in names:
            bed.append((ucsc_chrom(seqid), start - 1, end, name, strand))
            missing.discard(name)
    bed.sort(key=lambda r: (r[0], r[1], r[2], r[3]))
    with open(work / f'{org}_mature_{db}.bed', 'w') as fh:
        for seqid, start, end, name, strand in bed:
            fh.write(f'{seqid}\t{start}\t{end}\t{name}\t0\t{strand}\n')
    (lib / 'annotation.Libs').mkdir(parents=True, exist_ok=True)
    with open_text(args.gff) as src, open(lib / 'annotation.Libs' / f'{org}_{db}.gff3', 'w') as dst:
        dst.write(src.read())
    print(f'{db} {args.code}: {len(mature)} mature, {len(hairpin)} hairpin, {len(bed)} mature loci, '
          f'{len(missing)} mature without locus', file=sys.stderr)


def _counts(items):
    c = defaultdict(int)
    for i in items:
        c[i] += 1
    return c


# --------------------------------------------------------------------------------------------
# mirna-finish: SNP variants, mirna index, pseudo FASTA, merges, repeats
# --------------------------------------------------------------------------------------------

def read_bed(path):
    out = []
    with open(path) as fh:
        for line in fh:
            if line.strip():
                f = line.rstrip('\n').split('\t')
                out.append((f[0], int(f[1]), int(f[2]), f[3], f[5]))
    return out


def ucsc_chrom(c):
    """2 -> chr2, MT -> chrM; chr2 unchanged (UCSC RepeatMasker uses chr names)."""
    if c.startswith('chr'):
        return c
    return 'chrM' if c in ('MT', 'M') else 'chr' + c


def norm_chrom(c):
    """chr1 / 1 -> 1, chrM / MT / M -> MT (to match GFF and VCF contig names)."""
    c = c[3:] if c.startswith('chr') else c
    return 'MT' if c in ('M', 'MT') else c


def snvs_per_mature(bed, snp_rows, mature_seq):
    """{mature name: sorted [(offset, alt)]} for SNVs inside mature loci whose reference base
    matches the mature sequence. snp_rows: (chrom, pos 1-based, ref, alts)."""
    by_chrom = defaultdict(list)
    for chrom, pos, ref, alts in snp_rows:
        by_chrom[norm_chrom(chrom)].append((pos, ref, alts))
    found, mismatched = defaultdict(set), 0
    for seqid, start, end, name, strand in bed:
        seq = mature_seq.get(name)
        if seq is None or end - start != len(seq):
            continue  # locus does not match the sequence length (e.g. other assembly patch)
        for pos, ref, alts in by_chrom.get(norm_chrom(seqid), ()):
            if not (start < pos <= end) or len(ref) != 1:
                continue
            offset = pos - 1 - start if strand == '+' else end - pos
            r = ref.upper() if strand == '+' else revcomp(ref.upper())
            if seq[offset] != r:
                mismatched += 1
                continue
            for alt in alts:
                if len(alt) != 1 or alt.upper() not in 'ACGT':
                    continue
                a = alt.upper() if strand == '+' else revcomp(alt.upper())
                if a != r:
                    found[name].add((offset, a))
    return {n: sorted(v) for n, v in found.items()}, mismatched


def snp_variants(name, seq, snvs):
    """[(name.SNPC, seq), (name.SNPA, seq with first alt), ...]."""
    if len(snvs) > len(SNP_LETTERS):
        die(f'{name}: {len(snvs)} SNV alleles, more than {len(SNP_LETTERS)} letters')
    out = [(f'{name}.SNPC', seq)]
    for letter, (offset, alt) in zip(SNP_LETTERS, snvs):
        out.append((f'{name}.SNP{letter}', seq[:offset] + alt + seq[offset + 1:]))
    return out


def _acc_number(acc):
    return int(re.sub(r'\D', '', acc) or 0)


def precursor_for(db, name, seq, gff, hairpins, hairpin_names=None):
    """Hairpin sequence giving the flanks of a mature miRNA, or None.

    miRBase: the precursors the GFF derives the mature from (lowest accession first). Matures
    without a locus (precursor not placed on the assembly) fall back to the hairpins containing the
    sequence: the one named like the mature (rno-miR-335-5p -> rno-mir-335), else the lowest
    accession. hairpin_names: {accession: hairpin name}."""
    if db == 'MirGeneDB':
        hp = hairpins.get(mirgenedb_precursor(name))
        return hp if hp and seq in hp else None
    for acc in sorted(gff.get(name, ()), key=_acc_number):
        hp = hairpins.get(acc)
        if hp and seq in hp:
            return hp
    containing = sorted((a for a, hp in hairpins.items() if seq in hp), key=_acc_number)
    if not containing:
        return None
    stem = re.sub(r'_MIMAT\d+$', '', name)
    stem = re.sub(r'-[35]p$', '', stem).lower()
    named = [a for a in containing if (hairpin_names or {}).get(a, '').lower() == stem]
    return hairpins[(named or containing)[0]]


def read_snp_rows(path):
    rows = []
    if path:
        with open(path) as fh:
            for line in fh:
                if line.strip() and not line.startswith('#'):
                    chrom, pos, ref, alt = line.rstrip('\n').split('\t')[:4]
                    rows.append((chrom, int(pos), ref, alt.split(',')))
    return rows


def build_groups(mature, snvs):
    """[(group name, [base names])] for SNP miRNAs and identical mature sequences, in mature order."""
    by_seq = OrderedDict()
    for name, seq in mature:
        by_seq.setdefault(seq, []).append(name)
    groups = []
    for seq, names in by_seq.items():
        if len(names) > 1 or names[0] in snvs:
            groups.append((names[0] if len(names) == 1 else group_name(names), names))
    return groups


def cmd_mirna_finish(args):
    lib, work, org, db = Path(args.lib), Path(args.work), args.org, args.db
    mature = read_fasta(lib / 'fasta.Libs' / f'{org}_mature_{db}.fa')
    mature_seq = dict(mature)
    if db == 'miRBase':
        hp_records = read_fasta(work / f'{org}_hairpin_{db}.fa')
        hairpins = {h.split()[1]: s for h, s in hp_records}
        hairpin_names = {h.split()[1]: h.split()[0] for h, _ in hp_records}
        accession = dict(line.rstrip('\n').split('\t') for line in open(work / f'{org}_mature_{db}.accessions.tsv'))
        derives = defaultdict(list)
        for _, ftype, _, _, _, attrs in gff_records(args.gff):
            if ftype == 'miRNA' and 'Derives_from' in attrs and attrs.get('ID') in accession:
                derives[accession[attrs['ID']]].append(attrs['Derives_from'])
    else:
        hairpins = {h.split()[0]: s for h, s in read_fasta(work / f'{org}_hairpin_{db}.fa')}
        hairpin_names, derives = None, {}
    bed = read_bed(args.snv_bed or work / f'{org}_mature_{db}.bed')
    snvs, mismatched = snvs_per_mature(bed, read_snp_rows(args.snps), mature_seq)
    # More alleles than SNP letters (dbSNP 157: hsa-miR-8078-3p, 45 COMMON alleles in 23 nt, a
    # hypervariable locus): no variants for that miRNA rather than an arbitrary subset.
    too_many = sorted(n for n, v in snvs.items() if len(v) > len(SNP_LETTERS))
    for n in too_many:
        print(f'{db}: {n}: {len(snvs[n])} SNV alleles, more than {len(SNP_LETTERS)} letters; no SNP variants',
              file=sys.stderr)
        del snvs[n]

    index, pseudo, unflanked = [], [], 0
    for name, seq in mature:
        hp = precursor_for(db, name, seq, derives, hairpins, hairpin_names)
        flanks = mirge_flanks(hp, seq) if hp else None
        if flanks is None:
            flanks, unflanked = ('', ''), unflanked + 1
        records = snp_variants(name, seq, snvs[name]) if name in snvs else [(name, seq)]
        for rname, rseq in records:
            index.append((rname, flanks[0] + rseq + flanks[1]))
            pseudo.append((rname, rseq))

    groups = build_groups(mature, snvs)
    with open(lib / 'annotation.Libs' / f'{org}_merges_{db}.csv', 'w') as fh:
        for gname, names in groups:
            members = []
            for n in names:
                members += [r for r, _ in snp_variants(n, mature_seq[n], snvs[n])] if n in snvs else [n]
            fh.write(','.join([gname] + members) + '\n')
            pseudo.append((gname, mature_seq[names[0]]))
    write_fasta(work / f'{org}_mirna_{db}.fa', index)
    write_fasta(lib / 'fasta.Libs' / f'{org}_mirna_SNP_pseudo_{db}.fa', pseudo)

    rep_lines = OrderedDict()
    if args.repeats:
        with open(args.repeats) as fh:
            for line in fh:
                f = line.rstrip('\n').split('\t')
                if len(f) >= 11:  # mature BED6 + rmsk BED (chrom start end repName transcript_id)
                    rep_lines.setdefault(f'{f[3]},gene_id "{f[9]}"; transcript_id "{f[10]}";', None)
    with open(lib / 'annotation.Libs' / f'{org}_miRNAs_in_repetitive_element_{db}.csv', 'w') as fh:
        for line in rep_lines:
            fh.write(line + '\n')
    n_alleles = sum(len(v) for v in snvs.values())
    print(f'{db}: {len(mature)} mature, {len(snvs)} with SNVs ({n_alleles} alleles, {mismatched} ref '
          f'mismatches skipped), {len(index)} index records, {unflanked} without precursor flanks, '
          f'{len(groups)} groups, {len(rep_lines)} repeat overlaps', file=sys.stderr)


# --------------------------------------------------------------------------------------------
# rmsk-bed, ncrna, trna, fasta-dna
# --------------------------------------------------------------------------------------------

def cmd_rmsk_bed(args):
    """UCSC rmsk.txt(.gz) columns: bin swScore milliDiv milliDel milliIns genoName genoStart
    genoEnd genoLeft strand repName repClass repFamily ... -> BED with UCSC GTF-style ids."""
    seen = defaultdict(int)
    with open_text(args.rmsk) as fh, open(args.out, 'w') as out:
        for line in fh:
            f = line.rstrip('\n').split('\t')
            chrom, start, end, strand, rep = f[5], f[6], f[7], f[9], f[10]
            k = seen[rep]
            seen[rep] += 1
            tid = rep if k == 0 else f'{rep}_dup{k}'
            out.write(f'{chrom}\t{start}\t{end}\t{rep}\t{tid}\t{strand}\n')


def biotype(header):
    m = re.search(r'transcript_biotype:(\S+)', header)
    return m.group(1) if m else ''


def cmd_ncrna(args):
    """rRNA_pseudogene: Ensembl moved most human rRNA genes there (116: 71 rRNA, 516
    rRNA_pseudogene, in the cDNA file); they stay in the rRNA index as in the old libraries."""
    snorna, rrna, others, mrna = OrderedDict(), [], [], []
    for header, seq in read_fasta(args.cdna):
        if biotype(header) == 'rRNA_pseudogene':
            rrna.append((header, to_dna(seq)))
        else:
            mrna.append((header, to_dna(seq)))
    for header, seq in read_fasta(args.ncrna):
        seq, bt = to_dna(seq), biotype(header)
        if bt == 'snoRNA':
            snorna.setdefault(seq, []).append(header)
        elif bt in ('rRNA', 'rRNA_pseudogene'):
            rrna.append((header, seq))
        elif bt != 'miRNA':
            others.append((header, seq))
    sno = []
    for seq, headers in snorna.items():
        first = headers[0].split(' ', 1)
        ids = '/'.join(h.split()[0] for h in headers)
        sno.append((ids + (' ' + first[1] if len(first) > 1 else ''), seq))
    out = Path(args.outdir)
    write_fasta(out / 'snorna.fa', sno)
    write_fasta(out / 'rrna.fa', rrna)
    write_fasta(out / 'ncrna_others.fa', others)
    write_fasta(out / 'mrna.fa', mrna)
    print(f'ncRNA: {len(sno)} snoRNA ({sum(map(len, snorna.values()))} before collapsing), '
          f'{len(rrna)} rRNA (with rRNA_pseudogene), {len(others)} others, {len(mrna)} mRNA', file=sys.stderr)


def read_genome(path, wanted, rename):
    seqs, name, chunks = {}, None, []
    with open_text(path) as fh:
        for line in fh:
            if line.startswith('>'):
                if name in wanted:
                    seqs[name] = ''.join(chunks)
                raw = line[1:].split()[0]
                name, chunks = rename.get(raw, raw), []
            elif name in wanted:
                chunks.append(line.strip())
    if name in wanted:
        seqs[name] = ''.join(chunks)
    return seqs


def cmd_trna(args):
    mature = []
    for header, seq in read_fasta(args.mature):
        seq = to_dna(seq)
        mature.append((header.split()[0], seq if seq.endswith('CCA') else seq + 'CCA'))
    names = {n for n, _ in mature}
    rename = {}
    for pair in args.rename or []:
        a, b = pair.split('=')
        rename[a] = b
    loci = []
    with open(args.bed) as fh:
        for line in fh:
            f = line.rstrip('\n').split('\t')
            full = f'{args.species_prefix}_{f[3]}'
            if full in names:
                loci.append((args.chrom_prefix + norm_chrom(f[0]) if args.chrom_prefix is not None else f[0],
                             int(f[1]), int(f[2]), full, f[5]))
    genome = read_genome(args.genome, {c for c, *_ in loci}, rename)
    pre, skipped = [], []
    for chrom, start, end, name, strand in loci:
        g = genome.get(chrom)
        if g is None:
            skipped.append(name)
            continue
        trailer = g[end:end + args.trailer] if strand == '+' else revcomp(g[max(0, start - args.trailer):start])
        pre.append((f'pre_{name}_trailer', trailer.upper()))
    write_fasta(Path(args.outdir) / 'mature_trna.fa', mature)
    write_fasta(Path(args.outdir) / 'pre_trna.fa', pre)
    print(f'tRNA: {len(mature)} mature, {len(pre)} trailers, {len(skipped)} without genome contig '
          f'{skipped[:3]}', file=sys.stderr)
    if len(pre) < len(mature) * 0.9:
        die('fewer than 90% of the mature tRNAs got a trailer; check contig names')


def cmd_fasta_dna(args):
    records = []
    for f in args.fasta:
        records += [(h if args.keep_header else h.split()[0], to_dna(s)) for h, s in read_fasta(f)]
    write_fasta(args.out, records)


DATABASES = ('miRBase', 'MirGeneDB')  # exact spelling: miRge3 builds file names from -d as given
INDEXES = ['genome', 'mature_trna', 'pre_trna', 'mrna', 'ncrna_others', 'rrna', 'snorna', 'spike-in']


def library_files(org, trna_annotation=False):
    """Files of <lib>/<org>/ that miRge3 0.1.4 opens for the options gcf-workflows uses."""
    files = []
    for db in DATABASES:
        files += [f'annotation.Libs/{org}_{db}.gff3',
                  f'annotation.Libs/{org}_merges_{db}.csv',
                  f'annotation.Libs/{org}_miRNAs_in_repetitive_element_{db}.csv',
                  f'fasta.Libs/{org}_mature_{db}.fa',
                  f'fasta.Libs/{org}_mirna_SNP_pseudo_{db}.fa',
                  f'index.Libs/{org}_hairpin_{db}.1.ebwt',
                  f'index.Libs/{org}_mirna_{db}.1.ebwt']
    files += [f'index.Libs/{org}_{i}.1.ebwt' for i in INDEXES]
    if trna_annotation:
        files += [f'annotation.Libs/{org}_{n}' for n in
                  ('trna.str', 'trna_aminoacid_anticodon.csv', 'trna_deduplicated_list.csv',
                   'tRF_infor.csv', 'tRF_merges.csv')]
    return files


def cmd_snv_bed(args):
    """Mature loci from another miRBase release's GFF (e.g. 22.1 on GRCm38, for dbSNP 150), by
    accession, for the SNV lookup only. Loci whose length differs from the sequence are left out."""
    work = Path(args.work)
    accession = dict(line.rstrip('\n').split('\t') for line in open(work / f'{args.org}_mature_miRBase.accessions.tsv'))
    seqs = dict(read_fasta(Path(args.lib) / 'fasta.Libs' / f'{args.org}_mature_miRBase.fa'))
    bed = set()
    for seqid, ftype, start, end, strand, attrs in gff_records(args.gff):
        name = accession.get(attrs.get('ID'))
        if ftype == 'miRNA' and name in seqs and end - start + 1 == len(seqs[name]):
            bed.add((ucsc_chrom(seqid), start - 1, end, name, strand))
    with open(args.out, 'w') as fh:
        for seqid, start, end, name, strand in sorted(bed):
            fh.write(f'{seqid}\t{start}\t{end}\t{name}\t0\t{strand}\n')
    print(f'SNV loci from {args.gff}: {len(bed)} loci for {len({b[3] for b in bed})} of {len(seqs)} mature',
          file=sys.stderr)


def cmd_check_lib(args):
    lib = Path(args.lib)
    missing = [f for f in library_files(args.org, args.trna_annotation) if not (lib / f).is_file()]
    empty = [f for f in library_files(args.org, args.trna_annotation)
             if (lib / f).is_file() and (lib / f).stat().st_size == 0 and 'repetitive' not in f]
    if missing or empty:
        die(f'library {lib} is incomplete: missing {missing}, empty {empty}')
    print(f'library {lib}: all {len(library_files(args.org, args.trna_annotation))} files present',
          file=sys.stderr)


def main(argv=None):
    p = argparse.ArgumentParser(description=__doc__.split('\n')[0])
    sub = p.add_subparsers(dest='cmd', required=True)
    s = sub.add_parser('mirna')
    for a in ('--db', '--org', '--code', '--mature', '--hairpin', '--gff', '--lib', '--work'):
        s.add_argument(a, required=True)
    s.add_argument('--star', nargs='*')
    s.set_defaults(func=cmd_mirna)
    s = sub.add_parser('mirna-finish')
    for a in ('--db', '--org', '--gff', '--lib', '--work'):
        s.add_argument(a, required=True)
    s.add_argument('--snps', help='chrom<TAB>pos<TAB>ref<TAB>alt[,alt] (bcftools query)')
    s.add_argument('--repeats', help='bedtools intersect -wa -wb of the mature BED and rmsk BED')
    s.add_argument('--snv-bed', help='mature loci the --snps were queried on (default: the mature BED)')
    s.set_defaults(func=cmd_mirna_finish)
    s = sub.add_parser('rmsk-bed')
    s.add_argument('--rmsk', required=True)
    s.add_argument('--out', required=True)
    s.set_defaults(func=cmd_rmsk_bed)
    s = sub.add_parser('ncrna')
    s.add_argument('--ncrna', required=True)
    s.add_argument('--cdna', required=True)
    s.add_argument('--outdir', required=True)
    s.set_defaults(func=cmd_ncrna)
    s = sub.add_parser('trna')
    for a in ('--mature', '--bed', '--genome', '--outdir', '--species-prefix'):
        s.add_argument(a, required=True)
    s.add_argument('--chrom-prefix', default=None,
                   help="rewrite BED contigs to <prefix><1|MT> (e.g. '' for Ensembl names)")
    s.add_argument('--rename', nargs='*', help='genome contig renames, old=new')
    s.add_argument('--trailer', type=int, default=100)
    s.set_defaults(func=cmd_trna)
    s = sub.add_parser('fasta-dna')
    s.add_argument('--out', required=True)
    s.add_argument('--keep-header', action='store_true')
    s.add_argument('fasta', nargs='+')
    s.set_defaults(func=cmd_fasta_dna)
    s = sub.add_parser('snv-bed')
    for a in ('--org', '--gff', '--lib', '--work', '--out'):
        s.add_argument(a, required=True)
    s.set_defaults(func=cmd_snv_bed)
    s = sub.add_parser('check-lib')
    s.add_argument('--lib', required=True)
    s.add_argument('--org', required=True)
    s.add_argument('--trna-annotation', action='store_true')
    s.set_defaults(func=cmd_check_lib)
    args = p.parse_args(argv)
    args.func(args)


if __name__ == '__main__':
    main()
