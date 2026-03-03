## Script: Test_script.py
### Purpose: it runs 3 example queries (plus one query asking for a non esisting value)  and prints the results
### Inputs: Code.py is imported as a module
### Output: This script runs four example queries


### Import required libraries
#The Code.py script is imported as a module
import Code as cda

### Example queries
# The count of unique subjects and the subject matching IDs are printed as requested.
# The filtered datasets (check_dataset) and the json_commands used for filtering can be inspescted for reference

## First example
results_1 = cda.return_filtered_data("Give me the subjects who had Adverse events of Moderate severity")
check_commands_1 = results_1["pandas_commands"]
chek_dataset_1 = results_1["filtered_df"]
results_1["count of unique subject"]
results_1["list_of_matching_ids"]

## Second example
results_2 = cda.return_filtered_data("Give me the subjects who recovered from the adverse event")
check_commands_2 = results_2["pandas_commands"]
chek_dataset_2 = results_2["filtered_df"]
results_2["count of unique subject"]
results_2["list_of_matching_ids"]

## Third example
results_3 = cda.return_filtered_data("Give me the subjects for which the adverse event started before December 2013")
check_commands_3 = results_3["pandas_commands"]
chek_dataset_3 = results_3["filtered_df"]
results_3["count of unique subject"]
results_3["list_of_matching_ids"]

## Fourth example (clarification needed)
cda.return_filtered_data("Give me the subjects who had Adverse events of BOH severity")