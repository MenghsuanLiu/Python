# %%
import whisper
import translators as ts
import sounddevice as sd
from scipy.io.wavfile import write

# 定義錄音並儲存音檔的函數
def record_and_save_audio(file_path):
    fs = 16000
    seconds = 10 
    mydata = sd.rec(int(seconds * fs), samplerate=fs, channels=1)
    sd.wait()
    write(file_path, fs, mydata)

# 載入 Whisper large-v3 模型 
model = whisper.load_model("large-v3")

# 錄音並儲存為 audio.wav 檔案
record_and_save_audio("audio.wav") 

# 使用 Whisper 將音檔轉換成文字
zh_text = model.transcribe("audio.wav")

# 使用機器翻譯將中文翻譯成英文
en_text = ts.google(zh_text, from_language='zh', to_language='en')

print(en_text)
# %%
