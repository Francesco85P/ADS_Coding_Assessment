# Script: 02_create visualizations.R
# Purpose: Create outputs for adverse events summary using the ADAE dataset and ggplot
# Inputs: adae dataset
# Outputs: AE_severity_distribution_by_treatment.png, Top_10_most_frequent_AEs.png"

#### Import required libraries
library(ggplot2)
library(dplyr)
library(GenBinomApps)

### Import required dataset
adae <- pharmaverseadam::adae

#### Task 1: AE severity distribution by treatment (bar chart or heatmap)

### Create barplot using ggplot
png(
  "question_3_tlg/output/AE_severity_distribution_by_treatment.png",
  width = 800,
  height = 600
)
adae |>
  ggplot(aes(x = ACTARM, fill = AESEV)) +
  geom_bar() +
  labs(
    title = "AE severity distribution by treatment",
    x = "Treatment Arm",
    y = "Count of AEs",
    fill = "Severity/Intensity"
  ) +
  theme_bw() +
  theme(plot.title = element_text(size = 20, hjust = 0.5, face = "bold")) +
  theme(
    axis.text = element_text(size = 10),
    axis.title = element_text(size = 16, face = "bold"),
    legend.title = element_text(size = 12, face = "bold"),
    legend.text = element_text(size = 10)
  )
dev.off()


#### Task 2: Top 10 most frequent AEs (with 95% CI for incidence rates)

### Create plot using ggplot.
# In order to count each AE only one time for patient, distinct(AETERM, USUBJID) are selected.
# Freqency is computed by grouping for AETERM, counting the occurencies and dividing by the number
# of patients. To compute the Clopper-Pearson 95% confidence intervals the clopper.pearson.ci()
# function from GenBinomApps is used.
png(
  "question_3_tlg/output/Top_10_most_frequent_AEs.png",
  width = 800,
  height = 600
)

adae |>
  distinct(AETERM, USUBJID) |>
  group_by(AETERM) |>
  summarise(n = n()) %>%
  mutate(Frequency = n / length(unique(adae$USUBJID))) |>
  ungroup() |>
  rowwise() |>
  mutate(
    Clopper_Pearson_Lower = clopper.pearson.ci(
      n,
      length(unique(adae$USUBJID)),
      CI = "two.sided",
      alpha = 0.05
    )$Lower.limit
  ) |>
  mutate(
    Clopper_Pearson_Upper = clopper.pearson.ci(
      n,
      length(unique(adae$USUBJID)),
      CI = "two.sided",
      alpha = 0.05
    )$Upper.limit
  ) |>
  arrange(desc(Frequency)) |>
  head(10) |>
  select(c(AETERM, Frequency, Clopper_Pearson_Lower, Clopper_Pearson_Upper)) |>
  mutate(across(where(is.numeric), ~ 100 * .)) |>
  ggplot() +
  aes(
    x = Frequency,
    y = reorder(AETERM, Frequency),
    xmin = Clopper_Pearson_Lower,
    xmax = Clopper_Pearson_Upper
  ) +
  geom_point(size = 5) +
  geom_errorbarh(height = .2) +
  theme_bw() +
  labs(
    title = "Top 10 Most Frequent Adverse Events",
    subtitle = paste0(
      "n = ",
      length(unique(adae$USUBJID)),
      " subjects; 95% Clopper-Pearson CIs"
    ),
    x = "Percentage of Patients (%)",
    y = "Adverse Event"
  ) +
  theme_bw() +
  theme(
    plot.title = element_text(size = 20, hjust = 0.5, face = "bold"),
    plot.subtitle = element_text(size = 15, hjust = 0.5),
    axis.text.y = element_text(size = 12),
    axis.text.x = element_text(size = 14),
    axis.title = element_text(size = 16, face = "bold")
  ) +
  scale_x_continuous(labels = scales::label_percent(scale = 1, accuracy = 1))
dev.off()
