// Authored lines for the 2D world. Tone: cozy sci-fi student life in a near-future Yangon (GameConcept.md):
// tea, rain, family, mecha classes with generous retries, alien incursions that happen OUTSIDE the city, no violence in the streets.
// Interior people are placed on free floor by build.mjs. `skin` picks one of the 6 NPC palettes (0-5).
const P = (name, skin, role, lines) => ({ name, skin, role, lines })
export const LORE = {
  names: ["Ma Thida", "Ko Zin", "Aye Chan", "Htet Htet", "Min Khant", "Su Su", "Ko Pyae", "Hnin Wai", "Thura", "Nandar", "Phyo", "Ei Mon", "Kyaw Kyaw", "Moe Moe"],
  interiorNpcs: {
    byType: {
      sim: [P("Instructor U Aung Thu", 4, "Piloting instructor", [
        "Welcome to the simulator room. Nobody fails here. You just try again.",
        "Today's exercise: walk the Frame through the wide checkpoints. Slow is fine.",
        "Real deployments are handled by the adult defence corps. Until you are older, you train here, where it is safe.",
      ]), P("Ko Zin", 1, "Classmate", [
        "My pod keeps showing a cyan ring. Is that the sync ring? I never remember.",
        "If you get stuck on the checkpoints, follow my line. I will go slowly.",
      ])],
      classroom: [P("Daw Mya Mya", 3, "Teacher", [
        "Energy management today: slide the marker into the green zone. Easy. Take your time.",
        "Missed a lesson? Come to the catch-up window on Friday. No grade is ever lost for being late.",
      ]), P("Hnin Wai", 0, "Student", [
        "The engineering club is matching parts again. Come, it is like a puzzle with tea.",
        "I heard there is an alert tonight. Do not worry, it is far outside the city.",
      ])],
      dorm: [P("Phyo", 2, "Dorm resident", [
        "Rain on the window and a warm blanket. I am not coming out until class.",
        "The cat from the quad likes this room. Do not tell the warden.",
      ])],
      cafe: [P("U Tin Maung", 5, "Tea shop owner", [
        "Laphet thoke or mohinga? Sit, sit. The plastic stools are the best seats in the city.",
        "The tea is always hot here. Rain or alert, we stay open.",
        "Students pay with smiles on exam week. Do not tell my accountant.",
      ])],
      hangar: [P("Engineer Daw Khin Lay", 3, "Hangar chief", [
        "That is the school Frame. Eight metres of patience. We tune it every week.",
        "Match the part to the slot. If it clicks, it is right. If it does not, it is also fine. Try the next one.",
        "The sync ring glows on the roof when the machine is awake. Pretty, no?",
      ])],
      workshop: [P("Ko Aung Naing", 2, "Robot repair", [
        "A broken delivery drone, a rice cooker and a lamp. All fixed by Thursday.",
        "Hold the part. Feel the weight. Machines are friendly when you listen.",
      ])],
      office: [P("Daw Su Su Hlaing", 0, "Administrator", [
        "Timetables, passes and lost umbrellas. This office handles all three.",
        "Your allowance rises with your credits. Doing badly never ends anything here.",
      ])],
      clinic: [P("Dr. Ei Mon", 1, "Student clinic nurse", [
        "A scraped knee, a headache or exam stress? All welcome. Tea first, then check-up.",
        "After an incursion alert the clinic stays open late. People just like to talk.",
      ])],
      apartment: [P("Ma Thida", 5, "Neighbour", [
        "Four flights up and the lift is still slow. Good for the legs!",
        "The rooftop garden has new orchids. Take a look if you pass the family cafe.",
      ])],
      family: [P("Mum (Daw Khin Khin)", 3, "Your mother, runs the rooftop cafe", [
        "Good morning, little star. Eat something before class. There is tea on the counter.",
        "The cafe is open on the terrace. Help if you like. If you are tired, rest. The regulars will wait.",
        "Whatever happens outside the city, we are home here. Remember that.",
      ]), P("Grandpa U Ba Thein", 4, "Your grandfather", [
        "In my day the sky was empty. Now it has trains, drones and little stars. I like it better.",
        "Sit with me. The rain is coming. I can smell it.",
      ])],
      union: [P("Min Khant", 2, "Union volunteer", [
        "Clubs meet here: robotics, tea, music and the star-watching society.",
        "The festival needs stall helpers. Sign up, there is free mohinga.",
      ])],
      shop: [P("Ko Pyae", 1, "Shopkeeper", [
        "Notebooks, comics and tiny mech stickers. The glow ones are popular.",
        "Reading is the best mission. No alerts, no retries.",
      ])],
      club: [P("Htet Htet", 0, "Arcade regular", [
        "High score on the left cabinet is mine. For now.",
        "Losing is fine. The game says try again. Everything in this city says try again.",
      ])],
      warehouse: [P("Thura", 2, "Dispatcher", [
        "Crates for the market, parcels for the dorms. The drones do the lifting, I do the shouting.",
        "Cold storage is at the back. Mind the fish.",
      ])],
      market: [P("Daw Than Than", 3, "Stall keeper", [
        "Fresh herbs, thanaka bark and little lanterns. Take your pick.",
        "Under the glass roof the rain sounds like music. Stay a while.",
      ]), P("Moe Moe", 0, "Shopper", [
        "I am looking for a longyi that glows in the dark. The tailor says tomorrow.",
        "Everyone meets at the food hall after sunset.",
      ])],
    },
    byId: {},
  },
  ambient: {
    day: [
      "Morning! Have you eaten? Please eat.",
      "Class starts soon. I forgot my notes again.",
      "The skytrain is on time today. Rare!",
      "Look, the cat is sunbathing on the bench.",
      "My Frame practice went better. I only fell over once.",
      "There is fresh mohinga at the commons. Go before it is gone.",
    ],
    dusk: [
      "The lamps are coming on. I love this hour.",
      "Heading to the lake for tea and street snacks.",
      "Did you see the pink palms by the quad? They hum when the wind blows.",
      "Study group at the cafe tonight. Bring snacks.",
    ],
    night: [
      "Quiet night. Stars and neon, what more do you need?",
      "There is an alert on the transit screens, but it is far outside the city. We are fine.",
      "Careful on the stairs, the rail glows but the steps are dark.",
      "The cafe stays open late. Come with us?",
    ],
    rain: ["I can smell rain. Umbrellas out!"],
  },
}
