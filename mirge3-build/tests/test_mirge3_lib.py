#!/usr/bin/env python3
"""Synthetic checks of mirge3_lib.py. Usage: python3 -I tests/test_mirge3_lib.py (stdlib only)."""
import gzip
import re
import sys
import tempfile
import unittest
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE.parent))
import mirge3_lib as m  # noqa: E402


def write(path, text):
    path = Path(path)
    path.parent.mkdir(parents=True, exist_ok=True)
    if str(path).endswith('.gz'):
        with gzip.open(path, 'wt') as fh:
            fh.write(text)
    else:
        path.write_text(text)
    return str(path)


def fasta(path):
    return m.read_fasta(path)


class Flanks(unittest.TestCase):
    def test_same_as_mirge_build(self):
        # miRge-build 0.0.1 miRNA_miRge_format, copied for comparison
        def reference(hpin, mir):
            start, end = re.search(mir, hpin).span()
            return hpin[:start][-2:] + mir + hpin[end:][:6]
        hp = 'TGGGATGAGGTAGTAGGTTGTATAGTTTTAGGGTCACACCC'
        for mir in ('TGAGGTAGTAGGTTGTATAGTT', 'TGGGATGAGG', 'TCACACCC', 'GTCACACC'):
            pre, suf = m.mirge_flanks(hp, mir)
            self.assertEqual(pre + mir + suf, reference(hp, mir))
        self.assertIsNone(m.mirge_flanks(hp, 'AAAAAAAA'))


