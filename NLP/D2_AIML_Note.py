# # %%
# import aiml

# kernel = aiml.Kernel()
# kernel.learn("./Data/01-AIML-hello.xml")
# while True:   # Press CTRL-C to break this loop
#     t1 = input("Enter your message >> ")
#     t2 = kernel.respond(t1)
#     print(t2)
# # %%
# import aiml
# # Create the kernel and learn AIML files
# kernel = aiml.Kernel()
# kernel.learn("./Data/02-AIML-helloChinese.xml")
# kernel.learn("./Data/03-AIML-random.xml")
# kernel.learn("./Data/04-AIML-all.xml")
# kernel.learn("./Data/AIML_chris.xml")
# while True:   # Press CTRL-C to break this loop
#     try:
#         print(kernel.respond(input("Enter your message >> ")))
#     except:
#         print(kernel.respond(raw_input("Enter your message >> ")))

# # %%
# import aiml
# # Create the kernel and learn AIML files
# kernel = aiml.Kernel()
# kernel.learn("./Data/05-AIML-load.xml")
# kernel.respond("load aiml b")
# while True:   # Press CTRL-C to break this loop
#     try:
#         print(kernel.respond(input("Enter your message >> ")))
#     except:
#         print(kernel.respond(raw_input("Enter your message >> ")))


# %%
import pyttsx3
# 講英文
engine = pyttsx3.init()
engine.say("Good")
engine.runAndWait()

# 講中文
voices = engine.getProperty("voices")
for item in voices:
    print(item.id,item.languages)

engine = pyttsx3.init()
key1="HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Sp eech\Voices\Tokens\TTS_MS_ZH-CN_HUIHUI_11.0"
key1="HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Speech\Voices\Tokens\TTS_MS_ZH-TW_HANHAN_11.0"
key2="HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Speech\Voices\Tokens\TTS_MS_JA-JP_HARUKA_11.0"

engine.setProperty("voice",key1)
engine.say("你好嗎？")
engine.runAndWait()

engine.setProperty("voice",key2)
engine.say("おはようございます")
engine.runAndWait()

# 講英文
# engine = pyttsx3.init()
# engine.say("Good")
# engine.runAndWait()


# %%
import pyttsx3
# 講中文
voices = engine.getProperty("voices")
for item in voices:
    print(item.id,item.languages)

engine = pyttsx3.init()
key1="HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Sp eech\Voices\Tokens\TTS_MS_ZH-CN_HUIHUI_11.0"
key1="HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Speech\Voices\Tokens\TTS_MS_ZH-TW_HANHAN_11.0"
key2="HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Speech\Voices\Tokens\TTS_MS_JA-JP_HARUKA_11.0"

# 打開 test.txt 檔案，讀取內容，並設定為 str1
str1=""
with open("test.txt","r",encoding="utf-8") as f:
    for line in f:
        str1+=line


engine.setProperty("voice", key1)
engine.say(str1)
engine.runAndWait()

engine.setProperty("voice", key2)
engine.say(str1)
engine.runAndWait()


# %%
import pyttsx3
# 講英文
engine = pyttsx3.init()
# engine.say("Good")
# engine.runAndWait()

# 講中文
voices = engine.getProperty("voices")
for item in voices:
    print(item.id,item.languages)

engine = pyttsx3.init()


# https://pypi.org/project/pyttsx3/
""" 速度 RATE"""
rate = engine.getProperty('rate')   # getting details of current speaking rate
print (rate)                        #printing current voice rate
engine.setProperty('rate', 80)     # setting up new voice rate



""" 音量 VOLUME"""
volume = engine.getProperty('volume')   #getting to know current volume level (min=0 and max=1)
print (volume)                          #printing current volume level
engine.setProperty('volume',0.8)    # setting up volume level  between 0 and 1


"""切換不同人 VOICE"""
voices = engine.getProperty('voices')       #getting details of current voice
# 英文版的切換方法
print("切換不同人",voices)
engine.setProperty('voice', voices[0].id)  #changing index, changes voices. o for male
#engine.setProperty('voice', voices[1].id)   #changing index, changes voices. 1 for female

# 中文版的切換方法
# 英文 key1="HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Speech\Voices\Tokens\TTS_MS_ZH-CN_HUIHUI_11.0"
key1="HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Speech\Voices\Tokens\TTS_MS_ZH-TW_HANHAN_11.0"
engine.setProperty("voice",key1)

str1="首次以「FUN」為主題打造2022「Just FUN 新北」街頭文化節，即將於8月在板橋府中廣場"
engine.say(str1)
engine.runAndWait()

"""Saving Voice to a file"""
engine.save_to_file(str1, "./Data/test.mp3")
engine.save_to_file(str1, "./Data/test.wav")
engine.runAndWait()

key2="HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Speech\Voices\Tokens\TTS_MS_JA-JP_HARUKA_11.0"
engine.setProperty("voice", key2)
str1="高額の献金をするため、家にはいつもお金がなく、ご飯もまともに食べられなかった"
engine.say(str1)
engine.runAndWait()
# %%
from gtts import gTTS

# 要转换为语音的文本
text = "你好，这是一个使用Google Text-to-Speech的示例。"

# 创建一个gTTS对象
tts = gTTS(text=text, lang='zh-TW')  # 语言代码可以根据需要更改

# 保存语音文件
tts.save("output.mp3")



# %%
import aiml
from io import BytesIO
import pyttsx3
from gtts import gTTS
import pygame
import os

def speak_text(text):
    mp3_file_object = BytesIO()
    tts = gTTS(text, lang='en')
    tts.write_to_fp(mp3_file_object)
    pygame.init()
    pygame.mixer.init()
    pygame.mixer.music.load(mp3_file_object, "mp3")
    pygame.mixer.music.play()

speak_text("This is a test")
# %%
