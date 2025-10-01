# Singleton to store HDE curriculum related tables/variables

extends Node

# Called when the node enters the scene tree for the first time.
#func _ready():
#	pass # Replace with function body.

# traits for elcitraps
@export var traits = [
	["red", "Painting"], ["blue", "Law"], ["green", "Biology"],
	["red", "Singing"], ["blue", "Planting"], ["green", "Math"],
	["red", "Music"], ["blue", "Cooking"], ["green", "Physics"],
	["red", "Acting"], ["blue", "Building"], ["green", "Geology"],
	["red", "Sports"], ["blue", "Speaking"], ["green", "Astronomy"]
]

# choices for koi pond venn diagram level
@export var choices = [
	["y", "This is a yellow choice."], 
	["r", "Now a red choice!"],
	["y", "Yet another yellow choice!"],
	["b", "Ooh a blue choice."],
	["b", "And another blue choice!"],
	["yb", "Ooh a yellow and blue choice!"],
	["br", "And a red and blue choice."],
	["ybr", "A yellow, blue, and red choice!"],
	["y", "Drinking lots of clean water."],
	["ybr", "Growing a garden with others."],
	["yr", "Exercising."],
	["yr", "Learning to swim."],
	["y", "Learning to add numbers."],
	["br", "Playing games with friends."],
	["b", "Wishing someone a happy birthday."],
	["yb", "Learning about an archeology site."],
	["y", "Eating your vegetables."],
	["r", "Painting a picture."],
	["br", "Playing piano for others."],
	["ybr", "Playing in a soccer game."]
]

# dictionary mapping numbers to elements for dominos
# key: "top_number+bottomnumber", item: [top element, bottom element]
@export var domino_dict = {
	"00": ["", ""],
	"01": ["", "Copper"],
	"02": ["", "Lead"],
	"03": ["", "Carbon"],
	"04": ["", "Nickel"],
	"05": ["", "Cobalt"],
	"06": ["", "Aluminum"],
	"07": ["", "Cadmium"],
	"08": ["", "Iridium"],
	"09": ["", "Gold"],
	"11": ["Tin", "Copper"],
	"12": ["Tin", "Antimony"],
	"13": ["Copper", "Iron"],
	"14": ["Tin", "Titanium"],
	"15": ["Copper", "Chromium"],
	"16": ["Tin", "Magnesium"],
	"17": ["Copper", "Tellurium"],
	"18": ["Tin", "Platinum"],
	"19": ["Copper", "Silver"],
	"22": ["Lead", "Antimony"],
	"23": ["Lead", "Carbon"],
	"24": ["Antimony", "Nickel"],
	"25": ["Lead", "Cobalt"],
	"26": ["Antimony", "Aluminum"],
	"27": ["Lead", "Cadmium"],
	"28": ["Antimony", "Iridium"],
	"29": ["Lead", "Gold"],
	"33": ["Iron", "Carbon"],
	"34": ["Iron", "Titanium"],
	"35": ["Carbon", "Chromium"],
	"36": ["Iron", "Magnesium"],
	"37": ["Carbon", "Tellurium"],
	"38": ["Iron", "Platinum"],
	"39": ["Carbon", "Silver"],
	"44": ["Nickel", "Titanium"],
	"45": ["Nickel", "Cobalt"],
	"46": ["Titanium", "Aluminum"],
	"47": ["Nickel", "Cadmium"],
	"48": ["Titanium", "Iridium"],
	"49": ["Nickel", "Gold"],
	"55": ["Chromium", "Cobalt"],
	"56": ["Chromium", "Magnesium"],
	"57": ["Cobalt", "Tellurium"],
	"58": ["Chromium", "Platinum"],
	"59": ["Cobalt", "Silver"],
	"66": ["Aluminum", "Magnesium"],
	"67": ["Aluminum", "Cadmium"],
	"68": ["Magnesium", "Iridium"],
	"69": ["Aluminum", "Gold"],
	"77": ["Tellurium", "Cadmium"],
	"78": ["Tellurium", "Platinum"],
	"79": ["Cadmium", "Silver"],
	"88": ["Iridium", "Platinum"],
	"89": ["Iridium", "Gold"],
	"99": ["Silver", "Gold"]
}

# maps element to corresponding alloy
@export var element_to_alloy = {
	"Copper": "Bronze",
	"Tin": "Bronze",
	"Lead": "Antimonial Lead",
	"Antimony": "Antimonial Lead",
	"Carbon": "Steel",
	"Iron": "Steel",
	"Nickel": "Nitinol",
	"Titanium": "Nitinol",
	"Cobalt": "Vitalium",
	"Chromium": "Vitalium",
	"Aluminum": "Magnalium",
	"Magnesium": "Magnalium",
	"Cadmium": "Cadmium-Telluride",
	"Tellurium": "Cadmium-Telluride",
	"Iridium": "Platinum-Iridium",
	"Platinum": "Platinum-Iridium",
	"Gold": "Electrum",
	"Silver": "Electrum"
}

# maps alloy to description of alloy
@export var alloy_table = {
	"Bronze": "Combining Copper (Love) with Tin (Order) results in Bronze (A Loving Prepared Environment).",
	"Antimonial Lead": "Combining Antimony (Joy) with Lead (Focus) results in Antimonial Lead (Energy).",
	"Steel": "Combining Carbon (Care) with Iron (Safety) results in Steel (Stability).",
	"Nitinol": "Combining Titanium (Patience) with Nickel (Experiences) results in Nitinol (Perception).",
	"Vitalium": "Combining Cobalt (Goodness) with Chromium (Skills) results in Vitalium (Ability).",
	"Magnalium": "Combining Magnesium (Self-Control) with Aluminum (Purpose) results in Magnalium (Resilience).",
	"Cadmium-Telluride": "Combining Cadmium (Trust / Hope) with Tellurium (Knowledge) results in Cadmium-Telluride (Discernment).",
	"Platinum-Iridium": "Combining Platinum (Kindness) with Iridium (Understanding) results in Platinum-Iridium (Responsibility).",
	"Electrum": "Combining Gold (Gentleness) with Silver (Respect) results in Electrum (Relationship)."
}

# maps round number and domino number to title of footprint tile
# key: "round_number+domino_number", item: Title of footprint tile
# TODO: <add more footprint tiles to footprint_tile_table, then remove footprint_title_table and footprint_text_table as at that point, they are redundant>
@export var footprint_title_table = {
	"00": "Our Earth",
	"01": "Dinosaurs, Mastodons, and Megafauna",
	"02": "Our Earliest Ancestors",
	"03": "Tools",
	"04": "Many Branches on Our Human Tree",
	"05": "Fire and Language",
	"06": "How We Date Human Artifacts",
	"07": "Early Beads and Haplogroups",
	"08": "Migration and Volcanos",
	"09": "Human Trait Gumballs",
	"10": "Music and Sewing",
	"11": "Wolves and Cubs, Cats and Kittens",
	"12": "The First Fishing Trips",
	"13": "Melting Glaciers",
	"14": "Our First Battles",
	"15": "Growing Gardens / Return of Glaciers",
	"16": "Gobekli Tepe",
	"17": "Bye Glaciers (again), Hello Sheep Herding",
	"18": "Bread and Dominos",
	"19": "Clay and Catalhoyuk",
	"20": "Malachite to Copper",
	"21": "Human Skin",
	"22": "Young Earth Theory",
	"23": "Drums and Kilns",
	"24": "Our First Towns",
	"25": "Differing Human Opinions?",
	"26": "Duggarland and Indus River Valley",
	"27": "Cluck Cluck! Chickens and Wheels",
	"28": "Tulips and Horses",
	"29": "The First Written Words",
	"30": "Star Charts and Stonehenge",
	"31": "Sailboats",
	"32": "Timelines and Milk",
	"33": "Pearls and Pigeons",
	"34": "Chocolate and Bricks",
	"35": "First Laws and Governments",
	"36": "Pyramids, Games, Bees, and Medicine",
	"37": "Falcons and the First Minoan Palaces",
	"38": "Judaism and Horses",
	"39": "Hinduism and the New Kindgom of Egypt",
	"40": "Iron!",
	"41": "The First Olympics",
	"42": "Buddhism and Coins",
	"43": "Waterwheels and Blast Furnaces",
	"44": "Strong Concrete Called Pozzolana",
	"45": "Widespread Glassmaking",
	"46": "Steam Power",
	"47": "Our First Bound Books",
	"48": "Horseshoes and Attila",
	"49": "Islam and Tang",
	"50": "The Viking Clinker Built Ships",
	"51": "Eye Glasses, the Magnetic Compass, and the Song Dynasty",
	"52": "The Printing Press",
	"53": "Telescopes, Microscopes, and the First Piston Engine",
	"54": "Steel Mills and Darwin's Thoughts",
	"55": "Germs, Telegraphs, and Telephones",
	"56": "Phonographs, Zippers, Ballpoint Pens, and Cars!",
	"57": "Radio, TV, and Lift Off!",
	"58": "Haplogroups and Space Stations",
	"59": "Inventions and Cures of Our Future",
}