class MiRBase(unittest.TestCase):
    """hsa-miR-1-3p (plus strand, one SNV, multi-allelic second SNV), hsa-miR-2-5p (minus strand,
    one SNV whose VCF ref does not match: skipped), hsa-miR-3a/3b identical sequences, mmu
    records filtered out."""

    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        t = Path(self.tmp.name)
        self.lib, self.work = t / 'human', t / 'work'
        # hairpins: mir-1 holds miR-1-3p at 11..20 (1-based), mir-2 holds miR-2-5p
        self.mature = write(t / 'mature.fa',
                            '>hsa-miR-1-3p MIMAT01 Homo sapiens miR-1-3p\nUGGAAUGUAA\n'
                            '>hsa-miR-2-5p MIMAT02 Homo sapiens miR-2-5p\nCCCAAAGGGU\n'
                            '>hsa-miR-3a MIMAT03 Homo sapiens miR-3a\nAAACCCGGGUUU\n'
                            '>hsa-miR-3b MIMAT04 Homo sapiens miR-3b\nAAACCCGGGUUU\n'
                            '>mmu-miR-1-3p MIMAT05 Mus musculus miR-1-3p\nUGGAAUGUAA\n')
        self.hairpin = write(t / 'hairpin.fa',
                             '>hsa-mir-1 MI01 Homo sapiens miR-1 stem-loop\nGCGCGCGCGCUGGAAUGUAACCCCCCAAAA\n'
                             '>hsa-mir-2 MI02 Homo sapiens miR-2 stem-loop\nUUCCCAAAGGGUAGAGAGAG\n'
                             '>hsa-mir-3a MI03 Homo sapiens miR-3a stem-loop\nGGAAACCCGGGUUUCCCCCCGG\n'
                             '>hsa-mir-3b MI04 Homo sapiens miR-3b stem-loop\nUUAAACCCGGGUUUAAAAAAUU\n'
                             '>mmu-mir-1 MI05 Mus musculus miR-1 stem-loop\nGCGCGCGCGCUGGAAUGUAACCCCCCAAAA\n')
        # genomic loci: miR-1-3p chr1:101-110 (+), miR-2-5p chr2:201-210 (-)
        self.gff = write(t / 'hsa.gff3',
                         '##gff-version 3\n# genome-build-id: GRCh38\n'
                         'chr1\t.\tmiRNA_primary_transcript\t91\t120\t.\t+\t.\tID=MI01;Alias=MI01;Name=hsa-mir-1\n'
                         'chr1\t.\tmiRNA\t101\t110\t.\t+\t.\tID=MIMAT01;Alias=MIMAT01;Name=hsa-miR-1-3p;Derives_from=MI01\n'
                         'chr2\t.\tmiRNA\t201\t210\t.\t-\t.\tID=MIMAT02;Alias=MIMAT02;Name=hsa-miR-2-5p;Derives_from=MI02\n'
                         'chr3\t.\tmiRNA\t301\t312\t.\t+\t.\tID=MIMAT03;Alias=MIMAT03;Name=hsa-miR-3a;Derives_from=MI03\n'
                         'chr4\t.\tmiRNA\t401\t412\t.\t+\t.\tID=MIMAT04;Alias=MIMAT04;Name=hsa-miR-3b;Derives_from=MI04\n')
        # SNVs (VCF, chrom without chr): miR-1-3p pos 103 G>C (offset 2) and pos 104 A>G,T
        # (offset 3); miR-2-5p pos 209 (minus: offset 1, mature base C, genomic G) G>A -> T on
        # the miRNA; pos 205 ref T does not match genomic (mature offset 5 is A -> genomic T is
        # correct, so use a wrong ref C): skipped; one indel ignored.
        self.snps = write(t / 'snps.tsv', '1\t103\tG\tC\n1\t104\tA\tG,T\n2\t209\tG\tA\n2\t205\tC\tT\n1\t107\tAT\tA\n')
        self.repeats = write(t / 'rep.tsv', 'chr1\t100\t110\thsa-miR-1-3p\t0\t+\tchr1\t90\t130\tL2c\tL2c_dup7\t+\n')

    def tearDown(self):
        self.tmp.cleanup()

    def run_all(self):
        common = ['--db', 'miRBase', '--org', 'human', '--lib', str(self.lib), '--work', str(self.work)]
        m.main(['mirna', *common, '--code', 'hsa', '--mature', self.mature, '--hairpin', self.hairpin,
                '--gff', self.gff])
        m.main(['mirna-finish', *common, '--gff', self.gff, '--snps', self.snps, '--repeats', self.repeats])

    def test_outputs(self):
        self.run_all()
        lib, work = self.lib, self.work
        self.assertEqual(fasta(lib / 'fasta.Libs/human_mature_miRBase.fa'),
                         [('hsa-miR-1-3p', 'TGGAATGTAA'), ('hsa-miR-2-5p', 'CCCAAAGGGT'),
                          ('hsa-miR-3a', 'AAACCCGGGTTT'), ('hsa-miR-3b', 'AAACCCGGGTTT')])
        self.assertEqual([h for h, _ in fasta(work / 'human_hairpin_miRBase.fa')][0],
                         'hsa-mir-1 MI01 Homo sapiens miR-1 stem-loop')
        self.assertEqual((work / 'human_mature_miRBase.bed').read_text().splitlines()[0],
                         'chr1\t100\t110\thsa-miR-1-3p\t0\t+')
        self.assertTrue((lib / 'annotation.Libs/human_miRBase.gff3').read_text().startswith('##gff-version 3'))
        index = dict(fasta(work / 'human_mirna_miRBase.fa'))
        # miR-1-3p: reference C, offset 2 G>C -> A, offset 3 A>G -> B, A>T -> D; flanks GC / CCCCCC
        self.assertEqual(index['hsa-miR-1-3p.SNPC'], 'GC' + 'TGGAATGTAA' + 'CCCCCC')
        self.assertEqual(index['hsa-miR-1-3p.SNPA'], 'GC' + 'TGCAATGTAA' + 'CCCCCC')
        self.assertEqual(index['hsa-miR-1-3p.SNPB'], 'GC' + 'TGGGATGTAA' + 'CCCCCC')
        self.assertEqual(index['hsa-miR-1-3p.SNPD'], 'GC' + 'TGGTATGTAA' + 'CCCCCC')
        self.assertNotIn('hsa-miR-1-3p', index)
        # miR-2-5p on the minus strand: genomic G>A at offset 1 -> C>T on the miRNA
        self.assertEqual(index['hsa-miR-2-5p.SNPA'], 'TT' + 'CTCAAAGGGT' + 'AGAGAG')
        self.assertNotIn('hsa-miR-2-5p.SNPB', index)  # ref mismatch skipped
        self.assertEqual(index['hsa-miR-3a'], 'GG' + 'AAACCCGGGTTT' + 'CCCCCC')
        self.assertEqual(index['hsa-miR-3b'], 'TT' + 'AAACCCGGGTTT' + 'AAAAAA')
        merges = (lib / 'annotation.Libs/human_merges_miRBase.csv').read_text().splitlines()
        self.assertEqual(merges, [
            'hsa-miR-1-3p,hsa-miR-1-3p.SNPC,hsa-miR-1-3p.SNPA,hsa-miR-1-3p.SNPB,hsa-miR-1-3p.SNPD',
            'hsa-miR-2-5p,hsa-miR-2-5p.SNPC,hsa-miR-2-5p.SNPA',
            'hsa-miR-3a/3b,hsa-miR-3a,hsa-miR-3b'])
        pseudo = dict(fasta(lib / 'fasta.Libs/human_mirna_SNP_pseudo_miRBase.fa'))
        self.assertEqual(pseudo['hsa-miR-1-3p.SNPA'], 'TGCAATGTAA')  # no flanks
        self.assertEqual(pseudo['hsa-miR-1-3p'], 'TGGAATGTAA')        # group record
        self.assertEqual(pseudo['hsa-miR-3a/3b'], 'AAACCCGGGTTT')
        self.assertEqual(set(pseudo) - set(index), {'hsa-miR-1-3p', 'hsa-miR-2-5p', 'hsa-miR-3a/3b'})
        self.assertEqual((lib / 'annotation.Libs/human_miRNAs_in_repetitive_element_miRBase.csv').read_text(),
                         'hsa-miR-1-3p,gene_id "L2c"; transcript_id "L2c_dup7";\n')

    def test_name_clash(self):
        # miRBase 23.1 gives rno-miR-3084b-3p to two accessions; only one has a locus
        t = Path(self.tmp.name)
        self.mature = write(t / 'clash.fa', open(self.mature).read()
                            + '>hsa-miR-3b MIMAT06 Homo sapiens miR-3b\nGGGGGGGGGG\n')
        self.run_all()
        names = [n for n, _ in fasta(self.lib / 'fasta.Libs/human_mature_miRBase.fa')]
        self.assertEqual(names[2:], ['hsa-miR-3a', 'hsa-miR-3b_MIMAT04', 'hsa-miR-3b_MIMAT06'])
        self.assertIn('chr4\t400\t412\thsa-miR-3b_MIMAT04', (self.work / 'human_mature_miRBase.bed').read_text())
        self.assertEqual(dict(fasta(self.work / 'human_mirna_miRBase.fa'))['hsa-miR-3b_MIMAT04'],
                         'TT' + 'AAACCCGGGTTT' + 'AAAAAA')

    def test_precursor_without_locus(self):
        # matures whose precursor has no locus: hairpin by name, else lowest accession
        hp = {'MI10': 'AAAGGGCCCTTTAA', 'MI2': 'CCAAAGGGCCCTTTCC', 'MI3': 'TTTTGGGCCCAAAA'}
        names = {'MI10': 'hsa-mir-7', 'MI2': 'hsa-mir-8', 'MI3': 'hsa-mir-9'}
        self.assertEqual(m.precursor_for('miRBase', 'hsa-miR-7-5p', 'GGGCCC', {}, hp, names), hp['MI10'])
        self.assertEqual(m.precursor_for('miRBase', 'hsa-miR-6-5p', 'GGGCCC', {}, hp, names), hp['MI2'])
        self.assertEqual(m.precursor_for('miRBase', 'hsa-miR-7-5p', 'GGGCCC', {'hsa-miR-7-5p': ['MI3']}, hp, names), hp['MI3'])
        self.assertIsNone(m.precursor_for('miRBase', 'hsa-miR-7-5p', 'ACACAC', {}, hp, names))

    def test_snv_bed_other_release(self):
        # SNVs looked up on another release's loci (22.1 on GRCm38): miR-1-3p at 1001-1010 there,
        # GFF with Ensembl contig names; the SNV at 1003 G>C gives the same variant as before
        t = Path(self.tmp.name)
        old = write(t / 'old.gff3', '##gff-version 3\n'
                    '1\t.\tmiRNA\t1001\t1010\t.\t+\t.\tID=MIMAT01;Alias=MIMAT01;Name=hsa-miR-1-3p;Derives_from=MI01\n'
                    '1\t.\tmiRNA\t2001\t2005\t.\t+\t.\tID=MIMAT02;Alias=MIMAT02;Name=hsa-miR-2-5p;Derives_from=MI02\n')
        common = ['--db', 'miRBase', '--org', 'human', '--lib', str(self.lib), '--work', str(self.work)]
        m.main(['mirna', *common, '--code', 'hsa', '--mature', self.mature, '--hairpin', self.hairpin, '--gff', self.gff])
        m.main(['snv-bed', '--org', 'human', '--gff', old, '--lib', str(self.lib), '--work', str(self.work),
                '--out', str(t / 'snv.bed')])
        self.assertEqual((t / 'snv.bed').read_text(), 'chr1\t1000\t1010\thsa-miR-1-3p\t0\t+\n')  # length 5 left out
        snps = write(t / 's.tsv', '1\t1003\tG\tC\n1\t103\tG\tA\n')
        m.main(['mirna-finish', *common, '--gff', self.gff, '--snps', snps, '--snv-bed', str(t / 'snv.bed')])
        index = dict(fasta(self.work / 'human_mirna_miRBase.fa'))
        self.assertEqual(index['hsa-miR-1-3p.SNPA'], 'GC' + 'TGCAATGTAA' + 'CCCCCC')
        self.assertNotIn('hsa-miR-1-3p.SNPB', index)

    def test_bed_ucsc_contigs(self):
        self.assertEqual([m.ucsc_chrom(c) for c in ('2', 'X', 'MT', 'chr7', '901866519')],
                         ['chr2', 'chrX', 'chrM', 'chr7', 'chr901866519'])

    def test_too_many_alleles(self):
        # 36 alleles (more than the 25 SNP letters) on miR-3a: no variants for it, others kept
        t = Path(self.tmp.name)
        rows = '1\t103\tG\tC\n' + ''.join(f'3\t{301 + i}\t{b}\t{a}\n' for i, b in enumerate('AAACCCGGGTTT')
                                         for a in 'ACGT' if a != b)
        self.snps = write(t / 'many.tsv', rows)
        self.run_all()
        index = dict(fasta(self.work / 'human_mirna_miRBase.fa'))
        self.assertIn('hsa-miR-3a', index)
        self.assertIn('hsa-miR-1-3p.SNPA', index)

    def test_no_snps(self):
        self.snps = write(Path(self.tmp.name) / 'none.tsv', '')
        self.run_all()
        index = dict(fasta(self.work / 'human_mirna_miRBase.fa'))
        self.assertIn('hsa-miR-1-3p', index)
        self.assertEqual((self.lib / 'annotation.Libs/human_merges_miRBase.csv').read_text(),
                         'hsa-miR-3a/3b,hsa-miR-3a,hsa-miR-3b\n')


