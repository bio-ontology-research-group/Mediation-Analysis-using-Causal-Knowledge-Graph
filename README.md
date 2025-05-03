# Mediation-Analysis-using-Causal-Knowledge-Graph
We create a causal knowledge graph for drugs and their relations with diseases (DD-CKG). 
Drugs are represented using RxNorm identifiers and diseases are represented by ICD-10 codes.
We use DD-CKG to identify side effects of drugs using mediation analysis.

## Observational cohorts
- **UK Biobank** data is subject to strict access agreements and **must not** be shared publicly.
- **MIMIC-IV** data is also restricted under a data use agreement and **must not** be uploaded to this repository.

## Drug mapping
- We used Llama-3-70b-Instruct via [OpenRouter](https://openrouter.ai/meta-llama/llama-3-70b-instruct)
- The script we used can be found in **src/map_rxnorm.py**
- The result of the mapping can be found in **data/rxnorm2ukb.tsv** and **data/rxnorm2mimic.tsv**
- The expert curated set of mappings can be found in **data/curated_drug_mappings.tsv**

## DD-CKG construction
- We used the high precision indications from the [MEDI-C dataset](https://www.vumc.org/wei-lab/medi)
- We used side effects from the [OnSIDES dataset](https://github.com/tatonetti-lab/onsides/releases)
- We used disease--disease causal relationships [from our previous work](https://github.com/bio-ontology-research-group/Causal-relations-between-diseases)
- The created CKG can be found in **data/DD_CKG.tsv**
- The DD-CKG comes with a mapping function (f) that maps observations to nodes, because the used cohorts cannot be shared, we create a dummy dataset and show how the function is applied in **src/CKG_f.py**
- The probability measure is 
## Mediation analysis
- We used the R [**mediation**](https://cran.r-project.org/web/packages/mediation/index.html) package
- The R script we used can be found in **src/mediation_analysis.R**
- The results of the mediation analyses can be found in results/

