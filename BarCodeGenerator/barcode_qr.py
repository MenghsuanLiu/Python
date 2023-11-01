from flask import Flask, request, send_file
import qrcode
from io import BytesIO

app = Flask(__name__)

@app.route('/generate_matrix_barcode', methods=['GET'])
def generate_matrix_barcode():
    data = request.args.get('data')  # 從query string中獲取要生成條碼的數據
    size = request.args.get('size')  # 從query string中獲取條碼大小

    if data is not None:
        try:
            size = int(size)  # 將大小轉換為整數
        except ValueError:
            size = 10  # 如果無法轉換為整數，使用預設值

        qr = qrcode.QRCode(
            version=1,
            error_correction=qrcode.constants.ERROR_CORRECT_L,
            box_size = size,  # 設定條碼大小
            border = 2,
        )
        qr.add_data(data)
        qr.make(fit=True)
        img = qr.make_image(fill_color="black", back_color="white")

        img.save("./Python/BarCodeGenerator/qrcode.png")

        byte_io = BytesIO()
        img.save(byte_io)
        byte_io.seek(0)

        return send_file(byte_io, mimetype='image/png')  # 返回生成的條碼

    return "請提供要生成條碼的數據", 400

if __name__ == '__main__':
    app.run(debug=True)
            