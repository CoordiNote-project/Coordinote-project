import pandas as pd

categories = {
    "metro_stations": "metro_stations.csv",
    "parques_de_merendas_picnic_parks": "Parques_de_Merendas_Picnic_Parks.csv",
    "patrimonio_statues": "Patrimonio_Statues.csv",
    "teatros": "Teatros.csv"
}

dataframes = {}

# Load files
for category, file in categories.items():
    try:
        df = pd.read_csv(file, sep=";", header=None)
        df = df.iloc[:, :3]
        df.columns = ["a", "b", "c"]
        df = df.dropna()

        dataframes[category] = df

    except Exception as e:
        print(f"Error loading {file}: {e}")

if not dataframes:
    print("No data files loaded.")
    exit()

print("\nWelcome!")
print("Please select the address category where you would like to leave a message:\n")

for cat in dataframes.keys():
    print("-", cat)

selected_category = input("\nType the category name: ").strip().lower()

if selected_category in dataframes:

    df = dataframes[selected_category]

    print(f"\nLocations available in '{selected_category}':\n")

    for _, row in df.iterrows():
        print(f"- {row['c']} (X: {row['a']}, Y: {row['b']})")

else:
    print("Invalid category selected.")
