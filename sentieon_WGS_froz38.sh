#! /usr/bin/env bash
#!/bin/sh
#set -xo pipefail

#   sentieon_WGS_froz38.sh - Variant calling pipeline for paired-end WGS sequencing data using Sentieon software and genome build 38.
#   Copyright (C) 2022  Adrian Otamendi Laspiur adrota@dtu.dk
#
#   This program is free software: you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation, either version 3 of the License, or
#   (at your option) any later version.
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.

#   You should have received a copy of the GNU General Public License
#   along with this program.  If not, see <https://www.gnu.org/licenses/>.






# *******************************************
# At DTU this is VERSION 3.0. Sentieon Version: 202010.02
# *******************************************
# Script to perform DNA seq variant calling
# using a single sample with 2 fastq files

pipeline_version="PSG02"
# Full path to code repo 
apps="/home/projects/HT2_leukngs/apps/github/code"

# *******************************************
# fastq-files are named R1 and R2 as the final part of the filename. After this only extension (can be zipped or not) 
# reads are aligned to hg38 genome 

# *******************************************
# Update with the fullpath location of your sample fastq 
data_dir="$( dirname "$(realpath -s $1)" )"	# data_dir is  the directory of the input symlinks FASTQ file (symlinks should not be followed, done with -s option)
echo "FASTQ file directory: "$data_dir

# use full path of input fastq 
fastq_folder=$data_dir
fastq_1="$(realpath -s $1)"
fastq_2=$(sed 's/R1/R2/g' <<< "$fastq_1")
samplename=$(basename $fastq_1 | sed 's/.R1.*//')
sample="$samplename"."$pipeline_version"
workdir=$data_dir/$sample #Determine where the output files will be stored
group=$(zgrep -m 1 '@'  $fastq_1 | cut -d ':' -f3-4)
platform="ILLUMINA"


# Update with the location of the reference data files
fasta=/home/projects/HT2_leukngs/data/references/hg38/GATK_references38/Homo_sapiens_assembly38.fasta						
#fasta_=/home/projects/HT2_leukngs/data/references/hg38/GCA_000001405.15_GRCh38_no_alt_analysis_set.fna.gz
dbsnp=/home/projects/HT2_leukngs/data/references/hg38/GATK_references38/Homo_sapiens_assembly38.dbsnp138.vcf							
known_1000G_snp=/home/projects/HT2_leukngs/data/references/hg38/GATK_references38/1000G_phase1.snps.high_confidence.hg38.vcf.gz
known_Mills_indels=/home/projects/HT2_leukngs/data/references/hg38/GATK_references38/Mills_and_1000G_gold_standard.indels.hg38.vcf.gz
omni=/home/projects/HT2_leukngs/data/references/hg38/GATK_references38/1000G_omni2.5.hg38.vcf.gz	
hapmap=/home/projects/HT2_leukngs/data/references/hg38/GATK_references38/hapmap_3.3.hg38.vcf.gz
axiom=/home/projects/HT2_leukngs/data/references/hg38/GATK_references38/Axiom_Exome_Plus.genotypes.all_populations.poly.hg38.vcf.gz
	

# Update with the location of the Sentieon software package and license file	
export SENTIEON_LICENSE=localhost:8990
SENTIEON_INSTALL_DIR=/services/tools/cbspythontools/1.3
echo "SENTIEON INSTALL DIR= "$SENTIEON_INSTALL_DIR 
export SENTIEON_TMPDIR=/scratch


# Other settings
# add optional argument for number of threads, default is 38
if [[ -z $2 ]]; then
        nt=38
        echo "Threads: Running with defaults names"
else
    echo Got threads $2
    nt=$2
fi

echo "# Input files: $fastq_1 and $fastq_2"
echo "# Input number of samplename:" $samplename #XXXXX_XXXXXX.T.T01.S1
echo "# Input number of sample:" $sample 	#XXXXX_XXXXXX.T.T01.S1.PSG02
echo "# Input number of group:" $group 
echo "# Input number of platform:" $platform 



