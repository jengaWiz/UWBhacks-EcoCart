from dotenv import load_dotenv
load_dotenv()

from fastapi import FastAPI
from pydantic import BaseModel
from eco_score import (
    load_emissions_data,
    get_all_food_items,
    get_sustainability_score,
    get_recommendations
)
from eco_mealplan import router as mealplan_router


df = load_emissions_data("data/food_emissions_with_images.xlsx")

app = FastAPI()

app.include_router(mealplan_router)

class ClassifyRequest(BaseModel):
    food_name: str


@app.get("/all_items")
async def all_items():
    """Return all food items for full search."""
    return get_all_food_items(df)

@app.get("/recommendations")
async def recommendations():
    """Return recommended food items for the dashboard."""
    return get_recommendations(df)

@app.post("/classify")
async def classify(req: ClassifyRequest):
    """Classify a specific food item and return its sustainability information."""
    return get_sustainability_score(req.food_name, df)

@app.get("/health")
async def health_check():
    """Simple server health check."""
    return {"status": "ok"}



