import requests
import json, sys

model ='meta-llama/llama-3-70b-instruct'
#plug in your API key here
OPENROUTER_API_KEY=''

def prepare_list(input_list):
    output_string = ''
    for i,item in enumerate(input_list):
        output_string += str(i+1)+'- '+item[0]+': '+item[1]+'\n'
    return output_string


def ask(drug, drug_list):
    try:
        question = 'If the medication "'+drug+'" is commonly expressed as any of the medications in the following list, answer only with the number/s of the entry/entries separated by commas, otherwise, answer \"no\".\n'+ prepare_list(drug_list)
        print(question)
        response = requests.post(
          url="https://openrouter.ai/api/v1/chat/completions",
          headers={
            "Authorization": f"Bearer {OPENROUTER_API_KEY}",
          },
          data=json.dumps({
            "model": model, # Optional
            "temperature":0,
            "messages": [
              { "role": "user", "content":question
                  }
            ]
          })
        )
        return response.json()['choices'][0]['message']['content']
    except:
        return 'problem with '+drug+' to '+str(drug_list)