# maps round number and domino number to description of footprint tile
# key: "round_number+domino_number", item: Description of footprint tile
# TODO: <add more footprint tiles to footprint_tile_table, then remove footprint_title_table and footprint_text_table as at that point, they are redundant>
@export var footprint_text_table = {
	"00": "Our Earth",
	"01": "Dinosaurs, Mastodons, and Megafauna",
	"02": "Our Earliest Ancestors",
	"03": "Tools",
	"04": "Many Branches on Our Human Tree",
	"05": "Fire and Language",
	"06": "How We Date Human Artifacts",
	"07": "Early Beads and Haplogroups",
	"08": "Migration and Volcanos",
	"09": "Human Trait Gumballs",
	"10": "Music and Sewing",
	"11": "Wolves and Cubs, Cats and Kittens",
	"12": "The First Fishing Trips",
	"13": "Melting Glaciers",
	"14": "Our First Battles",
	"15": "Growing Gardens / Return of Glaciers",
	"16": "Gobekli Tepe",
	"17": "Bye Glaciers (again), Hello Sheep Herding",
	"18": "Bread and Dominos",
	"19": "Clay and Catalhoyuk",
	"20": "Malachite to Copper",
	"21": "Human Skin",
	"22": "Young Earth Theory",
	"23": "Drums and Kilns",
	"24": "Our First Towns",
	"25": "Differing Human Opinions?",
	"26": "Duggarland and Indus River Valley",
	"27": "Cluck Cluck! Chickens and Wheels",
	"28": "Tulips and Horses",
	"29": "The First Written Words",
	"30": "Star Charts and Stonehenge",
	"31": "Sailboats",
	"32": "Timelines and Milk",
	"33": "Pearls and Pigeons",
	"34": "Chocolate and Bricks",
	"35": "First Laws and Governments",
	"36": "Pyramids, Games, Bees, and Medicine",
	"37": "Falcons and the First Minoan Palaces",
	"38": "Judaism and Horses",
	"39": "Hinduism and the New Kindgom of Egypt",
	"40": "Iron!",
	"41": "The First Olympics",
	"42": "Buddhism and Coins",
	"43": "Waterwheels and Blast Furnaces",
	"44": "Strong Concrete Called Pozzolana",
	"45": "Widespread Glassmaking",
	"46": "Steam Power",
	"47": "Our First Bound Books",
	"48": "Horseshoes and Attila",
	"49": "Islam and Tang",
	"50": "The Viking Clinker Built Ships",
	"51": "Eye Glasses, the Magnetic Compass, and the Song Dynasty",
	"52": "The Printing Press",
	"53": "Telescopes, Microscopes, and the First Piston Engine",
	"54": "Steel Mills and Darwin's Thoughts",
	"55": "Germs, Telegraphs, and Telephones",
	"56": "Phonographs, Zippers, Ballpoint Pens, and Cars!",
	"57": "Radio, TV, and Lift Off!",
	"58": "Haplogroups and Space Stations",
	"59": "Inventions and Cures of Our Future",
}

