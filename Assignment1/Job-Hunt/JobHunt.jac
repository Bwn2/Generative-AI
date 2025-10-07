import from byllm.llm { Model }

glob llm = Model(model_name="gemini/gemini-2.5-flash", verbose=False);

def employment_advice(industry: str, location: str, experience: str) -> str by llm();
def market_trends(industry: str, region: str, scale: str) -> str by llm();
def skill_development_recommendations(industry: str, role: str, goals: str) -> str by llm();
def resume_building_tips(industry: str, experience: str, skills: str) -> str by llm();
def interview_preparation(role: str, company: str, experience: str) -> str by llm();
def networking_strategies(industry: str, location: str, goals: str) ->  str by llm();

walker UserProfile {
    has user_name: str;
    has industry: str;
    has location: str;
    has experience: str;
    has role: str;
    has company: str;
    has skills: str;
    has goals: str;
    
    can start with `root entry;
}
with entry:__main__ {
    print("👔 Welcome to EmploMen Career Companion! 👔");
    print("Let's create your personalized career profile...\n");
    
    user_name = input("What's your name? ");
    industry = input("What industry are you in or interested in? ");
    location = input("Where are you located (city/country)? ");
    experience = input("Years of professional experience? ");
    role = input("What is your target job role? ");
    company = input("Any specific companies you're interested in? ");
    skills = input("List your key skills (comma separated): ");
    goals = input("What are your main career goals? ");
    
    print(f"\n✅ Profile created for {user_name}!");
    print("Generating personalized career insights...\n");
    
    root spawn UserProfile(
        user_name=user_name,
        industry=industry,
        location=location,
        experience=experience,
        role=role,
        company=company,
        skills=skills,
        goals=goals
    );
    
    print("=== EMPLOYMENT ADVICE ===");
    employment_advice = employment_advice(industry, location, experience);
    print(employment_advice);
    
    print("\n=== MARKET TRENDS ===");
    trends = market_trends(industry, location, "local");
    print(trends);
    
    print("\n=== SKILL DEVELOPMENT RECOMMENDATIONS ===");
    skill_dev = skill_development_recommendations(industry, role, goals);
    print(skill_dev);
    
    print("\n=== RESUME BUILDING TIPS ===");
    resume_tips = resume_building_tips(industry, experience, skills);
    print(resume_tips);
    
    print("\n=== INTERVIEW PREPARATION ===");
    interview_prep = interview_preparation(role, company, experience);
    print(interview_prep);
    
    print("\n=== NETWORKING STRATEGIES ===");
    networking = networking_strategies(industry, location, goals);
    print(networking);
    
    print("\n🎉 Thank you for using EmploMen Career Companion! Best of luck in your career journey! 🎉");
}