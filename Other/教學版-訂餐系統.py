from datetime import datetime
from flask import Flask, request
from linebot import LineBotApi

app = Flask(__name__)
line_bot_api = LineBotApi
orderNum = {"Big": 0, "Small": 0}
lastName = None
cellphone = None
orderTime = None
canOrder = True

@app.route("/", methods=["GET", "POST"])
def index():
    global lastName, cellphone, orderTime, orderDate
    json_body = request.get_json()
    intentName = json_body["queryResult"]["intent"]["displayName"]
    print(intentName)
    if intentName == "使用者給予時間→機器人詢問人數":  
        orderDateTime = json_body["queryResult"]["parameters"]["date-time"]
        print(orderDateTime)        
        orderDate = (
            datetime.fromisoformat(orderDateTime).date
            if orderDateTime.__len__() == 1
            else datetime.fromisoformat(
                orderDateTime["startDateTime"]
            ).date
        )
        return