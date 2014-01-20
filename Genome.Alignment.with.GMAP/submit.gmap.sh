#SBATCH --partition=general
#SBATCH --ntasks=2
#SBATCH --nodes=1
#SBATCH --time=1-0
#SBATCH --mem=4000
#SBATCH --output=gmap.slurm.out

module load centos6/gmap-2013-10-04

gmap -d taeGut3.2.4.73 -f samse MySample.transcripts.fa  > MySample.sam 2> MySample.stderr
