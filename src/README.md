# The source code to run the mediation analysis

- map_rxnorm.py maps a list of drugs to RxNorm identifiers retrieved from MEDI-C.
- mediation_analysis.R tkes as input a csv file where the indication column is called "IND", the drug is called "Drug", and the side effect column is called "SE". Each row represents a sample.
- CKG_f.py applied the mapping function (f) on a set of observations to respect the semantics of the "is_a" relations in the DD-CKG
