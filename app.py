import os
from flask import Flask, jsonify, render_template

app = Flask(__name__)

DEPLOY_LOG = os.getenv("DEPLOY_LOG", "/deploy-state/history.log")


def read_history(limit=10):
    """Parse the deploy log written by scripts/deploy.sh (newest first)."""
    try:
        with open(DEPLOY_LOG) as f:
            lines = [l.strip() for l in f if l.strip()]
    except FileNotFoundError:
        return []
    entries = []
    for line in reversed(lines[-limit:]):
        parts = line.split(" ", 2)
        if len(parts) == 3:
            entries.append({"time": parts[0], "status": parts[1], "detail": parts[2]})
    return entries


@app.get("/")
def index():
    return render_template(
        "index.html",
        version=os.getenv("APP_VERSION", "dev"),
        history=read_history(),
    )


@app.get("/health")
def health():
    return jsonify(status="ok")


@app.get("/version")
def version():
    return jsonify(version=os.getenv("APP_VERSION", "dev"))


@app.get("/status")
def status():
    return jsonify(current_version=os.getenv("APP_VERSION", "dev"), deployments=read_history())


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
