# #!/bin/bash

# input_dir="/pollard/home/yorkz/york/BMI206/Simulated_pop/"
# output_dir="/pollard/home/yorkz/york/BMI206/Simulated_pop/Split"
# num_threads=32  # Number of parallel jobs
# cmd_file="${output_dir}/split_commands.txt"

# mkdir -p "$output_dir"

# split_gen_file() {
#     local pop=$1
#     local chr=$2
#     input_dir="/pollard/home/yorkz/york/BMI206/Simulated_pop/"
#     output_dir="/pollard/home/yorkz/york/BMI206/Simulated_pop/Split"
#     local gen_file="${input_dir}/${pop}_chr${chr}.controls.gen.gz"
#     local target_sample_file="${output_dir}/${pop}_chr${chr}.target.sample"
#     local discovery_sample_file="${output_dir}/${pop}_chr${chr}.discovery.sample"

#     # Write the line numbers of target individuals to a temp file
#     awk 'NR>2 {print NR-2}' "$target_sample_file" > "${output_dir}/target_indices_${pop}_${chr}.txt"

#     # Split the .gen.gz file for the target dataset
#     zcat "$gen_file" | awk -v idxfile="${output_dir}/target_indices_${pop}_${chr}.txt" '
#         BEGIN { while ((getline < idxfile) > 0) target_idx[$1] = 1; }
#         { 
#             printf $1 " " $2 " " $3 " " $4 " " $5; 
#             for (i = 6; i <= NF; i += 3) {
#                 if ((int((i - 5) / 3) + 1) in target_idx) {
#                     printf " " $i " " $(i+1) " " $(i+2);
#                 }
#             }
#             print ""; 
#         }
#     ' | gzip > "${output_dir}/${pop}_chr${chr}.target.gen.gz"

#     # Split the .gen.gz file for the discovery dataset
#     zcat "$gen_file" | awk -v idxfile="${output_dir}/target_indices_${pop}_${chr}.txt" '
#         BEGIN { while ((getline < idxfile) > 0) target_idx[$1] = 1; }
#         { 
#             printf $1 " " $2 " " $3 " " $4 " " $5; 
#             for (i = 6; i <= NF; i += 3) {
#                 if (!((int((i - 5) / 3) + 1) in target_idx)) {
#                     printf " " $i " " $(i+1) " " $(i+2);
#                 }
#             }
#             print ""; 
#         }
#     ' | gzip > "${output_dir}/${pop}_chr${chr}.discovery.gen.gz"

#     # Clean up temporary index file
#     rm "${output_dir}/target_indices_${pop}_${chr}.txt"
# }



# export -f split_gen_file
# # Store all the commands to be executed in an array
# declare -a commands

# for pop in EAS AFR EUR; do
#     for chr in {1..22} ; do
#         echo "${pop} ${chr}"
#         sample_file="${input_dir}/${pop}_chr${chr}.controls.sample"
#         gen_file="${input_dir}/${pop}_chr${chr}.controls.gen.gz"

#         if [[ -f "$sample_file" && -f "$gen_file" ]]; then
#             (
#                 # Randomly select 20000 individuals for the target dataset
#                 awk 'NR>2 {print $0}' "$sample_file" | shuf | head -n 20000 > "${output_dir}/target_ids_${pop}_${chr}.txt"
#                 awk 'NR>2' "$sample_file" | grep -v -F -f "${output_dir}/target_ids_${pop}_${chr}.txt" > "${output_dir}/discovery_ids_${pop}_${chr}.txt"
    
#                 # Create .sample files for target and discovery datasets
#                 awk 'NR==1 || NR==2' "$sample_file" > "${output_dir}/${pop}_chr${chr}.target.sample"
#                 # awk 'NR==1 || NR==2' "$sample_file" > "${output_dir}/${pop}_chr${chr}.discovery.sample"
#                 awk 'NR==FNR {a[$1$2]; next} ($1$2 in a)' "${output_dir}/target_ids_${pop}_${chr}.txt" "$sample_file" >> "${output_dir}/${pop}_chr${chr}.target.sample"
#                 awk 'NR==FNR {a[$1$2]; next} !($1$2 in a)' "${output_dir}/target_ids_${pop}_${chr}.txt" "$sample_file" >> "${output_dir}/${pop}_chr${chr}.discovery.sample"
    
#                 # Queue the splitting job for parallel execution
#                 # echo "$pop $chr" | xargs -n 2 -P $num_threads bash -c 'split_gen_file "$@"' _
#                 echo "$pop $chr" >> "$cmd_file"
#                 # echo "$pop $chr"
#             ) &
#         else
#             echo "Files for $pop chromosome $chr not found." >&2
#         fi
#         # break
#         # rm "${output_dir}/target_ids_${pop}_${chr}.txt" "${output_dir}/discovery_ids_${pop}_${chr}.txt"
#     done
#     # break
# done
# wait
# cat "$cmd_file" | xargs -n 2 -P $num_threads bash -c 'split_gen_file "$@"' _
# # Clean up intermediate files
# # rm "${output_dir}/target_ids.txt" "${output_dir}/discovery_ids.txt"






#!/bin/bash

