import os
import time
import pandas as pd
from sklearn.preprocessing import MinMaxScaler
import google.generativeai as genai
import random
from dotenv import load_dotenv
load_dotenv()


EMISSION_WEIGHTS = {
    "Agriculture": 0.50,
    "ILUC": 0.20,
    "Processing": 0.10,
    "Packaging": 0.14,
    "Transport": 0.03,
    "Retail": 0.03
}
REQUIRED_COLUMNS = ['Food product', 'kg CO2e/ pr. kg', 'Image Link'] + list(EMISSION_WEIGHTS.keys())

def raw_to_eco_score(raw_score: float) -> float:
    max_emissions = 10.0
    scaled_score = max(0.0, 10.0 - (raw_score / max_emissions * 10.0))
    return round(scaled_score, 1)



if "GEMINI_API_KEY" in os.environ:
    genai.configure(api_key=os.environ["GEMINI_API_KEY"])
    model = genai.GenerativeModel('gemini-1.5-flash')
else:
    model = None

def load_emissions_data(file_path: str) -> pd.DataFrame:
    """Load and preprocess emissions dataset."""
    try:
        df = pd.read_excel(file_path)

        missing_cols = set(REQUIRED_COLUMNS) - set(df.columns)
        if missing_cols:
            raise ValueError(f"Missing required columns: {missing_cols}")

        df = df.dropna(subset=['kg CO2e/ pr. kg']).reset_index(drop=True)


        df['eco_score_raw'] = df.apply(
            lambda row: sum(row[comp] * EMISSION_WEIGHTS[comp] for comp in EMISSION_WEIGHTS),
            axis=1
        )

        scaler = MinMaxScaler()
        df['eco_score_normalized'] = scaler.fit_transform(df[['eco_score_raw']])
        df['eco_score_normalized'] = df['eco_score_normalized'].clip(0, 1)

        return df

    except Exception as e:
        raise SystemError(f"Data loading failed: {str(e)}")

def get_sustainability_score(food_item: str, df: pd.DataFrame) -> dict:
    clean_item = food_item.strip().lower()
    matches = df[df['Food product'].str.lower().str.contains(clean_item, regex=False)]

    if matches.empty:
        return {"error": "Item not found", "image_link": None}

    row = matches.iloc[0]
    raw_score = row['eco_score_raw']

    eco_score = raw_to_eco_score(raw_score)
    label = _get_sustainability_category(eco_score)

    return {
        "name": row['Food product'],
        "label": label,
        "eco_score": eco_score,
        "rationale": _generate_rationale(row, label),
        "components": row[list(EMISSION_WEIGHTS)].to_dict(),
        "total_emissions": float(row['kg CO2e/ pr. kg']),
        "image_link": row['Image Link']
    }



def get_clean_label(label: str) -> str:
    """Simplify messy product names for UI display (optional)."""
    if not model or not os.environ.get("GEMINI_API_KEY"):
        return label.strip()

    prompt = f"""
You are a skilled grocery app content formatter. Your job is to clean and simplify messy food product names into professional, human-friendly formats.

Product Name: "{label}"

Follow these rules carefully:
- Capitalize properly
- Group extra details like percentages into parentheses
- Remove symbols like periods, dashes, underscores
- Keep meaning accurate and short
Return only the cleaned product name.
"""

    try:
        response = model.generate_content(prompt)
        time.sleep(1)
        return response.text.strip().replace('"', '')  
    except Exception as e:
        print(f"Gemini clean label error: {str(e)}")
        return label.strip()

def _get_sustainability_category(score: float) -> str:
    """Categorize sustainability based on eco_score (0-10)."""
    if score >= 7.0:
        return "High Sustainability"
    elif score >= 4.0:
        return "Medium Sustainability"
    else:
        return "Low Sustainability"



def _generate_rationale(row: pd.Series, label: str) -> str:
    """Generate a user-friendly sustainability rationale."""
    if not model or not os.environ.get("GEMINI_API_KEY"):
        return "Sustainability analysis unavailable: Missing Gemini API key"

    components_str = "\n".join(f"- {comp}: {row[comp]:.2f}" for comp in EMISSION_WEIGHTS)

    prompt = f"""
You are a sustainability insights assistant. Your task is to explain a food product's eco-score based on its carbon emissions in a clear, friendly, and easy-to-understand way.

Product:
- Name: {label}
- Total Carbon Emissions (kg CO2e/kg): {row['kg CO2e/ pr. kg']:.2f}

Component Emissions:
{components_str}

Write the output structured into two sections:
1. Eco-Score Summary: Explain why it received its sustainability label.
2. Recommendation: Suggest whether it's a good sustainable choice.

Keep it professional, helpful, and concise.
"""

    try:
        response = model.generate_content(prompt)
        time.sleep(1)
        return response.text.replace("**", "").strip()
    except Exception as e:
        print(f"Gemini API Error: {str(e)}")
        return "Sustainability analysis unavailable: API error occurred"

def get_all_food_items(df: pd.DataFrame) -> list:
    return [
        {
            "name": row["Food product"].strip(),
            "image_link": row.get("Image Link", None)
        }
        for _, row in df.iterrows()
    ]





def get_recommendations(df: pd.DataFrame, n: int = 5) -> list:
    high_sustainability = df[df['eco_score_normalized'] <= 0.33]

    if len(high_sustainability) >= n:
        sampled = high_sustainability.sample(n)
    else:
        sampled = df.sample(n)

    return [
        {
            "name": row["Food product"].strip(),
            "image_link": row.get("Image Link", None)
        }
        for _, row in sampled.iterrows()
    ]



