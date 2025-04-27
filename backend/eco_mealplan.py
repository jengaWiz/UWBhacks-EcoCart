import os
import time
import pandas as pd
import random
from fastapi import APIRouter, Body
from sklearn.preprocessing import MinMaxScaler
import google.generativeai as genai
import json
import re
from dotenv import load_dotenv


load_dotenv()
router = APIRouter()


EMISSION_WEIGHTS = {
    "Agriculture": 0.50,
    "ILUC": 0.20,
    "Processing": 0.10,
    "Packaging": 0.14,
    "Transport": 0.03,
    "Retail": 0.03
}
REQUIRED_COLUMNS = ['Food product', 'kg CO2e/ pr. kg', 'Image Link'] + list(EMISSION_WEIGHTS.keys())

if "GEMINI_API_KEY" in os.environ:
    genai.configure(api_key=os.environ["GEMINI_API_KEY"])
    model = genai.GenerativeModel('gemini-1.5-flash')
else:
    model = None

def load_food_data(file_path: str) -> pd.DataFrame:
    try:
        df = pd.read_excel(file_path)
        missing_cols = set(REQUIRED_COLUMNS) - set(df.columns)
        if missing_cols:
            raise ValueError(f"Missing required columns: {missing_cols}")
        df = df.dropna(subset=['kg CO2e/ pr. kg']).reset_index(drop=True)
        scaler = MinMaxScaler()
        df['eco_score_raw'] = df.apply(lambda row: sum(row[comp] * EMISSION_WEIGHTS[comp] for comp in EMISSION_WEIGHTS), axis=1)
        df['eco_score_normalized'] = scaler.fit_transform(df[['eco_score_raw']])
        df['eco_score_normalized'] = df['eco_score_normalized'].clip(0, 1)
        return df
    except Exception as e:
        raise SystemError(f"Data loading failed: {str(e)}")

def pick_random_ingredients(df: pd.DataFrame, num_ingredients: int = 30) -> list:
    ingredients = df['Food product'].dropna().tolist()
    return random.sample(ingredients, min(num_ingredients, len(ingredients)))


def extract_json(text: str) -> dict:
    try:
        match = re.search(r'\{[\s\S]+\}', text)
        if match:
            json_str = match.group(0)
            return json.loads(json_str)
        else:
            print("No valid JSON object found.")
            return {"meals": []}
    except Exception as e:
        print(f"Error parsing JSON: {e}")
        return {"meals": []}

def generate_meal_plan(ingredient_list: list, source: str) -> dict:
    ingredient_hint = ", ".join(ingredient_list)

    if source == "random":
        prompt = f"""
You are an AI-powered eco-conscious meal planner.
Available Ingredients:
{ingredient_hint}

Task:
- Create 5 healthy, realistic meal recipes.
- ONLY use these provided ingredients.
- No missing items.
- No recommendations outside this list.

Each Meal should include:
- meal_name
- description
- ingredients (array)

Only output valid JSON:
{{
  "meals": [
    {{"meal_name": "", "description": "", "ingredients": [...] }}
  ]
}}

Strict: No greetings, no extra explanation, only JSON.
"""
    else:
        prompt = f"""
You are an AI-powered eco-conscious meal planner.
Available Cart Items:
{ingredient_hint}

Task:
- Prioritize using cart ingredients.
- If needed, add extras logically from the 30 recommended items.
- List extras under missing_items field.

Each Meal should include:
- meal_name
- description
- ingredients (array)
- missing_items (array)

Only output valid JSON:
{{
  "meals": [
    {{"meal_name": "", "description": "", "ingredients": [...], "missing_items": [...] }}
  ]
}}

Strict: No greetings, no extra explanation, only JSON.
"""

    try:
        response = model.generate_content(prompt)
        time.sleep(2)
        raw_text = response.text.strip()
        print("🔵 GEMINI RAW OUTPUT:")
        print(raw_text)
        print("🔵 END RAW OUTPUT\n")
        cleaned_json = extract_json(raw_text)
        return cleaned_json

    except Exception as e:
        print(f"Gemini API error: {e}")
        return {"meals": []}




@router.post("/generate_random_meals")
async def generate_random_meals():
    food_df = load_food_data("data/food_emissions_with_images.xlsx")
    selected_ingredients = pick_random_ingredients(food_df)
    meals = generate_meal_plan(selected_ingredients, source="random")


    if isinstance(meals, dict) and "meals" in meals:
        return meals["meals"]
    else:
        return []


@router.post("/generate_cart_meals")
async def generate_cart_meals(cart_items: list = Body(...)):
    food_df = load_food_data("data/food_emissions_with_images.xlsx")
    available_products = set(food_df['Food product'].dropna().tolist())
    cart_ingredients = [item for item in cart_items if item in available_products]

    if not cart_ingredients or len(cart_ingredients) < 5:
        print("⚠️ Not enough cart ingredients, adding recommendations.")
        recommended_ingredients = pick_random_ingredients(food_df, num_ingredients=30)
        final_ingredients = list(set(cart_ingredients + recommended_ingredients))
    else:
        recommended_ingredients = []
        final_ingredients = cart_ingredients

    meals = generate_meal_plan(final_ingredients, source="cart")

    eco_score_mapping = food_df.set_index('Food product')['eco_score_normalized'].to_dict()
    ingredient_scores = {item: eco_score_mapping.get(item, None) for item in final_ingredients}

    return {
        "used_cart_items": cart_ingredients,
        "added_recommendations": recommended_ingredients,
        "final_ingredients_used": final_ingredients,
        "ingredient_eco_scores": ingredient_scores,
        "meals": meals
    }

if __name__ == "__main__":
    pass
