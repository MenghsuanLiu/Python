import requests
import os

# 一定要改的地方～～
auth_token="oUh1Oq4r/VRC5Yln2rf1sWXQgILoWQHGllhKYc2+U6hu5w9cBavLVKpYClyXrYfdwpCwKyqgSeRTk2Ib1ke95dOT7xPIUayZgYbeoo7wKVS/8Coj6xHkTDiwPAkEUMUOb/YwmTbL4wFyDW/0Ud9wbQdB04t89/1O/w1cDnyilFU="
YouruserID="2001497018"

from sys import version as python_version
# from cgi import parse_header, parse_multipart
import socketserver as socketserver
# import http.server
from http.server import SimpleHTTPRequestHandler as RequestHandler
from urllib.parse import parse_qs
import json
import requests
from bardapi import Bard

def generate_response_with_bard(text):
    # https://zhuanlan.zhihu.com/p/631178245
    return Bard().get_answer(text)["content"]

class MyHandler(RequestHandler):
    def do_HEAD(self):
        self.send_response(200)
        self.end_headers()



    def do_POST(self):

        userId=YouruserID
        varLen = int(self.headers['Content-Length'])
        if varLen > 0:
            post_data = self.rfile.read(varLen)
            data = json.loads(post_data)
            print(data)
            replyToken=data['events'][0]['replyToken']
            userId=data['events'][0]['source']['userId']
            text=data['events'][0]['message']['text']

        self.do_HEAD()


        ans = generate_response_with_bard(text)

        # print(self.wfile)
        message = {
            "replyToken":replyToken,
            "messages": [
                {
                    "type": "text",
                    "text": "Your User Id: " + userId + "\nText:" + ans,
                    
                }
            ]
        }

        hed = {'Authorization': 'Bearer ' + auth_token}
        url = 'https://api.line.me/v2/bot/message/reply'
        response = requests.post(url, json=message, headers=hed)
        print(response)
        print(response.json())

try:
    # Open the JSON file for reading
    with open("D:\\GitHub\\Python\\NLP\\Config\\api.json", "r") as json_file:
        data = json.load(json_file)
        os.environ["_BARD_API_KEY"] = data["bardkey"]
except FileNotFoundError:
    print(f"The file api.json does not exist.")

socketserver.TCPServer.allow_reuse_address = True
httpd = socketserver.TCPServer(('0.0.0.0', 8888), MyHandler)
httpd.serve_forever()