# ******************************************
# 0. Setup
# ******************************************
mkdir -p $workdir
logfile=$workdir/run.log
exec > $logfile 2>&1
echo "Copying executed script to" $workdir
script_name=$(basename $(readlink -f $0))
cp "$(readlink -f $0)" $workdir/"$sample".$script_name
cd $workdir



# ******************************************
# 1. Mapping reads with BWA-MEM, sorting
# ******************************************
#The results of this call are dependent on the number of threads used. To have number of threads independent results, add chunk size option -K 10000000 
( $SENTIEON_INSTALL_DIR/bin/sentieon bwa mem -R "@RG\tID:$group\tSM:$sample\tPL:$platform" -t $nt -K 10000000 $fasta $fastq_1 $fastq_2 || echo -n 'error' ) | $SENTIEON_INSTALL_DIR/bin/sentieon util sort -r $fasta -o sorted.bam -t $nt --sam2bam -i -



# ******************************************
# 2. Metrics
# ******************************************
$SENTIEON_INSTALL_DIR/bin/sentieon driver -r $fasta -t $nt -i sorted.bam --algo MeanQualityByCycle mq_metrics.txt --algo QualDistribution qd_metrics.txt --algo GCBias --summary gc_summary.txt gc_metrics.txt --algo AlignmentStat --adapter_seq '' aln_metrics.txt --algo InsertSizeMetricAlgo is_metrics.txt
$SENTIEON_INSTALL_DIR/bin/sentieon plot GCBias -o gc-report.pdf gc_metrics.txt
$SENTIEON_INSTALL_DIR/bin/sentieon plot QualDistribution -o qd-report.pdf qd_metrics.txt
$SENTIEON_INSTALL_DIR/bin/sentieon plot MeanQualityByCycle -o mq-report.pdf mq_metrics.txt
$SENTIEON_INSTALL_DIR/bin/sentieon plot InsertSizeMetricAlgo -o is-report.pdf is_metrics.txt


# ******************************************
# 2.b. CHECK-POINT FOR NUMBER OF READS
# ******************************************
stats=$(tail -n 2 aln_metrics.txt | head -n 1 | cut -f2,6)
total_reads=$(echo $stats | cut -d ' ' -f1)
pf_reads_aligned=$(echo $stats | cut -d ' ' -f2)
alignment_read_threshold1=1000
alignment_read_threshold2=1000

echo $total_reads were used in alignemnt, $pf_reads_aligned paired reads were aligned ...
if [ $total_reads -lt $alignment_read_threshold1 ]; then
    echo "Not enough reads, exiting ... "
    exit
else
    if [ $pf_reads_aligned -lt $alignment_read_threshold2 ]; then
        echo "Not enough aligned reads, exiting ... "
        exit
        fi
echo "Sufficient paired reads aligned!"
fi
echo "Passed test succesfully!"



# ******************************************
# 3. Remove Duplicate Reads. It is possible
# to mark instead of remove duplicates
# by ommiting the --rmdup option in Dedup
# ******************************************
$SENTIEON_INSTALL_DIR/bin/sentieon driver -t $nt -i sorted.bam --algo LocusCollector --fun score_info score.txt
$SENTIEON_INSTALL_DIR/bin/sentieon driver -t $nt -i sorted.bam --algo Dedup --rmdup --score_info score.txt --metrics dedup_metrics.txt deduped.bam 


grep "algo: Dedup" -A 4 run.log >> read_summary.txt
reads=$(grep "algo: Dedup" -A 4 run.log | grep 'reads' | cut -d ' ' -f2)
deduplication_threshold=1000

echo $reads reads were used in deduplication ...
if [ $total_reads -lt $deduplication_threshold ]; then
    echo "Not enough reads, exiting ... "
    exit
fi
echo "Passed test succesfully!"

$SENTIEON_INSTALL_DIR/bin/sentieon driver -t $nt -r $fasta \
   -i deduped.bam --algo WgsMetricsAlgo \
   "$sample".WGS_METRICS.TXT

# ******************************************
# 4. Indel realigner
# This step is optional for haplotyper-based caller like HC,
# but necessary for any pile-up based caller.
# ******************************************
$SENTIEON_INSTALL_DIR/bin/sentieon driver -r $fasta -t $nt -i deduped.bam --algo Realigner -k $known_Mills_indels -k $known_1000G_snp realigned.bam


