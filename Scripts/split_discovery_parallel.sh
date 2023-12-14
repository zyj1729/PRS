# #!/bin/bash

# input_dir="/pollard/home/yorkz/york/BMI206/Simulated_pop/Split/Overfitting_test/"
# output_dir="/pollard/home/yorkz/york/BMI206/Simulated_pop/Split/Overfitting_test/Discovery_sub/"
# num_threads=32  # Number of parallel jobs
# cmd_file="${output_dir}/split_commands.txt"
# rm ${cmd_file}

# mkdir -p "$output_dir"

# split_gen_file() {
#     local pop=$1
#     local chr=$2
#     local num=$3
#     input_dir="/pollard/home/yorkz/york/BMI206/Simulated_pop/Split/"
#     output_dir="/pollard/home/yorkz/york/BMI206/Simulated_pop/Split/Overfitting_test/Discovery_sub/"
#     local gen_file="${input_dir}/${pop}_chr${chr}.discovery.gen.gz"
#     local discovery_line_numbers_file="${output_dir}/${pop}_${num}.discovery.line_numbers.txt"

#     # Split the .gen.gz file for the target dataset
#     zcat "$gen_file" | awk -v idxfile="$discovery_line_numbers_file" '
#         BEGIN { while ((getline < idxfile) > 0) target_idx[$1] = 1; }
#         { 
#             printf $1 " " $2 " " $3 " " $4 " " $5; 
#             for (i = 6; i <= NF; i += 3) {
#                 if ((int((i - 5) / 3) + 3) in target_idx) {
#                     printf " " $i " " $(i+1) " " $(i+2);
#                 }
#             }
#             print ""; 
#         }
#     ' | gzip > "${output_dir}/${pop}_chr${chr}.discovery.gen.gz"
# }



# export -f split_gen_file
# # Store all the commands to be executed in an array
# declare -a commands
# # Define the superpopulations
# declare -A superpopulations=(
#   ["EUR"]=100000
#   ["AFR"]=5000
# )

# for pop in AFR EUR; do
#     discovery_line_numbers_file="${output_dir}/${pop}_${superpopulations[$pop]}.discovery.line_numbers.txt"
#     # change this
#     sample_file="${input_dir}/${pop}.discovery.sample"
#     awk 'NR>2 {print NR}' "$sample_file" | shuf | head -n ${superpopulations[$pop]} | sort -n > "${discovery_line_numbers_file}"
#     awk 'NR==1 || NR==2' "$sample_file" > "${output_dir}/${pop}_${superpopulations[$pop]}.discovery.sample"
#     awk 'NR==FNR {lines[$1]=1; next} FNR in lines' "${discovery_line_numbers_file}" "$sample_file" >> "${output_dir}/${pop}_${superpopulations[$pop]}.discovery.sample"
#     for chr in {1..22} ; do
#         echo "${pop} ${chr} ${superpopulations[$pop]}"
        
#         gen_file="${input_dir}/${pop}_chr${chr}.discovery.gen.gz"

#         if [[ -f "$sample_file" && -f "$gen_file" ]]; then
#             (
#                 echo "$pop $chr ${superpopulations[$pop]}" >> "$cmd_file"
#             ) &
#         else
#             echo "Files for $pop chromosome $chr not found." >&2
#         fi
#     done
# done
# wait
# cat "$cmd_file" | xargs -n 3 -P $num_threads bash -c 'split_gen_file "$@"' _
# # Clean up intermediate files
# rm "${output_dir}/target_ids*" "${output_dir}/discovery_ids*"

#!/bin/bash

input_dir="/pollard/home/yorkz/york/BMI206/Simulated_pop/Split/Overfitting_test/"
output_dir="/pollard/home/yorkz/york/BMI206/Simulated_pop/Split/Overfitting_test/Discovery_sub/"
num_threads=48  # Number of parallel jobs
cmd_file="${output_dir}/split_commands.txt"
rm ${cmd_file}

mkdir -p "$output_dir"

split_gen_file() {
    local pop=$1
    local chr=$2
    local num=$3
    local input_dir="/pollard/home/yorkz/york/BMI206/Simulated_pop/Split/Overfitting_test/"
    local output_dir="/pollard/home/yorkz/york/BMI206/Simulated_pop/Split/Overfitting_test/Discovery_sub/"
    local gen_file="${input_dir}/${pop}_chr${chr}.discovery.gen.gz"
    local discovery_line_numbers_file="${output_dir}/${pop}_${num}.discovery.line_numbers.txt"

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
    ' | gzip > "${output_dir}/${pop}_chr${chr}_${num}.discovery.gen.gz"
}

export -f split_gen_file

# Define the superpopulations with subset sizes
declare -A superpopulations=(
    ["EUR"]="5000 10000 45000 50000 95000 100000 145000 150000 190000"
    ["AFR"]="5000"
)

# Generate all line number files sequentially
# for pop in "${!superpopulations[@]}"; do
#     prev_size=0
#     for size in ${superpopulations[$pop]}; do
#         discovery_line_numbers_file="${output_dir}/${pop}_${size}.discovery.line_numbers.txt"
#         sample_file="${input_dir}/${pop}.discovery.sample"

#         if [[ $size -gt $prev_size && $prev_size -ne 0 ]]; then
#             prev_file="${output_dir}/${pop}_${prev_size}.discovery.line_numbers.txt"
#             # First, include all entries from the previous file
#             cat ${prev_file} > "${discovery_line_numbers_file}"
#             # Then, add unique entries until the size is reached
#             awk 'NR>2 {print NR}' "$sample_file" | grep -vxFf ${prev_file} | \
#                 shuf | head -n $((size-prev_size)) >> "${discovery_line_numbers_file}"
#             sort -n "${discovery_line_numbers_file}" -o "${discovery_line_numbers_file}"
#         else
#             awk 'NR>2 {print NR}' "$sample_file" | shuf | head -n $size | sort -n > "${discovery_line_numbers_file}"
#         fi

#         prev_size=$size
#     done
# done

# Prepare and run the split_gen_file function in parallel
for pop in "${!superpopulations[@]}"; do
    for size in ${superpopulations[$pop]}; do
        for chr in {1..22}; do
            echo "${pop} ${chr} ${size}"
            gen_file="${input_dir}/${pop}_chr${chr}.discovery.gen.gz"
            sample_file="${input_dir}/${pop}.discovery.sample"

            if [[ -f "$sample_file" && -f "$gen_file" ]]; then
                (
                    echo "$pop $chr $size" >> "$cmd_file"
                ) &
            else
                echo "Files for $pop chromosome $chr not found." >&2
            fi
        done
        # break
    done
    # break
done
wait

cat "$cmd_file" | xargs -n 3 -P $num_threads bash -c 'split_gen_file "$@"' _

# Clean up intermediate files
rm "${output_dir}/target_ids*" "${output_dir}/discovery_ids*"


