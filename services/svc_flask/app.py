import os, time, random
from flask import Flask, jsonify
svc   = os.getenv("SVCNAME","svc")
delay = int(os.getenv("EXTRA_DELAY_MS","0"))/1000
app = Flask(__name__)

@app.route("/", methods=["POST","GET"])
def handle():
    time.sleep(delay + random.uniform(0.02,0.05))
    return jsonify({"svc": svc, "msg": "ok"})

@app.route("/status")
def status():
    return {"busy": random.randint(1,10)}

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
