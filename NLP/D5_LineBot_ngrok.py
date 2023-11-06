import requests
import os
# from sys import version as python_version
# from cgi import parse_header, parse_multipart
import socketserver as socketserver
from http.server import SimpleHTTPRequestHandler as RequestHandler
# from urllib.parse import parse_qs
import json
from bardapi import Bard
from pyngrok import ngrok

auth_token="oUh1Oq4r/VRC5Yln2rf1sWXQgILoWQHGllhKYc2+U6hu5w9cBavLVKpYClyXrYfdwpCwKyqgSeRTk2Ib1ke95dOT7xPIUayZgYbeoo7wKVS/8Coj6xHkTDiwPAkEUMUOb/YwmTbL4wFyDW/0Ud9wbQdB04t89/1O/w1cDnyilFU="
YouruserID="2001497018"

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
                    "text": ans
                },
                # emoji
                # https://developers.line.biz/en/docs/messaging-api/emoji-list/#line-emoji-definitions
                {
                    "type": "text",
                    "text": "$ LINE emoji $",
                    "emojis": [
                        {
                            "index": 0,
                            "productId": "5ac1bfd5040ab15980c9b435",
                            "emojiId": "001"
                        },
                        {
                            "index": 13,
                            "productId": "5ac1bfd5040ab15980c9b435",
                            "emojiId": "002"
                        }
                    ]
                },
                # 貼圖
                # https://developers.line.biz/en/docs/messaging-api/sticker-list/
                {
                    "type": "sticker",
                    "packageId": "446",
                    "stickerId": "1988"
                },
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

# ngrok.set_auth_token("2Xk7eLOsfN7fcKdnszwLwT6iOsQ_6E1yxAfCRbRqaWsbx5Guy")
# Open a HTTP tunnel on the default port 80
# <NgrokTunnel: "https://<public_sub>.ngrok.io" -> "http://localhost:80">
# http_tunnel = ngrok.connect()

# Open a SSH tunnel
# <NgrokTunnel: "tcp://0.tcp.ngrok.io:12345" -> "localhost:22">
# ssh_tunnel = ngrok.connect("8888", "http")
public_url = ngrok.connect(8888, "http")
print(f"Public URL: {public_url}")
# Open a named tunnel from the config file
# named_tunnel = ngrok.connect(name = "my_tunnel_name")
# print(named_tunnel.public_url)

socketserver.TCPServer.allow_reuse_address = True
httpd = socketserver.TCPServer(('0.0.0.0', 8888), MyHandler)
httpd.serve_forever()
