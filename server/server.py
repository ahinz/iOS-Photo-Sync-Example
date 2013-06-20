from flask import Flask, render_template, send_file

import flask
import hashlib
import time
import os

app = Flask(__name__)
app.debug = True

@app.route('/')
def photos():
    images = [f for f in os.listdir("images") if f.endswith(".jpg")]

    images = sorted(images, reverse=True)

    return render_template('images.html', images=images)

@app.route('/images/<image>')
def get_image(image):
    return send_file(os.path.join("images",image))

@app.route('/photo', methods=['POST'])
def photo():
    d = flask.request.data
    name = hashlib.md5(d).hexdigest()
    t = int(time.time())

    with file('images/%i_%s.jpg' % (t,name),'wb') as f:
        f.write(d)

    time.sleep(3) # Mimic a delay

    return "OK";


if __name__ == '__main__':
    app.run(host='0.0.0.0')
