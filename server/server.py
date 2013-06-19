from flask import Flask
import flask
import hashlib
import time

app = Flask(__name__)

@app.route('/')
def hello_world():
    return "Hello";

@app.route('/photo', methods=['POST'])
def photo():
    d = flask.request.data
    name = hashlib.md5(d).hexdigest()
    t = int(time.time())

    with file('images/%i_%s.jpg' % (t,name),'wb') as f:
        f.write(d)

    return "OK";


if __name__ == '__main__':
    app.run(host='0.0.0.0')
