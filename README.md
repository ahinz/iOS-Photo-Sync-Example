# iOS Background Image Loading

The goal of this project is to show a prototype of a system that
automatically uploads a user photos to a central server whenever the app
is active.

In addition, any photos take since the last time the app is active are
also uploaded.

Right now the uploading is tied to the ```viewDidLoad``` event, which
means you may have to restart to the app to get the desired effect.

# Setup

## iOS

Build and run the Xcode project. The first time it is run it sets the
"initial date" timestamp. Only images saved after the initial date are
used.

## Server

To demonstrate uploading, there is a small python server. Provision your
virtual environment:

```bash
cd server
virtualenv env
source env/bin/activate
pip install -r requirements.txt
```

If you don't have virtualenv installed:

```bash
easy_install pip # If you need to install pip
pip install virtualenv
```

Run the server:

```bash
python server.py
```

You can go to http://localhost:5000/ to see uploaded photos.
