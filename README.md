This repository contains my ADS Coding Assessment. For each question in the assessment there is a corresponding folder. 

- The folder question_1_sdtm contains the scrpits, inputs and output files for the first question: SDTM Disposition (DS) Domain Creation using {sdtm.oak}.
The file 01_create_ds_domain.R is the R script that creates the SDTM_DS dataset and contains comments to explain the procedure followed and the derivations.
The file 01_create_ds_domain.log is the log file.
In the input folder there is the file sdtm_ct.csv containg the controlled terminology required for this task.
In the output folder the SDTM_DS_domain.csv is the SDTM_ds dataset produced

- The folder question_2_adam contains the scrpits, inputs and output files for the second question: ADaM ADSL  (Analysis Data Subject Level)  Dataset Creation.
The file 02_create_adsl.R is the R script that creates the ADSL dataset and contains comments to explain the procedure followed and the derivations.
The file 02_create_adsl.log is the log file.
In the input folder there is the file safety_specs.xlsx. This file contains the ADAM variables metadata and was downloaded from:
https://github.com/pharmaverse/examples/blob/main/metadata
In the output folder the ADSL.csv is the ADaM ADSL dataset produced

- The folder question_3_tlg contains the scripts and output files for the third question: TLG (Tables, Listings, and Graphs) - Adverse Events Reporting.
The file 01_create_ae_summary_table.R is the R script that creates the AE Summary Table and contains comments to explain the procedure followed.
The file 02_create_visualizations.R is the R script used to create the two plots: the AE severity distribution by treatment bar chart and the plot with the 10
most frequent AEs.
The file 01_create_ae_summary_table.log  and 02_create_visualizations.log are the corresponding log files.
In the output folder there are the SummaryTable as an html file and the two plots as png files.

- The folder question_4_GenAI_Clinical_Data_Assistant contains the scripts, inputs and output files for the fourth question: GenAI Clinical Data Assistant.
The file Code.py contains the code to develop a Generative AI Assistant and contains comments to explain the procedure followed.
The file Test_script.py is a test script that runs 3 example queries (plus one query asking for a non esisting value)  and prints the results.
In the input folder there are four files. The file adae.csv is the ADaM ADAE dataset. The file ae.R  was downloaded at https://github.com/pharmaverse/pharmaversesdtm/blob/main/R/ae.R 
and contains the description of each column in the ADaM ADAE dataset. The file create_adae_description.R is the R script that uses pharmaversesdtm::ae and ae.R as input and
creates the files adae.csv and adae_description.csv. The file adae_description.csv contains the description of each ADaM ADAE dataset column derived by ae.R


