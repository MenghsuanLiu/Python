from pypinyin import lazy_pinyin   # 拼音函示庫
import pypinyin
import pydub                       # 使用簡單易用的高級界面處理音頻
from pydub import AudioSegment
from pathlib import Path
import wave
import pyaudio
#import _thread
import threading
import time
import sys
import os
import requests
# import atc
import argparse


class TextToSpeech:

    CHUNK = 1024
    punctuation = ['，', '。','？','！','“','”','；','：','（',"）",":",";",",",".","?","!","\"","\'","(",")"]

    def __init__(self):                                 #初始化
        pass

    def speak(self, text):                              #說話 函數 method
        syllables = lazy_pinyin(text, style=pypinyin.TONE3)    #拼音函示庫   syllables是一個 ['ni3', 'hao3']
        print("拼音:",syllables)
        delay = 0

        # 移除摽點符號
        def preprocess(syllables):
            temp = []
            for syllable in syllables:
                for p in TextToSpeech.punctuation:
                    syllable = syllable.replace(p, "")
                if syllable.isdigit():
                    syllable = atc.num2chinese(syllable)
                    new_sounds = lazy_pinyin(syllable, style=pypinyin.TONE3)
                    for e in new_sounds:
                        temp.append(e)
                else:
                    temp.append(syllable)
            return temp

        syllables=preprocess(syllables)                      # 移除摽點符號

        threads = []
        for syllable in syllables:
            path = "./Library/syllables/"+syllable+".wav"
            t = threading.Thread(target=self._play_audio,args=(path, delay))     # 建立多執行緒 多工
            threads.append(t)                                                    # 加入多工array
            t.start()                                                            # 執行多工
            delay += 0.355                                                       # 延遲 每一個字的時間

        self.synthesize(text,"syllables/", "save/" )                                 # 產生音檔
    # 錄音
    def synthesize(self, text, src, dst):
        delay = 0
        increment = 355 # milliseconds
        pause = 500 # pause for punctuation
        syllables = lazy_pinyin(text, style=pypinyin.TONE3)

        # initialize to be complete silence, each character takes up ~500ms
        result = AudioSegment.silent(duration=500*len(text))
        for syllable in syllables:
            path = src+syllable+".wav"
            sound_file = Path(path)
            # insert 500 ms silence for punctuation marks
            if syllable in TextToSpeech.punctuation:
                short_silence = AudioSegment.silent(duration=pause)
                result = result.overlay(short_silence, position=delay)
                delay += increment
                continue
            # skip sound file that doesn't exist
            if not sound_file.is_file():
                continue
            segment = AudioSegment.from_wav(path)
            result = result.overlay(segment, position=delay)
            delay += increment

        directory = dst
        if not os.path.exists(directory):
            os.makedirs(directory)

        result.export(directory+"generated.wav", format="wav")
        print("Exported.")


    # _ 私有函數 method
    def _play_audio(self,path, delay):                      # 播放音檔 函數 method
        try:
            time.sleep(delay)                               # 延遲
            wf = wave.open(path, 'rb')

            p = pyaudio.PyAudio()

            def callback(in_data, frame_count, time_info, status):
                data = wf.readframes(frame_count)
                return (data, pyaudio.paContinue)

            # open stream using callback (3) 播放wav 檔案
            stream = p.open(format=p.get_format_from_width(wf.getsampwidth()),channels=wf.getnchannels(),rate=wf.getframerate(),output=True,stream_callback=callback)
            # start the stream (4)
            stream.start_stream()
            # wait for stream to finish (5)
            while stream.is_active():
                time.sleep(0.1)
            # stop stream (6) 關閉
            stream.stop_stream()
            stream.close()
            wf.close()
            # close PyAudio (7)
            p.terminate()
        except:
            pass
    """    
    def _play_audio2(path, delay):
        try:
            time.sleep(delay)
            wf = wave.open(path, 'rb')
            p = pyaudio.PyAudio()
            stream = p.open(format=p.get_format_from_width(wf.getsampwidth()),
                            channels=wf.getnchannels(),
                            rate=wf.getframerate(),
                            output=True)
            
            data = wf.readframes(TextToSpeech.CHUNK)
            
            while data:
                stream.write(data)
                data = wf.readframes(TextToSpeech.CHUNK)
        
            stream.stop_stream()
            stream.close()

            p.terminate()
            return
        except:
            pass
    """


if __name__ == '__main__':                  # 判斷是主程式的話。就執行
    tts = TextToSpeech()                    # 初始化
    while True:
        str1 = input('輸入中文(按下Ctrl+C離開)：')
        tts.speak(str1)
