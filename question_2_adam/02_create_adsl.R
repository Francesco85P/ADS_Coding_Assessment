### Script: 02_create adsl.R
### Purpose: Create an ADSL (Subject Level) dataset using SDTM source data, the {admiral} family of packages, and tidyverse tools.
### Inputs: sdtm data, safety_specs.xlsx
### Output: ADSL.csv

### Import required packages
library(admiral)
library(metacore)
library(metatools)
library(pharmaversesdtm)
library(admiral)
library(xportr)
library(dplyr)
library(tidyr)
library(lubridate)
library(stringr)

### Read in input SDTM data
dm <- pharmaversesdtm::dm
vs <- pharmaversesdtm::vs
ex <- pharmaversesdtm::ex
ds <- pharmaversesdtm::ds
ae <- pharmaversesdtm::ae
suppdm <- pharmaversesdtm::suppdm

### Convert missing values to NA
# This is done following the ADSL Pharmaverse Example, as NA values
# in the original SAS datasets appear as "" after conversion to R
dm <- convert_blanks_to_na(dm)
ds <- convert_blanks_to_na(ds)
ex <- convert_blanks_to_na(ex)
ae <- convert_blanks_to_na(ae)
vs <- convert_blanks_to_na(vs)
suppdm <- convert_blanks_to_na(suppdm)

### Combain dm domain and suppdm domain
# The metatools::combine_supp() is used as in the the ADSL Pharmaverse Example
dm_suppdm <- combine_supp(dm, suppdm)

###  Load the specification file in the form of a {metacore} object
# This is done to create the metacore object to combine the
# variables coming from the different SDTM domains and the derived ones.
# The file "safety_specs.xlsx" in the input folders contains the variables metadata
# and was downloaded from: https://github.com/pharmaverse/examples/blob/main/metadata
metacore <- spec_to_metacore(
  path = "question_2_adam/input/safety_specs.xlsx",
  where_sep_sheet = FALSE
) %>%
  select_dataset("ADSL")

### Start Building Derivations
# Following the ADSL Pharmaverse Example, the columns from DM and SUPPDM
# are combined and renamed according to the ADSL standards
adsl_preds <- build_from_derived(
  metacore,
  ds_list = list("dm" = dm_suppdm, "suppdm" = dm_suppdm),
  predecessor_only = FALSE,
  keep = FALSE
)

### Derive AGEGR9 and AGEGR9N
# Following the ADSL Pharmaverse Example, a look-up table is used to derive AGEGR9 and AGEGR9N from AGE.
# The categories are created following the indications provided.
# If AGE is missing AGEGR1 is mapped to "Missing" and AGEGR1N to 4
agegr1_lookup <- exprs(
  ~condition,
  ~AGEGR1,
  ~AGEGR1N,
  is.na(AGE),
  "Missing",
  4,
  AGE < 18,
  "<18",
  1,
  between(AGE, 18, 50),
  "18-50",
  2,
  !is.na(AGE),
  ">50",
  3
)

adsl_ct <- derive_vars_cat(
  dataset = adsl_preds,
  definition = agegr1_lookup
)

### Derive TRTSDTM (Datetime of First Exposure to Treatment) /TRTSTMF  (Time of First Exposure Imput Flag)
### and TRTEDTM (Date of Last Exposure to Treatment) /TRTEDTMF (Time of First Exposure Imput. Flag)
# Variables are derived similarly to the ADSL Pharmaverse Example.
# Following the indications, missing times are reported as 00:00:00 (time_imputation = "first").
# The default value ignore_seconds_flag = TRUE makes sure that the imputation flag is not populated
# when only seconds are imputed.The filtering(filter_add) makes sure that derivations
# only include patients that recieved a dose. TRTEDTM/TRTEDTMF are derived because
# they are required to derive LSTALVDT (see below)
ex_ext <- ex %>%
  derive_vars_dtm(
    dtc = EXSTDTC,
    new_vars_prefix = "EXST",
    time_imputation = "first",
  ) %>%
  derive_vars_dtm(
    dtc = EXENDTC,
    new_vars_prefix = "EXEN",
    time_imputation = "first",
    ignore_seconds_flag = FALSE
  )


