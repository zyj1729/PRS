#!/bin/bash
input_dir="/pollard/home/yorkz/york/BMI206/Simulated_pop/"
output_dir="/pollard/home/yorkz/york/BMI206/Simulated_pop/Split/"

for pop in EAS AFR EUR; do
    for chr in 22; do
        sample_file="${input_dir}/${pop}_chr${chr}.controls.sample"
        gen_file="${input_dir}/${pop}_chr${chr}.controls.gen.gz"

        # Check if files exist
        if [[ -f "$sample_file" && -f "$gen_file" ]]; then
            # Randomly select 20000 individuals for the target dataset
            awk 'NR>2 {print $1, $2}' "$sample_file" | shuf | head -n 20000 > ${output_dir}/target_ids.txt
            awk 'NR>2' "$sample_file" | grep -v -F -f ${output_dir}/target_ids.txt > ${output_dir}/discovery_ids.txt

            # Create .sample files for target and discovery datasets
            awk 'NR==1 || NR==2' "$sample_file" > "${output_dir}/${pop}_chr${chr}.target.sample"
            # awk 'NR==1 || NR==2' "$sample_file" > "${output_dir}/${pop}_chr${chr}.discovery.sample"
            # Add the selected individuals along with all columns to the target sample file
            awk 'NR==FNR {a[$1$2]; next} ($1$2 in a)' ${output_dir}/target_ids.txt "$sample_file" >> "${output_dir}/${pop}_chr${chr}.target.sample"

            # Add the remaining individuals to the discovery sample file
            awk 'NR==FNR {a[$1$2]; next} !($1$2 in a)' ${output_dir}/target_ids.txt "$sample_file" >> "${output_dir}/${pop}_chr${chr}.discovery.sample"

            # Split the .gen.gz files
            zcat "$gen_file" | awk -v ids="${output_dir}/target_ids.txt" '
                BEGIN { while ((getline < ids) > 0) id[$1]++ }
                { printf $1; for (i = 2; i <= NF; i++) if ((i-1) in id) printf " "$i; print "" }
            ' | gzip > "${output_dir}/${pop}_chr${chr}.target.gen.gz"

            zcat "$gen_file" | awk -v ids="${output_dir}/discovery_ids.txt" '
                BEGIN { while ((getline < ids) > 0) id[$1]++ }
                { printf $1; for (i = 2; i <= NF; i++) if ((i-1) in id) printf " "$i; print "" }
            ' | gzip > "${output_dir}/${pop}_chr${chr}.discovery.gen.gz"
        else
            echo "Files for $pop chromosome $chr not found."
        fi
        break
    done
    break
done

# Clean up
# rm target_ids.txt discovery_ids.txt