class MirGeneDB(unittest.TestCase):
    def test_star_and_precursor(self):
        with tempfile.TemporaryDirectory() as tmp:
            t = Path(tmp)
            mat = write(t / 'mat.fa', '>Hsa-Let-7-P1b_5p\nUGAGGUAGGA\n')
            star = write(t / 'star.fa', '>Hsa-Let-7-P1b_3p*\nCUAUACGGCC\n')
            pre = write(t / 'pre.fa', '>Hsa-Let-7-P1b_pre\nAAUGAGGUAGGAGGGGGCUAUACGGCCUUUUUUUU\n')
            gff = write(t / 'hsa.gff3', '##gff-version 3\n# microRNAs:    MirGeneDB v3.0\n'
                        'chr9\t.\tpre_miRNA\t1\t34\t.\t+\t.\tID=Hsa-Let-7-P1b_pre;Alias=MI1\n'
                        'chr9\t.\tmiRNA\t3\t12\t.\t+\t.\tID=Hsa-Let-7-P1b_5p;Alias=MIMAT1\n'
                        'chr9\t.\tmiRNA\t18\t27\t.\t+\t.\tID=Hsa-Let-7-P1b_3p*;Alias=MIMAT2\n')
            common = ['--db', 'MirGeneDB', '--org', 'human', '--lib', str(t / 'human'), '--work', str(t / 'w')]
            m.main(['mirna', *common, '--code', 'hsa', '--mature', mat, '--star', star, '--hairpin', pre, '--gff', gff])
            m.main(['mirna-finish', *common, '--gff', gff])
            self.assertEqual(fasta(t / 'human/fasta.Libs/human_mature_MirGeneDB.fa'),
                             [('Hsa-Let-7-P1b_5p', 'TGAGGTAGGA'), ('Hsa-Let-7-P1b_3p*', 'CTATACGGCC')])
            self.assertEqual(dict(fasta(t / 'w/human_mirna_MirGeneDB.fa')),
                             {'Hsa-Let-7-P1b_5p': 'AA' + 'TGAGGTAGGA' + 'GGGGGC',
                              'Hsa-Let-7-P1b_3p*': 'GG' + 'CTATACGGCC' + 'TTTTTT'})
            self.assertIn('chr9\t17\t27\tHsa-Let-7-P1b_3p*', (t / 'w/human_mature_MirGeneDB.bed').read_text())

    def test_names(self):
        self.assertEqual(m.mirgenedb_precursor('Hsa-Mir-8-P1a_3p*'), 'Hsa-Mir-8-P1a_pre')
        self.assertEqual(m.group_name(['Hsa-Mir-430-P23_5p', 'Hsa-Mir-430-P25_5p']), 'Hsa-Mir-430-P23_5p/430-P25_5p')
        self.assertEqual(m.group_name(['hsa-let-7a-5p', 'hsa-let-7b-5p']), 'hsa-let-7a-5p/7b-5p')


