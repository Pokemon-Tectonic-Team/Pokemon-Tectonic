module QuestModule
  
  # Major NPC Side Quests
  
  QUEST_IMOGENE = {
    :Name => _INTL("Impostor/Imperatrice"),
    :Stage1 => _INTL("Find her north of Svait."),
    :Stage2 => _INTL("Find her north of the Eleig."),
    :Stage3 => _INTL("Find her after your 6th badge."),
    :Stage4 => _INTL("Find her after the tournament."),
    :Location1 => _INTL("Ice Cave"),
    :Location2 => _INTL("Prizca West"),
    :Location3 => _INTL("Grouz"),
    :Location4 => _INTL("Carnation Graves"),
    :QuestDescription => _INTL("A pair of identical fortune tellers, each claiming the other is a Ditto. For some reason, they have a vested interest in you. Find out the truth."),
  }
  
  QUEST_ALESSA = {
    :Name => _INTL("Kayfabe"),
    :Stage1 => _INTL("Find her in the sewers."),
    :Stage2 => _INTL("Find her north of the Eleig."),
    :Stage3 => _INTL("Find her after your 7th badge."),
    :Stage4 => _INTL("Find her after the tournament."),
    :Location1 => _INTL("Luxtech Sewers"),
    :Location2 => _INTL("Prizca East"),
    :Location3 => _INTL("Volcanic Shore"),
    :Location4 => _INTL("Hollowed Layer"),
    :QuestDescription => _INTL("A confident young woman who trains Pokémon for a price. Dueling her could be good practice – but she looks at you with unnerving familiarity. She knows more than she lets on."),
  }
  
  QUEST_SKYLER = {
    :Name => _INTL("Dear Iconoclast"),
    :Stage1 => _INTL("Find him in Velenz."),
    :Stage2 => _INTL("Find him north east."),
    :Stage3 => _INTL("Find him after your 7th badge."),
    :Stage4 => _INTL("Find him after the tournament."),
    :Location1 => _INTL("Velenz"),
    :Location2 => _INTL("Prizca East"),
    :Location3 => _INTL("Team Chasm HQ"),
    :Location4 => _INTL("Kilna Ascent"),
    :QuestDescription => _INTL("A dashing young man trying his best to be charming. His appreciation for avatars borders on spiritual. Who knows what'll happen if you seek him out?"),
  }
  
  QUEST_KEONI = {
    :Name => _INTL("When in Makya"),
    :Stage1 => _INTL("Find him north of the Eleig."),
    :Stage2 => _INTL("Find him in the sewers."),
    :Stage3 => _INTL("Find him after your 8th badge."),
    :Stage4 => _INTL("Find him after the tournament."),
    :Location1 => _INTL("Eleig Stretch"),
    :Location2 => _INTL("Sewer Junction"),
    :Location3 => _INTL("Novo College"),
    :Location4 => _INTL("Velenz Menagerie"),
    :QuestDescription => _INTL("A studious man, foreign to Makya. He studies regional forms for his research. Something strange is afoot in the region – perhaps you can work together to find out what."),
  }
  
  QUEST_EIFION = {
    :Name => _INTL("Second Chances"),
    :Stage1 => _INTL("Find him near the river."),
    :Stage2 => _INTL("Find him up river."),
    :Stage3 => _INTL("Find him after your 8th badge."),
    :Stage4 => _INTL("Find him after the tournament."),
    :Location1 => _INTL("Eleig River Crossing"),
    :Location2 => _INTL("Highland Lake"),
    :Location3 => _INTL("Tournament Grounds"),
    :Location4 => _INTL("Abyssal Cavern"),
    :QuestDescription => _INTL("A modest young man with a Phione, a Pokémon of great import. He's a fellow gym challenger – maybe facing off against a living myth could sharpen your skills."),
  }
  
  QUEST_CANDY = {
    :Name => _INTL("do crimes plz <3"),
    :Stage1 => _INTL("Enter the man's house."),
    :Stage2 => _INTL("Find her at the college."),
    :Stage3 => _INTL("Find her north of the Eleig."),
    :Stage4 => _INTL("Find her in a cave."),
    :Stage5 => _INTL("Find her after your 8th badge."),
    :Location1 => _INTL("Barren Crater"),
    :Location2 => _INTL("Novo College"),
    :Location3 => _INTL("Prizca West"),
    :Location4 => _INTL("Cave of Hatching"),
    :Location5 => _INTL("Eleig Stretch"),
    :QuestDescription => _INTL("An energetic girl with no respect for the law. Despite her bubbly energy, it's easy to see she's burdened by a vendetta. Help her enact justice or find peace."),
  }

  # Fetch/Misc Quests

  QUEST_LOST_GROWLITHE = {
    :Name => _INTL("Lost Puppy"),
    :QuestGiver => _INTL("School Kid"),
    :Stage1 => _INTL("Find the Growlithe."),
    :Stage2 => _INTL("Return to the kid."),
    :Location1 => _INTL("Repora Forest"),
    :Location2 => _INTL("Novo Apartments"),
    :QuestDescription => _INTL("The kid in Novo Apartments is asking you to find his Growlithe, which is lost in Repora Forest."),
  }

  QUEST_HIDE_AND_SEEK = {
    :Name => _INTL("Hide and Seek"),
    :QuestGiver => _INTL("TM Kid"),
    :Stage1 => _INTL("Find him."),
    :Stage2 => _INTL("Find him again."),
    :Location1 => _INTL("Casaba Island"),
    :Location2 => _INTL("Casaba Island"),
    :QuestDescription => _INTL("Play hide and seek with the kid who said they'd give you TMs."),
    :RewardString => _INTL("TMs!")
  }

  QUEST_DIGIT_SLIPS = {
    :Name => _INTL("An Inconvenienced Ranger"),
    :QuestGiver => _INTL("Ranger"),
    :Stage1 => _INTL("Find all the digit slips."),
    :Location1 => _INTL("Menagerie-Velenz Gatehouse"),
    :QuestDescription => _INTL("The local ranger is tired of Rafael's gym puzzle. Find the digit slips and return them to him."),
  }

  QUEST_POKEMON_MASTER = {
    :Name => _INTL("Breaking Spirits"),
    :QuestGiver => _INTL("Mother"),
    :Stage1 => _INTL("Perfect the fight with the kid."),
    :Stage2 => _INTL("Return to the mother."),
    :Location1 => _INTL("Grouz, Mine Head's House"),
    :Location2 => _INTL("Grouz, Mine Head's House"),
    :QuestDescription => _INTL("A mother is concerned with her kid's career choices. Utterly destroy him."),
  }

  QUEST_SUS_PACKAGE = {
    :Name => _INTL("Don't Open It"),
    :QuestGiver => _INTL("Alolan"),
    :Stage1 => _INTL("Find their package."),
    :Stage2 => _INTL("Return the package."),
    :Location1 => _INTL("County Park"),
    :Location2 => _INTL("Prizca West Travel Agency"),
    :QuestDescription => _INTL("These people report they lost a package to a Gyarados attack, and want you to get it. Must be important, for their job...?"),
    :RewardString => _INTL("Alolan Wreath")
  }

  QUEST_MEMORY_LANE = {
    :Name => _INTL("Down Memory Lane"),
    :QuestGiver => _INTL("Berry Farmer"),
    :Stage1 => _INTL("Bring the Pokémon to her."),
    :Location1 => _INTL("County Park"),
    :QuestDescription => _INTL("This former Team Chasm member has been feeling nostalgic. Bring her a Bergmite, a Klink, a Dreepy, a Makyan Tangela, and an Elekid."),
    :RewardString => _INTL("Catching Charm")
  }

  QUEST_AGRAVELER = {
    :Name => _INTL("Geodude Frenzy!"),
    :QuestGiver => _INTL("Scientist"),
    :Stage1 => _INTL("Defeat the avatar."),
    :Location1 => _INTL("Novo Town, Scientist's House"),
    :QuestDescription => _INTL("The Alolan Geodudes have gone on a frenzy! This Avatar would wreak havoc unchecked."),
  }

  QUEST_ABSOLUS = {
    :Name => _INTL("Foreboding"),
    :QuestGiver => _INTL("Worker"),
    :Stage1 => _INTL("Defeat the Avatar."),
    :Location1 => _INTL("Novo Apartments, Attic"),
    :QuestDescription => _INTL("An Avatar has invaded Novo Apartments. Assist the Absol it's staring down!"),
  }

  QUEST_AEGIS_FRAUD = {
    :Name => _INTL("Aegis Insurance Fraud"),
    :QuestGiver => _INTL("Jogger?"),
    :Stage1 => _INTL("Find the ID Card."),
    :Stage2 => _INTL("Infiltrate the building."),
    :Stage3 => _INTL("Return to the Ranger."),
    :Location1 => _INTL("Prizca West"),
    :Location2 => _INTL("Aegis Insurance"),
    :Location3 => _INTL("Prizca West"),
    :QuestDescription => _INTL("An undercover Makyan Ranger is investigating Aegis Insurance. Help her infiltrate the building to discover the truth."),
  }

  QUEST_MALASADAS = {
    :Name => _INTL("Sewer Dining"),
    :QuestGiver => _INTL("Dragon Tamer"),
    :Stage1 => _INTL("Give them 10 Big Malasadas."),
    :Location1 => _INTL("Luxtech Sewers"),
    :QuestDescription => _INTL("Locals are feeding the Pokémon in the sewers as compensation for the items stolen from them."),
  }

  QUEST_NOVO_WREATHS = {
    :Name => _INTL("Don't Forget!"),
    :QuestGiver => _INTL("Flower Keeper"),
    :Stage1 => _INTL("Beat your 4th gym."),
    :Stage2 => _INTL("Return to her."),
    :Location1 => _INTL("Makya"),
    :Location2 => _INTL("Novo Town"),
    :QuestDescription => _INTL("A flower keeper at the south entrance of Novo Town says she'll give you a reward to celebrate completing your 4th gym. You won't forget her, right?\n\n\n\nFlower"),
  }

  QUEST_BATTLE_LAB = {
    :Name => _INTL("Luxtech Battle Labs"),
    :QuestGiver => _INTL("Scientist"),
    :Stage1 => _INTL("Defeat the gauntlet."),
    :Location1 => _INTL("Luxtech Main"),
    :QuestDescription => _INTL("You've been offered a gauntlet of scientists to try to get past. How difficult could these eggheads be anyways?"),
  }

  QUEST_SHOW_LEGEND = {
    :Name => _INTL("The Bucket List"),
    :QuestGiver => _INTL("Old Lady"),
    :Stage1 => _INTL("Show her a legendary."),
    :Location1 => _INTL("East-Peaks Gatehouse"),
    :QuestDescription => _INTL("An elderly lady notices your strength and status, and figures you may have a legendary Pokémon. She only wishes to see it and admire it. How about humoring her request? I'm sure there is something powerful in this region that you could find."),
  }

  # Gym Leader Avatars

  QUEST_GYM_AVATARS_1 = {
    :Name => _INTL("Peal of Thunder"),
    :QuestGiver => _INTL("Lambert"),
    :Stage1 => _INTL("Defeat what lurks behind the door."),
    :Stage2 => _INTL("Report back about your success."),
    :Location1 => _INTL("Casaba Villa, Lambert's House"),
    :Location2 => _INTL("Casaba Villa, Lambert's House"),
    :QuestDescription => _INTL("Lambert was tasked with keeping eyes on an imprisoned avatar until he found someone capable of destroying it. He seems to think that's you. Silence the beast."),
  }

  QUEST_GYM_AVATARS_2 = {
    :Name => _INTL("May I Have this Dance?"),
    :QuestGiver => _INTL("Eko"),
    :Stage1 => _INTL("Defeat what lurks behind the door."),
    :Stage2 => _INTL("Report back about your success."),
    :Location1 => _INTL("Shipping Lane"),
    :Location2 => _INTL("Novo Gym"),
    :QuestDescription => _INTL("Eko has waited for years to find someone capable of destroying a particularly powerful avatar. They gave you a key to get into its prison, and told you not to ask too many questions. Put an end to the thing's performance."),
  }

  QUEST_GYM_AVATARS_3 = {
    :Name => _INTL("The Thanks I Get"),
    :QuestGiver => _INTL("Helena"),
    :Stage1 => _INTL("Defeat what lurks behind the door."),
    :Stage2 => _INTL("Report back about your success."),
    :Location1 => _INTL("Team Chasm HQ"),
    :Location2 => _INTL("Luxtech Gym"),
    :QuestDescription => _INTL("Helena told you that Makya's gym challenge was partially created to find exceptional trainers. Having found one, she's eager to put you to work. Take her key, find this vicious avatar, and show it a former Chasm boss's gratitude."),
  }

  QUEST_GYM_AVATARS_4 = {
    :Name => _INTL("Quietus"),
    :QuestGiver => _INTL("Rafael"),
    :Stage1 => _INTL("Defeat what lurks behind the door."),
    :Stage2 => _INTL("Report back about your success."),
    :Location1 => _INTL("Velenz, Rafael's House"),
    :Location2 => _INTL("Velenz, Rafael's House"),
    :QuestDescription => _INTL("Rafael claims that the gym leaders' real purpose is to watch over the prisons of devastatingly powerful avatars. All he wants is for you to go in and end his work. Strike down the darkness writhing within its tomb."),
  }

  QUEST_GYM_AVATARS_5 = {
    :Name => _INTL("Neath Rust and Time"),
    :QuestGiver => _INTL("Zoé"),
    :Stage2 => _INTL("Defeat what lurks behind the door."),
    :Stage3 => _INTL("Report back about your success."),
    :Location1 => _INTL("Eleig River Crossing, Worn Shed"),
    :Location2 => _INTL("Eleig River Crossing, Worn Shed"),
    :QuestDescription => _INTL("Zoé told you that her mentor abandoned her and Bence, but left behind instructions. If they found a trainer of her caliber, they were to send them to destroy a pair of dire avatars. End the beasts' illustrious stories here and now."),
  }

  QUEST_GYM_AVATARS_6 = {
    :Name => _INTL("Beneficence"),
    :QuestGiver => _INTL("Noel"),
    :Stage1 => _INTL("Defeat what lurks behind the door."),
    :Stage2 => _INTL("Report back about your success."),
    :Location1 => _INTL("Ancient Sewers"),
    :Location2 => _INTL("Prizca East Gym"),
    :QuestDescription => _INTL("Noel explains that Team Chasm created something by tampering with the Regis. Whether intentional or accidental, the resulting avatar must be eliminated. Cull it and deaden its fell light."),
  }

  QUEST_GYM_AVATARS_7 = {
    :Name => _INTL("L'Enfant du Vide"),
    :QuestGiver => _INTL("Victoire"),
    :Stage1 => _INTL("Defeat what lurks behind the door."),
    :Stage2 => _INTL("Report back about your success."),
    :Location1 => _INTL("Sweetrock Harbor"),
    :Location2 => _INTL("Sweetrock Harbor Gym"),
    :QuestDescription => _INTL("Victoire has been waiting to find someone capable of eliminating a remnant of Team Chasm's experimentation with Regigigas's power. Provide this abomination a warm welcome."),
  }

  QUEST_GYM_AVATARS_8 = {
    :Name => _INTL("Kiss of Ascalon"),
    :QuestGiver => _INTL("Samorn"),
    :Stage1 => _INTL("Defeat what lurks behind the door."),
    :Stage2 => _INTL("Report back about your success."),
    :Location1 => _INTL("Kilna Ascent"),
    :Location2 => _INTL("Team Chasm HQ Gym"),
    :QuestDescription => _INTL("Samorn told you that she helped Team Chasm create impenetrable crypts to imprison avatars within, utilizing the power of the Regis. Now, it's time to get rid of one of those avatars for good. She's given you the means to get in and cut it down to size."),
  }

  # Avatar Bounties
  
  QUEST_CROBAT = {
    :Name => _INTL("Bounty: Crobat Avatar"),
    :QuestGiver => _INTL("Ranger"),
    :Stage1 => _INTL("Defeat the Crobat Avatar."),
    :Stage2 => _INTL("Report back to the Ranger."),
    :Location1 => _INTL("Underpeak Tunnels"),
    :Location2 => _INTL("Peaks-Harbor Gatehouse"),
    :QuestDescription => _INTL("A ranger is asking you to deal with a Crobat Avatar lying in the tunnels under Split Peaks. Says he'll make it worth your while."),
  }

  QUEST_BEARTIC = {
    :Name => _INTL("Bounty: Beartic Avatar"),
    :QuestGiver => _INTL("Ranger"),
    :Stage1 => _INTL("Defeat the Beartic Avatar."),
    :Stage2 => _INTL("Report back to the Ranger."),
    :Location1 => _INTL("Gigalith's Guts"),
    :Location2 => _INTL("Svait-Park Gatehouse"),
    :QuestDescription => _INTL("A ranger is asking you to deal with a Beartic Avatar lying in the Gigalith's Guts. Says he'll make it worth your while."),
  }

  QUEST_MAROMATISSE = {
    :Name => _INTL("Bounty: M. Aromatisse Avatar"),
    :QuestGiver => _INTL("Ranger"),
    :Stage1 => _INTL("Defeat the M. Aromatisse Avatar."),
    :Stage2 => _INTL("Report back to the Ranger."),
    :Location1 => _INTL("Highland Lake"),
    :Location2 => _INTL("West-Plaza Gatehouse"),
    :QuestDescription => _INTL("A ranger is asking you to deal with a Makyan Aromatisse Avatar lying in the Highland Lake... apparently. Says he'll make it worth your while."),
  }

  QUEST_MONKES = {
    :Name => _INTL("Bounty: Monkey Trio Avatars"),
    :QuestGiver => _INTL("Ranger"),
    :Stage1 => _INTL("Defeat the trio of Monkey Avatars."),
    :Stage2 => _INTL("Report back to the Ranger."),
    :Location1 => _INTL("The Shelf"),
    :Location2 => _INTL("Shelf-Novo Gatehouse"),
    :QuestDescription => _INTL("A ranger is asking you to deal with a trio of Avatars, a Pansage, Pansear, and Panpour, lying in The Shelf. Says she'll make it worth your while."),
  }

  # Legendary Quests

  QUEST_LEGEND_CLONE = {
    :Name => _INTL("A Primordial Material"),
    :QuestGiver => _INTL("Dr. Hekata"),
    :Stage1 => _INTL("Talk to Dr. Hekata."),
    :Stage2 => _INTL("Return to the Path of Paradise."),
    :Stage3 => _INTL("Report back to Dr. Hekata."),
    :Location1 => _INTL("Grouz"),
    :Location2 => _INTL("Hollowed Layer"),
    :Location3 => _INTL("Grouz"),
    :QuestDescription => _INTL("Dr. Hekata gave you a call mysteriously, asking to meet her in her home of Grouz. What could she want of you?"),
  }

  QUEST_LEGEND_REGIROCK = {
    :Name => _INTL("The Age of Stone"),
    :QuestGiver => _INTL("???"),
    :Stage1 => _INTL("Explore the dungeon."),
    :Location1 => _INTL("Crumbling Canyon"),
    :QuestDescription => _INTL("A strange dungeon lies before you. A crumbling canyon, carved out and inhabitated in an ancient time. That ancient time may not be as far away as it seems, however..."),
  }

  QUEST_LEGEND_REGICE = {
    :Name => _INTL("The Age of Ice"),
    :QuestGiver => _INTL("???"),
    :Stage1 => _INTL("Explore the dungeon."),
    :Location1 => _INTL("Mirror Tundra"),
    :QuestDescription => _INTL("A strange dungeon lies before you. A frozen wasteland, locked in time and place, rigid and reflective obstacles blocking your way. Perhaps a reflection of times long past."),
  }

  QUEST_LEGEND_REGISTEEL = {
    :Name => _INTL("The Age of Steel"),
    :QuestGiver => _INTL("???"),
    :Stage1 => _INTL("Explore the dungeon."),
    :Location1 => _INTL("Alloyed Thicket"),
    :QuestDescription => _INTL("A strange dungeon lies before you. A forest made of metals and alloys. Always malleable, always changing, the line between natural and man-made thin..."),
  }

  QUEST_LEGEND_REGIELEKI = {
    :Name => _INTL("The Age of Electricity"),
    :QuestGiver => _INTL("???"),
    :Stage1 => _INTL("Explore the dungeon."),
    :Location1 => _INTL("Oasis System"),
    :QuestDescription => _INTL("A strange dungeon lies before you. Circuits run throughout the entire cave, in a similar way to the small streams of water. Electrical currents flow like water, opening the way forward to your goal."),
  }

  QUEST_LEGEND_REGIDRAGO = {
    :Name => _INTL("The Age of Myths"),
    :QuestGiver => _INTL("???"),
    :Stage1 => _INTL("Explore the dungeon."),
    :Location1 => _INTL("The Catacombs"),
    :QuestDescription => _INTL("A strange dungeon lies before you. Winding age-old catacombs, full of myths and legends. Stories will be the basis of humanity for as long as it will exist."),
  }

  QUEST_LEGEND_CELEBI = {
    :Name => _INTL("Turn Back the Clock"),
    :QuestGiver => _INTL("Celebi"),
    :Stage1 => _INTL("Plant the seeds."),
    :Location1 => _INTL("Crumbling Canyon"),
    :QuestDescription => _INTL("The mythical being named Celebi handed you four latent seeds. Perhaps you need to plant these somewhere? Afterwards, seek out Celebi."),
  }

  QUEST_LEGEND_HOOPA = {
    :Name => _INTL("Spacial Split"),
    :QuestGiver => _INTL("???"),
    :Stage1 => _INTL("Find all the lost rangers."),
    :Location1 => _INTL("Mirror Tundra"),
    :QuestDescription => _INTL("You found a strange set of... spectres? Spirits? Whatever they could be, defeating them in a battle appears to give some resolution to this situation... What could've caused this?"),
  }

  QUEST_LEGEND_MELTAN = {
    :Name => _INTL("A Collapsed Metal"),
    :QuestGiver => _INTL("???"),
    :Stage1 => _INTL("Find the Meltan scattered about."),
    :Location1 => _INTL("Alloyed Thicket"),
    :QuestDescription => _INTL("A strange metallic creature fell apart into multiple smaller creatures, and scattered about the Alloyed Thicket. What might happen if you reunite them together?"),
  }

  QUEST_LEGEND_MARSHADOW = {
    :Name => _INTL("Always In Character"),
    :QuestGiver => _INTL("The LARPers"),
    :Stage1 => _INTL("See if you can find them again."),
    :Location1 => _INTL("Makya"),
    :QuestDescription => _INTL("Quite an eclectic group you've found. You've claimed their hoard, but this surely isn't the last time you'll find yourself encountering them."),
  }

  QUEST_LEGEND_NULL = {
    :Name => _INTL("The Most Dangerous Experiment"),
    :QuestGiver => _INTL("???"),
    :Stage1 => _INTL("Fight through the scientists."),
    :Location1 => _INTL("Battle Plaza Underground"),
    :QuestDescription => _INTL("A group of scientists appear to be guarding something important. You never were one for not sticking your nose in everything, what would a bunch of nerds hold up against you?"),
  }

  QUEST_LEGEND_VICTINI = {
    :Name => _INTL("The Novo Battle Club"),
    :QuestGiver => _INTL("Fight Club Louis"),
    :Stage1 => _INTL("Ascend the ranks."),
    :Location1 => _INTL("Novo Town"),
    :QuestDescription => _INTL("Louis is holding a Battle Club in Novo town. Simply a way to entertain yourselves and your Pokémon."),
  }

  QUEST_LEGEND_MAGEARNA = {
    :Name => _INTL("Parting With a Friend"),
    :QuestGiver => _INTL("Strange Girl"),
    :Stage1 => _INTL("Trade a Pokémon."),
    :Location1 => _INTL("Tournament Lobby"),
    :QuestDescription => _INTL("An odd girl in the tournament lobby has an offer. A Pokémon you've bonded with fully, for the individual she possesses... Can you make that trade?"),
  }

  QUEST_LEGEND_VOLCANION2 = {
    :Name => _INTL("A Clean Library"),
    :QuestGiver => _INTL("Nora"),
    :Stage1 => _INTL("Go to Luxtech to find information."),
    :Stage2 => _INTL("Return to Nora with the USB."),
    :Stage3 => _INTL("Head over to the Steamy Valley."),
    :Location1 => _INTL("Luxtech Campus, Cold Storage"),
    :Location2 => _INTL("Prizca East, Capitol Building"),
    :Location3 => _INTL("Svait"),
    :QuestDescription => _INTL("Finally a library in this damned region, maybe there is some interesting information you can learn."),
  }

  QUEST_LEGEND_TRI_ISLAND = {
    :Name => _INTL("Tri Island"),
    :QuestGiver => _INTL("???"),
    :Stage1 => _INTL("Explore the strange island."),
    :Location1 => _INTL("Tri Island"),
    :QuestDescription => _INTL("The TV talked about a newly discovered island off the coast. A lot of trainers will be heading there, try to be the best one."),
  }

  QUEST_LEGEND_CALYREX2 = {
    :Name => _INTL("The King and the Corvid"),
    :QuestGiver => _INTL("???"),
    :Stage1 => _INTL("Find the hidden entrance."),
    :Stage2 => _INTL("Prove yourself to the Corviknight."),
    :Stage3 => _INTL("Explore the hidden chamber."),
    :Stage4 => _INTL("Find the grassy pits."),
    :Stage5 => _INTL("Return to the hidden chamber."),
    :Location1 => _INTL("Battle Monument"),
    :Location2 => _INTL("Under the Battle Monument"),
    :Location3 => _INTL("Under the Battle Monument"),
    :Location4 => _INTL("Spots Around Makya"),
    :Location5 => _INTL("Crown Chamber"),
    :QuestDescription => _INTL("You've opened a strange cave under the Battle Monument.  What could it be hiding?"),
  }

  QUEST_LEGEND_GUARDIAN_ISLAND = {
    :Name => _INTL("Guardian Island"),
    :QuestGiver => _INTL("???"),
    :Stage1 => _INTL("Explore the strange island."),
    :Location1 => _INTL("Guardian Island"),
    :QuestDescription => _INTL("You won the map to an abandoned island, what secrets could this place hold?"),
  }

  QUEST_LEGEND_LUGIA = {
    :Name => _INTL("Sea Monster"),
    :QuestGiver => _INTL("Ship Captain"),
    :Stage1 => _INTL("Find the great Pokémon."),
    :Location1 => _INTL("Aquatopia Menagerie"),
    :QuestDescription => _INTL("A ship captain talks about a great Pokémon in the waves. Maybe you can be the one to find this beast."),
  }

  QUEST_LEGEND_SIGIL = {
    :Name => _INTL("Carnation Sigil"),
    :QuestGiver => _INTL("???"),
    :Stage1 => _INTL("Find the other piece of the sigil."),
    :Stage2 => _INTL("Discover where the sigil takes you."),
    :Location1 => _INTL("Makya"),
    :Location2 => _INTL("Makya"),
    :QuestDescription => _INTL("You found a half of a sigil of some sort. Completing it might let it do something."),
  }

  QUEST_LEGEND_HOOH = {
    :Name => _INTL("Ruined Tower"),
    :QuestGiver => _INTL("???"),
    :Stage1 => _INTL("Collect the key."),
    :Location1 => _INTL("Makya"),
    :QuestDescription => _INTL("You saw that a wild Pokémon was holding a key. Take it, and bring it to the tower it goes to."),
  }

  QUEST_LEGEND_CONDENSED = {
    :Name => _INTL("Best Friends for Light"),
    :QuestGiver => _INTL("Your friend!"),
    :Stage1 => _INTL("Collect the Condensed Lights."),
    :Stage2 => _INTL("Find your friend :)"),
    :Location1 => _INTL("Makya"),
    :Location2 => _INTL("Velenz Menagerie"),
    :QuestDescription => _INTL("At the name Lainie, a viscous mass of pure light formed in your bag. Find out more about the girl who's friends with all of Makya."),
  }

  QUEST_LEGEND_EVENTIDE = {
    :Name => _INTL("Eventide Island"),
    :QuestGiver => _INTL("Chara"),
    :Stage1 => _INTL("Follow Chara up to the lighthouse."),
    :Stage2 => _INTL("Explore the island."),
    :Stage3 => _INTL("Catch Cresselia."),
    :Location1 => _INTL("Sweetrock Lighthouse"),
    :Location2 => _INTL("Eventide Island"),
    :Location3 => _INTL("Eventide Island"),
    :QuestDescription => _INTL("After beating former champion Chara, she told you about an island she wants you to check out."),
  }

  QUEST_LEGEND_ATOLL = {
    :Name => _INTL("Spirit Atoll"),
    :QuestGiver => _INTL("Vincent"),
    :Stage1 => _INTL("Explore the atoll."),
    :Location1 => _INTL("Spirit Atoll"),
    :QuestDescription => _INTL("Vincent told you the location of a mysterious place called the Spirit Atoll. Journey to it through your boat and explore the secrets."),
  }

  QUEST_LEGEND_DRAGON_ISLE = {
    :Name => _INTL("Isle of Dragons"),
    :QuestGiver => _INTL("Dragon Hatcher"),
    :Stage1 => _INTL("Fully evolve every Dragon Egg."),
    :Stage2 => _INTL("Explore the isle."),
    :Location1 => _INTL("Samorn's House"),
    :Location2 => _INTL("Isle of Dragons"),
    :QuestDescription => _INTL("The mysterious Dragon Hatcher in Samorn's house offers to hatch the dragon eggs you find around the region."),
  }

  QUEST_LEGEND_WEATHER_TRIO = {
    :Name => _INTL("Bad Weather"),
    :QuestGiver => _INTL("???"),
    :Stage1 => _INTL("Find the other avatar."),
    :Stage2 => _INTL("Find Rayquaza."),
    :Location1 => _INTL("Makya"),
    :Location2 => _INTL("Kilna Ascent"),
    :QuestDescription => _INTL("A trio of imposing beasts, hidden in the outer reaches of Makya. Why not add controlling the weather to your arsenal?"),
  }

  QUEST_LEGEND_GENIES = {
    :Name => _INTL("Excessive Force"),
    :QuestGiver => _INTL("Jovan"),
    :Stage1 => _INTL("Explore the cave."),
    :Stage2 => _INTL("Defend the legends."),
    :Location1 => _INTL("Oasis System"),
    :Location2 => _INTL("Sandstone Estuary"),
    :QuestDescription => _INTL("The suspicious but friendly scientist is asking for help, you've eavesdropped a bit (un)intentionally, but the whole story still alludes you. What is so important about a dumb cave in the desert?"),
  }

  QUEST_JOVAN = {
    :Name => _INTL("A Troubled Scientist"),
    :QuestGiver => _INTL("Jovan"),
    :Stage1 => _INTL("Find him again."),
    :Stage2 => _INTL("Find him again."),
    :Stage3 => _INTL("Find him again."),
    :Stage4 => _INTL("Find him again."),
    :Location1 => _INTL("Bluepoint Beach"),
    :Location2 => _INTL("Shipping Lane"),
    :Location3 => _INTL("Luxtech Campus"),
    :Location4 => _INTL("Prizca West"),
    :QuestDescription => _INTL("This scientist keeps crossing your way. He keeps giving you interesting stuff, may as well continue finding him."),
  }

  # Former Champions

  QUEST_FORMER_CHAMPIONS = {
    :Name => _INTL("Former Champions of Makya"),
    :QuestGiver => _INTL("???"),
    :Stage1 => _INTL("Find and defeat the former champs."),
    :Location1 => _INTL("Makya"),
    :QuestDescription => _INTL("Makya has seen their own fair share of champions over the years. Inevitably, they'll be dethroned by the next tournament, so they add up. You're going to be the best champion of them all though, aren't you? May as well show those rejects why they are only 'former'."),
  }

  QUEST_FORMER_ANSEL = {
    :Name => _INTL("Former Champion Ansel"),
    :QuestGiver => _INTL("Ansel"),
    :Stage1 => _INTL("Defeat another former champ."),
    :Location1 => _INTL("Battle Plaza"),
    :QuestDescription => _INTL("An older champion, show him the future is now. After proving your worth to him, at least."),
  }

  QUEST_FORMER_PRAVEEN = {
    :Name => _INTL("Former Champion Praveen"),
    :QuestGiver => _INTL("Ansel"),
    :Stage1 => _INTL("Find and defeat the former champ."),
    :Stage2 => _INTL("Catch Zarude."),
    :Location1 => _INTL("Sandstone Estuary"),
    :Location2 => _INTL("Sandstone Estuary"),
    :QuestDescription => _INTL("You've been informed you can now speak to the former champion known as Praveen. What's his deal?"),
  }

  QUEST_FORMER_SCILLA = {
    :Name => _INTL("Former Champion Scilla"),
    :QuestGiver => _INTL("Scilla"),
    :Stage1 => _INTL("Defeat the dojo."),
    :Location1 => _INTL("Ironclad Dojo"),
    :QuestDescription => _INTL("Scilla runs a dojo in Prizca East, but she isn't one to be paid off to get a black belt from. Crush all those wimps."),
  }

  QUEST_FORMER_CHARA = {
    :Name => _INTL("Former Champion Chara"),
    :QuestGiver => _INTL("Scilla"),
    :Stage1 => _INTL("Find and defeat the former champ."),
    :Location1 => _INTL("Sweetrock Harbor"),
    :QuestDescription => _INTL("It appears Chara is your next target, found in Sweetrock. You're certain this won't be anymore challenging than your previous fight."),
  }

  QUEST_FORMER_ELISE = {
    :Name => _INTL("Former Champion Elise"),
    :QuestGiver => _INTL("Elise"),
    :Stage1 => _INTL("Defeat the former champ."),
    :Location1 => _INTL("Prizca Castle"),
    :QuestDescription => _INTL("So we got a princess here, don't we? Magnificent castles can always be brought down with enough hardwork."),
  }

  QUEST_FORMER_VINCENT = {
    :Name => _INTL("Former Champion Vincent"),
    :QuestGiver => _INTL("Elise"),
    :Stage1 => _INTL("Find and defeat the former champ."),
    :Location1 => _INTL("Aquatopia Menagerie"),
    :QuestDescription => _INTL("Elise mentioned Vincent likes finding strong trainers to fight. Maybe one day you'll find a strong trainer."),
  }

  QUEST_FORMER_CASEY = {
    :Name => _INTL("Former Champion Casey"),
    :QuestGiver => _INTL("Casey"),
    :Stage1 => _INTL("Clear out the Diancie Avatar."),
    :Stage2 => _INTL("Return to Casey."),
    :Location1 => _INTL("Underpeak Tunnels"),
    :Location2 => _INTL("Casey's Basement"),
    :QuestDescription => _INTL("What are you, an exterminator? Oh well, avatars will always be fun to face, then you can show him what you think of his request."),
  }

  # Evo Stone Gauntlets

  QUEST_STONES_KILNA = {
    :Name => _INTL("The Kilna Thieves"),
    :QuestGiver => _INTL("Ranger"),
    :Stage1 => _INTL("Investigate the bandits."),
    :Location1 => _INTL("Kilna Turf"),
    :QuestDescription => _INTL("A ranger told you about how Kilna is strewn in items from thieves. Maybe they have a valuable stash you could take from."),
    :RewardString => _INTL("Ice and Leaf Stone")
  }

  QUEST_STONES_SVAIT = {
    :Name => _INTL("Rowdy Tourists"),
    :QuestGiver => _INTL("Tourist Hater"),
    :Stage1 => _INTL("Calm them down."),
    :Location1 => _INTL("Svait"),
    :QuestDescription => _INTL("You're hearing things are getting pretty rowdy with these tourists. Teach them you should always respect the places you visit!"),
    :RewardString => _INTL("Alolan and Galarian Wreath")
  }

  QUEST_STONES_VELENZ = {
    :Name => _INTL("Power of the Stone"),
    :QuestGiver => _INTL("???"),
    :Stage1 => _INTL("Release the influence."),
    :Location1 => _INTL("Velenz"),
    :QuestDescription => _INTL("Appears these people are being influenced by a strange rock... probably not healthy to leave them like that, could be radioactive."),
    :RewardString => _INTL("Shiny and Moon Stone")
  }

  QUEST_STONES_SUICUNE = {
    :Name => _INTL("Clearwater Cave"),
    :QuestGiver => _INTL("???"),
    :Stage1 => _INTL("Defeat the avatar."),
    :Location1 => _INTL("Grouz"),
    :QuestDescription => _INTL("A powerful avatar of Suicune is being contained in this cave. Perhaps it is guarding something valuable..."),
    :RewardString => _INTL("Water and Dawn Stone")
  }

  QUEST_STONES_RAIKOU = {
    :Name => _INTL("Six Spire Cave"),
    :QuestGiver => _INTL("???"),
    :Stage1 => _INTL("Defeat the avatar."),
    :Location1 => _INTL("The Shelf"),
    :QuestDescription => _INTL("A powerful avatar of Raikou is being contained in this cave. Perhaps it is guarding something valuable..."),
    :RewardString => _INTL("Thunder and Dusk Stone")
  }

  QUEST_STONES_ENTEI = {
    :Name => _INTL("Volcanic Cave"),
    :QuestGiver => _INTL("???"),
    :Stage1 => _INTL("Defeat the avatar."),
    :Location1 => _INTL("County Park"),
    :QuestDescription => _INTL("A powerful avatar of Entei is being contained in this cave. Perhaps it is guarding something valuable..."),
    :RewardString => _INTL("Fire and Sun Stone")
  }

end
