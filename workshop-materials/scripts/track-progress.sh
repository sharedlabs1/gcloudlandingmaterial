#!/bin/bash

# Workshop Progress Tracker
WORKSHOP_DIR="~/gcp-landing-zone-workshop"

echo "=== GCP Landing Zone Workshop Progress ==="
echo "Checked at: $(date)"
echo

total_labs=14
completed_labs=0

for lab_num in $(seq -f "%02g" 1 14); do
    lab_dir="$WORKSHOP_DIR/lab-$lab_num"
    validation_file="$lab_dir/outputs/lab-$lab_num-validation.json"
    
    if [ -f "$validation_file" ]; then
        status=$(jq -r '.status' "$validation_file" 2>/dev/null)
        if [ "$status" = "PASSED" ]; then
            echo "✓ Lab $lab_num: COMPLETED"
            ((completed_labs++))
        else
            echo "⚠ Lab $lab_num: FAILED VALIDATION"
        fi
    elif [ -d "$lab_dir" ]; then
        echo "🔄 Lab $lab_num: IN PROGRESS"
    else
        echo "⭕ Lab $lab_num: NOT STARTED"
    fi
done

echo
echo "Progress: $completed_labs/$total_labs labs completed ($(( completed_labs * 100 / total_labs ))%)"

if [ $completed_labs -eq $total_labs ]; then
    echo "🎉 Congratulations! All labs completed successfully!"
else
    next_lab=$(printf "%02d" $((completed_labs + 1)))
    echo "📋 Next: Lab $next_lab"
fi