class Other(unittest.TestCase):
    def test_rmsk_bed(self):
        with tempfile.TemporaryDirectory() as tmp:
            row = '0\t1\t2\t3\t4\t{c}\t{s}\t{e}\t-1\t{st}\t{r}\tLINE\tL2\t1\t2\t3\t1\n'
            rmsk = write(Path(tmp) / 'rmsk.txt.gz', row.format(c='chr1', s=10, e=20, st='+', r='L2c')
                         + row.format(c='chr1', s=30, e=40, st='-', r='L2c') + row.format(c='chr2', s=5, e=9, st='+', r='MIR'))
            out = Path(tmp) / 'rmsk.bed'
            m.main(['rmsk-bed', '--rmsk', rmsk, '--out', str(out)])
            self.assertEqual(out.read_text().splitlines(), ['chr1\t10\t20\tL2c\tL2c\t+', 'chr1\t30\t40\tL2c\tL2c_dup1\t-',
                                                            'chr2\t5\t9\tMIR\tMIR\t+'])

    def test_ncrna(self):
        with tempfile.TemporaryDirectory() as tmp:
            t = Path(tmp)
            nc = write(t / 'nc.fa.gz',
                       '>T1.1 ncrna chromosome:GRCh38:1:1:9:1 gene:G1 transcript_biotype:snoRNA\nACGU\n'
                       '>T2.1 ncrna chromosome:GRCh38:2:1:9:1 gene:G2 transcript_biotype:snoRNA\nACGT\n'
                       '>T3.1 ncrna x transcript_biotype:rRNA\nGGGG\n>T4.1 ncrna x transcript_biotype:miRNA\nCCCC\n'
                       '>T5.1 ncrna x transcript_biotype:lncRNA\nTTTT\n>T6.1 ncrna x transcript_biotype:Mt_rRNA\nAAAA\n')
            cdna = write(t / 'cdna.fa.gz', '>C1.1 cdna x transcript_biotype:protein_coding\nATGA\n'
                         '>C2.1 cdna x transcript_biotype:rRNA_pseudogene\nGGCC\n')
            m.main(['ncrna', '--ncrna', nc, '--cdna', cdna, '--outdir', str(t / 'o')])
            self.assertEqual(fasta(t / 'o/snorna.fa'), [('T1.1/T2.1 ncrna chromosome:GRCh38:1:1:9:1 gene:G1 transcript_biotype:snoRNA', 'ACGT')])
            self.assertEqual([h.split()[0] for h, _ in fasta(t / 'o/rrna.fa')], ['C2.1', 'T3.1'])
            self.assertEqual([h.split()[0] for h, _ in fasta(t / 'o/mrna.fa')], ['C1.1'])
            self.assertEqual([h.split()[0] for h, _ in fasta(t / 'o/ncrna_others.fa')], ['T5.1', 'T6.1'])

    def test_trna(self):
        with tempfile.TemporaryDirectory() as tmp:
            t = Path(tmp)
            mat = write(t / 'm.fa', '>Mus_musculus_tRNA-Ala-AGC-1-1 (tRNAscan-SE ID: chr1.trna1) Ala (AGC)\nGGGGUU\n'
                        '>Mus_musculus_tRNA-Gly-GCC-1-1 (x)\nGCAUUGGCCA\n')
            bed = write(t / 't.bed', 'chr1\t4\t10\ttRNA-Ala-AGC-1-1\t1000\t+\n'
                        'chrM\t8\t18\ttRNA-Gly-GCC-1-1\t1000\t-\nchr1\t0\t3\ttRNA-Und-NNN-1-1\t1000\t+\n')
            genome = write(t / 'g.fa.gz', '>1 dna:primary_assembly\nAAAACCCCCCGGGTTTTA\n>MT dna\nTTTTGCAAAAAAAAAAAA\n')
            m.main(['trna', '--mature', mat, '--bed', bed, '--genome', genome, '--outdir', str(t / 'o'),
                    '--species-prefix', 'Mus_musculus', '--chrom-prefix', '', '--trailer', '4'])
            self.assertEqual(fasta(t / 'o/mature_trna.fa'), [('Mus_musculus_tRNA-Ala-AGC-1-1', 'GGGGTTCCA'),
                                                             ('Mus_musculus_tRNA-Gly-GCC-1-1', 'GCATTGGCCA')])
            self.assertEqual(fasta(t / 'o/pre_trna.fa'), [('pre_Mus_musculus_tRNA-Ala-AGC-1-1_trailer', 'GGGT'),
                                                          ('pre_Mus_musculus_tRNA-Gly-GCC-1-1_trailer', 'TTGC')])


