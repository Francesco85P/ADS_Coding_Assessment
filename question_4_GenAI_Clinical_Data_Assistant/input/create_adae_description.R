### Script: create_adae_description.R
### Purpose: parse the ae.R file using regular expressions from base R to produce the file adae_description.csv containing
# the description of each column in the adae dataset. pharmaversesdtm::ae  is saved as adae.csv to be used by the Code.py script
### Inputs: adae dataset, adae.description.
### Outputs: dae.csv, adae_description.csv

### Saving pharmaversesdtm::ae as adae.csv
pharmaversesdtm::ae |>
  write.csv(
    "question_4_GenAI_Clinical_Data_Assistant/input/adae.csv",
    row.names = FALSE
  )

### Reading in ae.R
txt <- readLines(
  "question_4_GenAI_Clinical_Data_Assistant/input/ae.R",
  encoding = "UTF-8"
)

#### Getting the lines with variables names and desriptions
lines <- grep("\\\\item\\{", txt, value = TRUE)

### Function to create a list of variables/variables descriptions
extract <- function(line) {
  m <- regmatches(line, gregexpr("\\\\item\\{([^}]+)\\}\\{([^}]+)\\}", line))[[
    1
  ]]
  if (length(m) == 0) {
    return(NULL)
  }
  parts <- sub("^\\\\item\\{([^}]+)\\}\\{([^}]+)\\}$", "\\1||\\2", m)
  strsplit(parts, "\\|\\|")[[1]]
}

### Apply the function to the lines of interest
kv <- lapply(lines, extract)

### Trasform kv to character vector with two dimensions
kv <- do.call(rbind, kv[!sapply(kv, is.null)])

### Trasform the character vector to a dataframe
df <- data.frame(
  variable = kv[, 1],
  description = kv[, 2],
  stringsAsFactors = FALSE
)

### Save the output dataframe
df |>
  write.csv(
    "question_4_GenAI_Clinical_Data_Assistant/input/adae_description.csv",
    row.names = FALSE
  )
