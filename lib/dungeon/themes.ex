defmodule Dungeon.Themes do
  @moduledoc """
  Defines all available dungeon themes with their properties and configurations.
  """

  # List of dungeon themes with their natural progression direction and visual themes
  @themes [
    %{
      name: "Pleasant Woods",
      transition_theme: "outdoor_waypoint",
      direction: :lateral,
      wall_theme: "green_shrubs.png",
      floor_theme: "dirt_and_grass.png",
      generation_type: "outdoor",
      fog_type: "daylight",
      monsters: [
        {"Ogre", :rare},
        {"Bandit", :uncommon},
        {"Druid", :uncommon},
        {"Fairy", :uncommon},
        {"Lizardfolk", :uncommon},
        {"Owlbear", :rare},
        {"Centaur", :uncommon},
        {"Mushroomfolk", :uncommon},
        {"Dryad", :rare},
        {"Female Druid", :uncommon},
        {"Female Elf", :uncommon},
        {"Male Elf", :uncommon}
      ],
      special_features: [
        {"Barrel", :uncommon},
        {"Campfire", :uncommon},
        {"Crate", :rare},
        {"Fungus", :common},
        {"Hut", :rare},
        {"Logs", :uncommon},
        {"Mushrooms", :common},
        {"Plant", :common},
        {"Rocks", :common},
        {"Rubble", :uncommon},
        {"Target", :uncommon},
        {"Tree", :common}
      ]
    },
    %{
      name: "Ancient Castle",
      direction: :up,
      transition_theme: "dungeon_stairs",
      wall_theme: "dark_cobblestone.png",
      floor_theme: "light_cobblestone.png",
      generation_type: "dungeon",
      fog_type: "dim",
      monsters: [
        {"Rat", :common},
        {"Orc", :common},
        {"Orc Boss", :uncommon},
        {"Orc Chieftain", :rare},
        {"Skeleton", :common},
        {"Bat Swarm", :uncommon},
        {"Animated Armor", :uncommon},
        {"Evil Mage", :uncommon},
        {"Gargoyle", :uncommon},
        {"Wailing Ghost", :uncommon},
        {"Silent Ghost", :uncommon},
        {"Lich", :rare},
        {"Assassin", :rare},
        {"Chimera", :rare},
        {"Imp Devil", :rare},
        {"Archmage", :rare},
        {"Efreeti", :rare},
        {"Griffon", :rare},
        {"Stone Golem", :rare}
      ],
      special_features: [
        {"Altar", :uncommon},
        {"Barrel", :common},
        {"Bookcase", :uncommon},
        {"Brazier", :common},
        {"Cage", :uncommon},
        {"Candle", :common},
        {"Chair", :common},
        {"Cobwebs", :common},
        {"Cupboard", :uncommon},
        {"Crown", :rare},
        {"Desk", :uncommon},
        {"Fireplace", :common},
        {"Lectern", :uncommon},
        {"Mirror", :rare},
        {"Pile of Weapons and Armor", :rare},
        {"Rug", :common},
        {"Stack of Books", :uncommon},
        {"Statue", :uncommon},
        {"Table", :common},
        {"Throne", :rare},
        {"Torture Rack", :uncommon},
        {"Weapon Rack", :uncommon}
      ]
    },
    %{
      name: "Dark Caverns",
      direction: :down,
      transition_theme: "cavern_stairs",
      wall_theme: "red_brown_cavern.png",
      floor_theme: "brown_cavern.png",
      generation_type: "cavern",
      fog_type: "dark",
      monsters: [
        {"Spider", :common},
        {"Black Pudding", :rare},
        {"Bugbear", :uncommon},
        {"Giant Centipede", :common},
        {"Bat Swarm", :common},
        {"Brain Eater", :rare},
        {"Cave Brute", :uncommon},
        {"Cave Creeper", :uncommon},
        {"Centipede Swarm", :common},
        {"Cloaker", :rare},
        {"Darkmantle", :uncommon},
        {"Drider", :rare},
        {"Drow Priestess", :rare},
        {"Drow", :rare},
        {"Giant Bat", :common},
        {"Deep Gnome", :uncommon},
        {"Duergar", :uncommon},
        {"Ettercap", :uncommon},
        {"Gelatinous Cube", :rare},
        {"Giant Dung Beetle", :common},
        {"Grick", :uncommon}
      ],
      special_features: [
        {"Barrel", :common},
        {"Brazier", :common},
        {"Cobwebs", :common},
        {"Crate", :common},
        {"Fungus", :common},
        {"Group of Barrels", :common},
        {"Magic Circle", :rare},
        {"Mushrooms", :common},
        {"Rocks", :common},
        {"Rubble", :common},
        {"Stack of Crates", :common}
      ]
    },
    %{
      name: "Ancient Catacombs",
      direction: :down,
      transition_theme: "dungeon_stairs",
      wall_theme: "dark_cobblestone.png",
      floor_theme: "red_dirt.png",
      generation_type: "dungeon",
      fog_type: "dark",
      monsters: [
        {"Rat", :common},
        {"Skeleton", :uncommon},
        {"Zombie", :common},
        {"Wailing Ghost", :rare},
        {"Giant Centipede", :common},
        {"Lich", :rare},
        {"Cloaker", :rare},
        {"Darkmantle", :uncommon},
        {"Ghoul", :uncommon},
        {"Giant Bat", :common},
        {"Gelatinous Cube", :rare},
        {"Ghast", :rare},
        {"Silent Ghost", :rare}
      ],
      special_features: [
        {"Coffin", :uncommon},
        {"Sarcophagus", :uncommon},
        {"Cobwebs", :common},
        {"Debris", :common},
        {"Rubble", :common},
        {"Candle", :common},
        {"Altar", :uncommon},
        {"Statue", :uncommon}
      ]
    },
    %{
      name: "Haunted Forest",
      transition_theme: "outdoor_waypoint",
      direction: :lateral,
      wall_theme: "haunted_forest_shrubs.png",
      floor_theme: "haunted_ground.png",
      generation_type: "outdoor",
      fog_type: "dim",
      monsters: [
        {"Spider", :common},
        {"Zombie", :common},
        {"Scary Face", :rare},
        {"Bandit", :uncommon},
        {"Bugbear", :uncommon},
        {"Wailing Ghost", :rare},
        {"Silent Ghost", :rare},
        {"Harpy", :rare},
        {"Hobgoblin", :uncommon},
        {"Owlbear", :rare},
        {"Bat Swarm", :uncommon},
        {"Beastman", :uncommon},
        {"Ghoul", :uncommon},
        {"Giant Bat", :common},
        {"Ettercap", :uncommon},
        {"Flesh Golem", :rare},
        {"Ghast", :rare},
        {"Giant Frog", :common},
        {"Gnoll", :uncommon},
        {"Weald Hag", :elite}
      ],
      special_features: [
        {"Barrel", :common},
        {"Campfire", :common},
        {"Cobwebs", :common},
        {"Coffin", :uncommon},
        {"Fungus", :common},
        {"Logs", :common},
        {"Rocks", :common},
        {"Statue", :uncommon},
        {"Tree", :common},
        {"Well", :uncommon}
      ]
    },
    %{
      name: "Cultist Lair",
      direction: :down,
      transition_theme: "dungeon_stairs",
      wall_theme: "dark_cobblestone.png",
      floor_theme: "gray_cavern.png",
      generation_type: "dungeon",
      fog_type: "dim",
      monsters: [
        {"Rat", :common},
        {"Evil Mage", :rare},
        {"Assassin", :rare},
        {"Brain Eater", :rare},
        {"Cultist Fighter", :uncommon},
        {"Cultist Mage", :rare},
        {"Imp Devil", :rare},
        {"Evil Guard", :uncommon},
        {"Flesh Golem", :rare}
      ],
      special_features: [
        {"Altar", :uncommon},
        {"Barrel", :common},
        {"Bookcase", :uncommon},
        {"Brazier", :common},
        {"Cage", :common},
        {"Candle", :common},
        {"Chair", :common},
        {"Cot", :common},
        {"Crate", :common},
        {"Cupboard", :common},
        {"Desk", :uncommon},
        {"Fireplace", :common},
        {"Group of Barrels", :common},
        {"Lectern", :uncommon},
        {"Magic Circle", :rare},
        {"Obelisk", :rare},
        {"Pool", :uncommon},
        {"Rug", :common},
        {"Stack of Books", :uncommon},
        {"Stack of Crates", :common},
        {"Statue", :uncommon},
        {"Stool", :common},
        {"Table", :common},
        {"Torture Rack", :uncommon},
        {"Treasure Pile", :rare},
        {"Weapon Rack", :uncommon}
      ]
    },
    %{
      name: "Goblin Lair",
      direction: :down,
      transition_theme: "cavern_stairs",
      wall_theme: "red_brown_cavern.png",
      floor_theme: "red_dirt.png",
      generation_type: "cavern",
      fog_type: "dim",
      monsters: [
        {"Rat", :common},
        {"Spider", :common},
        {"Goblin Scout", :common},
        {"Goblin Warrior", :common},
        {"Boar", :common},
        {"Goblin Shaman", :uncommon},
        {"Centipede Swarm", :uncommon},
        {"Giant Bat", :uncommon},
        {"Giant Dung Beetle", :uncommon},
        {"Cave Creeper", :uncommon},
        {"Cave Brute", :uncommon},
        {"Hobgoblin", :uncommon},
        {"Bugbear", :uncommon},
        {"Bat Swarm", :uncommon},
        {"Goblin Boss", :rare},
        {"Gelatinous Cube", :rare},
        {"Ogre", :rare}
      ],
      special_features: [
        {"Barrel", :common},
        {"Campfire", :common},
        {"Cobwebs", :common},
        {"Crate", :common},
        {"Debris", :common},
        {"Fungus", :common},
        {"Logs", :common},
        {"Mushrooms", :common},
        {"Pile of Chests", :rare},
        {"Pile of Weapons and Armor", :rare},
        {"Pit", :uncommon},
        {"Rocks", :common},
        {"Rubble", :common},
        {"Stack of Crates", :common},
        {"Stool", :common},
        {"Weapon Rack", :uncommon}
      ]
    },
    %{
      name: "Forgotten Temple",
      direction: :up,
      transition_theme: "dungeon_stairs",
      wall_theme: "dark_square_stones.png",
      floor_theme: "light_cracked_stone.png",
      generation_type: "dungeon",
      fog_type: "dark",
      monsters: [
        {"Spider", :common},
        {"Evil Lizardfolk", :uncommon},
        {"Gargoyle", :uncommon},
        {"Kobold Spearman", :common},
        {"Kobold Slinger", :common},
        {"Kobold Shaman", :rare},
        {"Kobold Warlock", :rare},
        {"Medusa", :rare},
        {"Bat Swarm", :uncommon},
        {"Gorgon", :rare},
        {"Snow Ape", :uncommon},
        {"Stone Golem", :rare},
        {"Cyclops", :rare}
      ],
      special_features: [
        {"Altar", :uncommon},
        {"Brazier", :common},
        {"Cage", :uncommon},
        {"Crate", :common},
        {"Debris", :common},
        {"Group of Barrels", :common},
        {"Magic Circle", :rare},
        {"Obelisk", :rare},
        {"Pile of Chests", :rare},
        {"Pile of Weapons and Armor", :rare},
        {"Rubble", :common},
        {"Sarcophagus", :uncommon},
        {"Stack of Crates", :common},
        {"Statue", :uncommon},
        {"Throne", :rare},
        {"Treasure Pile", :rare},
        {"Weapon Rack", :uncommon}
      ]
    },
    %{
      name: "Ancient Temple",
      direction: :up,
      transition_theme: "dungeon_stairs",
      wall_theme: "dark_stone_with_vines.png",
      floor_theme: "light_cracked_stone.png",
      generation_type: "dungeon",
      fog_type: "dark",
      monsters: [
        {"Rat", :common},
        {"Centipede Swarm", :common},
        {"Skeleton", :uncommon},
        {"Berserker", :uncommon},
        {"Wailing Ghost", :rare},
        {"Silent Ghost", :rare},
        {"Mummy", :uncommon},
        {"Minotaur", :rare},
        {"Chimera", :rare},
        {"Deep Gnome", :uncommon},
        {"Efreeti", :rare},
        {"Gorgon", :rare},
        {"Iron Golem", :rare},
        {"Ghoul", :uncommon},
        {"Ghast", :rare},
        {"Cyclops", :rare}
      ],
      special_features: [
        {"Altar", :uncommon},
        {"Brazier", :common},
        {"Candle", :common},
        {"Crown", :rare},
        {"Debris", :common},
        {"Obelisk", :rare},
        {"Rubble", :common},
        {"Sarcophagus", :uncommon},
        {"Statue", :uncommon},
        {"Throne", :rare},
        {"Treasure Pile", :rare},
        {"Weapon Rack", :uncommon}
      ]
    },
    %{
      name: "Merchant Town",
      direction: :lateral,
      transition_theme: "outdoor_waypoint",
      wall_theme: "dark_square_stones.png",
      floor_theme: "wood_boards.png",
      road_theme: "dirt_and_grass.png",
      shrub_theme: "green_shrubs.png",
      generation_type: "city",
      fog_type: "daylight",
      monsters: [
        {"Rat", :common}
      ],
      indoor_monsters: [
        {"Merchant", :common},
        {"Innkeeper", :uncommon},
        {"Maid", :uncommon},
        {"Apprentice", :uncommon},
        {"Acolyte", :uncommon},
        {"Hooded Acolyte", :uncommon}
      ],
      outdoor_monsters: [
        {"Guard", :common},
        {"Town Guard", :common},
        {"Thug", :common},
        {"Acolyte", :uncommon},
        {"Boar", :common},
        {"Assassin", :rare}
      ],
      indoor_features: [
        {"Altar", :uncommon},
        {"Bookcase", :uncommon},
        {"Chair", :common},
        {"Cot", :common},
        {"Cupboard", :common},
        {"Desk", :common},
        {"Fireplace", :common},
        {"Lectern", :uncommon},
        {"Mirror", :uncommon},
        {"Rug", :common},
        {"Stack of Books", :uncommon},
        {"Statue", :uncommon},
        {"Table", :common}
      ],
      outdoor_features: [
        {"Barrel", :common},
        {"Campfire", :common},
        {"Crate", :common},
        {"Fountain", :uncommon},
        {"Group of Barrels", :common},
        {"Stack of Crates", :common},
        {"Target", :common},
        {"Well", :uncommon},
        {"Tent", :uncommon}
      ]
    },
    %{
      name: "Ghost Town",
      direction: :lateral,
      transition_theme: "outdoor_waypoint",
      wall_theme: "dark_cobblestone.png",
      floor_theme: "wood_boards2.png",
      road_theme: "haunted_ground.png",
      shrub_theme: "haunted_forest_shrubs.png",
      generation_type: "city",
      fog_type: "dim",
      monsters: [
        {"Zombie", :common}
      ],
      indoor_monsters: [
        {"Rat", :common},
        {"Zombie", :common},
        {"Scary Face", :rare},
        {"Bat Swarm", :uncommon},
        {"Ghast", :rare},
        {"Wailing Ghost", :rare},
        {"Silent Ghost", :rare},
        {"Night Hag", :elite}
      ],
      outdoor_monsters: [
        {"Spider", :common},
        {"Zombie", :common},
        {"Bugbear", :uncommon},
        {"Harpy", :rare},
        {"Beastman", :uncommon},
        {"Ghoul", :uncommon},
        {"Ettercap", :uncommon},
        {"Giant Frog", :common},
        {"Gnoll", :uncommon},
        {"Weald Hag", :elite}
      ],
      indoor_features: [
        {"Bookcase", :uncommon},
        {"Chair", :common},
        {"Crate", :common},
        {"Cobwebs", :common},
        {"Cot", :common},
        {"Cupboard", :common},
        {"Desk", :uncommon},
        {"Debris", :common},
        {"Fireplace", :common},
        {"Lectern", :uncommon},
        {"Mirror", :uncommon},
        {"Rug", :common},
        {"Stack of Books", :uncommon},
        {"Stool", :common},
        {"Table", :common}
      ],
      outdoor_features: [
        {"Barrel", :common},
        {"Campfire", :common},
        {"Cobwebs", :common},
        {"Coffin", :uncommon},
        {"Group of Barrels", :common},
        {"Logs", :common},
        {"Mushrooms", :common},
        {"Rocks", :common},
        {"Rubble", :common},
        {"Tree", :common},
        {"Well", :uncommon}
      ]
    },
    %{
      name: "White Palace",
      direction: :up,
      transition_theme: "dungeon_stairs",
      wall_theme: "light_stones.png",
      floor_theme: "marble.png",
      generation_type: "dungeon",
      fog_type: "dim",
      monsters: [
        {"Male Elf", :uncommon},
        {"Female Elf", :uncommon},
        {"Animated Armor", :uncommon},
        {"Apprentice", :uncommon},
        {"Fairy", :uncommon},
        {"Gargoyle", :uncommon},
        {"Chimera", :rare},
        {"Archmage", :rare},
        {"Griffon", :rare},
        {"Iron Golem", :rare},
        {"Mage", :uncommon}
      ],
      special_features: [
        {"Altar", :uncommon},
        {"Barrel", :common},
        {"Bookcase", :uncommon},
        {"Chair", :common},
        {"Cot", :common},
        {"Crown", :rare},
        {"Dais", :uncommon},
        {"Desk", :uncommon},
        {"Fountain", :uncommon},
        {"Lectern", :uncommon},
        {"Magic Circle", :rare},
        {"Magic Portal", :rare},
        {"Mirror", :uncommon},
        {"Pedestal", :uncommon},
        {"Pillar", :common},
        {"Rug", :common},
        {"Stack of Books", :uncommon},
        {"Statue", :uncommon},
        {"Stool", :common},
        {"Treasure Pile", :rare},
        {"Weapon Rack", :uncommon},
        {"Obelisk", :rare},
        {"Throne", :rare}
      ]
    },
    %{
      name: "Lost Jungle",
      direction: :lateral,
      transition_theme: "outdoor_waypoint",
      wall_theme: "dark_jungle.png",
      floor_theme: "jungle_path.png",
      generation_type: "outdoor",
      fog_type: "dim",
      monsters: [
        {"Giant Centipede", :common},
        {"Boar", :common},
        {"Gorilla", :uncommon},
        {"Giant Bat", :common},
        {"Bat Swarm", :uncommon},
        {"Mushroomfolk", :uncommon},
        {"Spider", :common},
        {"Berserker", :uncommon},
        {"Druid", :uncommon},
        {"Evil Lizardfolk", :uncommon},
        {"Fairy", :uncommon},
        {"Gargoyle", :rare},
        {"Harpy", :rare},
        {"Beastman", :uncommon},
        {"Centaur", :uncommon},
        {"Cyclops", :rare},
        {"Dryad", :rare},
        {"Female Druid", :uncommon},
        {"Giant Dung Beetle", :common},
        {"Giant Frog", :common},
        {"Stone Golem", :rare},
        {"Weald Hag", :elite}
      ],
      special_features: [
        {"Mushrooms", :common},
        {"Fungus", :common},
        {"Logs", :common},
        {"Campfire", :common},
        {"Rocks", :common},
        {"Rubble", :common},
        {"Pillar", :uncommon},
        {"Statue", :uncommon},
        {"Fountain", :rare},
        {"Obelisk", :rare},
        {"Pool", :uncommon},
        {"Tent", :uncommon},
        {"Brazier", :uncommon}
      ]
    },
    %{
      name: "Wizard's Tower",
      direction: :down,
      transition_theme: "dungeon_stairs",
      wall_theme: "iron_plates.png",
      floor_theme: "mystical.png",
      generation_type: "dungeon",
      fog_type: "dark",
      monsters: [
        {"Animated Armor", :uncommon},
        {"Apprentice", :uncommon},
        {"Evil Mage", :rare},
        {"Gargoyle", :uncommon},
        {"Gibbering Mouther", :rare},
        {"Mimic", :rare},
        {"Chimera", :rare},
        {"Doppelganger", :rare},
        {"Imp Devil", :rare},
        {"Efreeti", :rare},
        {"Evil Guard", :uncommon},
        {"Flesh Golem", :rare},
        {"Hell Hound", :uncommon},
        {"Night Hag", :elite}
      ],
      special_features: [
        {"Altar", :uncommon},
        {"Barrel", :common},
        {"Bookcase", :uncommon},
        {"Brazier", :common},
        {"Candle", :common},
        {"Chair", :common},
        {"Crown", :rare},
        {"Desk", :uncommon},
        {"Fireplace", :common},
        {"Group of Barrels", :common},
        {"Lectern", :uncommon},
        {"Magic Circle", :rare},
        {"Magic Portal", :rare},
        {"Mirror", :uncommon},
        {"Pile of Chests", :rare},
        {"Pool", :uncommon},
        {"Rug", :common},
        {"Stack of Books", :uncommon},
        {"Stack of Crates", :common},
        {"Statue", :uncommon},
        {"Stool", :common},
        {"Table", :common},
        {"Throne", :rare},
        {"Treasure Pile", :rare},
        {"Weapon Rack", :uncommon}
      ]
    }
  ]

  @doc """
  Returns the list of all available themes.
  """
  def get_themes, do: @themes

  @doc """
  Returns themes filtered by generation type.
  """
  def get_themes_by_type(generation_type) do
    @themes
    |> Enum.filter(fn theme -> theme.generation_type == generation_type end)
    |> Enum.map(fn theme -> %{name: theme.name, generation_type: theme.generation_type} end)
  end

  @doc """
  Find a theme by name.
  """
  def find_theme_by_name(theme_name) do
    Enum.find(@themes, fn theme -> theme.name == theme_name end)
  end

  @doc """
  Get a random theme.
  """
  def get_random_theme do
    Enum.random(@themes)
  end

  @doc """
  Get a random theme of the specified generation type.
  """
  def get_random_theme_by_type(generation_type) do
    themes_of_type =
      Enum.filter(@themes, fn theme -> theme.generation_type == generation_type end)

    case themes_of_type do
      [] -> nil
      themes -> Enum.random(themes)
    end
  end
end
