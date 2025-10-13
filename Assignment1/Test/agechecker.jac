walker AgeChecker {
    with entry {
        age = 25;

        if (age <= 18) {
            print("Minor");
        }
        elif (age <= 22) {
            print("Young Adult");
        }
        elif (age >= 25) {
            print("Adult");
        }
        else {
            print("Senior");
        }
    }
}
