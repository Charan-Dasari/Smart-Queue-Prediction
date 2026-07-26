from fastapi import FastAPI, HTTPException
from pydantic import BaseModel, Field
from typing import Dict, Any, Optional
import pickle
import pandas as pd
import uvicorn
import os

app = FastAPI(title="Smart Queue ML Prediction API")

MODEL_PATH = "models/linear_model.pkl"
METADATA_PATH = "models/metadata.pkl"

model = None
metadata = None

@app.on_event("startup")
def load_artifacts():
    global model, metadata
    if not os.path.exists(MODEL_PATH) or not os.path.exists(METADATA_PATH):
        print(f"Warning: Model artifacts not found. Please run train_model.py first.")
        return
        
    with open(MODEL_PATH, "rb") as f:
        model = pickle.load(f)
        
    with open(METADATA_PATH, "rb") as f:
        metadata = pickle.load(f)
    print("Model and metadata loaded successfully.")

class PredictionRequest(BaseModel):
    # This allows sending a partial dictionary of features
    features: Dict[str, Any]

@app.post("/predict_wait_time")
def predict_wait_time(request: PredictionRequest):
    if model is None or metadata is None:
        raise HTTPException(status_code=503, detail="Model is not loaded.")
        
    feature_names = metadata['feature_names']
    defaults = metadata['defaults']
    encoders = metadata['encoders']
    scaler = metadata['scaler']
    
    # 1. Fill missing features with defaults
    input_data = {}
    for feature in feature_names:
        if feature in request.features and request.features[feature] is not None:
            input_data[feature] = request.features[feature]
        else:
            input_data[feature] = defaults.get(feature)
            
    # Convert to DataFrame (1 row)
    df = pd.DataFrame([input_data])
    
    # 2. Encode categorical variables
    for col, encoder in encoders.items():
        if col in df.columns:
            # Handle unseen labels by mapping them to a default/mode or catching exceptions
            # For simplicity, if a value is unseen, fallback to the first known class
            val = df[col].iloc[0]
            if val in encoder.classes_:
                df[col] = encoder.transform(df[col])
            else:
                # Fallback to the first class if unknown
                df[col] = 0
                
    # 3. Reorder columns to match training exactly
    df = df[feature_names]
    
    # 4. Scale numeric features
    X_scaled = scaler.transform(df)
    
    # 5. Predict
    prediction = model.predict(X_scaled)[0]
    
    # Ensure prediction is non-negative
    prediction = max(0.0, float(prediction))
    
    return {
        "estimated_wait_time_minutes": round(prediction, 1),
        "features_used": input_data
    }

if __name__ == "__main__":
    uvicorn.run("api:app", host="0.0.0.0", port=8000, reload=True)