adsl <- adsl_ct %>%
  # Treatment Start Datetime
  derive_vars_merged(
    dataset_add = ex_ext,
    filter_add = (EXDOSE > 0 |
      (EXDOSE == 0 &
        str_detect(EXTRT, "PLACEBO"))) &
      !is.na(EXSTDTM),
    new_vars = exprs(TRTSDTM = EXSTDTM, TRTSTMF = EXSTTMF),
    order = exprs(EXSTDTM, EXSEQ),
    mode = "first",
    by_vars = exprs(STUDYID, USUBJID)
  ) %>%
  # Treatment End Datetime
  derive_vars_merged(
    dataset_add = ex_ext,
    filter_add = (EXDOSE > 0 |
      (EXDOSE == 0 &
        str_detect(EXTRT, "PLACEBO"))) &
      !is.na(EXENDTM),
    new_vars = exprs(TRTEDTM = EXENDTM, TRTETMF = EXENTMF),
    order = exprs(EXENDTM, EXSEQ),
    mode = "first",
    by_vars = exprs(STUDYID, USUBJID)
  )

#### Derive ITTFL (Intent-To-Treat Population Flag)
# ITTFL is modified according to the instructions: "N" when DM.ARM is missing and "Y" otherwise.
adsl <- adsl %>%
  mutate(
    ITTFL = case_when(
      dm$ARM == "Screen Failure" ~ "N",
      TRUE ~ "Y"
    )
  )

#### Derive LSTALVDT (Last Date Known Alive)
# LSTALVDT  is derived following the admiral documentation "Creating ADSL".
# Following the instructions, Highest imputation level is left to the default value of "n".
# In this way not complete dates result in "NA_character". For VS, only dates with a valid test result
#([VS.VSSTRESN] and [VS.VSSTRESC] not both missing) are considered.
# The date part of ADSL.TRTEDTM is extracted as required.
adsl <- adsl %>%
  derive_vars_extreme_event(
    by_vars = exprs(STUDYID, USUBJID),
    events = list(
      event(
        dataset_name = "ae",
        order = exprs(AESTDTC, AESEQ),
        condition = !is.na(AESTDTC),
        set_values_to = exprs(
          LSTALVDT = convert_dtc_to_dt(AESTDTC),
          seq = AESEQ
        ),
      ),
      event(
        dataset_name = "ds",
        order = exprs(DSSTDTC, DSSEQ),
        condition = !is.na(DSSTDTC),
        set_values_to = exprs(
          LSTALVDT = convert_dtc_to_dt(DSSTDTC),
          seq = DSSEQ
        ),
      ),
      event(
        dataset_name = "vs",
        order = exprs(VSDTC, VSSEQ),
        condition = !is.na(VSDTC) & (!is.na(VSSTRESN) | !is.na(VSSTRESC)),
        ,
        set_values_to = exprs(
          LSTALVDT = convert_dtc_to_dt(VSDTC),
          seq = VSSEQ
        ),
      ),
      event(
        dataset_name = "adsl",
        condition = !is.na(as.Date(TRTEDTM)),
        set_values_to = exprs(
          LSTALVDT = as.Date(TRTEDTM),
          seq = 0
        ),
      )
    ),
    source_datasets = list(ae = ae, vs = vs, adsl = adsl, ds = ds),
    tmp_event_nr_var = event_nr,
    order = exprs(LSTALVDT, seq, event_nr),
    mode = "last",
    new_vars = exprs(LSTALVDT)
  )

### Save the final dataset to the output directory
out_dir <- "question_2_adam/output"
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
write.csv(adsl, file.path(out_dir, "ADSL.csv"), row.names = FALSE)
