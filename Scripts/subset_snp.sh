#!/bin/bash

# Define directory paths
hap_path="/pollard/home/yorkz/york/BMI206/1000GP_Phase3/"
legend_path="/pollard/home/yorkz/york/BMI206/1000GP_Phase3/"
output_path="/pollard/home/yorkz/york/BMI206/1000GP_Phase3/Subset/"

# Number of threads
threads=22

# Create the output directory if it doesn't exist
mkdir -p "$output_path"

# Function to process a single chromosome
process_chromosome() {
    chr=$1
    # Define file names
    hap_file="$hap_path/1000GP_Phase3_chr${chr}.hap.gz"
    legend_file="$legend_path/1000GP_Phase3_chr${chr}.legend.gz"
    output_file="$output_path/1000GP_Phase3_chr${chr}_filtered.hap.gz"
    output_legend_file="$output_path/1000GP_Phase3_chr${chr}_filtered.legend.gz"

    # Create a temporary file for the line numbers
    line_numbers_file=$(mktemp)

    # Extract line numbers for SNPs with MAF > 1% (skipping the header line)
    zcat "$legend_file" | awk 'NR > 1 && ($7 > 0.01 || $8 > 0.01 || $9 > 0.01) {print NR}' > "$line_numbers_file"

    # Subtract 1 from each line number to match the hap file
    awk '{print $1-1}' "$line_numbers_file" > "${line_numbers_file}_adjusted"
    
    # Count the number of selected SNPs and echo the result
    selected_snps=$(wc -l < "$line_numbers_file")
    echo "Number of selected SNPs for chromosome ${chr}: $selected_snps"

    # Now extract these lines from the hap file
    zcat "$hap_file" | awk -v line_file="${line_numbers_file}_adjusted" '
      BEGIN {
        while (getline < line_file) {
          lines[$1]
        }
        close(line_file)
      }
      (FNR in lines)
    ' | gzip > "$output_file"

    # Use the line numbers to filter the legend file
    zcat "$legend_file" | awk -v line_file="$line_numbers_file" '
      BEGIN {
        while (getline < line_file) {
          lines[$1]
        }
        close(line_file)
      }
      NR == 1 || (NR in lines)
    ' | gzip > "$output_legend_file"
    echo "Filtered legend file created for chromosome ${chr}."

    # Clean up the temporary file
    rm "$line_numbers_file" "${line_numbers_file}_adjusted"
}

export -f process_chromosome
export hap_path legend_path output_path

# Use xargs to run the process_chromosome function in parallel
seq 1 22 | xargs -I{} -P $threads bash -c 'process_chromosome "$@"' _ {}

echo "Filtering complete for all superpopulations and chromosomes."
