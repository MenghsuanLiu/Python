# %%
import pathlib
import textwrap

import google.generativeai as genai
# from google.colab import userdata

from IPython.display import display
from IPython.display import Markdown


def to_markdown(text):
    text = text.replace('•', '  *')
    return Markdown(textwrap.indent(text, '> ', predicate=lambda _: True))


GOOGLE_API_KEY = "AIzaSyAJUlBhiiZ6QSVlRn0piHIbBXxDQI1BjOU"
genai.configure(api_key = GOOGLE_API_KEY)

for m in genai.list_models():
    if 'generateContent' in m.supported_generation_methods:
        print(m.name)
# %%

# model = genai.GenerativeModel('gemini-pro')
model = genai.GenerativeModel("gemini-1.5-pro5-latest")

ques = input("請輸入問題:")
response = model.generate_content(ques)

to_markdown(response.text)

response.prompt_feedback

response.candidates

try:
    print(response.text)
except Exception as e:
    print(f'{type(e).__name__}: {e}')
# %%
