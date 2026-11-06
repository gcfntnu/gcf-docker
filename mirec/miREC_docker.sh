#!/bin/bash

R=0;
H=5;
S=8;
E=15;
T=8;
cut=0;
O=correct_read.fastq;

while getopts f:o:r:t:s:e:c:u: op
do 
    case $op in
        f)
            echo "Input file name is: $OPTARG"
            F=$OPTARG;;
        o)
            echo "Output file name is: $OPTARG"
            O=$OPTARG;;
        r)
            echo "Frequency threshold value is: $OPTARG"
            H=$OPTARG;;
        s)
            echo "K_1 value is: $OPTARG"
            S=$OPTARG;;
        e)
            echo "K_end value is: $OPTARG"
            E=$OPTARG;;
        t)
            echo "The number of threads is: $OPTARG"
            T=$OPTARG;;
        c)
            echo "start cutadapter with adapter seq: $OPTARG"
            cut=1;
            C=$OPTARG;;
        u)
	    echo "correct subs error only"
            R=1;;
        \?)
            echo "Usage: args [-f] [-s] [-e] [-t] [-u] [-r][-o][-c]"
            echo "-f means Input file name "
            echo "-o means Output file name "
            echo "-r means the value of frequency threshold (Default:5)"
            echo "-t means the number of threads (Default:8)"
            echo "-s means k_1 value"
            echo "-e means k_end value"
	    echo "-c means open cutadapter step with adapter sequence"
            echo "-u means run_type is subs error only"
            exit 1;;
    esac
done


if [ ${cut} -eq 1 ]
then
    echo "start cutadapter  ----";
    echo "cutadapt -j 0 -b ${C} -o cut.fq ${F}";
    ./cutadapt -j 0 -b ${C} -o cut.fq ${F};
    echo "cutadapter finished ----";
    awk '{if((NR%2)==1)print $1;else print $0}' cut.fq > input.fq
else
    awk '{if((NR%2)==1)print $1;else print $0}' ${F} > input.fq
fi


if [ $R -eq 1 ]
then
    echo "running subs error correction only";
    awk '{if(NR%4!=0)ORS=" ";else ORS="\n"}1' input.fq | awk '{print $1 " " $(NF-2) " " $NF}' > ./id_read.txt;
    awk '{print $2}' ./id_read.txt |sort |uniq -c| sort -r -nk1 > ./expreLevel_cor.txt   
    cp ./id_read.txt ./ID_read_quality_cor.txt
    cp ./ID_read_quality_cor.txt ./ID_read_quality_input.txt
    cp input.fq ./correct_read.fastq

    for i in $(seq $S $E )
    do
	#----recurring prepare ----: finish error correction, recount 'kmer frequency' and 'read frequency' and 'id_read'
	#recount 'kmer frequency', then create kmer.freq (e.g. 5mer.freq)
	kmc -k${i} -fq -ci1 ./correct_read.fastq tmp${i} ./
	kmc_dump -t tmp${i} tmpkc${i}
	sort -nk2 -r tmpkc${i} > ./${i}mer.freq
	rm tmp*

	#recount 'read frequency', then create read_expresslevel data ([read_freq] [read])
	awk '{print $2}' ID_read_quality_cor.txt |sort |uniq -c| sort -r -nk1 > expreLevel_cor.txt
	echo "----------------------${i} mer frequency preparation ready";

	#error correction
	echo "miREC_fq -k ${i} -m ${i}mer.freq -t ${T} -r ${H} -l expreLevel_cor.txt -f ID_read_quality_input.txt"

	miREC_fq -k ${i} -m ./${i}mer.freq -t ${T} -r ${H} -l expreLevel_cor.txt -f ID_read_quality_input.txt;

	cp ID_read_quality_cor.txt ID_read_quality_input.txt 
	#cp correct_read.fa correct_read_cp.fa
    done
    rm *.freq *.txt

else
    echo "running mix error correction";
    awk '{if(NR%4!=0)ORS=" ";else ORS="\n"}1' input.fq | awk '{print $1 " " $(NF-2) " " $NF}' > ./id_read.txt;
    awk '{print $2}' ./id_read.txt |sort |uniq -c| sort -r -nk1 > ./expreLevel_cor.txt   
    cp ./id_read.txt ./ID_read_quality_cor.txt
    cp ./ID_read_quality_cor.txt ./ID_read_quality_input.txt
    cp input.fq ./correct_read.fastq

    for i in $(seq $S $E )
    do
	#----recurring prepare ----: finish error correction, recount 'kmer frequency' and 'read frequency' and 'id_read'
	#recount 'kmer frequency', then create kmer.freq (e.g. 5mer.freq)
	kmc -t -k${i} -fq -ci1 ./correct_read.fastq tmp${i} ./
	kmc_dump -t tmp${i} tmpkc${i}
	sort -nk2 -r tmpkc${i} > ./${i}mer.freq
	rm tmp*

	#recount '(k-1)mer frequency', then create kmer.freq (e.g. 5mer.freq)
	tmpm=$(($i-1))
	kmc -t -k${tmpm} -fq -ci1 ./correct_read.fastq tmp${tmpm} ./
	kmc_dump -t tmp${tmpm} tmpkc${tmpm}
	sort -nk2 -r tmpkc${tmpm} > ./${tmpm}mer.freq
	rm tmp*

	#recount '(k+1)mer frequency', then create kmer.freq (e.g. 5mer.freq)
	awk '{print $2}' ID_read_quality_cor.txt |sort |uniq -c| sort -r -nk1 > expreLevel_cor.txt
	echo "----------------------${i} mer frequency preparation ready";

	#error correction
	echo "miREC_mix_fq -k ${i} -m ${i}mer.freq -s ${tmpm}mer.freq -b ${tmpa}mer.freq -t ${T} -r ${H} -l expreLevel_cor.txt -f ID_read_quality_input.txt";

	# time ./miREC_fq_update -k ${i} -m /home/xuanzhan/Data/miRNA/simu/${i}mer.freq -l expreLevel_cor.txt -f ID_read_quality_input.txt >> miREC_mix${file_id[${j}]}.log;
	miREC_mix_fq -k ${i} -m ${i}mer.freq -s ${tmpm}mer.freq -b ${tmpa}mer.freq -t ${T} -r ${H} -l expreLevel_cor.txt -f ID_read_quality_input.txt;

	echo "----------------------${i} mer correction finished";

	cp ID_read_quality_cor.txt ID_read_quality_input.txt 
	#cp correct_read.fa correct_read_cp.fa
    done
    rm *.freq *.txt

fi
rm input.fq

if [ "${O}" != "correct_read.fastq" ]
then 
	cp correct_read.fastq ${O};
	rm correct_read.fastq
fi
