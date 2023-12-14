#!/bin/bash
# Change the number of threads to use
num_threads=32
N_THREADS=1
export MKL_NUM_THREADS=$N_THREADS
export NUMEXPR_NUM_THREADS=$N_THREADS
export OMP_NUM_THREADS=$N_THREADS
process_chromosome() {
    pop=$1
    chr=$2
    EUR_size=$3
    AFR_size=$4
    col=$5
    echo ${pop} ${chr} ${EUR_size} ${AFR_size} ${col}
    # Change this dir to your PRScsX reference dir
    ref_dir="/pollard/home/yorkz/york/BMI206/Simulated_pop/Split/Plink/PRScsX/Reference/"
    # Change this to your summary statistics dir
    sst_dir="/pollard/home/yorkz/york/BMI206/Simulated_pop/Split/Overfitting_test/Plink/GWAS/Formatted/"
    # Change this to PRScsX output dir
    output_dir="/pollard/home/yorkz/york/BMI206/Simulated_pop/Split/Overfitting_test/Plink/PRScsX/S3/"
    # Change this to Plink score output dir
    output_score_dir="/pollard/home/yorkz/york/BMI206/Simulated_pop/Split/Overfitting_test/Plink/Scores/S3/"
    # Change this to your PRScsX dir
    PRScsx_path="/pollard/home/yorkz/york/BMI206/tools/PRScsx/"
    # Change this to the target files (bim bed fam) dir
    target_dir="/pollard/home/yorkz/york/BMI206/Simulated_pop/Split/Overfitting_test/Plink/Target/"
    ng_eur=$(wc -l < ${sst_dir}EUR_chr${chr}_${EUR_size}.${col}.discovery.formatted.assoc.linear)
    ng_afr=$(wc -l < ${sst_dir}AFR_chr${chr}_${AFR_size}.${col}.discovery.formatted.assoc.linear)
    # ng_eas=$(wc -l < ${sst_dir}EAS_chr${chr}.${col}.discovery.formatted.assoc.linear)
    # You can add more summary statistics for mixed population discovery, you need to specify pop name in order using --pop. You might want to change --out_name if you are using multiple summary stats for mixed populations.
    output_prefix="${target_dir}/${pop}_chr${chr}.${col}.target"
    python ${PRScsx_path}PRScsx.py --ref_dir=${ref_dir} --bim_prefix=$output_prefix --sst_file=${sst_dir}EUR_chr${chr}_${EUR_size}.${col}.discovery.formatted.assoc.linear,${sst_dir}AFR_chr${chr}_${AFR_size}.${col}.discovery.formatted.assoc.linear --n_gwas=$((ng_eur - 1)),$((ng_afr - 1)) --pop=EUR,AFR --out_dir=${output_dir} --out_name=AFR_target_EUR-AFR_discovery_chr${chr}_${EUR_size}_${AFR_size}_${col} --chrom=${chr} --n_iter 1000 --n_burnin 500

    # Change this to your plink path
    plink_path=""

    # Note if you are using multiple summary stats for mixed populaiton, the PRScsX output name pattern will change, you need to adjust "${pop}_target_${pop}_discovery_chr${chr}_${pop}_pst_eff_a1_b0.5_phiauto_chr${chr}.txt" accordingly, you might also want to change plink score file prefix in that case. 
    ${plink_path}plink --bfile ${target_dir}/AFR_chr${chr}.${col}.target --score ${output_dir}/AFR_target_EUR-AFR_discovery_chr${chr}_${EUR_size}_${AFR_size}_${col}_EUR_pst_eff_a1_b0.5_phiauto_chr${chr}.txt 2 5 6 sum --allow-no-sex --out ${output_score_dir}EUR-AFR_chr${chr}_${EUR_size}_${AFR_size}_${col}_EUR_score

    ${plink_path}plink --bfile ${target_dir}/AFR_chr${chr}.${col}.target --score ${output_dir}/AFR_target_EUR-AFR_discovery_chr${chr}_${EUR_size}_${AFR_size}_${col}_AFR_pst_eff_a1_b0.5_phiauto_chr${chr}.txt 2 5 6 sum --allow-no-sex --out ${output_score_dir}EUR-AFR_chr${chr}_${EUR_size}_${AFR_size}_${col}_AFR_score
    
    echo "Processing $pop chromosome $chr ${col}"
}
export -f process_chromosome
# This is an intermediate file, change the file path to your working dir, keep the file name.
cmd_file="/pollard/home/yorkz/york/BMI206/Simulated_pop/Split/Overfitting_test/Plink/Scores/S3/process_commands.txt"
> ${cmd_file}

# EUR_sizes=(5000 45000 95000 145000 190000)
# AFR_sizes=(5000 5000 5000 5000 5000)
EUR_sizes=(45000)
AFR_sizes=(5000)
output_score_dir="/pollard/home/yorkz/york/BMI206/Simulated_pop/Split/Overfitting_test/Plink/Scores/S3/"
for pop in EUR; do
    for i in ${!EUR_sizes[@]}; do
        EUR_size=${EUR_sizes[$i]}
        AFR_size=${AFR_sizes[$i]}
        for chr in {1..22}; do
            for i in {0..19}; do
                col=pheno${i}
                if [[ -f "${output_score_dir}EUR-AFR_chr${chr}_${EUR_size}_${AFR_size}_${col}_AFR_score.profile" ]]; then
                    continue
                fi
                echo "$pop $chr $EUR_size $AFR_size $col" >> "$cmd_file"
                # break
            done
        # fi
            # break
        done
        # break
    done
    # break
done
cat "$cmd_file" | xargs -n 5 -P $num_threads bash -c 'process_chromosome "$@"' _

