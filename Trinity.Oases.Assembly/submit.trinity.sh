#SBATCH --partition=general
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=6
#SBATCH --mem=100000
#SBATCH --time=3-0
#SBATCH --job-name=trinity
#SBATCH --output=trinity.%j.txt

module load centos6/samtools-0.1.19
module load centos6/bowtie2-2.1.0
module load centos6/trinityrnaseq_r20131110

Trinity.pl --seqType fq --JM 20G \
           --left  R1.paired.and_orphans.fastq \
           --right R2.paired.fastq \
           --CPU 6
