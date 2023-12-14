#!/bin/bash

data_dir="/pollard/home/yorkz/york/BMI206/Simulated_pop/Split/Overfitting_test/"  # Replace with the actual path to your data files
output_dir="/pollard/home/yorkz/york/BMI206/Simulated_pop/Split/Overfitting_test/Plink/Discovery/"  # Replace with your desired output directory
plink_path="plink"  # Replace with the path to the PLINK executable if it's not in PATH

num_threads=64  # Number of parallel jobs

mkdir -p "$output_dir"
cmd_file="${output_dir}/plink_commands.txt"
> "$cmd_file"  # Create or clear the command file

# for pop in AFR EUR; do
#     for chr in {1..22}; do
#         echo 'zcat '"${data_dir}${pop}_chr${chr}.target.gen.gz"' | awk '"'"'BEGIN {OFS=" "} {sub(/:.*/, "", $2); print}'"'"' | gzip > '"${data_dir}${pop}_chr${chr}.target.formatted.gen.gz" >> "$cmd_file"
#     done
# done

# max_jobs=24  # Set this to the number of parallel jobs you want
# count=0
# while IFS= read -r cmd; do
#     ((count++))
#     bash -c "$cmd" &

#     # Wait for all processes to finish before starting new ones
#     if (( count >= max_jobs )); then
#         wait
#         count=0
#     fi
# done < "$cmd_file"

# # Wait for any remaining background processes
# wait

declare -A superpopulations=(
    # ["EUR"]="5000 10000 45000 50000 95000 100000 145000 150000 190000 195000"
    ["EUR"]="195000"
    # ["AFR"]="5000"
)

for pop in EUR; do
    for size in ${superpopulations[$pop]}; do
        for chr in {1..22}; do
            for i in {0..19}; do
                col="pheno${i}"
                gen_file="${data_dir}/Discovery_sub/${pop}_chr${chr}_${size}.discovery.gen.gz"
                sample_file="${data_dir}/Discovery_sub/${pop}_${size}.discovery.sample"
                output_prefix="${output_dir}/${pop}_chr${chr}_${size}.${col}.discovery"

                if [[ "${size}" == "195000" ]]; then
                    echo "$plink_path --data $data_dir/${pop}_chr${chr}.discovery --gen ${data_dir}/${pop}_chr${chr}.discovery.gen.gz --sample ${data_dir}/${pop}.discovery.sample --oxford-pheno-name ${col} --out $output_prefix --oxford-single-chr $chr" >> "$cmd_file"
                    continue
                fi
                if [[ -f "$gen_file" ]]; then
                    # Write PLINK command to command file
                    echo "$plink_path --data $data_dir/Discovery_sub/${pop}_chr${chr}_${size}.discovery --gen $gen_file --sample ${sample_file} --oxford-pheno-name ${col} --out $output_prefix --oxford-single-chr $chr" >> "$cmd_file"
                else
                    echo "Gen file for $pop chromosome $chr not found." >&2
                fi
                # break
            done
            # break
        done
        # break
    done
    # break
done

# Execute PLINK commands in parallel using xargs
cat "$cmd_file" | xargs -P $num_threads -I {} bash -c '{}'

# Optionally, remove the command file after execution
# rm "$cmd_file"
