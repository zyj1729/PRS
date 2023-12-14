#!/bin/bash

data_dir="/pollard/home/yorkz/york/BMI206/Simulated_pop/Split/Overfitting_test/Plink/Discovery"  # Replace with the actual path to your data files
output_dir="/pollard/home/yorkz/york/BMI206/Simulated_pop/Split/Overfitting_test/Plink/GWAS/"  # Replace with your desired output directory
plink_path="plink"  # Replace with the path to the PLINK executable if it's not in PATH
N_THREADS=4
export MKL_NUM_THREADS=$N_THREADS
export NUMEXPR_NUM_THREADS=$N_THREADS
export OMP_NUM_THREADS=$N_THREADS
num_threads=16  # Number of parallel jobs

mkdir -p "$output_dir"
cmd_file="${output_dir}/plink_commands.txt"
> "$cmd_file"  # Create or clear the command file

# Define the superpopulations with subset sizes
declare -A superpopulations=(
    ["EUR"]="5000 10000 45000 50000 95000 100000 145000 150000 190000 195000"
    ["AFR"]="5000"
)

# for pop in AFR EUR; do
#     for size in ${superpopulations[$pop]}; do
#         for chr in {1..22}; do
#             for i in {0..19}; do
#                 col=pheno${i}
#                 input_file="${data_dir}/${pop}_chr${chr}_${size}.${col}.discovery"
#                 output_prefix="${output_dir}/${pop}_chr${chr}_${size}.${col}.discovery"
        
#                 if [[ -f "$input_file.bed" && -f "$input_file.bim" && -f "$input_file.fam" ]]; then
#                     # Write PLINK command to command file
                    
#                     echo "$plink_path --bfile ${input_file} --linear --allow-no-sex --out ${output_prefix} --threads 1" >> "$cmd_file"
#                 else
#                     echo "Gen file for $pop chromosome $chr not found." >&2
#                 fi
#                 # break
#             done
#             # break
#         done
#         # break
#     done
#     # break
# done

# # Execute PLINK commands in parallel using xargs
# cat "$cmd_file" | xargs -P $num_threads -I {} bash -c '{}'

# # Optionally, remove the command file after execution
# rm "$cmd_file"


mkdir -p "${output_dir}/Formatted/"
max_jobs=640  # Set this to the number of parallel jobs you want
count=0

for pop in EUR AFR; do
    for size in ${superpopulations[$pop]}; do
        for chr in {1..22}; do
            for i in {0..19}; do
                col=pheno${i}
                cmd_file="${output_dir}/cmd_${pop}_${chr}_${size}_${col}.sh"
                echo "Formated ${pop} ${chr} ${size} ${col}"
                echo "
input_file=\"${data_dir}/${pop}_chr${chr}_${size}.${col}.discovery\"
output_prefix=\"${output_dir}/${pop}_chr${chr}_${size}.${col}.discovery\"
# Read .bim file and create a mapping of SNP to its alleles
declare -A snp_alleles
while read -r chromo snp genetic_dist pos a1 a2; do
    snp_alleles[\$snp]=\"\$a1 \$a2\"
done < \"\${input_file}.bim\"

# Process .linear file and add A2
{
    read -r header
    echo -e \"SNP\\tA1\\tA2\\tBETA\\tP\"  # Add A2 column to header

    while read -r chromo snp bp a1 test nmiss beta stat p; do
        ref_alt=\${snp_alleles[\$snp]}
        read -ra alleles <<< \"\$ref_alt\"  # Split ref and alt alleles into an array

        if [[ \${alleles[0]} == \"\$a1\" ]]; then
            a2=\${alleles[1]}
        else
            a2=\${alleles[0]}
        fi

        echo -e \"\$snp\\t\$a1\\t\$a2\\t\$beta\\t\$p\"
    done
} < \"\${output_prefix}.assoc.linear\" > \"${output_dir}/Formatted/${pop}_chr${chr}_${size}.${col}.discovery.formatted.assoc.linear\"" > "$cmd_file"
                chmod +x "$cmd_file"
                ((count++))
                "$cmd_file" &

                # Wait for all processes to finish before starting new ones
                if (( count >= max_jobs )); then
                    wait
                    count=0
                fi

                # break
            done
            # break
        done
        # break
    done
    # break
done

wait  # Wait for any remaining jobs to finish

# Clean up command files
rm ${output_dir}/cmd_*




# # Loop through each population and chromosome
# for pop in AFR EUR; do
#     for size in ${superpopulations[$pop]}; do
#         for chr in {1..22}; do
#             for i in {0..19}; do
#                 col=pheno${i}
#                 file="${output_dir}/Formatted/${pop}_chr${chr}_${size}.${col}.discovery.formatted.assoc.linear"
#                 if [[ -f "$file" ]]; then
#                     awk 'BEGIN {OFS="\t"} NR==1 {print; next} {sub(/:.*/, "", $1); print}' "$file" > "${file}.tmp" && mv "${file}.tmp" "$file"
#                 else
#                     echo "File not found: $file"
#                 fi
#                 # break
#             done
#             # break
#         done
#         # break
#     done
#     # break
# done



# populations=("EAS" "EUR" "AFR")

# # Loop through each population and chromosome
# for pop in "${populations[@]}"; do
#     for chr in {1..22}; do
#         file="/pollard/home/yorkz/york/BMI206/Simulated_pop/Split/Plink/Target/${pop}_chr${chr}.target.bim"
#         if [[ -f "$file" ]]; then
#             awk 'BEGIN {OFS="\t"} {sub(/:.*/, "", $2); print}' "$file" > "/pollard/home/yorkz/york/BMI206/Simulated_pop/Split/Plink/Target/Bims/${pop}_chr${chr}.target.formatted.bim"
#         else
#             echo "File not found: $file"
#         fi
#     done
# done
