import pandas as pd
import random
from collections import defaultdict

# ----------------------------
# Step 1: Load DD_CKG.tsv
# ----------------------------
graph = pd.read_csv("DD_CKG.tsv", sep="\t")

# Extract relevant nodes
disease_nodes = set(graph[graph["Source node type"] == "Disease"]["Source node"]) | \
                set(graph[graph["Target node type"] == "Disease"]["Target node"])
drug_nodes = set(graph[graph["Source node type"] == "Drug"]["Source node"]) | \
             set(graph[graph["Target node type"] == "Drug"]["Target node"])

# Extract is_a disease hierarchy: child --> parent
isa_edges = graph[graph["Edge name"] == "is a"]
isa_map = defaultdict(set)
for _, row in isa_edges.iterrows():
    child = row["Source node"]
    parent = row["Target node"]
    if child in disease_nodes and parent in disease_nodes:
        isa_map[child].add(parent)

# ----------------------------
# Step 2: Generate dummy patient observations
# ----------------------------
random.seed(42)
all_diseases = list(disease_nodes)
all_drugs = list(drug_nodes)
#choose however many you want
patients = [f"patient_{i}" for i in range(1, 10)]
# For each patient, randomly assign diseases and drugs
patient_records = defaultdict(lambda: {"diseases": set(), "drugs": set()})
for pid in patients:
    patient_records[pid]["diseases"] = set(random.sample(all_diseases, random.randint(1, 3)))
    patient_records[pid]["drugs"] = set(random.sample(all_drugs, random.randint(1, 2)))
print("Dummy observations:",patient_records)
# ----------------------------
# Step 3: Build initial node → patient observation map
# ----------------------------
node_to_patients = defaultdict(set)
for pid, record in patient_records.items():
    for d in record["diseases"]:
        node_to_patients[d].add(pid)
    for drug in record["drugs"]:
        node_to_patients[drug].add(pid)

# ----------------------------
# Step 4: Propagate disease observations up the is_a hierarchy
# ----------------------------
def get_all_ancestors(disease, visited=None):
    if visited is None:
        visited = set()
    for parent in isa_map.get(disease, []):
        if parent not in visited:
            visited.add(parent)
            get_all_ancestors(parent, visited)
    return visited

for disease in list(disease_nodes):
    for parent in get_all_ancestors(disease):
        node_to_patients[parent].update(node_to_patients[disease])

#node_to_patients is the output of the CKG function f which assigns to each node a subset of the observations/patients

# ----------------------------
# Step 5: Print or inspect results
# ----------------------------
print("Only nodes with observations are printed below:")
for node, pats in list(node_to_patients.items()):
    if len(pats)>0:
        print(f"{node}: {sorted(pats)}")