input_dir="/pollard/home/yorkz/york/BMI206/Simulated_pop/"
output_dir="/pollard/home/yorkz/york/BMI206/Simulated_pop/Split/Overfitting_test/"
num_threads=32  # Number of parallel jobs
cmd_file="${output_dir}/split_commands.txt"
rm ${cmd_file}

mkdir -p "$output_dir"

split_gen_file() {
    local pop=$1
    local chr=$2
    input_dir="/pollard/home/yorkz/york/BMI206/Simulated_pop/"
    output_dir="/pollard/home/yorkz/york/BMI206/Simulated_pop/Split/Overfitting_test/"
    local gen_file="${input_dir}/${pop}_chr${chr}.controls.gen.gz"
    # local target_sample_file="${output_dir}/${pop}_chr${chr}.target.sample"
    # local target_sample_file="${output_dir}/${pop}_chr${chr}.target.sample"
    # local discovery_sample_file="${output_dir}/${pop}_${num}.discovery.sample"
    local discovery_line_numbers_file="${output_dir}/${pop}.discovery.line_numbers.txt"
    local target_line_numbers_file="${output_dir}/${pop}.target.line_numbers.txt"

    # Write the line numbers of target individuals to a temp file
    # awk 'NR>2 {print NR-2}' "$discovery_sample_file" > "${output_dir}/discovery_indices_${pop}_${chr}.txt"

    # Split the .gen.gz file for the target dataset
    zcat "$gen_file" | awk -v idxfile="$discovery_line_numbers_file" '
        BEGIN { while ((getline < idxfile) > 0) target_idx[$1] = 1; }
        { 
            printf $1 " " $2 " " $3 " " $4 " " $5; 
            for (i = 6; i <= NF; i += 3) {
                if ((int((i - 5) / 3) + 3) in target_idx) {
                    printf " " $i " " $(i+1) " " $(i+2);
                }
            }
            print ""; 
        }
    ' | gzip > "${output_dir}/${pop}_chr${chr}.discovery.gen.gz"

    # # Split the .gen.gz file for the discovery dataset
    zcat "$gen_file" | awk -v idxfile="$target_line_numbers_file" '
        BEGIN { while ((getline < idxfile) > 0) target_idx[$1] = 1; }
        { 
            printf $1 " " $2 " " $3 " " $4 " " $5; 
            for (i = 6; i <= NF; i += 3) {
                if ((int((i - 5) / 3) + 3) in target_idx) {
                    printf " " $i " " $(i+1) " " $(i+2);
                }
            }
            print ""; 
        }
    ' | gzip > "${output_dir}/${pop}_chr${chr}.target.gen.gz"

    # Clean up temporary index file
    # rm "${output_dir}/discovery_indices_${pop}_${chr}.txt"
}



export -f split_gen_file
# Store all the commands to be executed in an array
declare -a commands
# Define the superpopulations
declare -A superpopulations=(
  ["EUR"]=5000
  # ["EAS"]=20000
  ["AFR"]=5000
)

for pop in AFR EUR; do
    discovery_line_numbers_file="${output_dir}/${pop}.discovery.line_numbers.txt"
    target_line_numbers_file="${output_dir}/${pop}.target.line_numbers.txt"
    # change this
    sample_file="${input_dir}/${pop}_chr1.controls.sample"
    awk 'NR>2 {print NR}' "$sample_file" | shuf | head -n ${superpopulations[$pop]} | sort -n > "${target_line_numbers_file}"
    awk 'NR==1 || NR==2' "$sample_file" > "${output_dir}/${pop}.target.sample"
    awk 'NR==FNR {lines[$1]=1; next} FNR in lines' "${target_line_numbers_file}" "$sample_file" >> "${output_dir}/${pop}.target.sample"
    # Generate line numbers for discovery samples
    awk 'NR==FNR { target[$1]=1; next } NR>2 && !($1 in target)' "$target_line_numbers_file" <(awk 'NR>2 {print NR}' "$sample_file") > "$discovery_line_numbers_file"
    # awk 'NR>2 {print NR}' "$sample_file" | grep -vFf "$target_line_numbers_file" | sort -n > "$discovery_line_numbers_file"
    # Create the discovery sample file
    awk 'NR==1 || NR==2' "$sample_file" > "${output_dir}/${pop}.discovery.sample"
    awk 'NR==FNR {lines[$1]=1; next} FNR in lines' "$discovery_line_numbers_file" "$sample_file" >> "${output_dir}/${pop}.discovery.sample"
    for chr in {1..22} ; do
        echo "${pop} ${chr}"
        
        gen_file="${input_dir}/${pop}_chr${chr}.controls.gen.gz"

        if [[ -f "$sample_file" && -f "$gen_file" ]]; then
            (
                echo "$pop $chr" >> "$cmd_file"
                # echo "$pop $chr"
            ) &
        else
            echo "Files for $pop chromosome $chr not found." >&2
        fi
        # break
        # rm "${output_dir}/target_ids_${pop}_${chr}.txt" "${output_dir}/discovery_ids_${pop}_${chr}.txt"
    done
    # break
done
wait
cat "$cmd_file" | xargs -n 2 -P $num_threads bash -c 'split_gen_file "$@"' _
# Clean up intermediate files
# rm "${output_dir}/target_ids*" "${output_dir}/discovery_ids*"

