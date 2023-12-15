# #!/bin/bash

# # Loop through Type A files
# dir=/pollard/home/yorkz/york/BMI206/Simulated_pop/Split/Overfitting_test/Plink/PRScsX/S1/Train/
# for fileA in /pollard/home/yorkz/york/BMI206/Simulated_pop/Split/Overfitting_test/Plink/GWAS/Formatted/EUR_chr*_*000.pheno*.discovery.formatted.assoc.linear; do
#     # Extract N, size, and k from fileA's name
#     IFS='_' read -r -a array <<< "$(basename "$fileA")"
#     chr=$(echo "$fileA" | grep -oP 'chr\K\d+')
#     size=$(echo "$fileA" | grep -oP '_\K\d+(?=.pheno)')
#     pheno=$(echo "$fileA" | grep -oP 'pheno\K\d+')
#     echo ${chr} ${size} ${pheno}
#     # Define the corresponding Type B file
#     fileB="/pollard/home/yorkz/york/BMI206/Simulated_pop/Split/Overfitting_test/Plink/PRScsX/S1/EUR_target_EUR_discovery_chr${chr}_${size}_pheno${pheno}_EUR_pst_eff_a1_b0.5_phiauto_chr${chr}.txt"

#     # Check if the corresponding Type B file exists
#     if [[ -f "$fileB" ]]; then
#         # Create a temporary mapping file of Type A SNPs to Type B SNPs
#         awk -F'\t' 'NR>1 {split($1, a, ":"); print a[1]"\t"$1}' "$fileA" > ${dir}temp_mapping.txt

#         # Use the mapping to modify the SNPs in the Type B file
#         awk 'FNR==NR {map[$1]=$2; next} {if(map[$2]) $2=map[$2]} 1' OFS='\t' ${dir}temp_mapping.txt "$fileB" > "${dir}EUR_target_EUR_discovery_chr${chr}_${size}_pheno${pheno}_EUR_pst_eff_a1_b0.5_phiauto_chr${chr}.txt"

#         # Replace the original Type B file with the modified one

#         # Remove the temporary mapping file
#         rm ${dir}temp_mapping.txt
#     else
#         echo "Corresponding Type B file for $fileA does not exist."
#     fi
#     break
# done


#!/bin/bash

process_files() {
    chr=$1
    size=$2
    pheno=$3
    dir="/pollard/home/yorkz/york/BMI206/Simulated_pop/Split/Overfitting_test/Plink/PRScsX/S1/Train/"
    echo ${chr} ${size} ${pheno}
    fileA="/pollard/home/yorkz/york/BMI206/Simulated_pop/Split/Overfitting_test/Plink/GWAS/Formatted/EUR_chr${chr}_${size}.pheno${pheno}.discovery.formatted.assoc.linear"
    fileB="${dir}EUR_target_EUR_discovery_chr${chr}_${size}_pheno${pheno}_EUR_pst_eff_a1_b0.5_phiauto_chr${chr}.txt"

    if [[ -f "$fileB" ]] && [[ -f "$fileA" ]]; then
        awk -F'\t' 'NR>1 {split($1, a, ":"); print a[1]"\t"$1}' "$fileA" > "${dir}temp_mapping_chr${chr}_${size}_pheno${pheno}.txt"

        awk 'FNR==NR {map[$1]=$2; next} {if(map[$2]) $2=map[$2]} 1' OFS='\t' "${dir}temp_mapping_chr${chr}_${size}_pheno${pheno}.txt" "$fileB" > "${dir}EUR_target_EUR_discovery_chr${chr}_${size}_pheno${pheno}_EUR_pst_eff_a1_b0.5_phiauto_chr${chr}_updated.txt"

        rm "${dir}temp_mapping_chr${chr}_${size}_pheno${pheno}.txt"
    else
        echo "One or both files for chr${chr}, size${size}, pheno${pheno} do not exist."
    fi
}

export -f process_files

# Parameters
sizes=(10000 50000 100000 150000 195000)
chromosomes=({1..22})
phenos=({0..19})
dir="/pollard/home/yorkz/york/BMI206/Simulated_pop/Split/Overfitting_test/Plink/PRScsX/S1/Train/"
> "${dir}/commands.txt"
# Generate commands
for size in "${sizes[@]}"; do
    for chr in "${chromosomes[@]}"; do
        for pheno in "${phenos[@]}"; do
# for size in 100000; do
#     for chr in 10; do
#         for pheno in 10; do
            echo "$chr $size $pheno" >> "${dir}/commands.txt"
            # break
        done
        # break
    done
    # break
done

# Run commands in parallel
cat "${dir}/commands.txt" | xargs -n 3 -P 48 bash -c 'process_files "$@"' _

