from flask import Flask, request, send_file
import qrcode
from io import BytesIO
from pylibdmtx.pylibdmtx import encode
from PIL import Image

app = Flask(__name__)

@app.route("/generate_barcode", methods = ["GET"])
def generate_barcode():
    data = request.args.get("data")  # 從query string中獲取要生成條碼的數據
    size = request.args.get("size")  # 從query string中獲取條碼大小
    brtype = request.args.get("brtype")

    try:
        size = int(size)  # 將大小轉換為整數
    except ValueError:
        size = 10  # 如果無法轉換為整數，使用預設值

    if data is not None:
        if brtype == "q":
            byte_io = BytesIO()
            qr = qrcode.QRCode(
                version=1,
                error_correction=qrcode.constants.ERROR_CORRECT_L,
                box_size = size,  # 設定條碼大小
                border = 1,
            )
            qr.add_data(data)
            qr.make(fit=True)
            img = qr.make_image(fill_color="black", back_color="white")

            img.save("./Python/BarCodeGenerator/qrcode.png")
            img.save(byte_io)
            byte_io.seek(0)
            return send_file(byte_io, mimetype='image/png')  # 返回生86成的條碼
        
        if brtype == "d":
            # 將資料編碼為 Data Matrix 條形碼
            encoded = encode(data.encode("utf8"), size = '40x40')
            img = Image.frombytes('RGB', (encoded.width, encoded.height), encoded.pixels)  
            img.save("./Python/BarCodeGenerator/dmcode.png")
            return send_file('dmcode.png')
    return "請提供要生成條碼的數據", 400

if __name__ == '__main__':
    app.run(debug = True, host = "0.0.0.0")
            