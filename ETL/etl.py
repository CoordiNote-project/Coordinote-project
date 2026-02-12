import requests
import pandas as pd

# -------------------------------
# 1️⃣ ArcGIS REST API URL
# -------------------------------
url = (
    "https://services.arcgis.com/1dSrzEWVQn5kHHyK/arcgis/rest/services/"
    "POILazer/FeatureServer/1/query?"
    "outFields=*&where=1%3D1&f=json"
)

# -------------------------------
# 2️⃣ HTTP isteği
# -------------------------------
response = requests.get(url)

if response.status_code != 200:
    print("Hata! Status code:", response.status_code)
    print(response.text[:500])
    exit()  # Hata varsa script durur

# -------------------------------
# 3️⃣ JSON veriyi pandas DataFrame'e çevir
# -------------------------------
data = response.json()
features = data["features"]

# attributes kısmını alıyoruz
rows = [feat["attributes"] for feat in features]
df = pd.DataFrame(rows)

# -------------------------------
# 4️⃣ Temizlik işlemleri
# -------------------------------

# 4a) Satır içi newline karakterlerini temizle
for col in df.columns:
    if df[col].dtype == object:  # sadece string kolonlar
        df[col] = df[col].str.replace('\n', ' ').str.strip()

# 4b) Gereksiz kolonları at (opsiyonel)
drop_cols = ['GlobalID', 'OBJECTID']  # istersen diğer kolonları da atabilirsin
for col in drop_cols:
    if col in df.columns:
        df = df.drop(columns=[col])

# 4c) Duplicate satırları kaldır (opsiyonel)
df = df.drop_duplicates()

# -------------------------------
# 5️⃣ CSV olarak kaydet (Excel uyumlu UTF-8)
# -------------------------------
df.to_csv("POILazer_clean.csv", index=False, encoding="utf-8-sig")

# -------------------------------
# 6️⃣ Bilgi
# -------------------------------
print("✅ Veri başarıyla çekildi ve temizlendi!")
print("Satır sayısı:", len(df))
print(df.head())
