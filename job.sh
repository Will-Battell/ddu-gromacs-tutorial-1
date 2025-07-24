#$ -V
#$ -N 8B2T-in-water           # job name
#$ -pe smp 96                 # openmp threads
#$ -q ddu.q@@ddu_hpn          # node type
#$ -jc long.gpu4              # job class
#$ -l gpu=4                   # number of gpus (if applicable)
#$ -o 8B2T-in-water.log       # output log file
#$ -cwd                       # keep workdir

# Load the GROMACS module (meaning we can run GROMACS commands)
module load GROMACS-thmpi

# Define various variables
export GMX_ENABLE_DIRECT_GPU_COMM=1
export GMX_GPU_PME_DECOMPOSITION=1
export GMX_GPU_DD_COMMS=true
export GMX_GPU_PME_PP_COMMS=true
export GMX_FORCE_UPDATE_DEFAULT_GPU=true
export GMX_FORCE_GPU_AWARE_MPI=1

# Run simulation

# Energy Minimisation

mkdir EM
cd ./EM

gmx grompp -f ../mdp-files/em.mdp -c ../8B2T-water-ions.gro -r ../8B2T-water-ions.gro -p ../topol.top -o em.tpr  
gmx mdrun -s em.tpr  -c 8B2T-em.gro 

cd ../

# NVT simulation

mkdir NVT
cd ./NVT

gmx grompp -f ../mdp-files/nvt.mdp -c ../EM/8B2T-em.gro -r ../EM/8B2T-em.gro -p ../topol.top -o nvt.tpr
gmx mdrun -v -s nvt.tpr -c nvt.gro -cpi nvt.cpt -ntomp 24 -ntmpi 4 -gpu_id 0123 -nb gpu -bonded gpu -pme gpu -npme 1

cd ../

# NPT simulation

mkdir NPT
cd ./NPT

gmx grompp -f ../mdp-files/npt.mdp -c ../NVT/8B2T-nvt.gro -r ../NVT/8B2T-nvt.gro -p ../topol.top -o npt.tpr 
gmx mdrun -v -s npt.tpr -c npt.gro -cpi npt.cpt -ntomp 24 -ntmpi 4 -gpu_id 0123 -nb gpu -bonded gpu -pme gpu -npme 1

cd ../

# Long NPT production simulation

mkdir MD
cd ./MD

gmx grompp -f ../mdp-files/md.mdp -c ../NPT/8B2T-npt.gro -r ../NPT/8B2T-npt.gro -p ../topol.top -o md.tpr 
gmx mdrun -v -s md.tpr -c 8B2T-md.gro -cpi md.cpt -ntomp 24 -ntmpi 4 -gpu_id 0123 -nb gpu -bonded gpu -pme gpu -npme 1

cd ../