# TODO: <load the footprint_tile_table dynamically (potentially with a non-comma-delimited .csv file) for extensibility>
# TODO: <add more footprint tiles to footprint_tile_table, then remove footprint_title_table and footprint_text_table as at that point, they are redundant>
# TODO: <check with Stephanie about teams for each footprint tile as only the first round's tiles list teams>
## Footprint Tile Table that maps all information about a footprint tile by it's index
## For each index, the information about the corresponding footprint tile is stored in the following format:
## title, mini-doc, link names (which are usually present in external_link_dict), rhyme, teams
const footprint_tile_table = [
# FOOTPRINT TILES FOR ROUND 0
	[ # Footprint tile 0
		"Our Earth",
		"Scientists believe our Earth was formed around 4,600 years ago. Not everyone believes this is true. There are many different beliefs about how and when the earth was formed. In this game we will include several perspectives on this and other beliefs.\nComparing ideas and opinions in a respectful and fun way as we solve the mysteries of life on Earth is part of working together in our human family.\nThese footprint tiles include beliefs about events from different points of view including different faiths and from science too. It is good to hear and think critically about what others believe in order to determine what you believe is true. Here are some of the leading theories about the formation of the earth:",
		["The Frame Concept", "Formation of the Earth", "Where Did Earth Come From?", "Hindu Creation Story"],
		"Be it creation, mutation, or both,\nwe are here on this earth together,\nWho will sing, learn, and build, who will help and not harm,\nthrough the sunshine and storms we all weather?",
		["Geology"],
	],
	[ # Footprint tile 1
		"Dinosaurs, Mastodons, and Megafauna",
		"Dinosaur bones have been found all over our Earth.\nAgain and again scientists find bones from lower layers of dirt and rock that reveal when they lived because each of the layers on top of them represents year after year of settled plant and sediment material. This and many kinds of dating indicate that the dinosaurs lived 248-65 million years ago. There are humans who do not believe these dating methods are accurate and that is ok. We are still solving all the mysteries of life on Earth and our understanding could change. Maybe you can help solve some of them!",
		["From the Fall of Dinos to the Rise of Humans"],
		"From the homes in our caves to homes of today, we humans sure gained rad skills of survival.\n Be the start of our world, seven days or seven billion,\nwe've come too far to waste time being rivals.",
		["Geology", "Archeology"],
	],
	[ # Footprint tile 2
		"Our Earliest Ancestors",
		"3.3 million years ago the first stone tools were made by very ancient humans. These humans were not Homo Sapiens, yet they made and used tools using stones. DNA evidence from thousands of these bones found in Africa reveals that these early humans walked upright. Scientists who study human origins have discovered that there were at least 36 different kinds of humanlike people in a group scientists have named Hominini. These hominids lived on our earth 3.3 million years before any evidence our species of Hominid called Homo Sapiens lived on our Earth.\nWe are making progress on unraveling the mystery of how the DNA of these early humans precedes our Homo Sapien DNA.\nYou may want to learn more about this field of study and help solve the mysteries about our human origins. If this information offends you, try to think of it as information about what these scientists believe and understand why they believe it. A big part of this game is not only learning about human advances and setbacks but also how to learn and understand the different ways other Sapiens like you think and believe things that you disagree with. The goal is to hear and understand another person's truth without feeling the threat that we have to believe the same thing that person believes... all while speaking our own truth as others listen and understand us without choosing to feel the threat that they have to believe the same way we do. The hope of this game is to spark a hunger to listen with mutual respect for each-other's beliefs without feeling threatened by different beliefs, all for the sake of cooperation and discovery of mutually satisfying compromises for the well-being of all individuals in our communities and Earth. When other's beliefs and choices impose and prevent our own belief's and choices, problems arise.\nFinding solutions that allow for beliefs and choices to exist while they don't prevent the same for others can make for healthier communities.",
		["Earliest Human Faces", "Human Origins"],
		"Two million years ago our early human ancestors started making tools out of stones,\nyes, we've found thousands of beautiful hand axes.\nIt showed an ability to plan, in our early minds, a specific design.\nSuch smarts we had while living only in caves, jungles, and savanna grasses!",
		["Archeology", "Anthropology"],
	],
	[ # Footprint tile 3
		"Tools",
		"500,000 years ago, humans learned to use bones, string, and sticks, to make our spears.\nAt this time there were many branches of early humans. One of these groups (called a genus) is named Homo, and there are three branches (called species) that we will talk more about in this game. They are Sapiens, Neanderthals, Denisovians. The DNA of all three of these species survive in living humans today. All three made tools, shelters, and art too.",
		["Neanderthal Denisovians", "Human Origins", "The Evolving Story of Human Evolution", "Large Mammal Extinction Linked to Prehistoric Humans"],
		"500,000 years ago we fashioned bones, string and sticks, to make our first spears!\nOur first throwing weapons, yes, we were on our way to being true engineers.",
		["Archeology", "Anthropology"],
	],
	[ # Footprint tile 4
		"Many Branches on Our Human Tree",
		"Our species was created when a genetic change occured and as a result our ancestors' appearance and behavior changed from their ancestors. This split away is called a divergence and when this happens a new species is created.",
		["New Species", "Homo Sapiens", "Early Trade", "Hand Axe and Pigments", "How To Make A Prehistoric Flint Axe", "How a New Species of Ancestors is Changing Our Theory of Human Evolution", "Solving Mysteries with Archaeologists!", "Hominid Paleobiology"],
		"Archeologists digging in Kenya at the Olorgesailie Basin,\ndiscovered that 300,000 year old humans made hand axes and a kind of color pigment crayon.\nThey created a long distance network of trade,\nexchanging these early goods that they made.",
		["Archeology", "Anthropology"],
	],
	[ # Footprint tile 5
		"Fire and Language",
		"Understanding how dating methods work is an important part of getting children and teens engaged in the process of solving the mysteries of our human family. This understanding is foundational to helping students gaining an identity as a member of humanity that has been profressing through history for thousands of years. This content includes information about who we humans were in our earliest cultures to allow students the ability to form a mindset that \"we are all in this global community together.\"",
		["How Does Radiocarbon Dating Work?", "Human Language", "Secrets of the Stone Age", "Tracing Human Migration", "Carbon Comes From the Word Charcoal", "Ages of Each Haplogroup"],
		"DNA evidence from thousands of found bones and our many dating methods like, radio carbon dating, uranium series dating, electron spin resonance dating, and thermoluminescence,\nall show us exciting findings about our early and basic human essence.\nWe can test human bones and skulls like ours that show an order...\nWe can even tell how they lived to the ages of adulthood, childhood, and adolescence.",
		["Archeology", "Anthropology"],
	],
	[ # Footprint tile 6
		"How We Date Human Artifacts",
		"We modern humans can trace our lineage back to a small group of humans through our DNA Haplogroups. Our early family members worked together and continued to trade beads and used ochre paint for our bodies and cave homes.\nArcheology is the study of artifacts that help us learn more about how our human ancestors lived in the past.\nFire and spears are two examples of the kinds of evidence archeologists use to learn about our species' past.",
		["The Journey of Your Past", "Why We Speak", "The Journey of Man - A Genetic Odyssey"],
		"Every human today has cool DNA\nthat links up to our shared African mother and father. We are all their many-times great-grandchildren. We're all family; of that we can be glad!\n70,000 years ago we made our first jewelry beads out of ostrich egg and sea shells.\nWith ochre rock we made paint for our bodies and cave walls where we dwelled.",
		["Archeology", "Anthropology", "Genetics"],
	],
	[ # Footprint tile 7
		"Early Beads and Haplogroups",
		"100,000 years ago our ancient ancestors started building stone circles. The oldest one found is in Nabta Playa in modern day Egypt. It is a mystery why we created these circles of standing stones but scientists believe it probably had an astrological function. This means the people were using the stones to keep track of the stars, moon, and sun. Sometimes they called these stones the Giants' Dance. By this point in history we noticed that the sun always rises and sets along the East and West horizon line. By creating a circle of stones, early Sapiens were able to track the path of the sun with the shadows made by the stones on the ground. The shadows changed a little each day throughout the year giving us an early calendar for determining planting and harvesting during different seasons of that year. Scientists also believe the stone circles may have been a kind of home where ancient people returned after migration to gather for trade, funerals, courtship, celebrating, and feasting.",
		["First Standing Stones", "The Origins of Human Society", "African Stone Circles?", "African Stonehenge", "Stone Circles of Senegambia", "The Earth 100,000 Years Ago"],
		"Our branch of \"Sapiens\", we will call our human family for short,\nstarted making standing stone circles sunk deep in the earth for support.\nWhy did we do this? It is a mystery indeed,\narcheologists think they use them as calendars, or meeting places to trade tools, and seeds.",
		["Archeology", "Anthropology", "Genetics"],
	],
	[ # Footprint tile 8
		"Migration and Volcanos",
		"There are various theories about just where the first Sapiens walked out of Africa. Of course this group of people did not know they were leaving a continent. They were following the food sources found through hunting and gathering and seeking favorable living conditions. This content discusses those theories in the context of building a mindset of how \"us\" Sapiens were on the move toward Europe and Asia while some of our family stayed in Africa.",
		["Map Shows How Humans Migrated Across the Globe", "Where All Modern Humans Arose", "Early Human Migration Around the World Far Earlier Than Scientists Thought", "When We Took Over the World"],
		"60,000 years ago a group of first early human Sapiens walked north out of Africa leaving their family and friends.\nDid they mean to meet back one day? If they did they got lost, for they ended up in far separate lands.",
		["Archeology", "Anthropology", "Genetics"],
	],
	[ # Footprint tile 9
		"Human Trait Gumballs",
		"Modern day humans' descent emerged out of Africa at about 50-6000 years ago. One thing we know for sure about the Sapiens who went north out of Africa was that they \"met\" up with other species from the genus Homo - the Neanderthals and Denisovians. How do we know? Their DNA exists in the genomes of modern humans whose ancestors had relations with them. This evidence was discovered through the science of Paleogenetics Archaeogenetics which provide \"detailed information about genetic relationships, geographical origin, selective processes or genetic structure of historical and prehistorical human, plant, animal, or even pathogen populations using only miniscule samples.\"",
		["Department of Archaeogenetics", "Archaic Genomics", "Pioneer of Paleogenetics", "The Meeting of Homo Sapiens, Neanderthals, Denisovians", "Mystery of the Human Bottleneck", "Ancient DNA and the New Science of the Human Past"],
		"The group who left Africa met up with the Neanderthals and Denisovians,\nlater somehow they lost many people and that means loss of alleles in their gen group from things likehunger or drought.\nLike a bottleneck effect,\nsome alleles got stuck as others lived on... think of colored jellybeans stuck in a bottle poured out.\nAbout 50,000 years ago, the second group of humans left Africa and walked north toward Europe and Asia.\nA little later the Neanderthals sadly became extinct. About this time, we humans developed a few new phenotypes, like lighter skin. See we are the same race it's just our skin, like our clothes, makes us distinct.\nAt 50,000 years ago humans had reached Australia!",
		[],
	],
# FOOTPRINT TILES FOR ROUND 1
	[ # Footprint tile 10
		"Music and Sewing",
		"35,000 years ago, Sapiens made the first bone needles. We figured out how to use fibers to make clothes, bags, baskets, nets, and baby carriers. The first musical instrument was made... a flute! The first strands were twisted into rope. A standing lion figurine called Lowenmensch (Lion-man) was made by a human in the Aurignacian culture. It is the oldest figurine art found thus far. It is dated between 35,000 and 40,000 years old.",
		["Living in the Stone Age: Music", "Collective Learning", "Caveman Flutists?", "Fashion in Rock Art", "Migrations Into Europe"],
		"35,000 years ago we humans started making many bone needles in replica.\nWith new warm clothes we could now cross the cold Bering strait to walk into the Americas.\nThe first wild dogs and cats became our friends.\nAnd the first musical instrument, a flute, started a new melodious trend!",
		[],
	],
	[ # Footprint tile 11
		"Wolves and Cubs, Cats and Kittens",
		"25,000 years ago we built homes using mammoth bones and rocks that made a little hamlt in the modern day Czech Republic. This is the oldest permanent human settleement that has been found so far. In central Europe the first ovens were used to cook mammoth meat in about 29,000 BC.",
		["Domesticated Dogs"],
		"25,000 years ago using rocks, logs, and mammoth bones, human families worked to make our first permanent homes.\nWe also learned how to cook mammoth meat by building fires in deep pits. These were our first ovens, what do you think they used as oven mitts?\nBy now there are hundreds of pets to pat! Everyone can choose a dog or cat. (10 points each)",
		[],
	],
	[ # Footprint tile 12
		"The First Fishing Trips",
		"24,000 years ago, a human made the first fishing hook and tied it to string to catch fish. This helped us eat more of this vitamin-D-rich food which allowed us to survive in northern climates. Humans crossed the Bering Strait from modern day Russia to modern day Alaska.",
		["Beringia", "How to Make a Fish Hook From Bone", "First Humans Enter the Americas"],
		"Slippery, fast, and crazy hard to catch, a hook makes fish easier to snatch.",
		[],
	],
	[ # Footprint tile 13
		"Melting Glaciers Mean New Ways of Living",
		"This is one of the many phases of time when our Earth's glaciers melt. The climate begins to change at this time in northern Africa, causing it to become humid and fertile. 16,000 years ago a human sculpted Wisent (European bison) inside the cave, now know n as Le Tuc d'Audoubert, and painted animal scenes in Altimira cave in the French Pyrenees.",
		["Art of Altamira Cave"],
		"After the coldest Ice Age days, going back 15,000 years,\nthe glaciers began to finally melt and the world's climates became more humid with the extra water in the atmosphere.",
		[],
	],
	[ # Footprint tile 14
		"Our First Battles",
		"Archeologists found evidence of warfare in an area close to the Nile River. There is debate about the details of what happened with the people who lived there. Many scientists believe that the lack of food and the struggle associated with the colder climate was the cause of the warfare. This is a problem that still causes conflicts and is in need of solution today.",
		["Jebel Sahaba"],
		"14,000 years ago, at Jebel Sahaba, there sadly seemed to be perhaps,\nthe first battle between humans as a drought caused our resources to collapse.\nArcheologists think it may have been from conflict over land and food,\nfor basic survival problems even then caused humans to feud.",
		[],
	],
	[ # Footprint tile 15
		"We Learn to Grow Gardens and the Glaciers Are Back!",
		"During this time, a group of hunter-gatherers named the Natufians settled in an area called the Levant and started to grow rye seeds to make bread. An asteroid hits the Earth causing glaciers to grow in size.",
		["Natufians", "Ancient Eurasians Heterogeneity", "Natufians and Africans", "Evidence of a Planet-Cooling Asteroid 12,900 Years Ago"],
		"As things were warming up, humans had to endure a sudden drop in global temperatures that lasted 1200 years!\nCaused by the impact and debris of a comet 12,900 years ago, the mass extinctions and floods caused much hardship and fear.",
		[],
	],
	[ # Footprint tile 16
		"The First Human Building Project - Gobekli Tepe",
		"The first known structures made of stone for what appears to be for religious or ceremonial purposes are built in modern day Turkey.",
		["Gobekli Tepe", "Geometry Guided the Construction of Gobekli Tepe"],
		"10,000 BC - that's 12,000 years ago - some people built the oldest building with huge stones at Gobekli Tepe!\nTheir hunting skills gave them enough food and time to build with stone day to day.",
		[],
	],
	[ # Footprint tile 17
		"Bye-Bye Again Glaciers, Hello Sheep Herding",
		"Finally the Ice Age called the Younger Dryas was over and the Earth warmed again after 1,200 years. This was the last of many ice ages.\nPeople groups migrated across many miles, hunting and gathering food. Gathering stone for tools is a widespread practice now.",
		["Younger Dryas"],
		"This bitter cold era was named the Younger Dryas, after a flower that survived and flourished...\nfinally the cold ended and humans recovered from starvation and again found ways to be nourished!",
		[],
	],
	[ # Footprint tile 18
		"Bread and Dominos",
		"The Megafauna and Mammoths become extinct. Now that the last Ice Age is over, we are able to collect more seeds and grow larger fields of wheat, millet and rice.",
		["The Agriculture Revolution", "The History of Farming"],
		"10,000 years ago, the warming climate allowed us to collect more seeds from grasses and plant crops for the first time.\nThis is called agriculture, which gave us time to rest, play, build and perhaps make up some rhymes!\nThis new way of living began in the Fertile Crescent and slowly became widespread.\nLife was different with rice, millet, sorghum, and the wheat that brought us the first bread.",
		[],
	],
	[ # Footprint tile 19
		"Clay and Catalhoyuk",
		"All other species from the genus Homo become extinct and Sapiens are the only species of present day descendants. During this time, we Sapiens built a community or settlement called Catalhoyuk in Anatolia. Figs are cultivated in the Levant. We are using clay to make bowls and food storage containers.",
		["Origins of Clay", "The Invention of Pottery", "How is Clay Made"],
		"9,000 to 8,000 years ago, we humans began to make clay pots, to keep our foods and fermented drink that came from grain.\nIt was another innovation that eased human struggle and relieved survival's strain. 8,000 years ago, there is evidence of copper smelting in Plocnik and some other places,\nbut this idea is not used widdespread for another 4,000 years, it stays limited to these few cases.",
		[],
	],
# FOOTPRINT TILES FOR ROUND 2
	[ # Footprint tile 20
		"Malachite to Copper",
		"The Stone Age begins to transition into the Copper Age, also known as the Chalcolithic. No one knows how or who first discovered smelting; the process of crushing ore (rock that contains bits of metal) and heating it to high temperatures would produce a new material - metal. This discovery greatly improved the tools, weapons, and jewelry we used and changed the way we lived in many ways.",
		["From Stone to Bronze", "Revolutions: The Age of Metal and the Evolution of European Civilization", "Timeline of Metallurgy", "The History of Copper"],
		"Humans discovered one day or night,\nthat there is copper inside green rocks called malachite.\nIf you crush it to powder and heat it in fire,\nout comes shiny useful metal that we still use today for wire!\nWe do not know the name of the man or woman who,\ndiscovered this, shared, and changed our history from any point of view.",
		[],
	],
	[ # Footprint tile 21
		"Human Skin",
		"An archeology site in Sweden reveals that 7,700 years ago, 7 individuals from the area had light skin variants (variants slc24a5 and slc452a). Their ancestors came from Africa but their skin changed to bring vitamin D so they could stay up north to live, eat, and play. Persecution basaed on skin color is as silly as treating people differently because of the color of their clothing... for once our skin was all the same. Nina Jablonski explains how our genes tell the story and how color persecution is a real shame. Approximately 8,000 years ago, humans discovered that gold was useful for jewelry.",
		["The Evolution and Meanings of Human Skin Color", "Gold Jewelry"],
		# TODO: <footprint tile 21 did not come with a unique rhyme. Its rhyme in the google doc was the same as footprint tile 19>
		"",
		[],
	],
	[ # Footprint tile 22
		"Young Earth Theory",
		"There are many difference in beliefs about the origin of our earth within our Sapiens family. The stories and ideas about how humans were created vary greatly. Respecting the differences with the mindset that it's ok for us to believe differently and accept these differences with a mindset of mutual respect and anticipation that one day the mysteries will be solved. A continual faith that this evidence-based discovery of knowledge that allows us to agree on the exact details of how we and our home were creatted will come along in due time and creates a mindset of coexistence as we wait and live together... Science does not exclude an intelligent creator, and a creator does not exclude science.",
		["Creation or Evolution", "Origins of the Biblical Philistines?"],
		"Many people believe the universe spontaneously existed without an intelligent designer,\nwhile others believe in a creator who set life's elements a'rollin' and continues influence and care for us as a kind of life-refiner.\nIt's really ok to be respectfully aware,\nof all beliefs so we can better cope and thrive through the struggles we all share.\nOne day we may have perfect proof of which of these is true,\nfor now we can treasure our own personal truth and respect others' ideas too.",
		[],
	],
	[ # Footprint tile 23
		"Drums and Kilns",
		"Rock Gongs were made from large boulders with a high iron content. Divots were carved in them to create different tones. We made music by tapping with other smaller rocks. The first kilns were made by putting pottery in a deep hole and building a fire around it for specific amounts of time. This process hardened the dried clay making it harder and more durable for plates, cups, bowls, food storage containers, and even jewelry.",
		["FOLI (There is No Movement Without Rhythm)", "The First Rock Project", "Lost Kingdoms of Africa: Nubia", "Early Evidence of Drum History", "Poderosa Aainjala - 150 Tambores", "Rock Art in the Green Sahara", "How Banning the African Drum Gave Birth to American Music", "What is African Rock Art?", "Fashion in African Rock Art", "Rock Music Rock Art", "The Origins of Music", "When the Sahara Was Green"],
		"Drumming happens on a tree, our tummies, our laps.\nA drum is with our hands in a clap.\nHow can we figure when the first drummer clapped, patted, tapped?\nNo way to know, and that isn't wrong.\nThe first dateable evidence of drums are the rock gongs.\nOur ancient grandparents, cousins all drumming and patting, can you see is in your mind's eye.\nTogether and cooperating as they discovered how to fire cups and bowls in early kilns to better survive and get by.",
		[],
	],
	[ # Footprint tile 24
		"Our First Towns",
		"Catalhoyuk is the first known town we built. It was built in an area that is modern day Turkey in southeast Europe. It is a place where people settled and made houses packed together so closely that there were no streets between the homes. The people walked along the rooftops and entered dwellings through holes in the roofs and climbed down ladders.",
		["Catalhoyuk", "What We Learned From 25 Years of Research at Catalhoyuk", "The History of Iron and Steel"],
		"7,000 years ago, humans in a town called Catalhoyuk,\nbuilt the first known complex community of homes clustered and joined together by mud-walls.\nEvidence shows that they walked along their rooftops and climbed down ladders into homes that they built out of mud and shared with their children and, what seems to us like, spouses.\nThey were the first to experiment with mixing metals,\nthey may have been the first to notice how lead and tin smelts out from rocks when heated under the wood fire for their clay kettles.",
		[],
	],
	[ # Footprint tile 25
		"Differing Human Opinions?",
		"By now there are an estimated five million people living on Earth. Most of them still live in huts, tents, and caves as their homes. Many people slept outside under the stars at night and hunted and gathered their food. Several of the earliest communities were made up of extended families including children, parents, aunts, uncles, grandparents, siblings, and great grandparents. These families worked together to plant seeds,, hunt, and gather food and, eventually, these families grouped together to create the first villages. These cities grew along rivers and became what we call civilizations. The Indus Valley was a good place because it was built along two rivers which allowed people to grow food and survive well enough to have many children.",
		["Indus Valley Civilization"],
		"More and more people having more and more children!\nWe formed groups together to cooperate which brought about groups of cities we call civilization.",
		[],
	],
	[ # Footprint tile 26
		"Duggarland and Indus Valley",
		"The ideas about how to harvest and plant seeds for crops really begins to take hold in the lives of people in the Indus Valley. There were other groups of people who were still only hunters and gatherers. One of these groups lived in what is today Britain. These people suffered the devastation of a tsunami as evidenced by an archeologically studied site.",
		["Tsunami Devastated Europe 8,150 Years Ago", "Britain Stone Age Tsunami - Time Team"],
		"6,000 years ago, agriculture finally begins in the Indus Valley riverflow,\nwe know from evidence in their clay pots and their bones.\nAbout this time, Duggarland and Montrose were hit by a tsunami, we know from Autumn's cherry stones. Watch Time Team, you'll learn about this a-plenty!",
		[],
	],
	[ # Footprint tile 27
		"Cluck Cluck! Chickens and Wheels",
		"Changes in the frequency of genes under strong natural selection causes noticeable changes in the way we look. This means the changes in our skin color and hair happen because of the environment we live in. Factors including agriculture, more people living close together, and the weather or climate causes us to need certain traits more than others in order to survive. The changes in the way we look and differences in our health exist because the changes came from the genes which develop our bodies. These genes are like our instruction book on how to make each one of us. Some genes make it better able to survive in specific circumstances and regions. When groups migrated and stayed to make a home, they influenced the dominance of genes that helped in that geographical region. This is why the word race isn't appropriate when describing people who look different. Geographic background is a more fitting term. Once that helpful gene change happened, it got passed down to that person's child and so on.",
		["The Geography of Livestock", "Evolution of Human Genes and the Origin of Agriculture"],
		"6,000-4,000 years ago, specific gene mutations became prevalent.\nWhy do genes change? Because of the rise in population size making it\npossible for the natural selection of alleles for thicker hair, lactase persistence,\nand malaria resistance.",
		[],
	],
	[ # Footprint tile 28
		"Tulips and Horses",
		"The Eurasian Steppe is a large region of flat open ground where mainly grasses and flowers grew 5,500 years ago.",
		["Ancient Horse Domestication", "Horseback Riding and Bronze Age Pastoralism in the Eurasian Steppes", "Tin in Use for the First Time in Ur"],
		"7,500 years ago, some middle eastern farmers and then in 5,000 years ago,\npastoralist from central Asia migrate and mix with the existing hunter gatherers to make the general European genetic we now know.\n5,800 years ago, civilizations in the Fertile Crescent first domesticated horses and invented the potter's wheel which made better bowls for food prep.\nThese people enjoyed the tulip and iris, that were among the most widespread flowers in Europe and Asia we call the Eurasian Steppe.",
		[],
	],
	[ # Footprint tile 29
		"The First Written Words",
		"The idea to make a mark in clay in order to remember something that happened or tell someone information first occurred around 5,400 years ago.",
		["Mesopotamia", "The History of Writing"],
		"8,000-5,000 years ago, in China, Southeast Europe, and West Asia, archeologists found the first signs of written language.\nThis skill allowed people to write about events and keep track of trade which was a big advantage.",
		[],
	],
	# FOOTPRINT TILES FOR ROUND 3
	# will add code for rounds 3-5 soon
]

