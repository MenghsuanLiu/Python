import csv
import flask     # pip install flask
from flask import render_template
from flask import  request


app = flask.Flask(__name__,static_url_path='/static')

#
@app.route("/fun1", methods=['GET'])
def fun1():
    用戶輸入的文字 = request.args.get('用戶輸入的文字')
    ####
    # 回傳值, Log文字 = mylibs.Line_處理用的問題v2(用戶輸入的文字, sheet問答題)

    return "  用戶輸入的文字=" + 用戶輸入的文字

@app.route('/', methods=['GET', 'POST'])
def index():
    str1 = render_template('index.html', 標題1="Python 課程", 內容1="你好啊～")
    return str1

if __name__ == '__main__':
    app.run(port = 5000, host = "0.0.0.0")