import SwiftUI

struct Article: Identifiable {
    let id: String
    let emoji: String
    let title: String
    let summary: String
    let readMinutes: Int
    let sections: [(heading: String, body: String)]
}

let articles: [Article] = [
    Article(
        id: "understanding", emoji: "🧬",
        title: "Understanding your lipid panel",
        summary: "What total cholesterol, LDL, HDL and triglycerides actually measure.",
        readMinutes: 4,
        sections: [
            ("Total cholesterol", "The sum of all cholesterol carried in your blood. Under 200 mg/dL (5.2 mmol/L) is considered desirable, but the breakdown matters more than the total."),
            ("LDL — the primary target", "Low-density lipoprotein delivers cholesterol to tissues. Excess LDL penetrates artery walls and drives plaque formation, which is why treatment guidelines focus on it. Optimal is under 100 mg/dL (2.6 mmol/L); people with existing heart disease often aim below 70 mg/dL (1.8 mmol/L)."),
            ("HDL — the recycler", "High-density lipoprotein carries cholesterol back to the liver for disposal. Above 60 mg/dL (1.55 mmol/L) is protective. Low HDL — under 40 mg/dL for men, 50 mg/dL for women — is an independent risk factor."),
            ("Triglycerides", "The main form of stored fat in blood. Under 150 mg/dL (1.7 mmol/L) is normal. High levels usually track with diet, alcohol, inactivity and insulin resistance."),
            ("Why fasting matters", "Triglycerides rise sharply after meals, which also distorts calculated LDL. A 9–12 hour fast gives the most comparable numbers, so log whether each test was fasting.")
        ]
    ),
    Article(
        id: "ratios", emoji: "➗",
        title: "The ratios doctors look at",
        summary: "TC/HDL, LDL/HDL and TG/HDL — and what they reveal.",
        readMinutes: 3,
        sections: [
            ("Total/HDL ratio", "Divide total cholesterol by HDL. Below 3.5 is excellent, 3.5–5 is average, above 5 signals elevated risk. It often predicts risk better than total cholesterol alone."),
            ("LDL/HDL ratio", "A direct look at the 'bad vs good' balance. Below 2.5 is ideal; above 3.5 warrants a conversation with your doctor."),
            ("TG/HDL ratio", "Computed on mg/dL values, a ratio above 4 hints at insulin resistance and small, dense LDL particles — the more damaging kind. Below 2 is ideal."),
            ("Non-HDL cholesterol", "Total minus HDL — everything atherogenic in one number. Targets are simply your LDL target plus 30 mg/dL (0.8 mmol/L).")
        ]
    ),
    Article(
        id: "diet", emoji: "🥗",
        title: "Eating to lower LDL",
        summary: "Saturated fat matters more than dietary cholesterol for most people.",
        readMinutes: 5,
        sections: [
            ("The big lever: saturated fat", "Saturated fat (butter, ghee, fatty red meat, full-fat dairy, coconut oil) raises LDL more than cholesterol you eat. The AHA suggests keeping it under ~6% of calories — about 13 g on a 2,000 kcal diet."),
            ("Dietary cholesterol", "Guidelines dropped the strict 300 mg cap for healthy people, but those with diabetes, heart disease or high LDL still benefit from moderation — especially from organ meats, and for some 'hyper-responders', egg yolks."),
            ("Add, don't just remove", "Soluble fiber (oats, beans, psyllium, apples) can cut LDL up to 5–10%. Plant sterols, nuts, olive oil and fatty fish all help. The Mediterranean and Portfolio diets have the strongest evidence."),
            ("Trans fat: zero tolerance", "Partially hydrogenated oils raise LDL and lower HDL. Check labels on packaged bakery items and fried street food."),
            ("Practical swaps", "Ghee → olive or mustard oil • Red meat → fish or legumes • Full-fat dairy → low-fat • Fried snacks → roasted nuts • White bread → whole grain.")
        ]
    ),
    Article(
        id: "exercise", emoji: "🏃",
        title: "Exercise and your lipids",
        summary: "How movement changes HDL, triglycerides and LDL quality.",
        readMinutes: 3,
        sections: [
            ("What exercise does", "Regular aerobic exercise raises HDL by 5–10%, cuts triglycerides by up to 20%, and shifts LDL toward larger, less harmful particles."),
            ("How much", "150 minutes of moderate cardio per week — brisk walking counts — or 75 minutes of vigorous work. Consistency beats intensity."),
            ("Strength training too", "Two resistance sessions weekly improve insulin sensitivity, which lowers triglycerides and the TG/HDL ratio."),
            ("The non-negotiable", "Breaking up sitting time matters independently. Even 2–3 minute movement breaks each hour measurably improve post-meal triglycerides.")
        ]
    ),
    Article(
        id: "statins", emoji: "💊",
        title: "Statins and other treatments",
        summary: "How the main cholesterol medications work — and why adherence matters.",
        readMinutes: 4,
        sections: [
            ("Statins", "They block the liver enzyme that makes cholesterol, forcing the liver to pull LDL from blood. Expect a 30–50% LDL reduction. Muscle aches affect a minority — switching statin or dose usually solves it. Never stop without talking to your doctor."),
            ("Ezetimibe", "Blocks cholesterol absorption in the gut; adds ~15–20% LDL reduction on top of a statin."),
            ("PCSK9 inhibitors", "Injectable antibodies that dramatically lower LDL (50–60%), used when statins aren't enough or aren't tolerated."),
            ("Why adherence matters", "LDL rebounds within weeks of stopping. Missing a third of doses can halve the benefit — that's why LipidCare tracks your dose history."),
            ("Supplements", "Psyllium husk and plant sterols have modest evidence. Red yeast rice contains a natural statin — treat it like medication and tell your doctor.")
        ]
    ),
    Article(
        id: "risk-factors", emoji: "⚠️",
        title: "Beyond cholesterol: your total risk",
        summary: "Blood pressure, smoking, diabetes and family history multiply lipid risk.",
        readMinutes: 3,
        sections: [
            ("Risk is multiplicative", "An LDL of 130 mg/dL means something very different for a smoker with hypertension than for someone with no other risk factors. Doctors treat targets to your overall risk, not a universal number."),
            ("The modifiables", "Smoking roughly doubles cardiovascular risk and lowers HDL. Each 10 mmHg of blood pressure reduction cuts events ~20%. Weight loss of 5–10% improves the whole lipid panel."),
            ("The non-modifiables", "Age, male sex and family history of early heart disease (father/brother before 55, mother/sister before 65) raise baseline risk — making the modifiable factors more important, not less."),
            ("When to test", "Adults should check a lipid panel every 4–6 years; annually if abnormal, on treatment or with risk factors. LipidCare can remind you.")
        ]
    ),
    Article(
        id: "reading-results", emoji: "🔬",
        title: "How to read your lab report",
        summary: "Calculated vs measured LDL, units, and why results vary.",
        readMinutes: 3,
        sections: [
            ("Calculated LDL", "Most labs compute LDL with the Friedewald equation: Total − HDL − TG/5. It's unreliable when triglycerides exceed 400 mg/dL — LipidCare flags calculated values."),
            ("mg/dL vs mmol/L", "US labs report mg/dL, most other countries mmol/L. Multiply mmol/L by 38.7 (cholesterol) or 88.6 (triglycerides) to convert. LipidCare handles this automatically in Settings."),
            ("Normal variation", "Your cholesterol naturally fluctuates 5–10% day to day, plus seasonal swings. One borderline result is a data point, not a diagnosis — trends over months are what matter."),
            ("Same lab, same conditions", "For comparable trends, test at the same lab, at the same time of day, with consistent fasting.")
        ]
    ),
    Article(
        id: "myths", emoji: "🔎",
        title: "Cholesterol myths, fact-checked",
        summary: "Eggs, 'natural' cures, thin people and other common misconceptions.",
        readMinutes: 3,
        sections: [
            ("“I'm thin, so I'm fine”", "Genetics set much of your cholesterol. Plenty of lean, active people have familial hypercholesterolemia — that's why testing matters regardless of weight."),
            ("“Eggs are forbidden”", "For most people an egg a day doesn't move LDL meaningfully; the bacon and butter beside it matter more. People with diabetes or high LDL should still moderate yolks."),
            ("“I'd feel it if it were high”", "High cholesterol has zero symptoms. The first 'symptom' can be a heart attack — testing is the only way to know."),
            ("“Once it's normal, I can stop”", "Whether through diet or medication, cholesterol returns when the intervention stops. Think permanent habits, not temporary fixes."),
            ("“Natural means safe”", "Unregulated supplements can interact with statins or contain unlisted actives. Always tell your doctor everything you take.")
        ]
    )
]

struct LearnView: View {
    var body: some View {
        List(articles) { article in
            NavigationLink {
                ArticleView(article: article)
            } label: {
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(Theme.crimson.opacity(0.12))
                            .frame(width: 46, height: 46)
                        Text(article.emoji).font(.title3)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(article.title).font(.subheadline.weight(.semibold))
                        Text(article.summary)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("\(article.readMinutes) min read")
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(Theme.crimson)
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle("Learn")
    }
}

struct ArticleView: View {
    let article: Article

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                Text(article.title).font(.title.bold())
                Text("\(article.readMinutes) min read")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(Theme.crimson)
                ForEach(article.sections, id: \.heading) { section in
                    Text(section.heading)
                        .font(.headline)
                        .padding(.top, 10)
                    Text(section.body)
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
                Text("This content is educational and not a substitute for professional medical advice.")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .padding(.top, 16)
            }
            .padding(20)
        }
        .navigationTitle(article.emoji)
        .navigationBarTitleDisplayMode(.inline)
    }
}