## External Link Dictionary that stores a url for each HDE external link's name:
## Most of the elements of this dictionary are declared in order of when they appear in the google drive.
const external_link_dict = {
# LINKS FROM ROUND 0 IN GOOGLE DRIVE
	"The Frame Concept":
		"https://www.youtube.com/watch?v=NB-qqY3kV3w",
	"Formation of the Earth":
		"https://www.youtube.com/watch?v=HCDVN7DCzYE",
	# TODO: <the following link doesn't work>
#	"Where Did Earth Come From?":
#		"http://where%20did%20earth%20come%20from/?",
	"Hindu Creation Story":
		"https://www.youtube.com/watch?v=MZ6hVl84sjg",
	"From the Fall of Dinos to the Rise of Humans":
		"https://www.youtube.com/watch?v=yR8cR75iKGU",
	"Earliest Human Faces":
		"https://www.smithsonianmag.com/science-nature/a-closer-look-at-evolutionary-faces-8369070/",
	"Human Origins":	
		"https://www.youtube.com/watch?v=ehV-MmuvVMU",
	"Neanderthal Denisovians":
		"https://www.youtube.com/watch?v=CCUtcDjjw4w",
	"The Evolving Story of Human Evolution":
		"https://www.youtube.com/watch?v=WLXPi0Jha5o",
	"Large Mammal Extinction Linked to Prehistoric Humans":
		"https://www.sciencedaily.com/releases/2018/04/180419141536.htm",
	"New Species":
		"https://www.khanacademy.org/science/high-school-biology/hs-evolution/hs-phylogeny/v/genetic-variation-gene-flow-and-new-species",
	"Homo Sapiens":
		"https://www.khanacademy.org/humanities/world-history/world-history-beginnings/origin-humans-early-societies/v/peopling-the-earth",
	"Early Trade":
		"https://inews.co.uk/news/science/early-humans-trading-300000-years-135655",
	"Hand Axe and Pigments":
		"https://www.smithsonianmag.com/science-nature/colored-pigments-and-complex-tools-suggest-human-trade-100000-years-earlier-previously-believed-180968499/",
	# TODO: <the following link doesn't work>
#	"How To Make A Prehistoric Flint Axe":
#		"http://how%20to%20make%20a%20prehistoric%20flint%20axe/",
	"How a New Species of Ancestors is Changing Our Theory of Human Evolution":
		"https://www.youtube.com/watch?v=xv4_L5zlYaA&list=PLZpTOHUCVG5J9KRnfVX9L3v06pAXJ9IPi&index=20",
	"Solving Mysteries with Archaeologists!":
		"https://www.youtube.com/watch?v=zOJlCdMvWAI",
	"Hominid Paleobiology":
		"https://www.youtube.com/watch?v=fy7iraJ_S5o",
	"How Does Radiocarbon Dating Work?":
		"https://www.youtube.com/watch?v=phZeE7Att_s",
	"Human Language":
		"https://www.youtube.com/watch?v=OtM9Gqx6tk0",
	"Secrets of the Stone Age":
		"https://www.youtube.com/watch?v=I2vYr6gx56o",
	"Tracing Human Migration":
		"https://www.youtube.com/watch?v=dhOYxbsifkI",
	"Carbon Comes From the Word Charcoal":
		"https://www.mentalfloss.com/article/504856/9-diamond-facts-about-carbon",
	"Ages of Each Haplogroup":
		"https://en.wikipedia.org/wiki/Human_mitochondrial_DNA_haplogroup",
	"The Journey of Your Past":
		"https://www.youtube.com/watch?v=RGtaq3PiIoU",
	"Why We Speak":
		"https://www.theatlantic.com/business/archive/2015/06/why-humans-speak-language-origins/396635/",
	"The Journey of Man - A Genetic Odyssey":
		"https://www.youtube.com/watch?v=W_xTG6VXlIQ",
	"First Standing Stones":
		"https://www.scoop.it/topic/nubia/p/1131442507/2012/02/05/nabta-playa-african-archaeology",
	"The Origins of Human Society":
		"https://www.youtube.com/watch?v=_T9tAK9Vf8c",
	"African Stone Circles?":
		"https://www.youtube.com/watch?v=9o7S0l7Q76w",
	"African Stonehenge":
		"https://www.youtube.com/watch?v=3m2hRIXXo_Y",
	"Stone Circles of Senegambia":
		"https://www.youtube.com/watch?v=RKlh_hKKUm8",
	"The Earth 100,000 Years Ago":
		"https://www.youtube.com/watch?v=q81In8Os4nw",
	"Map Shows How Humans Migrated Across the Globe":
		"https://www.youtube.com/watch?v=CJdT6QcSbQ0",
	"Where All Modern Humans Arose":
		"https://www.nationalgeographic.com/science/article/controversial-study-pinpoints-birthplace-modern-humans",
	"Early Human Migration Around the World Far Earlier Than Scientists Thought":
		"https://www.businessinsider.com/early-humans-migrated-africa-to-asia-earlier-than-thought-2017-12",
	"When We Took Over the World":
		"https://www.youtube.com/watch?v=7E__zqy6xcw&list=PLZpTOHUCVG5J9KRnfVX9L3v06pAXJ9IPi&index=14",
	"Department of Archaeogenetics":
		"https://www.eva.mpg.de/archaeogenetics/index/",
	"Archaic Genomics":
		"https://www.youtube.com/watch?v=M7VdRKQuAa8",
	"Pioneer of Paleogenetics":
		"https://www.youtube.com/watch?v=gJLI3N5dovw",
	"The Meeting of Homo Sapiens, Neanderthals, Denisovians":
		"https://www.youtube.com/watch?v=jdYwMLSNHnU",
	"Mystery of the Human Bottleneck":
		"https://www.youtube.com/watch?v=cxTeZ6wGa04",
	"Ancient DNA and the New Science of the Human Past":
		"https://www.youtube.com/watch?v=990052wQywM",
# LINKS FROM ROUND 1 IN GOOGLE DRIVE
	"Living in the Stone Age: Music":
		"https://www.youtube.com/watch?v=qqKR_y0iDao",
	"Collective Learning":
		"https://www.youtube.com/watch?v=rSzUkMFbcO0",
	"Caveman Flutists?":
		"https://www.livescience.com/20563-ancient-bone-flute.html",
	"Fashion in Rock Art":
		"https://www.youtube.com/watch?v=lAM8JQw2i3s",
	"Migrations Into Europe":
		"https://www.bbc.com/news/science-environment-14630012",
	"Domesticated Dogs":
		"https://www.youtube.com/watch?v=4doKA0VpKgc",
	"Beringia":
		"https://www.youtube.com/watch?v=Kd00htzaHYw",
	"How to Make a Fish Hook From Bone":
		"https://www.youtube.com/watch?v=1RS-JEk00lE",
	"First Humans Enter the Americas":
		"https://www.smithsonianmag.com/smart-news/humans-colonized-americas-along-coast-not-through-ice-180960103/",
	"Art of Altamira Cave":
		"https://www.youtube.com/watch?v=qyIfPbn0RDs",
	# TODO: <the following link needs clarification from Stephanie as Jebel Sahaba was paired with the Younger Dryas link>
#	"Jebel Sahaba":
#		"https://en.wikipedia.org/wiki/Jebel_Sahaba",
	"Younger Dryas":
		"https://www.britannica.com/science/Younger-Dryas-climate-interval",
	# TODO: <the following link is working but points to an incorrect site>
#	"Natufians":
#		"https://jewishunpacked.com/welcome-to-unpacked/?utm_source=fromthegrapevine&utm_medium=website&utm_campaign=redirect",
	"Ancient Eurasians Heterogeneity":
		"https://www.frontiersin.org/articles/10.3389/fgene.2018.00268/full",
	"Natufians and Africans":
		"https://egyptsearchreloaded.proboards.com/thread/1411/who-natufian-pioneers-neolithic",
	"Evidence of a Planet-Cooling Asteroid 12,900 Years Ago":
		"https://www.scientificamerican.com/article/evidence-found-for-planet-cooling-asteroid-12900-years-ago/",
	"Gobekli Tepe":
		"https://www.worldhistory.org/G%C3%B6bekli_Tepe/",
	# TODO: <the following link is working but does not show correct article>
#	"Geometry Guided the Construction of Gobekli Tepe":
#		"https://archaeologynewsnetwork.blogspot.com/2020/05/geometry-guided-construction-of-gobekli.html",
	"The Agriculture Revolution":
		"https://www.youtube.com/watch?v=Yocja_N5s1I",
	"The History of Farming":
		"https://www.youtube.com/watch?v=bhzQFIZuNFY",
	"Origins of Clay":
		"https://www.youtube.com/watch?v=Wh3zNwy8ZFM",
	# TODO: <the following header did not have a link in the Google Doc>
#	"The Invention of Pottery":
#		"",
	# TODO: <the following link does not display video>
#	"How is Clay Made":
#		"https://www.youtube.com/watch?v=FXD9zDs9ygU",
# LINKS FROM ROUND 2 IN GOOGLE DRIVE
	"From Stone to Bronze":
		"https://www.youtube.com/watch?v=4vDDMYyhLBw&list=PLZpTOHUCVG5LRCThz2qf2iAA3MHrUpNfZ&index=4",
	"Revolutions: The Age of Metal and the Evolution of European Civilization":
		"https://www.youtube.com/watch?v=a7HStd26qJE&list=PLZpTOHUCVG5LRCThz2qf2iAA3MHrUpNfZ&index=9",
	"Timeline of Metallurgy":
		"https://www.visualcapitalist.com/history-of-metals/",
	"The History of Copper":
		"https://www.youtube.com/watch?v=RmaGh4g1JtY",
	"Gold Jewelry":
		"https://www.visualcapitalist.com/gold-series-sought-metal-earth-part-1-5/",
	"The Evolution and Meanings of Human Skin Color":
		"https://www.youtube.com/watch?v=sc4OFcT5m1Y",
	"Creation or Evolution":
		"https://www.youtube.com/watch?v=NQ5Wz4rqKFc",
	"Origins of the Biblical Philistines?":
		"https://www.eurekalert.org/news-releases/884697",
	"FOLI (There is No Movement Without Rhythm)":
		"https://www.youtube.com/watch?v=lVPLIuBy9CY",
	"The First Rock Project":
		"https://www.jahawi.com/first-rock",
	"Lost Kingdoms of Africa: Nubia":
		"https://www.youtube.com/watch?v=Mpz8h_MFkWg&t=300s", # document says to start at 5 minute mark
	"Early Evidence of Drum History":
		"https://www.youtube.com/watch?v=cBVD3BezpJg",
	"Poderosa Aainjala - 150 Tambores":
		"https://www.youtube.com/watch?v=0Pq8vOVbvzs",
	"Rock Art in the Green Sahara":
		"https://www.youtube.com/watch?v=HD_Ot2GaCXo",
	# TODO: <the following link doesn't work>
#	"How Banning the African Drum Gave Birth to American Music":
#		"http://how%20banning%20the%20african%20drum%20gave%20birth%20to%20american%20music/",
	"What is African Rock Art?":
		"https://www.youtube.com/watch?v=8Y4DddMXsHk",
	"Fashion in African Rock Art":
		"https://www.youtube.com/watch?v=lAM8JQw2i3s",
	# TODO: <the following headers were not provided with unique links>
#	"Rock Music Rock Art":
#		"",
#	"The Origins of Music":
#		"",
	"When the Sahara Was Green":
		"https://www.youtube.com/watch?v=ZQP-7BPvvq0",
	"Catalhoyuk":
		"https://www.catalhoyuk.com/",
	"What We Learned From 25 Years of Research at Catalhoyuk":
		"https://www.youtube.com/watch?v=o70A1VqrxEQ",
	"The History of Iron and Steel":
		"https://www.youtube.com/watch?v=WN9unCD30Rs",
	"Indus Valley Civilization":
		"https://www.youtube.com/watch?v=n7ndRwqJYDM",
	"Tsunami Devastated Europe 8,150 Years Ago":
		"https://www.dailymail.co.uk/sciencetech/article-3317451/Tsunami-devastated-Europe-8-150-years-ago-Huge-waves-swept-hundreds-miles-North-Sea-Ice-Age.html",
	"Britain Stone Age Tsunami - Time Team":
		"https://www.youtube.com/watch?v=XTvOcm5dgDI",
	"The Geography of Livestock":
		"https://www.youtube.com/watch?v=tZ-6rFEM2o4",
	"Evolution of Human Genes and the Origin of Agriculture":
		"https://www.youtube.com/watch?v=9SnmmSZGV88",
	"Ancient Horse Domestication":
		"https://www.youtube.com/watch?v=2V3MFaHlVg0",
	"Horseback Riding and Bronze Age Pastoralism in the Eurasian Steppes":
		"https://www.youtube.com/watch?v=QapUGZ0ObjA",
	"Tin in Use for the First Time in Ur":
		"http://www.makin-metals.com/history-of-tin/",
	"Mesopotamia":
		"https://www.youtube.com/watch?v=sohXPx_XZ6Y&list=PLBDA2E52FB1EF80C9&index=5",
	"The History of Writing":
		"https://www.youtube.com/watch?v=HyjLt_RGEww",
# LINKS FROM ROUND 3 IN GOOGLE DRIVE
	# TODO: <the following header was missing a link>
#	"The Scorpion King and the Birth of Egypt":
#		"",
	"Homo Naledi":
		"https://www.youtube.com/watch?v=OgBJmdpqWsU",
	"What is the Meaning of Stonehenge":
		"https://www.youtube.com/watch?v=fkJKym1-9tA",
	"Who Built Stonehenge?":
		"https://www.youtube.com/watch?v=yP2DlTwQuIY",
	# TODO: <the following video is private and won't display>
#	"The World of Stonehenge":
#		"https://www.youtube.com/watch?v=FqdhkuMTNWU",
	"What the Science of Stonehenge Has Taught Us":
		"https://www.youtube.com/watch?v=eGAMaM2nC7M",
	"First Lead Mining":
		"https://www.youtube.com/watch?v=Bv8Zl5oh-9s",
	"The Physics of Sailing":
		"https://www.youtube.com/watch?v=yqwb4HIrORM",
	"The Digital Story of the History of Sailboats":
		"https://www.youtube.com/watch?v=jwqd_It0vtU",
	# TODO: <the following 2 video links from the google drive don't start at minute 0, check with Stepahnie to ensure this is correct>
	"Bronze Age Transformations of the Mediterranean World":
		"https://www.youtube.com/watch?v=VJ5RhZBOEGM&list=PLZpTOHUCVG5LRCThz2qf2iAA3MHrUpNfZ&index=8&t=1988s",
	"The Nordic Bronze Age":
		"https://www.youtube.com/watch?v=s_OFqGuLc7s&list=PLZpTOHUCVG5LRCThz2qf2iAA3MHrUpNfZ&index=11&t=263s",
	"5000 Years Ago the Ancient Egyptians Used Antimony in Their Cosmetics":
		"https://www.chemicool.com/elements/antimony.html",
	# TODO: <the following 2 headers did not have a unique link>
#	"Cultural Gene Interactions of Adult Milk Intake":
#		"",
#	"AD and BC Explained (As Well As CE and BCE)":
#		"",
	"The Evolution of Lactose Tolerance":
		"https://www.youtube.com/watch?v=MA9boI1qTuk",
	"Putting BC and AD in Order":
		"https://www.youtube.com/watch?v=BKbDy09JZ6I",
	"First Gold Mining in Egypt":
		"https://www.rsc.org/periodic-table/element/79/gold",
	"The History of Pearls":
		"https://www.youtube.com/watch?v=9pDdQjPYL04",
	"Formation of Pearls":
		"https://www.youtube.com/watch?v=m07OvPEoR6g",
	"Pearls in Japan":
		"https://www.youtube.com/watch?v=ZiM1RMrckIc",
	"How Do Pigeons Know Where to Go?":
		"https://www.youtube.com/watch?v=thXQseoxKN8",
	"Pigeon Genius":
		"https://www.youtube.com/watch?v=ID3J7hprG8g",
	"Silver Mining Started in Greece and Turkey":
		"https://www.rsc.org/periodic-table/element/47/silver",
	"The History of Chocolate":
		"https://www.youtube.com/watch?v=ibjUpk9Iagk",
	# TODO: <the following 2 provided links lead to an error page and Apple's homepage respectively>
#	"Who Invented Bricks, Mortar, and Concrete?":
#		"https://owlcation.com/humanities/Who-Invented-Bricks-Mortar-and-Concrete",
#	"Bricks Are a Symbol of Human Beings and Building History":
#		"https://www.apple.com/",
	"Ascent of Woman":
		"https://www.youtube.com/watch?v=cAfqqe_0Gbc",
	# TODO: <the following 2 videos either have a copyright claim or are private>
#	"Engineering of Ancienct Egypt":
#		"https://www.youtube.com/watch?v=J34vYXEaFTU",
#	"The Silence of the Bees":
#		"https://www.youtube.com/watch?v=lE-8QuBDkkw",
	"Ancient and Medieval Medicine":
		"https://www.youtube.com/watch?v=iGiZXQVGpbY",
	"Deciphering the World's Oldest Rule Book":
		"https://www.youtube.com/watch?v=wHjznvH54Cw&list=PLZpTOHUCVG5J9KRnfVX9L3v06pAXJ9IPi&index=46",
	# TODO: <the following video starts at 5:30 minutes, need to confirm with Stephanie>
	"Mesopotamia Tablet of Gilgamesh":
		"https://www.youtube.com/watch?v=2VWS_F_UeQI&t=339s",
	"The Evolution of Falconry":
		"https://www.youtube.com/watch?v=0Q0vyXBKwPc",
	"Crete and the Magnificent Minoan Palace of Knossos":
		"https://www.youtube.com/watch?v=uAm3dsk67RE",
	"Ancient Artisans - Falconry":
		"https://www.youtube.com/watch?v=41KExZ060Fc",
	"Coopers Hawks in Falconry":
		"https://www.youtube.com/watch?v=Uak16hgnUXc",
	# TODO: <the following header is missing a unique link>
#	"Judaism in Brief":
#		"",
	"Hinduism in Brief":
		"https://www.youtube.com/watch?v=PRPQMg6t9JQ",
	"The Olmec":
		"https://www.khanacademy.org/humanities/world-history/world-history-beginnings/ancient-americas/a/the-olmec-article",
# LINKS FROM ROUND 4 IN GOOGLE DRIVE
	"Explore the Ruins of a Medieval East African Empire":
		"https://www.youtube.com/watch?v=YByo9L5VarM",
	"Confucious":
		"https://www.youtube.com/watch?v=2dZfaU5tsDY&list=PLLiykcLllCgOVkyIh5QhsUmVGnr0lHtoe&index=3",
	# TODO: <the following header is missing a link>
#	"Plato":
#		"",
	"DNA Insights to Bronze Age Greece":
		"https://www.youtube.com/watch?v=ttqbRIaRRwY",
	"Buddhism in Brief":
		"https://www.youtube.com/watch?v=pG4R-rmX7HA",
	"Herodotus, the Kingdom of Lydia":
		"https://www.youtube.com/watch?v=MIEMev16GLk",
	"The Invention of Coinage: Lydia 630 BCE":
		"https://www.youtube.com/watch?v=SkjrvsTf6ew",
	# TODO: <the following header links to a private video>
#	"Democracy":
#		"https://www.youtube.com/watch?v=SPI4m69UbTE",
	"Ancient Egyptians Used Platinum":
		"https://www.rsc.org/periodic-table/element/78/platinum",
	# TODO: <the following video works, but seems incorrectly paired with its header>
	"The Etruscans":
		"https://www.youtube.com/watch?v=kerFNYMpSIA",
	"Buddha":
		"https://www.youtube.com/watch?v=X-_cJU-pFwQ",
	"Concrete":
		"https://www.explainthatstuff.com/steelconcrete.html",
	"Nickel Was Used in China in 200 BC":
		"https://www.rsc.org/periodic-table/element/28/nickel",
	"Teotihuacan":
		"https://clas.berkeley.edu/teotihuacan-exceptional-multiethnic-city-pre-hispanic-central-mexico",
	"Glassblowing":
		"https://www.khanacademy.org/humanities/special-topics-art-history/creating-conserving/mosaic-metalwork-and-glass/v/glassmaking-technique-roman-mold-blown-glass",
	"The History of Glass":
		"http://www.historyofglass.com/",
	"Steam Engines":
		"https://www.explainthatstuff.com/steamengines.html",
	"Hero's Steam Engine (Aeolipile)":
		"https://www.youtube.com/watch?v=QBh8cHZvE9U",
	"Christianity in Brief":
		"https://www.youtube.com/watch?v=Qsnzwx5ggq4",
	"The First Aluminum Was Used in 200 AD":
		"https://www.rsc.org/periodic-table/element/13/aluminium",
	"Horses in Human History":
		"https://www.britishmuseum.org/blog/horses-and-human-history",
	"Islam in Brief":
		"https://www.youtube.com/watch?v=lglIENhbgJo",
	"What is an Alloy?":
		"https://study.com/academy/lesson/what-is-an-alloy-definition-examples.html",
	# TODO: <the following header is missing a unique link>
#	"Alloys and Their Properties":
#		"",
# LINKS FROM ROUND 5 IN GOOGLE DRIVE
	# TODO: <verify the following video should start at minute 0>
	"1000 AD":
		"https://youtu.be/kerFNYMpSIA?t=0",
	"Mapungubwe":
		"https://www.youtube.com/watch?v=szcuw-I2-WI",
	"Every Genius Detail That Made Viking Longships Remarkable":
		"https://www.youtube.com/watch?v=M2v0CsoFctA",
	"The Song Dynasty":
		"https://www.youtube.com/watch?v=QO7NHZJ-eE4",
	"Cathedrals and Universities":
		"https://www.youtube.com/watch?v=0wDlLwLIFeI",
	"20 Things You Never Knew About Dominos!":
		"https://www.youtube.com/watch?v=X-RNmaWkYD4",
	"Gutenberg Printing Press":
		"https://www.youtube.com/watch?v=DLctAw4JZXE",
	# TODO: <the following header links to a private video>
#	"The Printing Press":
#		"https://www.youtube.com/watch?v=SPI4m69UbTE",
	"Mansa Musa and Africa":
		"https://www.youtube.com/watch?v=jvnU0v6hcUo",
	# TODO: <the following header is missing a unique link>
#	"John Locke":
#		"",
	"Microscopes":
		"https://www.youtube.com/watch?v=Ue-86MDmjns",
	"Telescopes":
		"https://www.youtube.com/watch?v=mYhy7eaazIk",
	"Antione Lavoisier Discovery About Carbon, Coal, and Diamonds":
		"https://www.mentalfloss.com/article/504856/9-diamond-facts-about-carbon",
	"Tellurium Discovered in 1783":
		"https://www.rsc.org/periodic-table/element/52/tellurium",
	"Charles Darwin":
		"https://www.youtube.com/watch?v=T0B6os-6uuc",
	"Cobalt Discovered in 1739":
		"https://education.jlab.org/itselemental/ele027.html",
	"Chromium Discovered in 1762":
		"https://republicofmining.com/2012/12/14/chromes-colourful-history-from-the-international-chromium-development-association-icda/",
	"How Does Morse Code Work":
		"https://www.youtube.com/watch?v=iy8BaMs_JuI",
	"The History of the Telephone":
		"https://www.youtube.com/watch?v=qWUP9EigdjY",
	"Titanium Discovered in 1791":
		"https://www.rsc.org/periodic-table/element/22/titanium#history",
	"Iridium Discovered in 1803":
		"https://www.rsc.org/periodic-table/element/77/iridium",
	"Magnesium Discovered in 1755":
		"https://www.rsc.org/periodic-table/element/12/magnesium",
	# TODO: <the following header links to a private video>
#	"Phonograph and Gramophone":
#		"https://www.youtube.com/watch?v=7o3ZcDl34hQ",
	"A Brief History of How Plastic Has Changed Our World":
		"https://www.youtube.com/watch?v=jQdBag_p6kE&feature=youtu.be",
	"The Zipper: Where Did It Come From?":
		"https://www.youtube.com/watch?v=LMM3Dn0joDU",
	"Who Invented Cars?":
		"https://www.youtube.com/watch?v=0-VUjfcRn4E",
	"Cadmium Discovered in 1817":
		"https://www.rsc.org/periodic-table/element/48/cadmium",
	"Who Invented the Radio?":
		"https://www.youtube.com/watch?v=71pAgRgNhd8",
	"How a Teenager From Idaho Invented TV":
		"https://www.youtube.com/watch?v=i9g3KQOEsa0",
	# TODO: <the following header is missing a unique link>
#	"The Wright Brothers, First Successful Airplane":
#		"",
	"Global Phylogenic Tree":
		"https://journals.plos.org/plosgenetics/article?id=10.1371/journal.pgen.1003309",
	"Who Are the San Bushman?":
		"https://www.youtube.com/watch?v=1oQ5Jd7p2aY",
	"Khoisan Click Language":
		"https://www.youtube.com/watch?v=W6WO5XabD-s",
	"Who Are the Khoisan?":
		"https://www.youtube.com/watch?v=l0xQQE_Qy64",
	# TODO: <the following link states the video is unavailable>
#	"International Space Station":
#		"https://www.youtube.com/watch?v=uvPDWLiy54E",
	"Future Cities":
		"https://www.youtube.com/watch?v=NmRoc7_jVdo",
	"What if We Built a Ringworld in Space":
		"https://www.youtube.com/watch?v=QyDuk-eAFAI",
	"World Population":
		"https://web.archive.org/web/20150221004127/http://itbulk.org/population/world-population-history/",
}