# ******************************************
# 5. Base recalibration
# ******************************************
$SENTIEON_INSTALL_DIR/bin/sentieon driver -r $fasta -t $nt -i realigned.bam --algo QualCal -k $dbsnp -k $known_Mills_indels -k $known_1000G_snp recal_data.table
$SENTIEON_INSTALL_DIR/bin/sentieon driver -r $fasta -t $nt -i realigned.bam -q recal_data.table --algo QualCal -k $dbsnp -k $known_Mills_indels -k $known_1000G_snp recal_data.table.post
$SENTIEON_INSTALL_DIR/bin/sentieon driver -t $nt --algo QualCal --plot --before recal_data.table --after recal_data.table.post recal.csv   
$SENTIEON_INSTALL_DIR/bin/sentieon plot QualCal -o recal_plots.pdf recal.csv

# ******************************************
# 5b. ReadWriter to output recalibrated bam
# This stage is optional as variant callers
# can perform the recalibration on the fly
# using the before recalibration bam plus
# the recalibration table
# ******************************************
#$SENTIEON_INSTALL_DIR/bin/sentieon driver -r $fasta -t $nt -i realigned.bam -q recal_data.table --algo ReadWriter recaled.bam

# ******************************************
# 5c. bam-statistics 
# ******************************************
# rename the final bam-file 
mv realigned.bam "$sample".bam 
mv realigned.bam.bai "$sample".bam.bai 

#$apps/computerome/submit.py "$apps/ngs-tools/bam_statistics.sh "$sample".bam" --hours 15 -n "$sample".bam.stat -np 2 --no-numbering


# ******************************************
# 6. HC Variant caller
# ******************************************
$SENTIEON_INSTALL_DIR/bin/sentieon driver -r $fasta -t $nt -i "$sample".bam -q recal_data.table --algo Haplotyper -d $dbsnp --emit_conf=30 --call_conf=30 output.vcf.gz

module load bcftools/1.12
bcftools view output.vcf.gz --regions chr1,chr2,chr3,chr4,chr5,chr6,chr7,chr8,chr9,chr10,chr11,chr12,chr13,chr14,chr15,chr16,chr17,chr18,chr19,chr20,chr21,chr22,chrX,chrY,chrM --output "$sample".chr.vcf.gz


hc_variant_threshold=-1
nr_variants=$(zgrep -v  '#' output.vcf.gz | wc -l)
echo $nr_variants were called with Haplotyper ...
if [ $total_reads -lt $hc_variant_threshold ]; then
    echo "Not enough variants (less than $hc_variant_threshold) were called!"
    echo "Assuming an error happened, and exiting ... "
    exit
fi
echo "Passed test succesfully!"


# ******************************************
# 7. Variant Quality Scrore Recalibration (VQSR)
# ******************************************
$SENTIEON_INSTALL_DIR/bin/sentieon driver -r $fasta --algo VarCal -v output.vcf.gz --tranches_file tranches_output_snp --annotation QD --annotation SOR --annotation FS --annotation MQ --annotation MQRankSum --annotation ReadPosRankSum --resource $dbsnp --resource_param dbsnp,known=true,training=false,truth=false,prior=7 --resource $known_1000G_snp --resource_param 1000G,known=false,training=true,truth=false,prior=10 --resource $omni --resource_param omni,known=false,training=true,truth=true,prior=12 --resource $hapmap --resource_param hapmap,known=false,training=true,truth=true,prior=15 --var_type SNP --plot_file plot_file output_vqsr.vcf

#--aggregate_data /home/projects/HT2_leukngs/people/adrota/sentieon_v2/vqsr/21370_147573.G.T01.S1.PSG01.vcf.gz --aggregate_data /home/projects/HT2_leukngs/people/adrota/sentieon_v2/vqsr/21371_155212.G.T01.S1.PSG01.vcf.gz 

