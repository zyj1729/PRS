#!/bin/bash

# Define file paths
genotype_file="/pollard/home/yorkz/york/BMI206/Simulated_pop/Phenotypes/EAS_causal_snp_genotypes.txt"
map_file="/pollard/home/yorkz/york/BMI206/Simulated_pop/Phenotypes/EAS_causal_snp_genotypes.map"
ped_file="/pollard/home/yorkz/york/BMI206/Simulated_pop/Phenotypes/EAS_causal_snp_genotypes.ped"

# Create MAP file
awk '{ print $1 " " $2 " 0 " $3 }' "$genotype_file" > "$map_file"

# Initialize an array to hold genotype data for each individual
declare -a genotype_data

# Process genotypes and transpose
awk '{
    for (i = 6; i <= NF; i++) {
        ref = $4
        alt = $5
        g = $i
        if (g == 0) genotype = ref " " ref
        else if (g == 1) genotype = ref " " alt
        else if (g == 2) genotype = alt " " alt

        if (NR == 1) genotype_data[i] = i-5 " " i-5 " 0 0 0 -9 " genotype
        else genotype_data[i] = genotype_data[i] " " genotype
    }
} END {
    for (i = 6; i <= NF; i++) {
        print genotype_data[i]
    }
}' "$genotype_file" > "$ped_file"