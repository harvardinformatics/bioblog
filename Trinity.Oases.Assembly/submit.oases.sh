#SBATCH --partition=general
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=6
#SBATCH --mem=100000
#SBATCH --time=3-0
#SBATCH --job-name=oases
#SBATCH --output=oases.%j.txt

module load centos6/oases_0.2.8
module load centos6/velvet-1.2.10_gcc-4.8.0

python /n/sw/centos6/oases_0.2.8/scripts/oases_pipeline.py \
   -m 21 \
   -M 23 \
   -o "mysample"
   -p ' -ins_length 100 ' \
   -d " -shortPaired  MySample.paired.fasta"

