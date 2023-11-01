from flask import Flask, request, send_file
from io import BytesIO
import treepoem

app = Flask(__name__)

@app.route('/generate_datamatrix', methods=['GET'])
def generate_datamatrix():
    text = request.args.get('text')
    size = request.args.get('size', default=200)  # 默认尺寸为200

    barcode = treepoem.generate_barcode(barcode_type = 'datamatrix', data = text, scale = int(size))

    # filepath = f'datamatrix.png'
    # barcode.save(filepath)
    # 将生成的图像数据存储在内存中
    # image_stream = BytesIO()
    # barcode.save(image_stream)
    barcode.convert("1").save("./barcode.png")
    # 设置流的位置到开始以便后续读取
    # image_stream.seek(0)

    # return send_file(image_stream, mimetype='image/png')


if __name__ == '__main__':
    app.run(debug=True)
