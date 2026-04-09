defmodule Dungeon.Monster do
  @moduledoc """
  Monster definitions and attributes for the combat system
  """

  defstruct [
    :name,
    :image,
    :armor_class,
    :hit_points,
    :attack_bonus,
    :damage_dice,
    :weapon,
    :current_hit_points,
    :max_hit_points,
    :treasure,
    :rarity,
    :size,
    :role,
    :alignment,
    :challenge_rating,
    :hunts_player?
  ]

  def all_monsters do
    [
      %__MODULE__{
        name: "Acolyte",
        image: "acolyte.png",
        armor_class: 10,
        hit_points: 5,
        attack_bonus: 1,
        damage_dice: "1d6",
        weapon: "Mace",
        treasure: "1d4",
        rarity: :common,
        size: 1.0,
        role: "npc",
        alignment: :lawful,
        challenge_rating: 1,
        hunts_player?: false
      },
      %__MODULE__{
        name: "Hooded Acolyte",
        image: "hooded_acolyte.png",
        armor_class: 11,
        hit_points: 6,
        attack_bonus: 2,
        damage_dice: "1d6",
        weapon: "Mace",
        treasure: "1d4",
        rarity: :uncommon,
        size: 1.0,
        role: "npc",
        alignment: :lawful,
        challenge_rating: 1,
        hunts_player?: false
      },
      %__MODULE__{
        name: "Animated Armor",
        image: "animated_armor.png",
        armor_class: 16,
        hit_points: 18,
        attack_bonus: 4,
        damage_dice: "1d8",
        weapon: "Sword",
        treasure: nil,
        rarity: :uncommon,
        size: 1.0,
        role: nil,
        alignment: :neutral,
        challenge_rating: 4,
        hunts_player?: true
      },
      %__MODULE__{
        name: "Ant",
        image: "ant.png",
        armor_class: 12,
        hit_points: 2,
        attack_bonus: 1,
        damage_dice: "1d2",
        weapon: "Mandibles",
        treasure: "1d4",
        rarity: :common,
        size: 0.75,
        role: nil,
        alignment: :neutral,
        challenge_rating: 1,
        hunts_player?: false
      },
      %__MODULE__{
        name: "Apprentice",
        image: "apprentice.png",
        armor_class: 11,
        hit_points: 6,
        attack_bonus: 1,
        damage_dice: "1d4",
        weapon: "Dagger",
        treasure: "1d4",
        rarity: :common,
        size: 1.0,
        role: "npc",
        alignment: :neutral,
        challenge_rating: 1,
        hunts_player?: false
      },
      %__MODULE__{
        name: "Archmage",
        image: "archmage.png",
        armor_class: 14,
        hit_points: 18,
        attack_bonus: 5,
        damage_dice: "2d8",
        weapon: "Arcane Blast",
        treasure: "3d6",
        rarity: :elite,
        size: 1.0,
        role: nil,
        alignment: :neutral,
        challenge_rating: 4,
        hunts_player?: true
      },
      %__MODULE__{
        name: "Assassin",
        image: "assassin.png",
        armor_class: 15,
        hit_points: 12,
        attack_bonus: 4,
        damage_dice: "2d4",
        weapon: "Dagger",
        treasure: "2d6",
        rarity: :rare,
        size: 1.0,
        role: nil,
        alignment: :chaotic,
        challenge_rating: 4,
        hunts_player?: true
      },
      %__MODULE__{
        name: "Bandit",
        image: "bandit.png",
        armor_class: 12,
        hit_points: 8,
        attack_bonus: 2,
        damage_dice: "1d6",
        weapon: "Club",
        treasure: "1d6",
        rarity: :common,
        size: 1.0,
        role: nil,
        alignment: :chaotic,
        challenge_rating: 2,
        hunts_player?: true
      },
      %__MODULE__{
        name: "Bat Swarm",
        image: "bat_swarm.png",
        armor_class: 13,
        hit_points: 8,
        attack_bonus: 2,
        damage_dice: "2d4",
        weapon: "Bite",
        treasure: nil,
        rarity: :uncommon,
        size: 1.25,
        role: nil,
        alignment: :neutral,
        challenge_rating: 2,
        hunts_player?: true
      },
      %__MODULE__{
        name: "Beastman",
        image: "beastman.png",
        armor_class: 14,
        hit_points: 14,
        attack_bonus: 3,
        damage_dice: "1d8",
        weapon: "Spear",
        treasure: "1d6",
        rarity: :uncommon,
        size: 1.25,
        role: nil,
        alignment: :chaotic,
        challenge_rating: 4,
        hunts_player?: true
      },
      %__MODULE__{
        name: "Berserker",
        image: "berserker.png",
        armor_class: 13,
        hit_points: 14,
        attack_bonus: 3,
        damage_dice: "1d8",
        weapon: "Greataxe",
        treasure: "1d12",
        rarity: :uncommon,
        size: 1.25,
        role: nil,
        alignment: :chaotic,
        challenge_rating: 2,
        hunts_player?: true
      },
      %__MODULE__{
        name: "Black Pudding",
        image: "black_pudding.png",
        armor_class: 12,
        hit_points: 22,
        attack_bonus: 3,
        damage_dice: "2d6",
        weapon: "Acidic Slam",
        treasure: nil,
        rarity: :rare,
        size: 1.5,
        role: nil,
        alignment: :chaotic,
        challenge_rating: 4,
        hunts_player?: true
      },
      %__MODULE__{
        name: "Blob Fish",
        image: "blob_fish.png",
        armor_class: 9,
        hit_points: 8,
        attack_bonus: 0,
        damage_dice: "1d4",
        weapon: "Gooey Slap",
        treasure: nil,
        rarity: :common,
        size: 1.0,
        role: nil,
        alignment: :neutral,
        challenge_rating: 2,
        hunts_player?: false
      },
      %__MODULE__{
        name: "Boar",
        image: "boar.png",
        armor_class: 12,
        hit_points: 5,
        attack_bonus: 2,
        damage_dice: "1d6",
        weapon: "Tusks",
        treasure: nil,
        rarity: :common,
        size: 1.0,
        role: nil,
        alignment: :neutral,
        challenge_rating: 2,
        hunts_player?: false
      },
      %__MODULE__{
        name: "Brain Eater",
        image: "brain_eater.png",
        armor_class: 15,
        hit_points: 16,
        attack_bonus: 4,
        damage_dice: "1d10",
        weapon: "Psychic Blast",
        treasure: "2d6",
        rarity: :rare,
        size: 1.0,
        role: nil,
        alignment: :chaotic,
        challenge_rating: 4,
        hunts_player?: true
      },
      %__MODULE__{
        name: "Bugbear",
        image: "bugbear.png",
        armor_class: 15,
        hit_points: 16,
        attack_bonus: 3,
        damage_dice: "2d6",
        weapon: "Morningstar",
        treasure: "2d6",
        rarity: :uncommon,
        size: 1.50,
        role: nil,
        alignment: :chaotic,
        challenge_rating: 3,
        hunts_player?: true
      },
      %__MODULE__{
        name: "Cave Brute",
        image: "cave_brute.png",
        armor_class: 13,
        hit_points: 18,
        attack_bonus: 3,
        damage_dice: "2d6",
        weapon: "Claws",
        treasure: nil,
        rarity: :uncommon,
        size: 1.5,
        role: nil,
        alignment: :chaotic,
        challenge_rating: 5,
        hunts_player?: true
      },
      %__MODULE__{
        name: "Cave Creeper",
        image: "cave_creeper.png",
        armor_class: 12,
        hit_points: 9,
        attack_bonus: 2,
        damage_dice: "1d6",
        weapon: "Bite",
        treasure: nil,
        rarity: :common,
        size: 1.5,
        role: nil,
        alignment: :neutral,
        challenge_rating: 2,
        hunts_player?: true
      },
      %__MODULE__{
        name: "Centaur",
        image: "centaur.png",
        armor_class: 14,
        hit_points: 15,
        attack_bonus: 3,
        damage_dice: "1d8",
        weapon: "Spear",
        treasure: "2d6",
        rarity: :uncommon,
        size: 1.5,
        role: nil,
        alignment: :neutral,
        challenge_rating: 4,
        hunts_player?: false
      },
      %__MODULE__{
        name: "Centipede Swarm",
        image: "centipede_swarm.png",
        armor_class: 12,
        hit_points: 7,
        attack_bonus: 2,
        damage_dice: "2d4",
        weapon: "Bite",
        treasure: nil,
        rarity: :common,
        size: 1.0,
        role: nil,
        alignment: :neutral,
        challenge_rating: 2,
        hunts_player?: true
      },
      %__MODULE__{
        name: "Chimera",
        image: "chimera.png",
        armor_class: 16,
        hit_points: 22,
        attack_bonus: 5,
        damage_dice: "2d8",
        weapon: "Fire Breath",
        treasure: "3d6",
        rarity: :elite,
        size: 2.0,
        role: nil,
        alignment: :chaotic,
        challenge_rating: 6,
        hunts_player?: true
      },
      %__MODULE__{
        name: "Clay Golem",
        image: "clay_golem.png",
        armor_class: 16,
        hit_points: 30,
        attack_bonus: 4,
        damage_dice: "2d10",
        weapon: "Slam",
        treasure: nil,
        rarity: :elite,
        size: 2.0,
        role: nil,
        alignment: :neutral,
        challenge_rating: 6,
        hunts_player?: true
      },
      %__MODULE__{
        name: "Cloaker",
        image: "cloaker.png",
        armor_class: 15,
        hit_points: 13,
        attack_bonus: 4,
        damage_dice: "1d8",
        weapon: "Bite",
        treasure: nil,
        rarity: :rare,
        size: 1.25,
        role: nil,
        alignment: :chaotic,
        challenge_rating: 3,
        hunts_player?: true
      },
      %__MODULE__{
        name: "Cultist Fighter",
        image: "cultist_fighter.png",
        armor_class: 13,
        hit_points: 8,
        attack_bonus: 2,
        damage_dice: "1d8",
        weapon: "Sword",
        treasure: "1d4",
        rarity: :common,
        size: 1.0,
        role: nil,
        alignment: :chaotic,
        challenge_rating: 2,
        hunts_player?: true
      },
      %__MODULE__{
        name: "Cultist Mage",
        image: "cultist_mage.png",
        armor_class: 12,
        hit_points: 7,
        attack_bonus: 3,
        damage_dice: "1d8",
        weapon: "Magic Bolt",
        treasure: "1d6",
        rarity: :uncommon,
        size: 1.0,
        role: nil,
        alignment: :chaotic,
        challenge_rating: 2,
        hunts_player?: true
      },
      %__MODULE__{
        name: "Cyclops",
        image: "cyclops.png",
        armor_class: 14,
        hit_points: 20,
        attack_bonus: 4,
        damage_dice: "2d6",
        weapon: "Club",
        treasure: "2d6",
        rarity: :rare,
        size: 2.0,
        role: nil,
        alignment: :chaotic,
        challenge_rating: 4,
        hunts_player?: true
      },
      %__MODULE__{
        name: "Dark Elf",
        image: "dark_elf.png",
        armor_class: 15,
        hit_points: 9,
        attack_bonus: 1,
        damage_dice: "1d8",
        weapon: "Rapier",
        treasure: "2d6",
        rarity: :rare,
        size: 1.0,
        role: nil,
        alignment: :chaotic,
        challenge_rating: 3,
        hunts_player?: true
      },
      %__MODULE__{
        name: "Darkmantle",
        image: "darkmantle.png",
        armor_class: 13,
        hit_points: 8,
        attack_bonus: 2,
        damage_dice: "1d6",
        weapon: "Crush",
        treasure: nil,
        rarity: :uncommon,
        size: 1.0,
        role: nil,
        alignment: :chaotic,
        challenge_rating: 3,
        hunts_player?: true
      },
      %__MODULE__{
        name: "Deep Gnome",
        image: "deep_gnome.png",
        armor_class: 13,
        hit_points: 7,
        attack_bonus: 1,
        damage_dice: "1d4",
        weapon: "Pickaxe",
        treasure: "1d6",
        rarity: :uncommon,
        size: 0.75,
        role: nil,
        alignment: :neutral,
        challenge_rating: 2,
        hunts_player?: false
      },
      %__MODULE__{
        name: "Doppelganger",
        image: "doppelganger.png",
        armor_class: 14,
        hit_points: 12,
        attack_bonus: 3,
        damage_dice: "1d8",
        weapon: "Slam",
        treasure: "2d6",
        rarity: :rare,
        size: 1.0,
        role: nil,
        alignment: :neutral,
        challenge_rating: 4,
        hunts_player?: true
      },
      %__MODULE__{
        name: "Drider",
        image: "drider.png",
        armor_class: 16,
        hit_points: 18,
        attack_bonus: 4,
        damage_dice: "2d6",
        weapon: "Spear",
        treasure: "2d6",
        rarity: :rare,
        size: 1.5,
        role: nil,
        alignment: :chaotic,
        challenge_rating: 5,
        hunts_player?: true
      },
      %__MODULE__{
        name: "Drow",
        image: "drow.png",
        armor_class: 14,
        hit_points: 10,
        attack_bonus: 2,
        damage_dice: "1d6",
        weapon: "Sword",
        treasure: "1d6",
        rarity: :uncommon,
        size: 1.0,
        role: nil,
        alignment: :chaotic,
        challenge_rating: 3,
        hunts_player?: true
      },
      %__MODULE__{
        name: "Drow Priestess",
        image: "drow_priestess.png",
        armor_class: 15,
        hit_points: 14,
        attack_bonus: 4,
        damage_dice: "1d10",
        weapon: "Whip",
        treasure: "2d6",
        rarity: :rare,
        size: 1.0,
        role: nil,
        alignment: :chaotic,
        challenge_rating: 4,
        hunts_player?: true
      },
      %__MODULE__{
        name: "Druid",
        image: "druid.png",
        armor_class: 12,
        hit_points: 10,
        attack_bonus: 2,
        damage_dice: "1d6",
        weapon: "Staff",
        treasure: "1d6",
        rarity: :uncommon,
        size: 1.0,
        role: "npc",
        alignment: :neutral,
        challenge_rating: 2,
        hunts_player?: false
      },
      %__MODULE__{
        name: "Dryad",
        image: "dryad.png",
        armor_class: 13,
        hit_points: 8,
        attack_bonus: 2,
        damage_dice: "1d6",
        weapon: "Staff",
        treasure: "1d6",
        rarity: :uncommon,
        size: 1.0,
        role: nil,
        alignment: :neutral,
        challenge_rating: 2,
        hunts_player?: false
      },
      %__MODULE__{
        name: "Duergar",
        image: "duergar.png",
        armor_class: 15,
        hit_points: 12,
        attack_bonus: 3,
        damage_dice: "1d8",
        weapon: "Warhammer",
        treasure: "1d8",
        rarity: :uncommon,
        size: 0.75,
        role: nil,
        alignment: :neutral,
        challenge_rating: 3,
        hunts_player?: true
      },
      %__MODULE__{
        name: "Efreeti",
        image: "efreeti.png",
        armor_class: 17,
        hit_points: 28,
        attack_bonus: 6,
        damage_dice: "2d10",
        weapon: "Flame Blade",
        treasure: "2d8",
        rarity: :elite,
        size: 2.0,
        role: nil,
        alignment: :chaotic,
        challenge_rating: 6,
        hunts_player?: true
      },
      %__MODULE__{
        name: "Ettercap",
        image: "ettercap.png",
        armor_class: 13,
        hit_points: 10,
        attack_bonus: 2,
        damage_dice: "1d8",
        weapon: "Poison Bite",
        treasure: "1d6",
        rarity: :uncommon,
        size: 1.25,
        role: nil,
        alignment: :chaotic,
        challenge_rating: 3,
        hunts_player?: true
      },
      %__MODULE__{
        name: "Evil Guard",
        image: "evil_guard.png",
        armor_class: 15,
        hit_points: 10,
        attack_bonus: 3,
        damage_dice: "1d10",
        weapon: "Halberd",
        treasure: "1d6",
        rarity: :uncommon,
        size: 1.0,
        role: "guard",
        alignment: :chaotic,
        challenge_rating: 3,
        hunts_player?: true
      },
      %__MODULE__{
        name: "Evil Lizardfolk",
        image: "evil_lizardfolk.png",
        armor_class: 14,
        hit_points: 13,
        attack_bonus: 2,
        damage_dice: "1d8",
        weapon: "Spear",
        treasure: "1d6",
        rarity: :uncommon,
        size: 1.0,
        role: nil,
        alignment: :chaotic,
        challenge_rating: 3,
        hunts_player?: true
      },
      %__MODULE__{
        name: "Evil Mage",
        image: "evil_mage.png",
        armor_class: 12,
        hit_points: 9,
        attack_bonus: 3,
        damage_dice: "1d10",
        weapon: "Fireball",
        treasure: "2d6",
        rarity: :rare,
        size: 1.0,
        role: nil,
        alignment: :chaotic,
        challenge_rating: 3,
        hunts_player?: true
      },
      %__MODULE__{
        name: "Evil Piggy",
        image: "evil_piggy.png",
        armor_class: 12,
        hit_points: 7,
        attack_bonus: 1,
        damage_dice: "1d6",
        weapon: "Tusks",
        treasure: "1d4",
        rarity: :common,
        size: 1.0,
        role: nil,
        alignment: :chaotic,
        challenge_rating: 2,
        hunts_player?: true
      },
      %__MODULE__{
        name: "Fairy",
        image: "fairy.png",
        armor_class: 15,
        hit_points: 4,
        attack_bonus: 2,
        damage_dice: "1d4",
        weapon: "Dagger",
        treasure: "1d4",
        rarity: :rare,
        size: 0.75,
        role: nil,
        alignment: :neutral,
        challenge_rating: 2,
        hunts_player?: false
      },
      %__MODULE__{
        name: "Female Druid",
        image: "female_druid.png",
        armor_class: 12,
        hit_points: 10,
        attack_bonus: 2,
        damage_dice: "1d6",
        weapon: "Staff",
        treasure: "1d6",
        rarity: :uncommon,
        size: 1.0,
        role: "npc",
        alignment: :neutral,
        challenge_rating: 2,
        hunts_player?: false
      },
      %__MODULE__{
        name: "Female Elf",
        image: "female_elf.png",
        armor_class: 14,
        hit_points: 8,
        attack_bonus: 2,
        damage_dice: "1d6",
        weapon: "Shortbow",
        treasure: "1d6",
        rarity: :uncommon,
        size: 1.0,
        role: nil,
        alignment: :neutral,
        challenge_rating: 2,
        hunts_player?: false
      },
      %__MODULE__{
        name: "Flesh Golem",
        image: "flesh_golem.png",
        armor_class: 15,
        hit_points: 28,
        attack_bonus: 4,
        damage_dice: "2d8",
        weapon: "Slam",
        treasure: nil,
        rarity: :elite,
        size: 2.0,
        role: nil,
        alignment: :neutral,
        challenge_rating: 6,
        hunts_player?: true
      },
      %__MODULE__{
        name: "Gargoyle",
        image: "gargoyle.png",
        armor_class: 17,
        hit_points: 22,
        attack_bonus: 4,
        damage_dice: "2d6",
        weapon: "Claws",
        treasure: nil,
        rarity: :rare,
        size: 1.50,
        role: nil,
        alignment: :chaotic,
        challenge_rating: 4,
        hunts_player?: true
      },
      %__MODULE__{
        name: "Gelatinous Cube",
        image: "gelatinous_cube.png",
        armor_class: 6,
        hit_points: 22,
        attack_bonus: 3,
        damage_dice: "2d6",
        weapon: "Acid",
        treasure: "2d6",
        rarity: :rare,
        size: 3.0,
        role: nil,
        alignment: :neutral,
        challenge_rating: 4,
        hunts_player?: true
      },
      %__MODULE__{
        name: "Ghast",
        image: "ghast.png",
        armor_class: 14,
        hit_points: 13,
        attack_bonus: 3,
        damage_dice: "1d8",
        weapon: "Claws",
        treasure: nil,
        rarity: :uncommon,
        size: 1.0,
        role: nil,
        alignment: :chaotic,
        challenge_rating: 4,
        hunts_player?: true
      },
      %__MODULE__{
        name: "Wailing Ghost",
        image: "wailing_ghost.png",
        armor_class: 13,
        hit_points: 12,
        attack_bonus: 3,
        damage_dice: "1d8",
        weapon: "Chill Touch",
        treasure: nil,
        rarity: :rare,
        size: 1.0,
        role: nil,
        alignment: :chaotic,
        challenge_rating: 3,
        hunts_player?: true
      },
      %__MODULE__{
        name: "Silent Ghost",
        image: "silent_ghost.png",
        armor_class: 14,
        hit_points: 14,
        attack_bonus: 4,
        damage_dice: "1d8",
        weapon: "Haunt",
        treasure: nil,
        rarity: :rare,
        size: 1.0,
        role: nil,
        alignment: :chaotic,
        challenge_rating: 4,
        hunts_player?: true
      },
      %__MODULE__{
        name: "Ghoul",
        image: "ghoul.png",
        armor_class: 13,
        hit_points: 11,
        attack_bonus: 2,
        damage_dice: "1d6",
        weapon: "Claws",
        treasure: nil,
        rarity: :uncommon,
        size: 1.0,
        role: nil,
        alignment: :chaotic,
        challenge_rating: 3,
        hunts_player?: true
      },
      %__MODULE__{
        name: "Giant Bat",
        image: "giant_bat.png",
        armor_class: 12,
        hit_points: 7,
        attack_bonus: 1,
        damage_dice: "1d6",
        weapon: "Bite",
        treasure: nil,
        rarity: :common,
        size: 1.0,
        role: nil,
        alignment: :neutral,
        challenge_rating: 2,
        hunts_player?: false
      },
      %__MODULE__{
        name: "Giant Centipede",
        image: "giant_centipede.png",
        armor_class: 13,
        hit_points: 3,
        attack_bonus: 2,
        damage_dice: "1d4",
        weapon: "Bite",
        treasure: nil,
        rarity: :common,
        size: 1.0,
        role: nil,
        alignment: :neutral,
        challenge_rating: 1,
        hunts_player?: false
      },
      %__MODULE__{
        name: "Giant Crab",
        image: "giant_crab.png",
        armor_class: 15,
        hit_points: 7,
        attack_bonus: 2,
        damage_dice: "1d6",
        weapon: "Claw",
        treasure: nil,
        rarity: :common,
        size: 1.0,
        role: nil,
        alignment: :neutral,
        challenge_rating: 2,
        hunts_player?: false
      },
      %__MODULE__{
        name: "Giant Dung Beetle",
        image: "giant_dung_beetle.png",
        armor_class: 12,
        hit_points: 8,
        attack_bonus: 1,
        damage_dice: "1d6",
        weapon: "Mandibles",
        treasure: nil,
        rarity: :common,
        size: 1.50,
        role: nil,
        alignment: :neutral,
        challenge_rating: 2,
        hunts_player?: false
      },
      %__MODULE__{
        name: "Giant Frog",
        image: "giant_frog.png",
        armor_class: 12,
        hit_points: 6,
        attack_bonus: 1,
        damage_dice: "1d6",
        weapon: "Tongue Lash",
        treasure: nil,
        rarity: :common,
        size: 1.0,
        role: nil,
        alignment: :neutral,
        challenge_rating: 2,
        hunts_player?: false
      },
      %__MODULE__{
        name: "Gibbering Mouther",
        image: "gibbering_mouther.png",
        armor_class: 13,
        hit_points: 18,
        attack_bonus: 3,
        damage_dice: "2d6",
        weapon: "Bite",
        treasure: "2d6",
        rarity: :rare,
        size: 1.5,
        role: nil,
        alignment: :chaotic,
        challenge_rating: 4,
        hunts_player?: true
      },
      %__MODULE__{
        name: "Gnoll",
        image: "gnoll.png",
        armor_class: 13,
        hit_points: 12,
        attack_bonus: 2,
        damage_dice: "1d8",
        weapon: "Spear",
        treasure: "1d6",
        rarity: :uncommon,
        size: 1.25,
        role: nil,
        alignment: :chaotic,
        challenge_rating: 3,
        hunts_player?: true
      },
      %__MODULE__{
        name: "Goblin Scout",
        image: "goblin_scout.png",
        armor_class: 11,
        hit_points: 5,
        attack_bonus: 0,
        damage_dice: "1d4",
        weapon: "Dagger",
        treasure: "1d4",
        rarity: :common,
        size: 0.75,
        role: nil,
        alignment: :chaotic,
        challenge_rating: 1,
        hunts_player?: true
      },
      %__MODULE__{
        name: "Goblin Warrior",
        image: "goblin_warrior.png",
        armor_class: 12,
        hit_points: 6,
        attack_bonus: 1,
        damage_dice: "1d6",
        weapon: "Club",
        treasure: "1d4",
        rarity: :common,
        size: 0.75,
        role: nil,
        alignment: :chaotic,
        challenge_rating: 1,
        hunts_player?: true
      },
      %__MODULE__{
        name: "Goblin Boss",
        image: "goblin_boss.png",
        armor_class: 13,
        hit_points: 10,
        attack_bonus: 2,
        damage_dice: "1d6",
        weapon: "Spear",
        treasure: "2d6",
        rarity: :rare,
        size: 1.0,
        role: nil,
        alignment: :chaotic,
        challenge_rating: 2,
        hunts_player?: true
      },
      %__MODULE__{
        name: "Goblin Shaman",
        image: "goblin_shaman.png",
        armor_class: 12,
        hit_points: 7,
        attack_bonus: 2,
        damage_dice: "1d6",
        weapon: "Magic Bolt",
        treasure: "1d6",
        rarity: :uncommon,
        size: 0.75,
        role: nil,
        alignment: :chaotic,
        challenge_rating: 2,
        hunts_player?: true
      },
      %__MODULE__{
        name: "God Of All Multiverses",
        image: "god_of_all_multiverses.png",
        armor_class: 18,
        hit_points: 20,
        attack_bonus: 5,
        damage_dice: "2d12",
        weapon: "Reality Warp",
        treasure: "3d6",
        rarity: :elite,
        size: 1.5,
        role: nil,
        alignment: :neutral,
        challenge_rating: 6,
        hunts_player?: false
      },
      %__MODULE__{
        name: "Gorgon",
        image: "gorgon.png",
        armor_class: 17,
        hit_points: 22,
        attack_bonus: 4,
        damage_dice: "2d8",
        weapon: "Petrifying Breath",
        treasure: "2d6",
        rarity: :rare,
        size: 2.0,
        role: nil,
        alignment: :chaotic,
        challenge_rating: 5,
        hunts_player?: true
      },
      %__MODULE__{
        name: "Gorilla",
        image: "gorilla.png",
        armor_class: 13,
        hit_points: 16,
        attack_bonus: 3,
        damage_dice: "2d6",
        weapon: "Fists",
        treasure: nil,
        rarity: :uncommon,
        size: 1.5,
        role: nil,
        alignment: :neutral,
        challenge_rating: 3,
        hunts_player?: true
      },
      %__MODULE__{
        name: "Grick",
        image: "grick.png",
        armor_class: 14,
        hit_points: 10,
        attack_bonus: 2,
        damage_dice: "1d6",
        weapon: "Tentacles",
        treasure: nil,
        rarity: :uncommon,
        size: 1.25,
        role: nil,
        alignment: :chaotic,
        challenge_rating: 2,
        hunts_player?: true
      },
      %__MODULE__{
        name: "Griffon",
        image: "griffon.png",
        armor_class: 15,
        hit_points: 18,
        attack_bonus: 4,
        damage_dice: "2d8",
        weapon: "Claws",
        treasure: "2d6",
        rarity: :rare,
        size: 1.5,
        role: nil,
        alignment: :neutral,
        challenge_rating: 5,
        hunts_player?: true
      },
      %__MODULE__{
        name: "Guard",
        image: "guard.png",
        armor_class: 14,
        hit_points: 8,
        attack_bonus: 2,
        damage_dice: "1d6",
        weapon: "Spear",
        treasure: nil,
        rarity: :common,
        size: 1.0,
        role: "guard",
        alignment: :lawful,
        challenge_rating: 3,
        hunts_player?: false
      },
      %__MODULE__{
        name: "Harpy",
        image: "harpy.png",
        armor_class: 13,
        hit_points: 9,
        attack_bonus: 2,
        damage_dice: "1d6",
        weapon: "Claws",
        treasure: "1d6",
        rarity: :uncommon,
        size: 1.0,
        role: nil,
        alignment: :chaotic,
        challenge_rating: 3,
        hunts_player?: true
      },
      %__MODULE__{
        name: "Hell Hound",
        image: "hell_hound.png",
        armor_class: 15,
        hit_points: 14,
        attack_bonus: 3,
        damage_dice: "2d6",
        weapon: "Fire Breath",
        treasure: nil,
        rarity: :rare,
        size: 1.0,
        role: nil,
        alignment: :chaotic,
        challenge_rating: 4,
        hunts_player?: true
      },
      %__MODULE__{
        name: "Hobgoblin",
        image: "hobgoblin.png",
        armor_class: 15,
        hit_points: 11,
        attack_bonus: 2,
        damage_dice: "1d8",
        weapon: "Longsword",
        treasure: "1d6",
        rarity: :uncommon,
        size: 1.0,
        role: nil,
        alignment: :chaotic,
        challenge_rating: 3,
        hunts_player?: true
      },
      %__MODULE__{
        name: "Imp Devil",
        image: "imp_devil.png",
        armor_class: 15,
        hit_points: 9,
        attack_bonus: 3,
        damage_dice: "1d6",
        weapon: "Sting",
        treasure: "1d6",
        rarity: :rare,
        size: 0.75,
        role: nil,
        alignment: :chaotic,
        challenge_rating: 3,
        hunts_player?: true
      },
      %__MODULE__{
        name: "Innkeeper",
        image: "innkeeper.png",
        armor_class: 10,
        hit_points: 5,
        attack_bonus: 0,
        damage_dice: "1d2",
        weapon: "Fists",
        treasure: "1d4",
        rarity: :common,
        size: 1.0,
        role: "npc",
        alignment: :lawful,
        challenge_rating: 1,
        hunts_player?: false
      },
      %__MODULE__{
        name: "Iron Golem",
        image: "iron_golem.png",
        armor_class: 19,
        hit_points: 40,
        attack_bonus: 6,
        damage_dice: "2d12",
        weapon: "Slam",
        treasure: nil,
        rarity: :elite,
        size: 2.0,
        role: nil,
        alignment: :neutral,
        challenge_rating: 7,
        hunts_player?: true
      },
      %__MODULE__{
        name: "Kobold Spearman",
        image: "kobold_spearman.png",
        armor_class: 12,
        hit_points: 5,
        attack_bonus: 1,
        damage_dice: "1d4",
        weapon: "Spear",
        treasure: "1d4",
        rarity: :common,
        size: 0.75,
        role: nil,
        alignment: :chaotic,
        challenge_rating: 2,
        hunts_player?: true
      },
      %__MODULE__{
        name: "Kobold Defender",
        image: "kobold_defender.png",
        armor_class: 13,
        hit_points: 6,
        attack_bonus: 2,
        damage_dice: "1d4",
        weapon: "Spear",
        treasure: "1d4",
        rarity: :common,
        size: 0.75,
        role: nil,
        alignment: :chaotic,
        challenge_rating: 1,
        hunts_player?: true
      },
      %__MODULE__{
        name: "Lich",
        image: "lich.png",
        armor_class: 17,
        hit_points: 18,
        attack_bonus: 5,
        damage_dice: "2d8",
        weapon: "Necrotic Touch",
        treasure: "3d6",
        rarity: :elite,
        size: 1.0,
        role: nil,
        alignment: :chaotic,
        challenge_rating: 5,
        hunts_player?: true
      },
      %__MODULE__{
        name: "Lizard Dude",
        image: "lizard_dude.png",
        armor_class: 14,
        hit_points: 11,
        attack_bonus: 2,
        damage_dice: "1d6",
        weapon: "Spear",
        treasure: "1d6",
        rarity: :uncommon,
        size: 1.0,
        role: nil,
        alignment: :neutral,
        challenge_rating: 3,
        hunts_player?: false
      },
      %__MODULE__{
        name: "Lizardfolk",
        image: "lizardfolk.png",
        armor_class: 14,
        hit_points: 12,
        attack_bonus: 2,
        damage_dice: "1d8",
        weapon: "Spear",
        treasure: "1d6",
        rarity: :uncommon,
        size: 1.0,
        role: nil,
        alignment: :neutral,
        challenge_rating: 3,
        hunts_player?: false
      },
      %__MODULE__{
        name: "Mage",
        image: "mage.png",
        armor_class: 12,
        hit_points: 8,
        attack_bonus: 2,
        damage_dice: "1d6",
        weapon: "Magic Missile",
        treasure: "1d6",
        rarity: :uncommon,
        size: 1.0,
        role: nil,
        alignment: :neutral,
        challenge_rating: 1,
        hunts_player?: false
      },
      %__MODULE__{
        name: "Maid",
        image: "maid.png",
        armor_class: 10,
        hit_points: 3,
        attack_bonus: 0,
        damage_dice: "1d2",
        weapon: "Broom",
        treasure: "1d2",
        rarity: :common,
        size: 1.0,
        role: "npc",
        alignment: :lawful,
        challenge_rating: 1,
        hunts_player?: false
      },
      %__MODULE__{
        name: "Male Elf",
        image: "male_elf.png",
        armor_class: 14,
        hit_points: 8,
        attack_bonus: 2,
        damage_dice: "1d6",
        weapon: "Longbow",
        treasure: "1d6",
        rarity: :uncommon,
        size: 1.0,
        role: nil,
        alignment: :neutral,
        challenge_rating: 1,
        hunts_player?: false
      },
      %__MODULE__{
        name: "Medusa",
        image: "medusa.png",
        armor_class: 15,
        hit_points: 16,
        attack_bonus: 4,
        damage_dice: "1d10",
        weapon: "Petrifying Gaze",
        treasure: "2d6",
        rarity: :rare,
        size: 1.0,
        role: nil,
        alignment: :chaotic,
        challenge_rating: 4,
        hunts_player?: true
      },
      %__MODULE__{
        name: "Merchant",
        image: "merchant.png",
        armor_class: 10,
        hit_points: 5,
        attack_bonus: 0,
        damage_dice: "1d2",
        weapon: "Fists",
        treasure: "2d6",
        rarity: :common,
        size: 1.0,
        role: "npc",
        alignment: :lawful,
        challenge_rating: 1,
        hunts_player?: false
      },
      %__MODULE__{
        name: "Mimic",
        image: "mimic.png",
        armor_class: 14,
        hit_points: 15,
        attack_bonus: 3,
        damage_dice: "1d8",
        weapon: "Bite",
        treasure: "2d6",
        rarity: :rare,
        size: 1.0,
        role: nil,
        alignment: :chaotic,
        challenge_rating: 3,
        hunts_player?: true
      },
      %__MODULE__{
        name: "Minotaur",
        image: "minotaur.png",
        armor_class: 16,
        hit_points: 20,
        attack_bonus: 4,
        damage_dice: "2d8",
        weapon: "Greataxe",
        treasure: "2d6",
        rarity: :rare,
        size: 1.5,
        role: nil,
        alignment: :chaotic,
        challenge_rating: 5,
        hunts_player?: true
      },
      %__MODULE__{
        name: "Moeshrooom",
        image: "moeshrooom.png",
        armor_class: 13,
        hit_points: 15,
        attack_bonus: 2,
        damage_dice: "1d6",
        weapon: "Slam",
        treasure: nil,
        rarity: :uncommon,
        size: 1.0,
        role: nil,
        alignment: :neutral,
        challenge_rating: 4,
        hunts_player?: false
      },
      %__MODULE__{
        name: "Mummy",
        image: "mummy.png",
        armor_class: 13,
        hit_points: 14,
        attack_bonus: 3,
        damage_dice: "1d8",
        weapon: "Rotting Fist",
        treasure: "2d6",
        rarity: :rare,
        size: 1.0,
        role: nil,
        alignment: :chaotic,
        challenge_rating: 4,
        hunts_player?: true
      },
      %__MODULE__{
        name: "Mushroomfolk",
        image: "mushroomfolk.png",
        armor_class: 11,
        hit_points: 6,
        attack_bonus: 1,
        damage_dice: "1d4",
        weapon: "Spore Cloud",
        treasure: nil,
        rarity: :common,
        size: 1.25,
        role: nil,
        alignment: :neutral,
        challenge_rating: 1,
        hunts_player?: false
      },
      %__MODULE__{
        name: "Night Hag",
        image: "night_hag.png",
        armor_class: 15,
        hit_points: 16,
        attack_bonus: 4,
        damage_dice: "1d10",
        weapon: "Claws",
        treasure: "2d6",
        rarity: :rare,
        size: 1.0,
        role: nil,
        alignment: :chaotic,
        challenge_rating: 4,
        hunts_player?: true
      },
      %__MODULE__{
        name: "Ogre",
        image: "ogre.png",
        armor_class: 12,
        hit_points: 20,
        attack_bonus: 3,
        damage_dice: "2d6",
        weapon: "Club",
        treasure: nil,
        rarity: :common,
        size: 2.0,
        role: nil,
        alignment: :chaotic,
        challenge_rating: 5,
        hunts_player?: false
      },
      %__MODULE__{
        name: "Orc",
        image: "orc.png",
        armor_class: 15,
        hit_points: 6,
        attack_bonus: 2,
        damage_dice: "1d8",
        weapon: "Greataxe",
        treasure: "1d6",
        rarity: :uncommon,
        size: 1.25,
        role: nil,
        alignment: :chaotic,
        challenge_rating: 1,
        hunts_player?: true
      },
      %__MODULE__{
        name: "Orc Boss",
        image: "orc_boss.png",
        armor_class: 17,
        hit_points: 10,
        attack_bonus: 3,
        damage_dice: "1d12",
        weapon: "Club",
        treasure: "2d6",
        rarity: :rare,
        size: 1.50,
        role: nil,
        alignment: :chaotic,
        challenge_rating: 2,
        hunts_player?: false
      },
      %__MODULE__{
        name: "Orc Chieftain",
        image: "orc_chieftain.png",
        armor_class: 18,
        hit_points: 16,
        attack_bonus: 4,
        damage_dice: "2d8",
        weapon: "Greataxe",
        treasure: "2d6",
        rarity: :rare,
        size: 1.50,
        role: nil,
        alignment: :chaotic,
        challenge_rating: 3,
        hunts_player?: true
      },
      %__MODULE__{
        name: "Owlbear",
        image: "owlbear.png",
        armor_class: 15,
        hit_points: 17,
        attack_bonus: 4,
        damage_dice: "2d6",
        weapon: "Claws",
        treasure: "2d6",
        rarity: :rare,
        size: 1.5,
        role: nil,
        alignment: :neutral,
        challenge_rating: 4,
        hunts_player?: true
      },
      %__MODULE__{
        name: "Possessed Head",
        image: "possessed_head.png",
        armor_class: 16,
        hit_points: 15,
        attack_bonus: 4,
        damage_dice: "1d10",
        weapon: "Psychic Blast",
        treasure: "2d6",
        rarity: :rare,
        size: 1.0,
        role: nil,
        alignment: :chaotic,
        challenge_rating: 4,
        hunts_player?: true
      },
      %__MODULE__{
        name: "Rat",
        image: "rat.png",
        armor_class: 10,
        hit_points: 1,
        attack_bonus: 0,
        damage_dice: "1d1",
        weapon: "Bite",
        treasure: nil,
        rarity: :common,
        size: 0.75,
        role: nil,
        alignment: :neutral,
        challenge_rating: 1,
        hunts_player?: false
      },
      %__MODULE__{
        name: "Scary Face",
        image: "scary_face.png",
        armor_class: 14,
        hit_points: 12,
        attack_bonus: 3,
        damage_dice: "1d8",
        weapon: "Terror Scream",
        treasure: "2d6",
        rarity: :rare,
        size: 1.25,
        role: nil,
        alignment: :chaotic,
        challenge_rating: 3,
        hunts_player?: true
      },
      %__MODULE__{
        name: "Skeleton",
        image: "skeleton.png",
        armor_class: 13,
        hit_points: 10,
        attack_bonus: 1,
        damage_dice: "1d8",
        weapon: "Longsword",
        treasure: nil,
        rarity: :uncommon,
        size: 1.0,
        role: nil,
        alignment: :chaotic,
        challenge_rating: 2,
        hunts_player?: true
      },
      %__MODULE__{
        name: "Snow Ape",
        image: "snow_ape.png",
        armor_class: 13,
        hit_points: 18,
        attack_bonus: 3,
        damage_dice: "2d6",
        weapon: "Fists",
        treasure: nil,
        rarity: :uncommon,
        size: 1.5,
        role: nil,
        alignment: :neutral,
        challenge_rating: 4,
        hunts_player?: true
      },
      %__MODULE__{
        name: "Kobold Shaman",
        image: "kobold_shaman.png",
        armor_class: 13,
        hit_points: 7,
        attack_bonus: 2,
        damage_dice: "1d6",
        weapon: "Magic Bolt",
        treasure: "1d6",
        rarity: :uncommon,
        size: 0.75,
        role: nil,
        alignment: :chaotic,
        challenge_rating: 2,
        hunts_player?: true
      },
      %__MODULE__{
        name: "Kobold Warlock",
        image: "kobold_warlock.png",
        armor_class: 14,
        hit_points: 8,
        attack_bonus: 3,
        damage_dice: "1d8",
        weapon: "Magic Bolt",
        treasure: "1d6",
        rarity: :uncommon,
        size: 0.75,
        role: nil,
        alignment: :chaotic,
        challenge_rating: 2,
        hunts_player?: true
      },
      %__MODULE__{
        name: "Spider",
        image: "spider.png",
        armor_class: 11,
        hit_points: 1,
        attack_bonus: 1,
        damage_dice: "1d1",
        weapon: "Bite",
        treasure: nil,
        rarity: :common,
        size: 0.75,
        role: nil,
        alignment: :neutral,
        challenge_rating: 1,
        hunts_player?: false
      },
      %__MODULE__{
        name: "Stone Golem",
        image: "stone_golem.png",
        armor_class: 18,
        hit_points: 36,
        attack_bonus: 5,
        damage_dice: "2d10",
        weapon: "Slam",
        treasure: nil,
        rarity: :elite,
        size: 2.0,
        role: nil,
        alignment: :neutral,
        challenge_rating: 7,
        hunts_player?: true
      },
      %__MODULE__{
        name: "Thug",
        image: "thug.png",
        armor_class: 10,
        hit_points: 5,
        attack_bonus: 1,
        damage_dice: "1d2",
        weapon: "Fists",
        treasure: "1d6",
        rarity: :common,
        size: 1.0,
        role: "npc",
        alignment: :chaotic,
        challenge_rating: 1,
        hunts_player?: false
      },
      %__MODULE__{
        name: "Town Guard",
        image: "town_guard.png",
        armor_class: 15,
        hit_points: 10,
        attack_bonus: 2,
        damage_dice: "1d8",
        weapon: "Spear",
        treasure: nil,
        rarity: :common,
        size: 1.0,
        role: "guard",
        alignment: :lawful,
        challenge_rating: 1,
        hunts_player?: false
      },
      %__MODULE__{
        name: "Weald Hag",
        image: "weald_hag.png",
        armor_class: 14,
        hit_points: 12,
        attack_bonus: 3,
        damage_dice: "1d8",
        weapon: "Claws",
        treasure: "2d6",
        rarity: :rare,
        size: 1.0,
        role: nil,
        alignment: :chaotic,
        challenge_rating: 2,
        hunts_player?: true
      },
      %__MODULE__{
        name: "Zombie",
        image: "zombie.png",
        armor_class: 8,
        hit_points: 11,
        attack_bonus: 2,
        damage_dice: "1d6",
        weapon: "Slam",
        treasure: nil,
        rarity: :common,
        size: 1.0,
        role: nil,
        alignment: :chaotic,
        challenge_rating: 1,
        hunts_player?: true
      },
      %__MODULE__{
        name: "Zombie Piggy",
        image: "zombie_piggy.png",
        armor_class: 10,
        hit_points: 13,
        attack_bonus: 2,
        damage_dice: "1d6",
        weapon: "Rotting Bite",
        treasure: nil,
        rarity: :uncommon,
        size: 1.0,
        role: nil,
        alignment: :chaotic,
        challenge_rating: 3,
        hunts_player?: true
      }
    ]
  end

  @doc """
  Get monster by name
  """
  def get_monster_by_name(name) do
    all_monsters()
    |> Enum.find(&(&1.name == name))
  end

  @doc """
  Get monster by image filename
  """
  def get_monster_by_image(image_filename) do
    all_monsters()
    |> Enum.find(&(&1.image == image_filename))
  end

  @doc """
  Get a random monster
  """
  def get_random_monster do
    all_monsters()
    |> Enum.random()
  end

  @doc """
  Get a random monster from a specific theme's monster list using rarity and challenge_rating filtering.
  If no monster matches, fallback to next rarity, then any monster.
  """
  def get_random_monster_for_theme(theme_monsters, max_challenge_rating)
      when is_list(theme_monsters) and theme_monsters != [] do
    theme_monster_list = normalize_theme_monsters(theme_monsters)

    case theme_monster_list do
      [] ->
        # No valid monsters in theme, use global rarity system
        get_random_monster_by_rarity(max_challenge_rating)

      valid_monsters ->
        get_random_monster_from_theme_with_rarity(valid_monsters, max_challenge_rating)
    end
  end

  def get_random_monster_for_theme(_, max_challenge_rating),
    do: get_random_monster_by_rarity(max_challenge_rating)

  @doc """
  Get a random monster for theme with full theme object support for fog_type logic.
  This is the preferred method for new code.
  """
  def get_random_monster_for_theme_with_fog_type(theme, map_level, player_level) do
    case theme do
      %{monsters: theme_monsters} when is_list(theme_monsters) and theme_monsters != [] ->
        determine_theme_monster(theme, map_level, player_level)

      %{monsters: _} ->
        # Theme has no valid monsters, fallback to global system
        get_random_monster_by_rarity(max(map_level, player_level))

      _ ->
        # No theme or invalid theme, fallback to global system
        get_random_monster_by_rarity(max(map_level, player_level))
    end
  end

  @doc """
  Determine theme monster based on fog_type logic:
  - daylight themes: use only theme and rarity
  - dim/dark themes: use theme, rarity, and highest of player or map level
  """
  def determine_theme_monster(theme, map_level, player_level) do
    rarity = determine_rarity()

    case Map.get(theme, :fog_type, "dark") do
      "daylight" ->
        determine_theme_monster_by_rarity(theme, rarity)

      _ ->
        level = max(map_level, player_level)
        determine_theme_monster_by_rarity_and_level(theme, rarity, level)
    end
  end

  @doc """
  Determine theme monster by rarity only (for daylight themes)
  """
  def determine_theme_monster_by_rarity(theme, rarity) do
    monster = select_random_theme_monster_by_rarity(theme, rarity)

    if monster == nil do
      next_rarity = get_next_lowest_rarity(rarity)

      if next_rarity == rarity do
        # We're already at the lowest rarity, fallback to any monster from theme
        fallback_to_any_theme_monster(theme)
      else
        determine_theme_monster_by_rarity(theme, next_rarity)
      end
    else
      monster
    end
  end

  @doc """
  Determine theme monster by rarity and level (for dim/dark themes)
  """
  def determine_theme_monster_by_rarity_and_level(theme, rarity, level) do
    monster = select_random_theme_monster_by_rarity_and_level(theme, rarity, level)

    if monster == nil do
      next_rarity = get_next_lowest_rarity(rarity)

      if next_rarity == rarity do
        # We're already at the lowest rarity, fallback to any monster from theme within level range
        fallback_to_any_theme_monster_with_level(theme, level)
      else
        determine_theme_monster_by_rarity_and_level(theme, next_rarity, level)
      end
    else
      monster
    end
  end

  @doc """
  Select random theme monster by rarity only
  """
  def select_random_theme_monster_by_rarity(theme, rarity) do
    theme_monsters = Map.get(theme, :monsters, [])
    theme_monster_list = normalize_theme_monsters(theme_monsters)

    monsters_of_rarity =
      theme_monster_list
      |> Enum.filter(fn {_monster, monster_rarity} ->
        monster_rarity == rarity
      end)
      |> Enum.map(fn {monster, _rarity} -> monster end)

    case monsters_of_rarity do
      [] -> nil
      monsters -> Enum.random(monsters)
    end
  end

  @doc """
  Select random theme monster by rarity and level (challenge_rating between level-2 and level)
  """
  def select_random_theme_monster_by_rarity_and_level(theme, rarity, level) do
    theme_monsters = Map.get(theme, :monsters, [])
    theme_monster_list = normalize_theme_monsters(theme_monsters)

    monsters_of_rarity_and_level =
      theme_monster_list
      |> Enum.filter(fn {monster, monster_rarity} ->
        monster_rarity == rarity and
          monster.challenge_rating >= level - 2 and
          monster.challenge_rating <= level
      end)
      |> Enum.map(fn {monster, _rarity} -> monster end)

    case monsters_of_rarity_and_level do
      [] -> nil
      monsters -> Enum.random(monsters)
    end
  end

  @doc """
  Get the next lowest rarity for fallback logic
  """
  def get_next_lowest_rarity(current_rarity) do
    case current_rarity do
      :elite -> :rare
      :rare -> :uncommon
      :uncommon -> :common
      # Stay at common as lowest
      :common -> :common
    end
  end

  # Private helper functions for fallback logic

  defp fallback_to_any_theme_monster(theme) do
    theme_monsters = Map.get(theme, :monsters, [])
    theme_monster_list = normalize_theme_monsters(theme_monsters)

    case theme_monster_list do
      [] ->
        # No valid monsters in theme, fallback to global system
        get_random_monster()

      monsters ->
        # Pick any monster from theme regardless of rarity
        # For daylight themes, we don't have level constraints, so this is fine
        {monster, _rarity} = Enum.random(monsters)
        monster
    end
  end

  defp fallback_to_any_theme_monster_with_level(theme, level) do
    theme_monsters = Map.get(theme, :monsters, [])
    theme_monster_list = normalize_theme_monsters(theme_monsters)

    # Preferred range: level - 2 to level + 1
    preferred_monsters =
      theme_monster_list
      |> Enum.filter(fn {monster, _rarity} ->
        monster.challenge_rating >= level - 2 and monster.challenge_rating <= level + 1
      end)
      |> Enum.map(fn {monster, _rarity} -> monster end)

    case preferred_monsters do
      [] ->
        # No monsters in preferred range, try any monster <= level
        monsters_at_or_below_level =
          theme_monster_list
          |> Enum.filter(fn {monster, _rarity} -> monster.challenge_rating <= level end)
          |> Enum.map(fn {monster, _rarity} -> monster end)

        case monsters_at_or_below_level do
          [] ->
            # Still no monsters, fallback to global system with level constraint
            get_random_monster_by_rarity(level)

          monsters ->
            # Pick the monster with the highest challenge_rating (closest to level)
            max_cr = Enum.max_by(monsters, & &1.challenge_rating).challenge_rating
            best_monsters = Enum.filter(monsters, fn m -> m.challenge_rating == max_cr end)
            Enum.random(best_monsters)
        end

      monsters ->
        # Pick from preferred range (level - 2 to level + 1)
        Enum.random(monsters)
    end
  end

  @doc """
  Get a random monster using the global rarity system, with challenge_rating filter
  """
  def get_random_monster_by_rarity(max_challenge_rating) do
    rarity = determine_rarity()

    monsters_of_rarity =
      get_monsters_by_rarity(rarity)
      |> Enum.filter(&(&1.challenge_rating <= max_challenge_rating))

    case monsters_of_rarity do
      [] ->
        # Fallback: if no monsters of selected rarity, pick any monster with challenge_rating <= max_challenge_rating
        all_monsters()
        |> Enum.filter(&(&1.challenge_rating <= max_challenge_rating))
        |> case do
          [] -> get_random_monster()
          filtered -> Enum.random(filtered)
        end

      monsters ->
        Enum.random(monsters)
    end
  end

  # Private helper functions for rarity system

  defp normalize_theme_monsters(theme_monsters) do
    theme_monsters
    |> Enum.map(&normalize_theme_monster/1)
    |> Enum.filter(& &1)
  end

  defp normalize_theme_monster({name, rarity}) when is_binary(name) and is_atom(rarity) do
    case get_monster_by_name(name) do
      nil -> nil
      monster -> {monster, rarity}
    end
  end

  defp normalize_theme_monster(name) when is_binary(name) do
    case get_monster_by_name(name) do
      nil -> nil
      monster -> {monster, monster.rarity}
    end
  end

  defp normalize_theme_monster(_), do: nil

  defp get_random_monster_from_theme_with_rarity(theme_monster_list, max_challenge_rating) do
    rarity = determine_rarity()

    monsters_of_rarity =
      theme_monster_list
      |> Enum.filter(fn {monster, monster_rarity} ->
        monster_rarity == rarity and monster.challenge_rating <= max_challenge_rating
      end)
      |> Enum.map(fn {monster, _rarity} -> monster end)

    case monsters_of_rarity do
      [] ->
        # No monsters of selected rarity in theme, pick any from theme (with challenge_rating filter)
        theme_monster_list
        |> Enum.map(fn {monster, _rarity} -> monster end)
        |> Enum.filter(fn monster -> monster.challenge_rating <= max_challenge_rating end)
        |> case do
          [] ->
            # Fallback to any monster in theme (ignore challenge_rating)
            theme_monster_list |> Enum.map(fn {monster, _rarity} -> monster end) |> Enum.random()

          filtered ->
            Enum.random(filtered)
        end

      monsters ->
        Enum.random(monsters)
    end
  end

  defp determine_rarity do
    case :rand.uniform(100) do
      # 60%
      n when n <= 60 -> :common
      # 25%
      n when n <= 85 -> :uncommon
      # 10%
      n when n <= 95 -> :rare
      # 5%
      _ -> :elite
    end
  end

  defp get_monsters_by_rarity(rarity) do
    all_monsters()
    |> Enum.filter(&(&1.rarity == rarity))
  end

  @doc """
  Get monsters with challenge_rating <= max_level
  """
  def get_monsters_by_challenge_rating(max_level) do
    all_monsters()
    |> Enum.filter(&(&1.challenge_rating <= max_level))
  end

  @doc """
  Get monsters with challenge_rating == level
  """
  def get_monsters_by_exact_challenge_rating(level) do
    all_monsters()
    |> Enum.filter(&(&1.challenge_rating == level))
  end

  @doc """
  Get a random monster for quest by challenge_rating, fallback by decrementing level until found, then fallback to any monster
  """
  def get_random_monster_for_quest(level) when level > 0 do
    case get_monsters_by_exact_challenge_rating(level) do
      [] -> get_random_monster_for_quest(level - 1)
      monsters -> Enum.random(monsters)
    end
  end

  def get_random_monster_for_quest(_level), do: get_random_monster()

  @doc """
  Get monster hit points (now fixed values instead of calculated)
  """
  def get_hit_points(%__MODULE__{hit_points: hit_points}) do
    hit_points
  end

  @doc """
  Create a monster instance with calculated hit points
  """
  def create_monster_instance(name) when is_binary(name) do
    case get_monster_by_name(name) do
      nil -> nil
      monster -> create_monster_instance(monster)
    end
  end

  def create_monster_instance(%__MODULE__{} = monster) do
    hit_points = get_hit_points(monster)

    monster
    |> Map.put(:current_hit_points, hit_points)
    |> Map.put(:max_hit_points, hit_points)
  end

  @doc """
  Display monster stats for debugging/testing
  """
  def display_monster_stats(%__MODULE__{} = monster) do
    """
    #{monster.name}
    AC: #{monster.armor_class}
    Hit Points: #{monster.hit_points}
    Attack Bonus: +#{monster.attack_bonus}
    Damage: #{monster.damage_dice}
    Weapon: #{monster.weapon}
    Image: #{monster.image}
    """
  end
end
