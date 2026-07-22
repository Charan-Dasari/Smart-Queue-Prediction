from fastapi import FastAPI
from pydantic import BaseModel
import pandas as pd
import joblib

app = FastAPI(title="Smart Queue Prediction API")

model = joblib.load("../models/linear_regression.pkl")
scaler = joblib.load("../models/scaler.pkl")
encoders = joblib.load("../models/label_encoders.pkl")


class PredictionRequest(BaseModel):
    facility_id: str
    age: int
    service_type: str
    priority_level: str
    customer_type: str
    wait_tolerance: int
    queue_length: int
    queue_position: int
    historical_avg_wait: float
    active_staff_count: int
    avg_service_time: float
    staff_availability: float
    hour_of_day: int
    day_of_week: int
    is_holiday: int
    peak_hours: int
    no_show_indicator: int
    service_counters: int
    operational_hours: int
    feedback_score: float
    queue_status: str


@app.post("/predict")
def predict(data: PredictionRequest):

    df = pd.DataFrame([data.dict()])

    for col, encoder in encoders.items():
        df[col] = encoder.transform(df[col])

    scaled = scaler.transform(df)

    prediction = model.predict(scaled)

    return {
        "predicted_wait_time": round(float(prediction[0]), 2)
    }