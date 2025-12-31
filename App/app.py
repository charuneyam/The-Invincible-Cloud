from flask import Flask, request, jsonify
from models import create_table, get_items, create_item

app = Flask(__name__)

create_table()

@app.route("/", methods=["GET"])
def health():
    return "API is running"

@app.route("/items", methods=["GET"])
def list_items():
    return jsonify(get_items())

@app.route("/items", methods=["POST"])
def add_item():
    data = request.json
    item_id = create_item(data["name"])
    return jsonify({"id": item_id})

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
