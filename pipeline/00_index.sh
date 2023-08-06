#!/usr/bin/bash -l
module load samtools
module load bwa
if [ ! -x $(which bwa) ]; then 
	source ~/.bashrc
	conda activate ./env
fi

if [ ! -x $(which bwa) ]; then
	echo "cannot run as bwa is not in the env"
	exit
fi
if [ -f config.txt ]; then
	source config.txt
fi
mkdir -p $GENOMEFOLDER
pushd $GENOMEFOLDER
# THIS IS EXAMPLE CODE FOR HOW TO DOWNLOAD DIRECT FROM FUNGIDB
SPECIES=Poccidentalis
URL=https://ftp.ncbi.nlm.nih.gov/genomes/all/GCA/030/142/935/GCA_030142935.1_WPI_Io_ApC_1.0/GCA_030142935.1_WPI_Io_ApC_1.0_genomic.fna.gz
PREF=Poccidentalis_ApC
FASTAFILE=${PREF}_Genome.fasta

if [ ! -f $FASTAFILE ] ; then
	curl $URL | pigz -dc > $FASTAFILE
fi

if [[ ! -f $FASTAFILE.fai || $FASTAFILE -nt $FASTAFILE.fai ]]; then
	samtools faidx $FASTAFILE
fi
if [[ ! -f $FASTAFILE.bwt || $FASTAFILE -nt $FASTAFILE.bwt ]]; then
	bwa index $FASTAFILE
fi

DICT=$(basename $FASTAFILE .fasta)".dict"

if [[ ! -f $DICT || $FASTAFILE -nt $DICT ]]; then
	rm -f $DICT
	samtools dict $FASTAFILE > $DICT
	ln -s $DICT $FASTAFILE.dict 
fi
grep ">" $FASTAFILE | perl -p -e 's/>(\S+).+scaffold_(\d+).+/$1,$2/' > chrom_nums.csv
popd
