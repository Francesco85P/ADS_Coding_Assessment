# Script: 01_create_ds_domain.R
# Purpose: Create the SDTM DS domain from raw data using controlled terminology.
# Inputs: ds_raw, study_ct.csv, dm
# Output: SDTM_DS_domain.csv

### Import required packages
library(dplyr)
library(sdtm.oak)

### Import raw data
ds_raw <- pharmaverseraw::ds_raw

### Read in CT
study_ct <- read.csv("question_1_sdtm/input/sdtm_ct.csv")

### Read in DM domain
# The DM domain is imported because the variable RFXSTDTC is required
# for the derivation of DSSTDY. This is equivalent to AESTDY derivation
# in the SDTM AE Pharmaverse Example
dm <- pharmaversesdtm::dm

### Create oak_id_vars
# This generates the mandatory key variables (oak_id, raw_source andpatient_number)
#required to map raw data to SDTM
ds_raw <- ds_raw %>%
  generate_oak_id_vars(
    pat_var = "PATNUM",
    raw_src = "ds_raw"
  )

### Map Topic Variable DSTERM (Reported Term for the Disposition Event)
# Here the topic variables is mapped from the raw data; for the DS domain the
#topic variable is DSTERM that is mapped from IT.DSTERM
ds <-
  assign_no_ct(
    raw_dat = ds_raw,
    raw_var = "IT.DSTERM",
    tgt_var = "DSTERM",
    id_vars = oak_id_vars()
  )

### Map DSSTDTC (Start Date/Time of Disposition Event)
# Here  DSSTDTC is mapped from IT.DSSTDTD using the sdtm.oak function assign_datetime().
# This is equivalent to AESTDTC derivation in the SDTM AE Pharmaverse Example
ds <- ds %>%
  assign_datetime(
    raw_dat = ds_raw,
    raw_var = "IT.DSSTDAT",
    tgt_var = "DSSTDTC",
    raw_fmt = c("m-d-y"),
    id_vars = oak_id_vars()
  )


### Map DSDECOD (Standardized Disposition Term)
# For the derivation of DSDECOD the instruction reported in the Subject_Disposition_aCRF.pdf
# file was followed.If OTHERSP is null in the raw dataset than the value of IT.DSDECOD
# is mapped to DSDECOD, otherwise the value of OTHERSP is mapped to DSDECOD
ds <- ds %>%
  mutate(
    DSDECOD = case_when(
      is.na(ds_raw$OTHERSP) ~ ds_raw$IT.DSDECOD,
      TRUE ~ ds_raw$OTHERSP
    )
  )


### Map DSCAT (Category for Disposition Event)
# For the derivation of DSCAT the instruction reported in the Subject_Disposition_aCRF.pdf
# file was followed.If OTHERSP is null in the raw dataset, than if IT.DSDECOD is equal
# to "Randomized" DSCAT is mapped to "PROTOCOL MILESTONE", while if IT.DSDECOD is not equal
# to "Randomized" DSCAT is mapped to "DISPOSITION EVENT". If OTHERSP is not null, than
# DSCAT is mapped to "OTHER EVENT".
ds <- ds %>%
  mutate(
    DSCAT = case_when(
      is.na(ds_raw$OTHERSP) &
        ds_raw$IT.DSDECOD == "Randomized" ~ "PROTOCOL MILESTONE",
      is.na(ds_raw$OTHERSP) &
        ds_raw$IT.DSDECOD != "Randomized" ~ "DISPOSITION EVENT",
      !is.na(ds_raw$OTHERSP) ~ "OTHER EVENT"
    )
  )


### Map DSTERM
# DSTERM is modified in accordance with Subject_Disposition_aCRF.pdf.If OTHERSP in
# the raw dataset is not null, then its value is mapped to DSTERM.
ds <- ds %>%
  mutate(
    DSTERM = case_when(
      is.na(ds_raw$OTHERSP) ~ DSTERM,
      TRUE ~ ds_raw$OTHERSP
    )
  )


### Map DSDTC (Date/Time of Collection)
# DSDTC is mapped in accordance with Subject_Disposition_aCRF.pdf by mapping
# the values of DSDTCOL and DSTMCOL in the raw dataset in ISO8601 format.
# The sdtm.oak assign_datetime() function is used specifying the inputs formats
ds <- ds %>%
  assign_datetime(
    raw_dat = ds_raw,
    raw_var = c("DSDTCOL", "DSTMCOL"),
    tgt_var = "DSDTC",
    raw_fmt = c("m-d-y", "H:M")
  )


### Create SDTM derived variables
# The variables DOMAIN (SDTM domain), STUDYID (Study Identifier) and
#  USUBJID (Unique Subject Identifier) are derived following the same procedure as
# in the SDTM AE Pharmaverse Example
ds <- ds %>%
  dplyr::mutate(
    STUDYID = ds_raw$STUDY,
    DOMAIN = "DS",
    USUBJID = paste0("01-", ds_raw$PATNUM)
  )


### DERIVE DSSEQ (Sequence Number)is derved following the same procedure as
# in the SDTM AE Pharmaverse Example
ds <- ds %>%
  derive_seq(
    tgt_var = "DSSEQ",
    rec_vars = c("USUBJID", "DSTERM")
  )


### DERIVE VISIT AND VISITNUM
# The variables VISIT and VISITNUM are mapped from the variable INSTANCE in the raw
# dataset using the controlled terminology in study_ct
ds <- ds %>%
  assign_ct(
    raw_dat = ds_raw,
    raw_var = "INSTANCE",
    tgt_var = "VISIT",
    ct_spec = study_ct,
    ct_clst = "VISIT",
    id_vars = oak_id_vars()
  ) %>%
  assign_ct(
    raw_dat = ds_raw,
    raw_var = "INSTANCE",
    tgt_var = "VISITNUM",
    ct_spec = study_ct,
    ct_clst = "VISITNUM",
    id_vars = oak_id_vars()
  )


### Derive DSSTDY (Study Day of Start of Disposition Event)
# The variable DSSTDY is derived from the RFXSTDTC variable in the dm domain.
#This is equivalent to AESTDY derivation in the SDTM AE Pharmaverse Example
ds <- ds %>%
  derive_study_day(
    sdtm_in = .,
    dm_domain = dm,
    tgdt = "DSSTDTC",
    refdt = "RFXSTDTC",
    study_day_var = "DSSTDY"
  )


### Select required fields
ds <- ds %>%
  select(c(
    STUDYID,
    DOMAIN,
    USUBJID,
    DSSEQ,
    DSTERM,
    DSDECOD,
    DSCAT,
    VISITNUM,
    VISIT,
    DSDTC,
    DSSTDTC,
    DSSTDY
  ))

### Save the final dataset to the output directory
out_dir <- "question_1_sdtm/output"
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
write.csv(ds, file.path(out_dir, "SDTM_DS_domain.csv"), row.names = FALSE)
