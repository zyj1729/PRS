# #!/bin/bash

# # Define directory paths
# legend_path="/pollard/home/yorkz/york/BMI206/1000GP_Phase3/Subset/"
# hap_path="/pollard/home/yorkz/york/BMI206/1000GP_Phase3/Subset/"
# output_path="/pollard/home/yorkz/york/BMI206/1000GP_Phase3/Subset/Intersect_HM/"
# bed_file="/pollard/home/yorkz/york/BMI206/HapMap3/hapmap3_r1_b36_fwd_consensus.qc.poly.recode.bed"

# # Ensure the output directory exists
# mkdir -p "$output_path"

# # Extract rsIDs from the bed file
# grep -oP 'rs\d+' "$bed_file" | sort -u > rsids_to_keep.txt

# # Initialize the SNP counter
# total_snps=0

# # Loop over each chromosome
# for chr in {1..22}; do
#     # Define file names
#     legend_file="${legend_path}1000GP_Phase3_chr${chr}_filtered.legend.gz"
#     hap_file="${hap_path}1000GP_Phase3_chr${chr}_filtered.hap.gz"
#     output_legend="${output_path}chr${chr}_hapmap3.legend.gz"
#     output_hap="${output_path}chr${chr}_hapmap3.hap.gz"
    
#     # Filter the legend file for biallelic SNPs and exclude strand ambiguous SNPs
#     zgrep -v "Multiallelic" "$legend_file" | \
#     awk '$5 == "Biallelic_SNP" && !($6 == "A" && $7 == "T" || $6 == "T" && $7 == "A" || $6 == "C" && $7 == "G" || $6 == "G" && $7 == "C") {print $1}' | \
#     grep -oP 'rs\d+' | \
#     sort -u | \
#     comm -12 - rsids_to_keep.txt > tmp.txt

#     sed 's/$/:/' tmp.txt > intersected_rsIDs.txt

#     # Use zgrep with fixed strings and patterns from file B to filter rows from file A
#     # Append the filtered rows to file C
#     zcat "$legend_file" | head -n 1 | gzip > "$output_legend"
#     zgrep -F -f intersected_rsIDs.txt <(zcat "$legend_file" | tail -n +2) | gzip >> "$output_legend"

#     # Count the number of SNPs in the filtered legend file (excluding the header line)
#     num_snps=$(zcat "$output_legend" | tail -n +2 | wc -l)
#     total_snps=$((total_snps + num_snps))

#     # Get the line numbers for the intersected rsIDs to filter the hap file
#     zgrep -nFf intersected_rsIDs.txt "$legend_file" | cut -d':' -f1 > line_numbers.txt

#     # Filter the hap file based on the line numbers from the filtered legend
#     zcat "$hap_file" | awk 'NR == FNR {lines[$1]; next} FNR in lines' line_numbers.txt - | gzip > "$output_hap"
    
#     echo "Subset files created for chromosome ${chr}, containing ${num_snps} SNPs."
#     # break
# done

# # Clean up
# rm rsids_to_keep.txt line_numbers.txt intersected_rsIDs.txt tmp.txt
# # rm line_numbers.txt
# echo "All subset files created."
# echo "Total number of SNPs across all chromosomes: $total_snps"

#!/bin/bash

# Define directory paths
legend_path="/pollard/home/yorkz/york/BMI206/1000GP_Phase3/Subset/"
hap_path="/pollard/home/yorkz/york/BMI206/1000GP_Phase3/Subset/"
output_path="/pollard/home/yorkz/york/BMI206/1000GP_Phase3/Subset/Intersect_HM/"
bed_file="/pollard/home/yorkz/york/BMI206/HapMap3/hapmap3_r1_b36_fwd_consensus.qc.poly.recode.bed"

# Ensure the output directory exists
mkdir -p "$output_path"

# Extract rsIDs from the bed file
grep -oP 'rs\d+' "$bed_file" | sort -u > rsids_to_keep.txt

# Function to process each chromosome
process_chromosome() {
    chr=$1
    # Define file names
    legend_file="${legend_path}1000GP_Phase3_chr${chr}_filtered.legend.gz"
    hap_file="${hap_path}1000GP_Phase3_chr${chr}_filtered.hap.gz"
    output_legend="${output_path}chr${chr}_hapmap3.legend.gz"
    output_hap="${output_path}chr${chr}_hapmap3.hap.gz"
    
    # Filter the legend file for biallelic SNPs and exclude strand ambiguous SNPs
    zgrep -v "Multiallelic" "$legend_file" | \
    awk '$5 == "Biallelic_SNP" && !($6 == "A" && $7 == "T" || $6 == "T" && $7 == "A" || $6 == "C" && $7 == "G" || $6 == "G" && $7 == "C") {print $1}' | \
    grep -oP 'rs\d+' | \
    sort -u | \
    comm -12 - rsids_to_keep.txt > tmp_${chr}.txt

    sed 's/$/:/' tmp_${chr}.txt > intersected_rsIDs_${chr}.txt

    # Use zgrep with fixed strings and patterns to filter rows from the legend file
    zcat "$legend_file" | head -n 1 | gzip > "$output_legend"
    zgrep -F -f intersected_rsIDs_${chr}.txt <(zcat "$legend_file" | tail -n +2) | gzip >> "$output_legend"

    # Count the number of SNPs in the filtered legend file (excluding the header line)
    num_snps=$(zcat "$output_legend" | tail -n +2 | wc -l)

    # Get the line numbers for the intersected rsIDs to filter the hap file
    zgrep -nFf intersected_rsIDs_${chr}.txt "$legend_file" | cut -d':' -f1 | awk '{print $1-1}' > line_numbers_${chr}.txt

    # Filter the hap file based on the line numbers from the filtered legend
    zcat "$hap_file" | awk 'NR == FNR {lines[$1]; next} FNR in lines' line_numbers_${chr}.txt - | gzip > "$output_hap"
    
    echo "Subset files created for chromosome ${chr}, containing ${num_snps} SNPs."
}

export -f process_chromosome
export legend_path hap_path output_path bed_file

# Create an input argument list of chromosome numbers
seq 1 22 | xargs -I {} -P 22 bash -c 'process_chromosome "$@"' _ {}


# Count total SNPs across all chromosomes (assumes no duplicate SNPs across chromosomes)
total_snps=$(zcat "${output_path}"*.legend.gz | tail -n +2 | wc -l)

# Clean up
rm rsids_to_keep.txt
rm tmp_*.txt intersected_rsIDs_*.txt line_numbers_*.txt

echo "All subset files created."
echo "Total number of SNPs across all chromosomes: $total_snps"