#INDEL
#$SENTIEON_INSTALL_DIR/bin/sentieon driver -r $fasta --algo VarCal -v 23388_152835.G.T01.S1.PSG01.vcf.gz --tranches_file tranches_output_indel --annotation QD --annotation QUAL --annotation SOR --annotation FS --annotation MQ --annotation MQRankSum --annotation ReadPosRankSum --resource $dbsnp --resource_param dbsnp,known=true,training=false,truth=false,prior=2 --resource $known_1000G_snp --resource_param known=false,training=true,truth=true,prior=12 --resource $axiom --resource_param axiomPoly,known=false,training=true,truth=false,prior=10 --max_mq 60 --aggregate_data /home/projects/HT2_leukngs/people/adrota/sentieon_v2/vqsr/21370_147573.G.T01.S1.PSG01.vcf.gz --aggregate_data /home/projects/HT2_leukngs/people/adrota/sentieon_v2/vqsr/21371_155212.G.T01.S1.PSG01.vcf.gz --var_type INDEL


#APPLY
$SENTIEON_INSTALL_DIR/bin/sentieon driver -r $fasta --algo ApplyVarCal -v output.vcf.gz --recal output_vqsr.vcf --tranches_file tranches_output_snp --var_type SNP recaled_variants.vcf
#--vqsr_model var_type=SNP,recal=test.txt,tranches_file=tranches_output_snp,sensitivity=99 output_vqsr.vcf
# --vqsr_model var_type=INDEL,recal=VARIANT_RECAL_DATA,tranches_file=tranches_output_indel,sensitivity=99

#PLOT
$SENTIEON_INSTALL_DIR/bin/sentieon plot VarCal -o vqsr_plots.pdf plot_file --tranches_file tranches_output_snp

bcftools view recaled_variants.vcf -Oz -o recaled_variants.vcf.gz
bcftools index recaled_variants.vcf.gz
bcftools view recaled_variants.vcf.gz --regions chr1,chr2,chr3,chr4,chr5,chr6,chr7,chr8,chr9,chr10,chr11,chr12,chr13,chr14,chr15,chr16,chr17,chr18,chr19,chr20,chr21,chr22,chrX,chrY,chrM --output "$sample".chr.vqsr.vcf.gz

$SENTIEON_INSTALL_DIR/bin/sentieon driver --algo CollectVCMetrics -d $dbsnp -v "$sample".chr.vcf.gz "$sample".chr.vcf.metrics
$SENTIEON_INSTALL_DIR/bin/sentieon driver --algo CollectVCMetrics -d $dbsnp -v "$sample".chr.vqsr.vcf.gz "$sample".chr.vqsr.vcf.metrics

# ******************************************
# 8. Clean-up and VCF-stats submission  
# The final bam-file is the recaled.bam + *bai which may be used in other
# analysis 
# VCF-stats are found with vcf statistics and all quality is kept in
# $sample.quality_reports
# ******************************************
# rename the final vcf-file to comply with naming scheme

mv output.vcf.gz "$sample".vcf.gz
mv output.vcf.gz.tbi "$sample".vcf.gz.tbi
mv recaled_variants.vcf "$sample".vqsr.vcf
mv recaled_variants.vcf.idx "$sample".vqsr.vcf.gz.idx 
#VQSR recalibration data
mv recaled_variants.vcf.gz "$sample".vqsr.vcf.gz
mv recaled_variants.vcf.gz.csi "$sample".vqsr.vcf.gz.csi
mv recaled_variants.vcf.gz.idx "$sample".vqsr.vcf.gz.idx
rm recaled_variants.vcf

mv ../*qsub .
mv run.log "$sample".run.log
mv recal_data.table "$sample".bam.recal_table
#$apps/ngs-tools/vcf_statistics.sh "$sample".vcf.gz

# make sure quality reports is named corrrectly (this should actually have been done in {bam/vcf}_statistics)
mkdir -p quality_reports
mv quality_reports "$sample".quality_reports
mv *pdf "$sample".quality_reports
mv *txt "$sample".quality_reports
# remove all the files we don't want to keep: 
rm recal*
#rm realigned.bam*
rm "$sample".quality_reports/score.txt*
rm score.txt*
rm sorted.bam*
rm deduped.bam*

