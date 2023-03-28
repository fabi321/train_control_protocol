# Train Control Protocol

## Getting started

First of all, create a venv and populate .env by running `random_keys.py` for generating a private key.
If you don't want to enforce that coupling cars have to share the key, set `TRUSTED_MODE` in `.env` to `"false"`

```shell
python3 -m virtualenv --creator venv .venv
. .venv/bin/activate
pip install -U -r requirements.txt
cp .env.template .env
sed -i 's/^KEY=.*/KEY="'"$(python random_keys.py)"'"/' .env
```

Compiling all the batches into a single file can be done by running

```shell
python compiler.py
```

This will result in a complete microcontroller in the file `train_controller.xml`

## Idea

The idea of this project is to implement a serial communication method to exchange train control data between train cars.

## Architecture

It shares a lot of similarities with TCP/IP. Namely there are Switches and Routers, that switch or route messages. Messages are built out of one state channel and one value channel.

## Message types

They are integers, and message types below 10 are reserved for future internal use.

