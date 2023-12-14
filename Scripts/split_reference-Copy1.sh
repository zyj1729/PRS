#!/bin/bash

# Define the superpopulations
declare -A superpopulations=(
  ["EUR"]="CEU IBS FIN GBR TSI"
  ["EAS"]="CDX CHB CHS JPT KHV"
  ["AFR"]="ACB ASW ESN GWD LWK MSL YRI"
)

sample_file="/pollard/home/yorkz/york/BMI206/1000GP_Phase3/1000GP_Phase3.sample"

# Function to process a single chromosome
process_chromosome() {
    local chr="$1"
    local hap_file="/pollard/home/yorkz/york/BMI206/1000GP_Phase3/Subset/Intersect_HM/chr${chr}_hapmap3.hap.gz"

    # Process the sample file to get indices for each superpopulation
    for superpop in "${!superpopulations[@]}"; do
        indices=$(awk -v pops="${superpopulations[$superpop]}" 'BEGIN { split(pops, arr, " "); for (i in arr) pop[arr[i]] = 1; }
                    NR > 1 && $2 in pop { print 2*(NR-1)-1; print 2*(NR-1); }' "$sample_file" | tr '\n' ',' | sed 's/,$//')

        # Use these indices to filter the .hap.gz file using cut
        zcat "$hap_file" | cut -d' ' -f${indices} | gzip > "/pollard/home/yorkz/york/BMI206/1000GP_Phase3/Subset/Intersect_HM/Superpop/${superpop}_chr${chr}.hap.gz"
    done
}
# process_chromosome() {
#     local chr="$1"
#     local hap_file="/pollard/home/yorkz/york/BMI206/1000GP_Phase3/1000GP_Phase3_chr${chr}.hap.gz"

#     # Process the sample file to get indices for each superpopulation
#     for superpop in "${!superpopulations[@]}"; do
#         indices=$(awk -v pops="${superpopulations[$superpop]}" 'BEGIN { split(pops, arr, " "); for (i in arr) pop[arr[i]] = 1; }
#                     NR > 1 && $2 in pop { print NR-1 }' "$sample_file" | tr '\n' ',' | sed 's/,$//')

#         # Use these indices to filter the .hap.gz file using cut
#         zcat "$hap_file" | cut -d' ' -f${indices} | gzip > "/pollard/home/yorkz/york/BMI206/1000GP_Phase3/Superpop/${superpop}_chr${chr}.hap.gz"
#     done
# }

# Max number of concurrent jobs
MAX_JOBS=16

# Launch jobs up to MAX_JOBS concurrently
for chr in {1..22}; do
    # chr4 already processed
    # if [ "$chr" -eq 4 ]; then
    #     continue
    # fi
    # Run process in the background
    process_chromosome "$chr" &

    # If the number of jobs reaches MAX_JOBS, wait for one to finish before continuing
    while true; do
        job_count=$(jobs -p | wc -l)
        if [ "$job_count" -lt "$MAX_JOBS" ]; then
            break
        fi
        sleep 1
    done
done

# Wait for any remaining background jobs to complete
wait
