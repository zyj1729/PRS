#!/bin/bash

# Define file paths
genotype_file="/pollard/home/yorkz/york/BMI206/Simulated_pop/Phenotypes/AFR_causal_snp_genotypes.txt"
map_file="/pollard/home/yorkz/york/BMI206/Simulated_pop/Phenotypes/AFR_causal_snp_genotypes_p.map"
ped_file="/pollard/home/yorkz/york/BMI206/Simulated_pop/Phenotypes/AFR_causal_snp_genotypes_p.ped"
temp_dir="/pollard/home/yorkz/york/BMI206/Simulated_pop/Phenotypes/tmp/"


# Create MAP file
awk '{ print $1 " " $2 " 0 " $3 }' "$genotype_file" > "$map_file"

# Number of columns in the genotype file (excluding the first 5 columns)
num_cols=$(awk '{print NF-5; exit}' "$genotype_file")

# Number of parallel jobs and columns per chunk
num_jobs=8 # Adjust based on your CPU
cols_per_chunk=$(( (num_cols + num_jobs - 1) / num_jobs ))

# Function to process a chunk of columns
process_chunk() {
    local start_col=$1
    local end_col=$2
    local chunk_file="${temp_dir}/chunk_${start_col}_to_${end_col}.ped"

    for (( col=start_col; col<=end_col; col++ )); do
        if (( col > num_cols )); then
            break
        fi

        awk -v col="$col" '{
            if (NR == 1) {
                ref = $4
                alt = $5
            }
            g = $(col+5)
            if (g == 0) genotype = ref " " ref
            else if (g == 1) genotype = ref " " alt
            else if (g == 2) genotype = alt " " alt
            printf "%s ", genotype
        }' "$genotype_file" > "${chunk_file}_${col}"
    done

    # Combine the individual column files into one chunk file
    paste -d ' ' "${chunk_file}"_* > "$chunk_file"
    rm "${chunk_file}"_*
}

export -f process_chunk

# Create temporary directory
mkdir -p "$temp_dir"

# Process each chunk of columns in parallel
for (( i=1; i<=num_cols; i+=cols_per_chunk )); do
    end_col=$(( i + cols_per_chunk - 1 ))
    process_chunk "$i" "$end_col" &
done

# Wait for all background jobs to finish
wait

# Combine the chunks into the final PED file
for (( i=1; i<=num_cols; i+=cols_per_chunk )); do
    end_col=$(( i + cols_per_chunk - 1 ))
    chunk_file="${temp_dir}/chunk_${i}_to_${end_col}.ped"
    while read -r line; do
        echo "$(( (i-1)/cols_per_chunk + 1 )) $(( (i-1)/cols_per_chunk + 1 )) 0 0 0 -9 $line"
    done < "$chunk_file" >> "$ped_file"
    rm "$chunk_file"
done

# Clean up temporary directory
rm -rf "$temp_dir"