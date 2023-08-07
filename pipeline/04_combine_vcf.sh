#!/usr/bin/bash -l
#SBATCH --mem 64gb -N 1 -n 1 -c 4 --out logs/concat_vcf.log

#if [ ! -z $LMOD_CMD ]; then
#module load bcftools
#module load yq
#module load cyvcf2
#	module load workspace/scratch
#fi

#if [ -z $(which yq) ]; then
	echo "attempting to load conda env"
	. /sw/apps/miniconda3/etc/profile.d/conda.sh
    conda activate ./env
#fi

if [ -z $(which yq) ]; then
	echo "do not have modules or conda env installed"
	exit
fi

CPU=1
if [ $SLURM_CPUS_ON_NODE ]; then
    CPU=$SLURM_CPUS_ON_NODE
fi
if [ -f config.txt ]; then
	source config.txt
else
	echo "need a config.txt"
fi

if [ -z $FINALVCF ]; then
	echo "Need to define FINALVCF in config.txt"
	exit
fi
if [ -z $SLICEVCF ]; then
	echo "Need to define SLICEVCF in config.txt"
	exit
fi
if [[ -z $POPYAML || ! -s $POPYAML ]]; then
	echo "Cannot find \$POPYAML variable - set in config.txt"
	exit
fi
IN=$SLICEVCF
mkdir -p $FINALVCF

for POPNAME in $(yq -y '.Populations | keys' $POPYAML | perl -p -e 's/^\s*\-\s*//')
do
	for TYPE in SNP INDEL
	do
		OUT=$FINALVCF/$PREFIX.$POPNAME.$TYPE.combined_selected.vcf.gz
		QC=$FINALVCF/$PREFIX.$POPNAME.$TYPE.combined_selected.QC.tsv
		if [ ! -s $OUT ];  then
			bcftools concat -Oz -o $OUT --threads $CPU $IN/$POPNAME/${PREFIX}.*.${TYPE}.selected.vcf.gz
			tabix $OUT
		fi
		if [[ ! -s $QC || $OUT -nt $QC ]]; then
			./scripts/vcf_QC_report.py --vcf $OUT -o $QC
		fi

	done
done
