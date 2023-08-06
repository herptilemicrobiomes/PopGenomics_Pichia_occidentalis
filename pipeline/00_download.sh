#!/usr/bin/bash -l
#SBATCH -p short -c 4 --mem 8gb --out logs/download.%A.log

if [ ! -z $LMOD_CMD ]; then
	module load sra-toolkit
	module load parallel-fastq-dump
	module load workspace/scratch
fi
if [ ! -x $(which fastq-dump) ]; then
  echo "attempting to load conda env"
  . /sw/apps/miniconda3/etc/profile.d/conda.sh
  # whict env name to config.txt perhaps
  conda activate ./env
fi

CPU=2
if [ $SLURM_CPUS_ON_NODE ]; then
  CPU=$SLURM_CPUS_ON_NODE
fi
N=${SLURM_ARRAY_TASK_ID}
if [ -z $N ]; then
  N=$1
fi
if [ -z $N ]; then
  echo "cannot run without a number provided either cmdline or --array in sbatch"
  exit
fi

FOLDER=input
mkdir -p $FOLDER
# parallel fastq dumping is better support

SRA=$(sed -n ${N}p lib/sra.txt)
RMSCRATCH=""
if [ -z $SCRATCH ]; then
	SCRATCH=$(mktemp -d)
	RMSCRATCH=1
fi
echo $SCRATCH
if [ ! -s ${SRA}_1.fastq.gz ]; then
	parallel-fastq-dump -T $SCRATCH -O $FOLDER  --threads $CPU --split-files --gzip --sra-id $SRA
fi

if [ $RMSCRATCH ]; then
	rm -rf $SCRATCH
fi