class LibraryNames(unittest.TestCase):
    """File names miRge3 0.1.4 opens (mirge/libs/*.py), with -d miRBase or -d MirGeneDB and
    -on human. A library built with 'miRGeneDB' (miRge-build's documented spelling) fails here."""
    MIRGE3_LOOKUPS = [
        'annotation.Libs/{o}_{d}.gff3',                          # summary.py:809, novel_mir.py:276
        'annotation.Libs/{o}_merges_{d}.csv',                    # summary.py:684
        'annotation.Libs/{o}_miRNAs_in_repetitive_element_{d}.csv',  # mirge2_tRF_a2i.py:1035
        'fasta.Libs/{o}_mature_{d}.fa',                          # summary.py:805
        'fasta.Libs/{o}_mirna_SNP_pseudo_{d}.fa',                # mirge2_tRF_a2i.py:1030
        'index.Libs/{o}_hairpin_{d}.1.ebwt',                     # summary.py:806, manifoldAlign.py
        'index.Libs/{o}_mirna_{d}.1.ebwt',                       # summary.py:775, manifoldAlign.py
    ]
    MIRGE3_INDEXES = ['genome', 'mature_trna', 'pre_trna', 'mrna', 'ncrna_others', 'rrna', 'snorna', 'spike-in']

    def test_names(self):
        want = [p.format(o='human', d=d) for d in ('miRBase', 'MirGeneDB') for p in self.MIRGE3_LOOKUPS]
        want += [f'index.Libs/human_{i}.1.ebwt' for i in self.MIRGE3_INDEXES]
        self.assertEqual(sorted(m.library_files('human')), sorted(want))
        self.assertNotIn('miRGeneDB', ' '.join(m.library_files('human')))


if __name__ == '__main__':
    unittest.main(verbosity=1)
