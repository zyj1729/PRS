#!/bin/bash
# Change the number of threads to use
num_threads=48
N_THREADS=2
export MKL_NUM_THREADS=$N_THREADS
export NUMEXPR_NUM_THREADS=$N_THREADS
export OMP_NUM_THREADS=$N_THREADS
process_chromosome() {
    pop=$1
    chr=$2
    size=$3
    col=$4
    echo ${pop} ${chr} ${size} ${col}
    # Change this dir to your PRScsX reference dir
    ref_dir="/pollard/home/yorkz/york/BMI206/Simulated_pop/Split/Plink/PRScsX/Reference/"
    # Change this to your summary statistics dir
    sst_dir="/pollard/home/yorkz/york/BMI206/Simulated_pop/Split/Overfitting_test/Plink/GWAS/Formatted/"
    # Change this to PRScsX output dir
    output_dir="/pollard/home/yorkz/york/BMI206/Simulated_pop/Split/Overfitting_test/Plink/PRScsX/S1/Train/"
    # Change this to Plink score output dir
    output_score_dir="/pollard/home/yorkz/york/BMI206/Simulated_pop/Split/Overfitting_test/Plink/Scores/S1/Train/"
    # Change this to your PRScsX dir
    PRScsx_path="/pollard/home/yorkz/york/BMI206/tools/PRScsx/"
    # Change this to the target files (bim bed fam) dir
    target_dir="/pollard/home/yorkz/york/BMI206/Simulated_pop/Split/Overfitting_test/Plink/Discovery/"
    # ng=$(wc -l < ${sst_dir}EUR_chr${chr}.discovery.formatted.assoc.linear)
    ng=$(wc -l < ${sst_dir}${pop}_chr${chr}_${size}.${col}.discovery.formatted.assoc.linear)
    # You can add more summary statistics for mixed population discovery, you need to specify pop name in order using --pop. You might want to change --out_name if you are using multiple summary stats for mixed populations.
    output_prefix="${target_dir}/${pop}_chr${chr}_${size}.${col}.discovery"
    # python ${PRScsx_path}PRScsx.py --ref_dir=${ref_dir} --bim_prefix=$output_prefix --sst_file=${sst_dir}${pop}_chr${chr}_${size}.${col}.discovery.formatted.assoc.linear --n_gwas=$((ng - 1)) --pop=${pop} --out_dir=${output_dir} --out_name=${pop}_target_${pop}_discovery_chr${chr}_${size}_${col} --chrom=${chr}

    # Change this to your plink path
    plink_path=""

    # Note if you are using multiple summary stats for mixed populaiton, the PRScsX output name pattern will change, you need to adjust "${pop}_target_${pop}_discovery_chr${chr}_${pop}_pst_eff_a1_b0.5_phiauto_chr${chr}.txt" accordingly, you might also want to change plink score file prefix in that case. 
    ${plink_path}plink --bfile ${target_dir}/${pop}_chr${chr}_${size}.${col}.discovery --score ${output_dir}/${pop}_target_${pop}_discovery_chr${chr}_${size}_${col}_${pop}_pst_eff_a1_b0.5_phiauto_chr${chr}_updated.txt 2 5 6 sum --allow-no-sex --out ${output_score_dir}${pop}_chr${chr}_${size}_${col}_score
    
    echo "Processing $pop discovery ${size} $pop target chromosome $chr ${col}"
}
export -f process_chromosome
# This is an intermediate file, change the file path to your working dir, keep the file name.
cmd_file="/pollard/home/yorkz/york/BMI206/Simulated_pop/Split/Overfitting_test/Plink/Scores/S1/process_commands.txt"
> ${cmd_file}
# Define the superpopulations with subset sizes
declare -A superpopulations=(
    ["EUR"]="10000 50000 100000 150000 195000"
    # ["AFR"]="5000"
)
output_score_dir="/pollard/home/yorkz/york/BMI206/Simulated_pop/Split/Overfitting_test/Plink/Scores/S1/Train/"
for pop in EUR; do
    for size in ${superpopulations[$pop]}; do
        for chr in {1..22}; do
            for i in {0..19}; do
                col=pheno${i}
                # if [[ -f "${output_score_dir}${pop}_chr${chr}_${size}_${col}_score.profile" ]]; then
                #     continue
                # fi
        # if [[ "$pop" == "AFR" && "$chr" -eq 22 ]]; then
        #     continue
        # else
                echo "$pop $chr $size $col" >> "$cmd_file"
                # break
            done
            # break
        # fi
        # break
        done
        # break
    done
    # break
done
cat "$cmd_file" | xargs -n 4 -P $num_threads bash -c 'process_chromosome "$@"' _

