# app.py
from flask import Flask, request
import random

app = Flask(__name__)

@app.route("/api")
def api():
    if request.args.get("unresponsive") == "1":
        return "Internal Server Error (simulated)", 500
    return "Hello from flaky API", 200

@app.route("/api/random")
def api_random():
    if random.random() < 0.3:  # 30% failure
        return "Random failure", 500
    return "Success", 200
