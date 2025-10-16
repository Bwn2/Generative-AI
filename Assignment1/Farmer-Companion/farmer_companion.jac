import from byllm.llm { Model }

glob llm = Model(model_name="gemini/gemini-2.5-flash", verbose=False);

def analyze_farm_soil(soil_type: str, location: str, crops: str) -> str by llm();
def diagnose_crop_issue(symptoms: str, crop: str, weather: str) -> str by llm();
def suggest_planting_schedule(region: str, season: str, experience: str) -> str by llm();
def recommend_organic_solutions(problem: str, crop: str, farm_size: str) -> str by llm();
def provide_market_insights(crop: str, region: str, scale: str) -> str by llm();
def irrigation_advice(soil_type: str, climate: str, water_source: str) -> str by llm();
def livestock_integration_advice(crops: str, farm_size: str, resources: str) -> str by llm();

walker FarmerProfile {
    has farmer_name: str;
    has farm_location: str;
    has farm_size: str;
    has soil_type: str;
    has main_crops: str;
    has farming_experience: str;
    has water_source: str;
    has crop: str;
    has symptoms: str;
    
    can start with `root entry{
      print("UserProfile walker initialized!");
    }
}

with entry:__main__ {
    print("🌾 Welcome to AgriSmart Companion! 🌾");
    print("Let's create your personalized farming profile...\n");
    
    farmer_name = input("What's your name? ");
    farm_location = input("Where is your farm located (region/village)? ");
    farm_size = input("What is your farm size (acres/hectares)? ");
    soil_type = input("What is your main soil type (clay/sandy/loamy)? ");
    main_crops = input("What crops do you grow (comma separated)? ");
    farming_experience = input("Years of farming experience? ");
    water_source = input("Main water source (rain/well/river/irrigation)? ");
    crop = input("What is the primary crop you want advice on? ");
    symptoms = input("Describe any issues/symptoms observed in your crop: ");
    
    print(f"\n✅ Profile created for {farmer_name}!");
    print("Generating personalized farming insights...\n");
    
    root spawn FarmerProfile(
        farmer_name=farmer_name,
        farm_location=farm_location,
        farm_size=farm_size,
        soil_type=soil_type,
        main_crops=main_crops,
        farming_experience=farming_experience,
        water_source=water_source,
        crop=crop,
        symptoms=symptoms
    );
    
    
    print("=== SOIL ANALYSIS ===");
    soil_analysis = analyze_farm_soil(soil_type, farm_location, main_crops);
    print(f"Soil advice for {soil_type} soil: {soil_analysis}");
    
    print("\n=== PLANTING SCHEDULE ===");
    planting_schedule = suggest_planting_schedule(farm_location, "current", farming_experience);
    print(f"Planting schedule: {planting_schedule}");

    print("\n=== CROP DIAGNOSIS ===");
    crop_diagnosis = diagnose_crop_issue(symptoms, crop, "current weather");
    print(f"Crop diagnosis: {crop_diagnosis}");

    print("\n=== ORGANIC SOLUTIONS ===");
    organic_solutions = recommend_organic_solutions(symptoms, crop, farm_size); 
    print(f"Organic solutions: {organic_solutions}");


    print("\n=== IRRIGATION ADVICE ===");
    irrigation_tips = irrigation_advice(soil_type, "local", water_source);
    print(f"Water management: {irrigation_tips}");

}