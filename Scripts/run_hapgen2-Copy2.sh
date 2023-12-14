#!/bin/bash

# Base directories
hap_base="/pollard/home/yorkz/york/BMI206/1000GP_Phase3/Subset/Intersect_HM/Superpop/"
legend_base="/pollard/home/yorkz/york/BMI206/1000GP_Phase3/Subset/Intersect_HM/"
map_base="/pollard/home/yorkz/york/BMI206/Sub_map/"
output_base="/pollard/home/yorkz/york/BMI206/Simulated_pop/"
working_dir="/pollard/home/yorkz/york/BMI206/Simulated_pop/working"

# Ensure the output directory exists
mkdir -p "$output_base"
mkdir -p "$working_dir"

# Populations array
declare -a populations=("AFR" "EUR" "EAS")

# Number of genotypes for each population
declare -A num_genotypes
num_genotypes["AFR"]=100000
num_genotypes["EUR"]=200000
num_genotypes["EAS"]=100000

run_hapgen2() {
    pop=$1
    chr=$2
    num_gen=$3
    echo ${pop} 
    echo ${chr}
    echo ${num_gen}
    # Define file paths
    hap_gz_file="${hap_base}/${pop}_chr${chr}.hap.gz"
    legend_gz_file="${legend_base}/chr${chr}_hapmap3.legend.gz"
    map_gz_file="${map_base}_$pop/${pop}-${chr}-superpop-final.txt.gz"
    output_file="${output_base}/${pop}_chr${chr}.gz"

    # Temporary files
    hap_file="${working_dir}/${pop}_chr${chr}.hap"
    legend_file="${working_dir}/chr${chr}_hapmap3.legend"
    map_file="${working_dir}/${pop}-${chr}-superpop-final.txt"

    # Decompress files
    zcat "$hap_gz_file" > "$hap_file"
    zcat "$legend_gz_file" > "$legend_file"
    zcat "$map_gz_file" > "$map_file"
    
    dummyDL=`sed -n '4'p ${legend_file} | cut -d ' ' -f2`
    # Run hapgen2 with the appropriate files
    hapgen2 -h "$hap_file" \
            -l "$legend_file" \
            -m "$map_file" \
            -o "$output_file" \
            -dl $dummyDL 0 0 0 \
            -n ${num_gen} 0 \
            -no_haps_output \
    gzip "$output_file.controls.gen"
    
    # Check if hapgen2 was successful
    if [ $? -eq 0 ]; then
        echo "Simulation successful for ${pop} chromosome ${chr}"
    else
        echo "Simulation failed for ${pop} chromosome ${chr}"
    fi
    # Remove temporary files to free up space
    rm "$hap_file" "$legend_file" "$map_file"
    rm "$output_file.cases*"
}

export -f run_hapgen2
export hap_base legend_base map_base output_base working_dir num_genotypes

# Number of parallel threads to use
threads=4

# Generate the list of tasks and pipe into xargs
for pop in EUR; do
    for chr in 16 18 21 22; do
        num_gen=${num_genotypes[$pop]}
        printf "%s %s\n" "$pop" "$chr" "$num_gen"
    done
done | xargs -n 3 -P "$threads" bash -c 'run_hapgen2 "$0" "$1" "$2"' 

# seq 1 22 | xargs -I{} -P $threads bash -c 'process_chromosome "$@"' _ {}

echo "All simulations completed."
