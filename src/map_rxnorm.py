import gzip, csv
from ask_llm import ask
from nltk import word_tokenize

def partial_match(drug,drug_dict):
    drug_words = word_tokenize(drug)
    candidates = []
    for key, item in drug_dict.items():
        words = word_tokenize(item)
        intersection = [x for x in words if x in drug_words]
        if len(intersection)>0:
            candidates.append([key,item])
    return candidates


if __name__=="__main__":
    name2id = {}
    drug_names = {}

    #You need the drug names from UKB, the file is called coding4.tsv 
    #downloadable from: https://biobank.ctsu.ox.ac.uk/ukb/coding.cgi?id=4
    lines=open('data/coding4.tsv').readlines()
    for l in lines:
        p = l.rstrip().split('\t')
        p[1] = l.rstrip().lower()[l.find('\t')+1:]
        drug_names[p[0]]=p[1]
        if p[1] not in name2id:
            name2id[p[1]]=set()
        name2id[p[1]].add(p[0])


    fn='data/MEDI-C.csv'
    rx_dic = {}
    with open(fn, newline='') as csvfile:
        reader = csv.reader(csvfile)
        for p in reader:
            rx_dic[p[0]]=p[1].lower()

    #Output file
    f=open('output/rxnorm2ukb.tsv','w+')
    for drug, drug_name in rx_dic.items():
        if drug_name in name2id:
            f.write('*'+drug+'\t'+'|'.join(list(name2id[drug_name]))+'\n')
            #an exact match was found so we can move on to the next drug
            continue
        candidates = partial_match(drug_name,drug_names)
        if len(candidates)>0:
            answer = ask(drug_name,candidates).replace('\n',' ')
            answer = answer.split(',')
            codes = []
            for item in answer:
                item= item.replace(' ','')
                if item.isnumeric() and int(item)<=len(candidates):
                    codes.append(candidates[int(item)-1][0])
            if len(codes)>0:
                f.write(drug+'\t'+'|'.join(codes)+'\n')
