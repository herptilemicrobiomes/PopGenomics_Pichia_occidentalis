#!/usr/bin/bash -l
#SBATCH --out logs/make_shred_asm.%a.log -c 4 -N 1 -n 1 -a 1 

CPU=2
if [ $SLURM_CPUS_ON_NODE ]; then
	CPU=$SLURM_CPUS_ON_NODE
fi
N=${SLURM_ARRAY_TASK_ID}
if [ -z $N ]; then
	N=$1
fi

conda activate ./env
INDIR=asm_only
INPUT=input
IFS=,
sed -n ${N}p $INDIR/samples.csv | while read STRAIN ASSEMBLY
do
	if [ ! -f $INPUT/${STRAIN}_1.fastq.gz ]; then
		wgsim -N 2000000 -r 0 -e 0 -R 0 -1 150 -2 150 $INDIR/$ASSEMBLY $INPUT/${STRAIN}_1.fastq $INPUT/${STRAIN}_2.fastq
		pigz -p $CPU $INPUT/${STRAIN}_[12].fastq
	fi
done
