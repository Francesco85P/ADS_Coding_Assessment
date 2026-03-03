# Script: 01_create ae_summary_table.R
# Purpose: Create outputs for adverse events summary using the ADAE dataset and {gtsummary}
# Inputs: adae, adsl datasets
# Output: SummaryTable.html

### Import required libraries
library(dplyr)
library(gt)
library(gtsummary)
library(cards)
library(tfrmt)
theme_gtsummary_compact()

### Import required datasets
adae <- pharmaverseadam::adae
adsl <- pharmaverseadam::adsl

### Filter Treatment-emergent records from ADAE dataset
# As asked in the instructions
adae <- adae |>
  filter(SAFFL == "Y" & TRTEMFL == "Y")

### Filter Safety Population records from ADSL dataset
# Following Pharmaver Example TLG "Adverse Events"
adsl <- adsl |> filter(SAFFL == "Y")

### Create table using gtsummary
# Using Build Table instructions from FDA Table 10 (link provided in instructions).
# Sort by descending frequency is achived by sort_hierarchical("descending")
tbl <- adae |>
  tbl_hierarchical(
    variables = c(AESOC, AETERM),
    by = TRT01A,
    id = USUBJID,
    denominator = adsl,
    overall_row = TRUE,
    label = "..ard_hierarchical_overall.." ~ "Treatment Emergent AEs"
  ) |>
  sort_hierarchical("descending")

### Table is converted to "gt_tbl" object
gt_tbl <- as_gt(tbl)

### Save the final dataset to the output directory
out_dir <- "question_3_tlg/output"
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
gt::gtsave(gt_tbl, file.path(out_dir, "SummaryTable.html"))
