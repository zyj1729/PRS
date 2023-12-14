#!/bin/bash

# Define the population prefix (e.g., EUR, EAS, AFR)
pop="EUR"

# Define the input file with the list of causal SNPs
input_file="/pollard/home/yorkz/york/BMI206/causal_snps.txt"

# Define the output file
output_file="/pollard/home/yorkz/york/BMI206/Simulated_pop/Phenotypes/${pop}_causal_snp_genotypes.txt"

# Empty the output file if it already exists
> "$output_file"

# Sort the input file by chromosome and position
sorted_file="/pollard/home/yorkz/york/BMI206/sorted_causal_snps_3.txt"
sort -k1,1V -k2,2n "$input_file" > ${sorted_file}

# Loop through each chromosome
for chr in {1..22}; do
# for chr in 22; do
    # Check if there are any SNPs for this chromosome in the sorted file
    if grep -q "^chr${chr} " ${sorted_file}; then
        echo ${chr}
        # Generate the name of the gen.gz file for the chromosome
        gen_file="/pollard/home/yorkz/york/BMI206/Simulated_pop/${pop}_chr${chr}.controls.gen.gz"
        
        # Extract the positions for the current chromosome
        positions=($(grep "^chr${chr} " ${sorted_file} | cut -d ' ' -f2))
        
        # Create an awk pattern for matching line numbers
        pattern=$(IFS="|"; echo "${positions[*]}")
        
        # Use zcat and awk to extract the genotypes for all SNPs on this chromosome
        zcat "$gen_file" | awk -v chr="$chr" -v pattern="$pattern" '
        BEGIN { split(pattern, pos, "|") }
        {
            for (i in pos) {
                if (NR == pos[i]) {
                    printf "%s %s %d %s %s", chr, $2, $3, $4, $5
                    for (j = 6; j <= NF; j += 3) {
                        if ($j == "1") printf " 0"
                        else if ($(j+1) == "1") printf " 1"
                        else if ($(j+2) == "1") printf " 2"
                    }
                    printf "\n"
                }
            }
        }' >> "$output_file"
    fi
done
echo "Genotypes written to $output_file"
   