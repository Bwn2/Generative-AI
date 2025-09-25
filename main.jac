def hello_farmer(name: str) -> str {
    return f"Hello {name}, welcome to Farmer's Companion!";
}

with entry {
    user_name = input("Enter your name: ");
    print(hello_farmer(user_name));
}
def base_yield(crop: str) -> float {
    if crop.lower() == "maize" {
        return 2500.0;
    } elif crop.lower() == "beans" {
        return 1000.0;
    } else {
        return 800.0;
    }
}
def yield_estimate(crop: str, rain: float, fert: str) -> float {
    base = base_yield(crop);
    if fert.lower() == "good" {
        factor = 1.2;
    } elif fert.lower() == "poor" {
        factor = 0.8;
    } else {
        factor = 1.0;
    }
    rain_factor = 0.5 + (rain/10.0);
    return base * factor * rain_factor;
}
with entry {
    crop = input("Enter your crop (maize/beans): ");
    rain = float(input("Expected rainfall (0-10): "));
    fert = input("Fertilizer quality (good/average/poor): ");
    est = yield_estimate(crop, rain, fert);
    print(f"Estimated yield for {crop}: ~{int(est)} kg/ha");
}
