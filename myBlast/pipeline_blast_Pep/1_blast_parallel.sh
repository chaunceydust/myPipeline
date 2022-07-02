#!/bin/bash
set -exuo pipefail

# Default parameter
threadCutoff=160
evalueCutoff=1e-5
resultfmt=0
singleThreads=2

while getopts "p:j:s:f:e:h" OPTION
do
    case $OPTION in
        p)
            PopName=$OPTARG
            ;;
        j)
            threadCutoff=$OPTARG
            ;;
        s)
            singleThreads=$OPTARG
            ;;
        f)
            resultfmt=$OPTARG
            ;;
        e)
            evalueCutoff=$OPTARG
            ;;
        h)
            usage
            exit 1
            ;;
        ?)
            usage
            exit 1
            ;;
    esac
done

oriWD=$(dirname $PWD)
WD=$(dirname $PWD)/${PopName}

[ -d $WD/02_blast_result ] && rm -rf $WD/02_blast_result
[ ! -d $WD/02_blast_result ] && mkdir -p $WD/02_blast_result;

rm -rf $WD/tmp.blast.list*
:> $WD/tmp.blast.list
for i in `ls $WD/01_sequences/*.fasta`;
do
	# Sequences producing significant alignments
cat >> $WD/tmp.blast.list << EOF
	blastp -query $i \
               -db $oriWD/00_BlastDB/db \
               -out $WD/02_blast_result/$(basename $i).txt \
               -evalue $evalueCutoff \
               -outfmt $resultfmt \
               -num_threads $singleThreads;
EOF

done

num=$(ls $WD/01_sequences/*.fasta | wc -l)
# threadCutoff=160
[ $num -gt $threadCutoff ] && num=$threadCutoff
ParaFly -c $WD/tmp.blast.list -CPU $num

cd $WD/02_blast_result
for n in *.txt; do mv $n `echo $n|sed "s/\.fasta.txt/\.blastp/"`; done;
:> Samples.txt
ls *.blastp > Samples.txt
perl -pi -e "s/.blastp//" Samples.txt

