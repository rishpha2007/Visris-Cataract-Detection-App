from flask import Flask, request, jsonify
from flask_cors import CORS
from tensorflow.keras.models import load_model
from PIL import Image
import numpy as np

app = Flask(__name__)
CORS(app)

# Load model
model = load_model("cataract_model.h5")

# Labels
class_names = ["High", "Medium", "Normal"]

# Solutions
solutions = {
    "High": "Consult an eye specialist immediately.",
    "Medium": "Visit doctor for proper treatment.",
    "Normal": "Eye looks normal. Regular checkup recommended."
}

@app.route("/")
def home():
    return "Visris AI Backend Running"

@app.route("/predict", methods=["POST"])
def predict():

    if "file" not in request.files:
        return jsonify({"error": "No file uploaded"})

    file = request.files["file"]

    # Open image
    img = Image.open(file).convert("RGB")

    # Resize image
    img = img.resize((224, 224))

    # Convert to array
    img_array = np.array(img) / 255.0

    # Add batch dimension
    img_array = np.expand_dims(img_array, axis=0)

    # Predict
    prediction = model.predict(img_array)

    predicted_class = class_names[np.argmax(prediction)]

    confidence = float(np.max(prediction) * 100)

    solution = solutions[predicted_class]

    return jsonify({
        "prediction": predicted_class,
        "confidence": round(confidence, 2),
        "solution": solution
    })

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=True)