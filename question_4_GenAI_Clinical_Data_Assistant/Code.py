### Script: Code.py
### Purpose: Develop a Generative AI Assistant that translates natural language questions into structured Pandas queries.
### Inputs: adae.csv, adae.description.csv . The adae.csv file was created by saving as csv the pharmaversesdtm::ae
# using the script input/create_adae_description.R .The adae_description.csv file was created using the script 
# input/create_adae_description.R from ae.R that was downloaded at https://github.com/pharmaverse/pharmaversesdtm/blob/main/R/ae.R 
# adae.description.csv contains the description of each column in the adae dataset and is used together with adae.csv 
# to create the schema.
### Output: This script is imported as a module by Test_script.py that runs three example queries


### Import required libraries
import pandas as pd
import numpy as np
import os, json
from mistralai import Mistral

### Chosing LLM model from Mistral and creating client
# I used MistralAI as LLM provider because I already used it before
# for a course and it offers a free tier. The MISTRAL_API_KEY should be 
# in the .env file in the working directory.
api_key = os.environ["MISTRAL_API_KEY"]
model = "codestral-embed"
client = Mistral(api_key=api_key)

### Import adae dataset and adae description
adae = pd.read_csv("question_4_GenAI_Clinical_Data_Assistant/input/adae.csv")
adae_description = pd.read_csv("question_4_GenAI_Clinical_Data_Assistant/input/adae_description.csv")


### Build schema with columns description and allowed values for categorical columns

## Function to convert values of categorical columns to a list
def to_str_list(x):
    return ["" if pd.isna(v) else str(v) for v in x.tolist()]

## Function that defines categorical columns and returns the schema dictionary with
# for each column its description (from adae_description) and for the categorical columns
# their unique values (from adae.csv)
def build_schema(adae: pd.DataFrame, adae_description: pd.DataFrame):
    desc_map = dict(zip(adae_description["variable"], adae_description["description"]))
    categorical_columns = {"AESEV", "AESER", "AEOUT", "AEREL", "AESOD", "AESOC", "AEBODSYS"}

    cols = []
    for col in adae.columns:
        col_dict = {
            "name": col,
            "description": str(desc_map.get(col, "")),
            "dtype": str(adae[col].dtype)
        }
        if col in categorical_columns:
            uniq = adae[col].dropna().astype(str).unique()
            col_dict["allowed_values"] = to_str_list(pd.Series(uniq))
        cols.append(col_dict)

    schema = {
        "dataset": "main",
        "columns": cols
    }
    return schema

### Apply the function and create the schema
SCHEMA = build_schema(adae, adae_description)


### Implement ClinicalTrialDataAgent (ClinicalTrailDataAgent function) 
## A prompt is given to the LLM agent with the instruction to map user question
## to a json to filter the AE dataset. Only columns names and categorical variables
## allowed values can be outputed. It is also explained the format of time variables in the 
## dataset. The dataset schema generated above is also provided (default value of the schema argoument)
## together with the json schema to output and the rules to follow. The user provides a question in input
def ClinicalTrialDataAgent(question: str, schema: SCHEMA) -> dict:
    system_prompt = f"""
System:
You are a strict JSON generator that maps user questions about the AE dataset
to a single filter condition. Use ONLY the provided columns and, when present,
their allowed_values. Output ONLY valid JSON, no prose. All the columns that contain 
time values are in string format and time is reported as YYYY-MM-DD, in some cases 
month and/or days are not reported

Schema (columns with description, dtype, and optional allowed_values):
{schema}

JSON schema to output:
{{
  "column": "<one of schema columns>",
  "operator": "<one of: '==', '>=', '<=', '>', '<'>",
  "value": "<string or number, if allowed values are present in the schema value for that column should be one of those>",
  "clarification_needed": "<string>"
}}

Rules:
- If the question is ambiguous or refers to a non-existent column/value, return:
  {{ "clarification_needed": true, "reason": "<short reason>" }}
- For categorical columns with allowed_values, prefer EXACT matches from allowed_values.
- Do NOT invent columns or values. Do NOT return arrays.
- Output JSON only.

User: 
{question}

Schema: 
{json.dumps(schema, ensure_ascii=False)}  
JSON schema to output:
{{ "column": "...", "operator": "...", "value": "...", "clarification_needed": "..." }}
Rules:
..."""
    resp = client.chat.complete(
        model="mistral-small-latest",  ## The mistral-small-latest model is used
        messages=[
            {"role":"system","content":system_prompt},  ## The chat roles are stated
            {"role":"user","content":question}
        ],
        temperature=0 ## The temperature is set to 0 to allow more reproduible results and avoid allucinations
    )
    raw = resp.choices[0].message.content
     
    ## This removes trailin comas and empty string from the raw json so that it can be used by the return filtered data function
    clean = (
    raw.strip()
        .replace("```json", "")
        .replace("```", "")
        .strip()
    )
    return json.loads(clean)

#### Execution 
## The function takes as input the user question as a string and calls internally
## the ClinicalTrialDataAgent function.  The json output by ClinicalTrialDataAgen is
## used to filter the adae dataset. Depending on the values of pandas_commands["operator"]
## different types of filtering are performed.The function return four outputs in a dictionary.
## 1) the filtered dataset 2) The json commands used for filtering 3) The count
## of unique subjects and 4) The subject matching IDs.

def return_filtered_data(question: str):
  pandas_commands = ClinicalTrialDataAgent(question = question, schema = SCHEMA)

  if pandas_commands['clarification_needed'] is True:
    print("Clarification needed:",pandas_commands["reason"])
  else:
    if pandas_commands["operator"] == "==":
     filtered_df = adae[adae[str(pandas_commands["column"])] == pandas_commands["value"]]

    elif pandas_commands["operator"] == ">=":
     filtered_df = adae[adae[str(pandas_commands["column"])] >= pandas_commands["value"]]

    elif pandas_commands["operator"] == ">":
     filtered_df = adae[adae[str(pandas_commands["column"])] > pandas_commands["value"]]

    elif pandas_commands["operator"] == "<=":
     filtered_df = adae[adae[str(pandas_commands["column"])] <= pandas_commands["value"]]

    else:
     filtered_df = adae[adae[str(pandas_commands["column"])] <= pandas_commands["value"]]
    
    count_unique_ids = len(filtered_df["USUBJID"].unique())
    list_of_matching_ids = filtered_df["USUBJID"].unique().tolist()
    
    return{"filtered_df": filtered_df, "pandas_commands": pandas_commands,
     "count of unique subject": count_unique_ids, "list_of_matching_ids": list_of_matching_ids}

