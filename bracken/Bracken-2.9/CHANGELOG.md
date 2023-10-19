# CHANGELOG: 2023/09/20

## 2023/09/20 Version 2.9
   * Creating release 2.9 to be compatible with new kraken-uniq builds 

## 2022/10/11 Version 2.8 
    * Creating release 2.8 to be compatible with kraken-uniq output reports

## 2022/06/02 fix
    * Fixing issue where non-unique genomes cause clade to be removed 
    * Reads at/below abundance level will not be redistributed

## 2020/08/13 Updated
    * Fixed README version number
    * Adding error catches for est_abundance.py (check for Kraken default output/mpa report) 

## Released fixes 2020/03/26
    * Remove need for user to specify -w option when running the bracken script  

## Released fixes 2020/03/20
    * Fixing problems with generating the correct kmer distribution files
    * Allow for non-ncbi taxonomy files (notably, root node does NOT have to be the first line in the nodes.dmp file anymore) 
    * Allow for non-traditional nodes for abundance estimation (e.g. abundance estimation of S1 taxons) 

## 2020/01/08 Update
    * Fixed generate_kmer_distrib.py script to use the taxid instead of the seqid in map file 
    * New Year 

# Author information
Jennifer Lu (jlu26@jhmi.edu, jennifer.lu717@gmail.com)
