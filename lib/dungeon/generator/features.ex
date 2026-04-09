defmodule Dungeon.Generator.Features do
  @moduledoc """
  Doors, traps, treasures, encounters, stairs and pillars for dungeon generation.
  Also contains the special feature registry with all feature data and attributes.
  """

  alias Dungeon.Generator.{Caverns, Grid, Outdoor}

  # Comprehensive special feature registry with all attributes and metadata
  @special_feature_registry %{
    "Altar" => %{
      category: :religious,
      image: "altar.png",
      size: 1.5,
      creates_light: true,
      treasure_chance: 10,
      special_item_chance: 25,
      rumor_chance: 20,
      trap_chance: 5,
      monster_chance: 0,
      monster_list: [],
      rarity: :uncommon
    },
    "Barrel" => %{
      category: :container,
      image: "barrel.png",
      size: 0.75,
      creates_light: false,
      treasure_chance: 15,
      special_item_chance: 5,
      rumor_chance: 0,
      trap_chance: 0,
      monster_chance: 10,
      monster_list: [
        "Rat",
        "Spider",
        "Giant Centipede",
        "Bat Swarm",
        "Centipede Swarm"
      ],
      rarity: :common
    },
    "Bookcase" => %{
      category: :knowledge,
      image: "bookcase.png",
      size: 1.5,
      creates_light: false,
      treasure_chance: 10,
      special_item_chance: 25,
      rumor_chance: 35,
      trap_chance: 0,
      monster_chance: 0,
      monster_list: [],
      rarity: :uncommon
    },
    "Brazier" => %{
      category: :light_source,
      image: "brazier.png",
      size: 1,
      creates_light: true,
      treasure_chance: 5,
      special_item_chance: 0,
      rumor_chance: 0,
      trap_chance: 0,
      monster_chance: 0,
      monster_list: [],
      rarity: :common
    },
    "Cage" => %{
      category: :container,
      image: "cage.png",
      size: 1.75,
      creates_light: false,
      treasure_chance: 10,
      special_item_chance: 5,
      rumor_chance: 5,
      trap_chance: 0,
      monster_chance: 20,
      monster_list: ["Rat", "Goblin Scout", "Beastman", "Boar", "Doppelganger"],
      rarity: :common
    },
    "Campfire" => %{
      category: :light_source,
      image: "campfire.png",
      size: 1,
      creates_light: true,
      treasure_chance: 0,
      special_item_chance: 0,
      rumor_chance: 10,
      trap_chance: 0,
      monster_chance: 0,
      monster_list: [],
      rarity: :common
    },
    "Candle" => %{
      category: :light_source,
      image: "candle.png",
      size: 0.75,
      creates_light: true,
      treasure_chance: 0,
      special_item_chance: 0,
      rumor_chance: 0,
      trap_chance: 0,
      monster_chance: 0,
      monster_list: [],
      rarity: :common
    },
    "Chair" => %{
      category: :furniture,
      image: "chair.png",
      size: 1,
      creates_light: false,
      treasure_chance: 0,
      special_item_chance: 0,
      rumor_chance: 0,
      trap_chance: 0,
      monster_chance: 0,
      monster_list: [],
      rarity: :common
    },
    "Cobwebs" => %{
      category: :debris,
      image: "cobwebs.png",
      size: 2,
      creates_light: false,
      treasure_chance: 15,
      special_item_chance: 5,
      rumor_chance: 0,
      trap_chance: 0,
      monster_chance: 30,
      monster_list: ["Spider", "Bat Swarm"],
      rarity: :common
    },
    "Coffin" => %{
      category: :tomb,
      image: "coffin.png",
      size: 1.5,
      creates_light: false,
      treasure_chance: 20,
      special_item_chance: 10,
      rumor_chance: 10,
      trap_chance: 5,
      monster_chance: 75,
      monster_list: ["Skeleton", "Zombie", "Ghoul", "Ghast"],
      rarity: :uncommon
    },
    "Cot" => %{
      category: :furniture,
      image: "cot.png",
      size: 1.5,
      creates_light: false,
      treasure_chance: 5,
      special_item_chance: 0,
      rumor_chance: 0,
      trap_chance: 0,
      monster_chance: 0,
      monster_list: [],
      rarity: :common
    },
    "Crate" => %{
      category: :container,
      image: "crate.png",
      size: 1,
      creates_light: false,
      treasure_chance: 15,
      special_item_chance: 2,
      rumor_chance: 0,
      trap_chance: 0,
      monster_chance: 15,
      monster_list: ["Rat", "Bat Swarm", "Centipede Swarm"],
      rarity: :common
    },
    "Crown" => %{
      category: :decorative,
      image: "crown.png",
      size: 0.75,
      creates_light: false,
      treasure_chance: 40,
      special_item_chance: 30,
      rumor_chance: 20,
      trap_chance: 0,
      monster_chance: 5,
      monster_list: ["Wailing Ghost"],
      rarity: :rare
    },
    "Cupboard" => %{
      category: :container,
      image: "cupboard.png",
      size: 1.5,
      creates_light: false,
      treasure_chance: 15,
      special_item_chance: 5,
      rumor_chance: 5,
      trap_chance: 0,
      monster_chance: 10,
      monster_list: ["Rat"],
      rarity: :common
    },
    "Dais" => %{
      category: :decorative,
      image: "dais.png",
      size: 3,
      creates_light: false,
      treasure_chance: 15,
      special_item_chance: 10,
      rumor_chance: 15,
      trap_chance: 10,
      monster_chance: 0,
      monster_list: [],
      rarity: :uncommon
    },
    "Desk" => %{
      category: :furniture,
      image: "desk.png",
      size: 1.0,
      creates_light: false,
      treasure_chance: 15,
      special_item_chance: 10,
      rumor_chance: 20,
      trap_chance: 2,
      monster_chance: 0,
      monster_list: [],
      rarity: :common
    },
    "Debris" => %{
      category: :debris,
      image: "debris.png",
      size: 2,
      creates_light: false,
      treasure_chance: 5,
      special_item_chance: 0,
      rumor_chance: 0,
      trap_chance: 1,
      monster_chance: 10,
      monster_list: ["Rat", "Spider", "Giant Centipede"],
      rarity: :common
    },
    "Fence" => %{
      category: :barrier,
      image: "fence.png",
      size: 1.25,
      creates_light: false,
      treasure_chance: 0,
      special_item_chance: 0,
      rumor_chance: 0,
      trap_chance: 0,
      monster_chance: 0,
      monster_list: [],
      rarity: :common
    },
    "Fireplace" => %{
      category: :light_source,
      image: "fireplace.png",
      size: 1.5,
      creates_light: true,
      treasure_chance: 5,
      special_item_chance: 1,
      rumor_chance: 1,
      trap_chance: 0,
      monster_chance: 0,
      monster_list: [],
      rarity: :common
    },
    "Fountain" => %{
      category: :water,
      image: "fountain.png",
      size: 2,
      creates_light: false,
      treasure_chance: 15,
      special_item_chance: 10,
      rumor_chance: 25,
      trap_chance: 0,
      monster_chance: 0,
      monster_list: [],
      rarity: :uncommon
    },
    "Fungus" => %{
      category: :natural,
      image: "fungus.png",
      size: 1.0,
      creates_light: false,
      treasure_chance: 0,
      special_item_chance: 0,
      rumor_chance: 0,
      trap_chance: 0,
      monster_chance: 10,
      monster_list: ["Spider", "Giant Centipede", "Cave Creeper", "Mushroomfolk"],
      rarity: :common
    },
    "Group of Barrels" => %{
      category: :container,
      size: 1,
      image: "group_of_barrels.png",
      creates_light: false,
      treasure_chance: 25,
      special_item_chance: 10,
      rumor_chance: 0,
      trap_chance: 0,
      monster_chance: 20,
      monster_list: [
        "Rat",
        "Spider",
        "Giant Centipede",
        "Bat Swarm",
        "Centipede Swarm",
        "Mushroomfolk"
      ],
      rarity: :common
    },
    "Hut" => %{
      category: :structure,
      image: "hut.png",
      size: 3,
      creates_light: false,
      treasure_chance: 15,
      special_item_chance: 5,
      rumor_chance: 10,
      trap_chance: 1,
      monster_chance: 20,
      monster_list: ["Goblin Scout", "Orc"],
      rarity: :uncommon
    },
    "Lectern" => %{
      category: :furniture,
      image: "lectern.png",
      size: 1,
      creates_light: false,
      treasure_chance: 10,
      special_item_chance: 25,
      rumor_chance: 35,
      trap_chance: 5,
      monster_chance: 0,
      monster_list: [],
      rarity: :uncommon
    },
    "Logs" => %{
      category: :natural,
      image: "logs.png",
      size: 0.75,
      creates_light: false,
      treasure_chance: 5,
      special_item_chance: 0,
      rumor_chance: 0,
      trap_chance: 0,
      monster_chance: 5,
      monster_list: ["Spider", "Rat"],
      rarity: :common
    },
    "Magic Circle" => %{
      category: :magical,
      image: "magic_circle.png",
      size: 2,
      creates_light: false,
      treasure_chance: 15,
      special_item_chance: 20,
      rumor_chance: 20,
      trap_chance: 0,
      monster_chance: 20,
      monster_list: ["Dark Elf", "Cultist Mage", "Imp Devil", "Drow Priestess"],
      rarity: :rare
    },
    "Magic Portal" => %{
      category: :magical,
      image: "magic_portal.png",
      size: 2,
      creates_light: false,
      treasure_chance: 25,
      special_item_chance: 20,
      rumor_chance: 30,
      trap_chance: 0,
      monster_chance: 30,
      monster_list: ["Cultist Mage", "Imp Devil", "Drow Priestess"],
      rarity: :rare
    },
    "Mirror" => %{
      category: :magical,
      image: "mirror.png",
      size: 1,
      creates_light: false,
      treasure_chance: 0,
      special_item_chance: 0,
      rumor_chance: 15,
      trap_chance: 0,
      monster_chance: 10,
      monster_list: ["Scary Face"],
      rarity: :uncommon
    },
    "Mushrooms" => %{
      category: :natural,
      image: "mushrooms.png",
      size: 0.75,
      creates_light: false,
      treasure_chance: 0,
      special_item_chance: 0,
      rumor_chance: 0,
      trap_chance: 0,
      monster_chance: 15,
      monster_list: ["Spider", "Giant Centipede", "Mushroomfolk"],
      rarity: :common
    },
    "Obelisk" => %{
      category: :religious,
      image: "obelisk.png",
      size: 2,
      creates_light: false,
      treasure_chance: 15,
      special_item_chance: 10,
      rumor_chance: 30,
      trap_chance: 5,
      monster_chance: 0,
      monster_list: [],
      rarity: :rare
    },
    "Pedestal" => %{
      category: :religious,
      image: "pedestal.png",
      size: 1,
      creates_light: false,
      treasure_chance: 30,
      special_item_chance: 25,
      rumor_chance: 25,
      trap_chance: 15,
      monster_chance: 0,
      monster_list: [],
      rarity: :uncommon
    },
    "Pile of Chests" => %{
      category: :treasure,
      image: "pile_of_chests.png",
      size: 1.50,
      creates_light: false,
      treasure_chance: 60,
      special_item_chance: 35,
      rumor_chance: 20,
      trap_chance: 40,
      monster_chance: 5,
      monster_list: ["Mimic"],
      rarity: :rare
    },
    "Pile of Weapons and Armor" => %{
      category: :treasure,
      image: "pile_of_weapons_and_armor.png",
      size: 1.25,
      creates_light: false,
      treasure_chance: 60,
      special_item_chance: 35,
      rumor_chance: 20,
      trap_chance: 20,
      monster_chance: 0,
      monster_list: [],
      rarity: :rare
    },
    "Pillar" => %{
      category: :architecture,
      image: "pillar.png",
      size: 2,
      creates_light: false,
      treasure_chance: 0,
      special_item_chance: 0,
      rumor_chance: 0,
      trap_chance: 0,
      monster_chance: 0,
      monster_list: [],
      rarity: :common
    },
    "Pit" => %{
      category: :hazard,
      image: "pit.png",
      size: 1.25,
      creates_light: false,
      treasure_chance: 10,
      special_item_chance: 5,
      rumor_chance: 5,
      trap_chance: 60,
      monster_chance: 25,
      monster_list: ["Spider", "Rat", "Giant Centipede"],
      rarity: :uncommon
    },
    "Plant" => %{
      category: :natural,
      image: "plant.png",
      size: 1.25,
      creates_light: false,
      treasure_chance: 0,
      special_item_chance: 0,
      rumor_chance: 1,
      trap_chance: 0,
      monster_chance: 5,
      monster_list: ["Spider", "Giant Centipede"],
      rarity: :common
    },
    "Pool" => %{
      category: :water,
      image: "pool.png",
      size: 3,
      creates_light: false,
      treasure_chance: 15,
      special_item_chance: 10,
      rumor_chance: 10,
      trap_chance: 10,
      monster_chance: 10,
      monster_list: ["Blob Fish"],
      rarity: :uncommon
    },
    "Quicksand" => %{
      category: :hazard,
      image: "quicksand.png",
      size: 3,
      creates_light: false,
      treasure_chance: 10,
      special_item_chance: 0,
      rumor_chance: 5,
      trap_chance: 80,
      monster_chance: 0,
      monster_list: [],
      rarity: :uncommon
    },
    "Rocks" => %{
      category: :natural,
      image: "rocks.png",
      size: 1.5,
      creates_light: false,
      treasure_chance: 2,
      special_item_chance: 0,
      rumor_chance: 0,
      trap_chance: 5,
      monster_chance: 10,
      monster_list: ["Rat", "Giant Centipede", "Cave Creeper"],
      rarity: :common
    },
    "Rubble" => %{
      category: :debris,
      image: "rubble.png",
      size: 1.75,
      creates_light: false,
      treasure_chance: 15,
      special_item_chance: 5,
      rumor_chance: 0,
      trap_chance: 10,
      monster_chance: 10,
      monster_list: ["Rat", "Spider", "Cave Creeper"],
      rarity: :common
    },
    "Rug" => %{
      category: :decorative,
      image: "rug.png",
      size: 2,
      creates_light: false,
      treasure_chance: 15,
      special_item_chance: 5,
      rumor_chance: 5,
      trap_chance: 1,
      monster_chance: 0,
      monster_list: [],
      rarity: :common
    },
    "Sarcophagus" => %{
      category: :tomb,
      image: "sarcophagus.png",
      size: 1.75,
      creates_light: false,
      treasure_chance: 35,
      special_item_chance: 20,
      rumor_chance: 10,
      trap_chance: 10,
      monster_chance: 75,
      monster_list: [
        "Skeleton",
        "Zombie",
        "Ghoul",
        "Mummy"
      ],
      rarity: :uncommon
    },
    "Stack of Books" => %{
      category: :knowledge,
      image: "stack_of_books.png",
      size: 0.75,
      creates_light: false,
      treasure_chance: 10,
      special_item_chance: 5,
      rumor_chance: 40,
      trap_chance: 1,
      monster_chance: 0,
      monster_list: [],
      rarity: :uncommon
    },
    "Stack of Crates" => %{
      category: :container,
      image: "stack_of_crates.png",
      size: 1,
      creates_light: false,
      treasure_chance: 25,
      special_item_chance: 10,
      rumor_chance: 0,
      trap_chance: 1,
      monster_chance: 10,
      monster_list: [
        "Rat",
        "Spider",
        "Giant Centipede",
        "Centipede Swarm"
      ],
      rarity: :common
    },
    "Statue" => %{
      category: :decorative,
      image: "statue.png",
      size: 1.50,
      creates_light: false,
      treasure_chance: 20,
      special_item_chance: 15,
      rumor_chance: 25,
      trap_chance: 5,
      monster_chance: 0,
      monster_list: ["Gargoyle", "Cyclops", "Chimera", "Drider"],
      rarity: :uncommon
    },
    "Stool" => %{
      category: :furniture,
      image: "stool.png",
      size: 0.75,
      creates_light: false,
      treasure_chance: 0,
      special_item_chance: 0,
      rumor_chance: 0,
      trap_chance: 0,
      monster_chance: 0,
      monster_list: [],
      rarity: :common
    },
    "Table" => %{
      category: :furniture,
      image: "table.png",
      size: 1.25,
      creates_light: false,
      treasure_chance: 5,
      special_item_chance: 1,
      rumor_chance: 1,
      trap_chance: 0,
      monster_chance: 0,
      monster_list: [],
      rarity: :common
    },
    "Target" => %{
      category: :combat,
      image: "target.png",
      size: 1,
      creates_light: false,
      treasure_chance: 0,
      special_item_chance: 1,
      rumor_chance: 1,
      trap_chance: 0,
      monster_chance: 0,
      monster_list: [],
      rarity: :common
    },
    "Tent" => %{
      category: :structure,
      image: "tent.png",
      size: 2,
      creates_light: false,
      treasure_chance: 15,
      special_item_chance: 1,
      rumor_chance: 10,
      trap_chance: 1,
      monster_chance: 25,
      monster_list: ["Goblin Scout", "Orc", "Rat"],
      rarity: :common
    },
    "Throne" => %{
      category: :furniture,
      image: "throne.png",
      size: 1,
      creates_light: false,
      treasure_chance: 35,
      special_item_chance: 25,
      rumor_chance: 30,
      trap_chance: 50,
      monster_chance: 0,
      monster_list: ["Wailing Ghost"],
      rarity: :rare
    },
    "Torture Rack" => %{
      category: :combat,
      image: "torture_rack.png",
      size: 1.75,
      creates_light: false,
      treasure_chance: 10,
      special_item_chance: 5,
      rumor_chance: 10,
      trap_chance: 10,
      monster_chance: 25,
      monster_list: ["Skeleton", "Wailing Ghost", "Possessed Head"],
      rarity: :uncommon
    },
    "Treasure Pile" => %{
      category: :treasure,
      image: "treasure_pile.png",
      size: 2,
      creates_light: false,
      treasure_chance: 80,
      special_item_chance: 50,
      rumor_chance: 15,
      trap_chance: 50,
      monster_chance: 5,
      monster_list: ["Mimic"],
      rarity: :elite
    },
    "Tree" => %{
      category: :natural,
      image: "tree.png",
      size: 2.5,
      creates_light: false,
      treasure_chance: 1,
      special_item_chance: 1,
      rumor_chance: 5,
      trap_chance: 0,
      monster_chance: 5,
      monster_list: ["Spider"],
      rarity: :common
    },
    "Well" => %{
      category: :water,
      image: "well.png",
      size: 1.5,
      creates_light: false,
      treasure_chance: 15,
      special_item_chance: 10,
      rumor_chance: 10,
      trap_chance: 5,
      monster_chance: 15,
      monster_list: ["Rat", "Spider", "Giant Centipede"],
      rarity: :uncommon
    },
    "Weapon Rack" => %{
      category: :combat,
      image: "weapon_rack.png",
      size: 1.25,
      creates_light: false,
      treasure_chance: 35,
      special_item_chance: 35,
      rumor_chance: 5,
      trap_chance: 0,
      monster_chance: 0,
      monster_list: [],
      rarity: :uncommon
    }
  }

  # Legacy list for backward compatibility
  @special_features Map.keys(@special_feature_registry)

  # === SPECIAL FEATURE REGISTRY API ===

  @doc """
  Get all special feature names
  """
  def all_special_feature_names, do: @special_features

  @doc """
  Get feature data by name
  """
  def get_special_feature_data(feature_name) do
    Map.get(@special_feature_registry, feature_name)
  end

  @doc """
  Get a random special feature from theme-specific list using rarity-based selection
  Theme features can be either strings (legacy) or {name, rarity} tuples
  If theme doesn't have features defined, falls back to all features with global rarity system
  """
  def get_random_special_feature(theme_features)
      when is_list(theme_features) and theme_features != [] do
    # Convert theme features to a standardized format
    theme_feature_list = normalize_theme_features(theme_features)

    case theme_feature_list do
      [] ->
        # No valid features in theme, use global rarity system
        get_random_special_feature_by_rarity()

      valid_features ->
        # Use theme-specific rarity system
        get_random_feature_from_theme_with_rarity(valid_features)
    end
  end

  def get_random_special_feature(_), do: get_random_special_feature_by_rarity()

  @doc """
  Get a random special feature using the global rarity system
  """
  def get_random_special_feature_by_rarity do
    rarity = determine_feature_rarity()
    features_of_rarity = get_features_by_rarity(rarity)

    case features_of_rarity do
      [] ->
        # Fallback: if no features of selected rarity, pick any feature
        Enum.random(@special_features)

      features ->
        Enum.random(features)
    end
  end

  # Private helper functions for feature rarity system

  defp normalize_theme_features(theme_features) do
    theme_features
    |> Enum.map(&normalize_theme_feature/1)
    |> Enum.filter(& &1)
  end

  defp normalize_theme_feature({name, rarity}) when is_binary(name) and is_atom(rarity) do
    case get_special_feature_data(name) do
      nil -> nil
      _feature_data -> {name, rarity}
    end
  end

  defp normalize_theme_feature(name) when is_binary(name) do
    case get_special_feature_data(name) do
      nil -> nil
      feature_data -> {name, feature_data.rarity}
    end
  end

  defp normalize_theme_feature(_), do: nil

  defp get_random_feature_from_theme_with_rarity(theme_feature_list) do
    rarity = determine_feature_rarity()

    # Filter features by the selected rarity
    features_of_rarity =
      theme_feature_list
      |> Enum.filter(fn {_name, feature_rarity} -> feature_rarity == rarity end)
      |> Enum.map(fn {name, _rarity} -> name end)

    case features_of_rarity do
      [] ->
        # No features of selected rarity in theme, pick any from theme
        theme_feature_list
        |> Enum.map(fn {name, _rarity} -> name end)
        |> Enum.random()

      features ->
        Enum.random(features)
    end
  end

  defp determine_feature_rarity do
    case :rand.uniform(100) do
      # 60% - Common features (basic containers, furniture, natural elements)
      n when n <= 60 -> :common
      # 25% - Uncommon features (religious items, knowledge sources, special structures)
      n when n <= 85 -> :uncommon
      # 12% - Rare features (magical items, valuable treasures, dangerous objects)
      n when n <= 97 -> :rare
      # 3% - Elite features (ultimate treasures, extremely powerful items)
      _ -> :elite
    end
  end

  defp get_features_by_rarity(rarity) do
    @special_feature_registry
    |> Enum.filter(fn {_name, data} -> data.rarity == rarity end)
    |> Enum.map(fn {name, _data} -> name end)
  end

  @doc """
  Check if a special feature creates light
  """
  def special_feature_creates_light?(feature_name) do
    case get_special_feature_data(feature_name) do
      %{creates_light: creates_light} -> creates_light
      _ -> false
    end
  end

  @doc """
  Get the contents configuration for a feature
  """
  def get_special_feature_contents_config(feature_name) do
    data = get_special_feature_data(feature_name) || get_default_special_feature_attributes()

    %{
      treasure_chance: data.treasure_chance,
      special_item_chance: data.special_item_chance,
      rumor_chance: data.rumor_chance,
      trap_chance: data.trap_chance,
      monster_chance: data.monster_chance,
      monster_list: data.monster_list
    }
  end

  @doc """
  Get the size of a special feature
  """
  def get_special_feature_size(feature_name) do
    case get_special_feature_data(feature_name) do
      %{size: size} -> size
      _ -> 1
    end
  end

  @doc """
  Get the image path for a special feature
  """
  def get_special_feature_image_path(feature_name) do
    case get_special_feature_data(feature_name) do
      %{image: image} ->
        # Items that stay in root /images/ directory (not considered special features)
        root_items = ["chest.png", "torch.png", "healing_potion.png", "pile_of_bones.png"]

        if image in root_items do
          "/images/#{image}"
        else
          "/images/special_features/#{image}"
        end

      nil ->
        "/images/special_features/barrel.png"
    end
  end

  defp get_default_special_feature_attributes do
    %{
      creates_light: false,
      treasure_chance: 0,
      special_item_chance: 0,
      rumor_chance: 0,
      trap_chance: 0,
      monster_chance: 0,
      monster_list: []
    }
  end

  # === DUNGEON GENERATION FUNCTIONS ===

  @doc """
  Add pillars to large rooms
  """
  def add_pillars(grid, rooms) do
    Enum.reduce(rooms, grid, fn room, acc_grid ->
      # Add pillars to larger rooms
      if room.width >= 8 and room.height >= 8 and Enum.random(1..2) == 1 do
        add_pillars_to_room(acc_grid, room)
      else
        acc_grid
      end
    end)
  end

  @doc """
  Add doors at corridor-room intersections
  """
  def add_doors(grid, corridors, rooms) do
    Enum.reduce(corridors, grid, fn corridor, acc_grid ->
      place_doors_for_corridor(acc_grid, corridor, rooms)
    end)
  end

  @doc """
  Add staircases to rooms
  """
  def add_staircases(grid, rooms, theme_direction) do
    # First, add starting staircase to R1 (first room)
    [first_room | other_rooms] = rooms
    grid = add_starting_staircase(grid, first_room)

    # Add 1-4 additional staircases randomly to other rooms
    num_staircases = Enum.random(1..4)
    available_rooms = Enum.shuffle(other_rooms)

    place_staircases(grid, available_rooms, num_staircases, theme_direction)
  end

  @doc """
  Add room traps (skip R1)
  """
  def add_room_traps(grid, rooms) do
    # Skip R1 (first room) - it's the starting room
    [_first_room | other_rooms] = rooms

    Enum.reduce(other_rooms, grid, fn room, acc_grid ->
      # 1 in 20 rooms should have a trap
      if Enum.random(1..20) == 1 do
        add_trap_to_room(acc_grid, room)
      else
        acc_grid
      end
    end)
  end

  @doc """
  Add encounters to rooms and corridors
  """
  def add_encounters(grid, rooms, corridors, theme \\ nil, max_level \\ 1) do
    encounter_counter = 0

    # Add room encounters (2 in 3 rooms)
    {grid, encounter_counter} =
      add_room_encounters(grid, rooms, encounter_counter, theme, max_level)

    # Add corridor encounters (1 in 4 corridors)
    {grid, _encounter_counter} =
      add_corridor_encounters(grid, corridors, rooms, encounter_counter, theme, max_level)

    grid
  end

  @doc """
  Add treasures to rooms and corridors
  """
  def add_treasures(grid, rooms, corridors) do
    # Add room treasures (1 in 2 rooms)
    grid = add_room_treasures(grid, rooms)

    # Add corridor treasures (1 in 4 corridors)
    grid = add_corridor_treasures(grid, corridors, rooms)

    grid
  end

  @doc """
  Add special features to rooms (F1, F2, F3, etc.)
  Number of features scales with room size plus randomness
  Features are numbered per room (each room gets F1, F2, F3, etc.)
  """
  def add_special_features(grid, rooms, theme \\ nil) do
    # Skip R1 (first room) - it's the starting room
    [_first_room | other_rooms] = rooms

    theme_features = if theme, do: Map.get(theme, :special_features), else: nil

    Enum.reduce(other_rooms, grid, fn room, acc_grid ->
      # Each room starts its feature counter at 1
      {new_grid, _final_counter} = add_features_to_room(acc_grid, room, 1, theme_features)
      new_grid
    end)
  end

  @doc """
  Add torches to rooms (1 in 4 rooms should have a torch)
  """
  def add_torches(grid, rooms) do
    # Skip R1 (first room) - it's the starting room
    [_first_room | other_rooms] = rooms

    Enum.reduce(other_rooms, grid, fn room, acc_grid ->
      # 1 in 2 rooms should have a torch
      if Enum.random(1..2) == 1 do
        add_torch_to_room(acc_grid, room)
      else
        acc_grid
      end
    end)
  end

  @doc """
  Add torches to rooms with level-aware placement (always include torch in R1 for level 2+)
  """
  def add_torches_with_level(grid, rooms, level) do
    [first_room | other_rooms] = rooms

    # Always add torch to R1 (first room) if level >= 2
    grid =
      if level >= 2 do
        add_torch_to_room(grid, first_room)
      else
        grid
      end

    # Add torches to other rooms normally
    Enum.reduce(other_rooms, grid, fn room, acc_grid ->
      # 1 in 2 rooms should have a torch
      if Enum.random(1..2) == 1 do
        add_torch_to_room(acc_grid, room)
      else
        acc_grid
      end
    end)
  end

  @doc """
  Add food to rooms (1 in 4 rooms should have food)
  """
  def add_food(grid, rooms) do
    # Skip R1 (first room) - it's the starting room
    [_first_room | other_rooms] = rooms

    Enum.reduce(other_rooms, grid, fn room, acc_grid ->
      # 1 in 4 rooms should have food
      if Enum.random(1..4) == 1 do
        add_food_to_room(acc_grid, room)
      else
        acc_grid
      end
    end)
  end

  @doc """
  Add healing potions to rooms and corridors (1 in 8 chance each)
  """
  def add_healing_potions(grid, rooms, corridors) do
    # Add healing potions to rooms (1 in 8 rooms)
    grid = add_healing_potions_to_rooms(grid, rooms)

    # Add healing potions to corridors (1 in 8 corridors)
    grid = add_healing_potions_to_corridors(grid, corridors, rooms)

    grid
  end

  # Private functions - Pillars

  defp add_pillars_to_room(grid, room) do
    # Add 2x2 pillar in center of large rooms using special feature format
    center_x = room.x + div(room.width, 2)
    center_y = room.y + div(room.height, 2)

    pillar_positions = [
      {center_x, center_y},
      {center_x + 1, center_y},
      {center_x, center_y + 1},
      {center_x + 1, center_y + 1}
    ]

    # Add pillars as special features with proper labels for rendering order
    pillar_positions
    |> Enum.with_index(1)
    |> Enum.reduce(grid, fn {{x, y}, index}, acc ->
      # Use P1, P2, P3, P4 labels for the 4 pillar segments
      pillar_label = "P#{index}"
      Map.put(acc, {x, y}, {:special_feature, pillar_label, "Pillar"})
    end)
  end

  # Private functions - Doors

  defp place_doors_for_corridor(grid, corridor, rooms) do
    # Find where corridors intersect with room boundaries
    door_positions = find_corridor_room_intersections(corridor.path, rooms, grid)

    # Randomly place doors at some intersections
    placed_doors = Enum.take_random(door_positions, min(2, length(door_positions)))

    Enum.reduce(placed_doors, grid, fn {x, y}, acc ->
      door_type = random_door_type()
      Map.put(acc, {x, y}, door_type)
    end)
  end

  defp random_door_type do
    # A door can be both locked and trapped, but secret doors are always unlocked and untrapped
    is_secret = Enum.random(1..10) == 1

    if is_secret do
      :secret_door
    else
      is_locked = Enum.random(1..5) == 1
      is_trapped = Enum.random(1..20) == 1

      case {is_locked, is_trapped} do
        {true, true} -> :locked_trapped_door
        {true, false} -> :locked_door
        {false, true} -> :trapped_door
        {false, false} -> :door
      end
    end
  end

  defp find_corridor_room_intersections(corridor_path, rooms, grid) do
    Enum.filter(corridor_path, fn {x, y} ->
      # Check if this corridor position is adjacent to a room
      Map.get(grid, {x, y}) == :corridor and
        Enum.any?([{x - 1, y}, {x + 1, y}, {x, y - 1}, {x, y + 1}], fn {adj_x, adj_y} ->
          Map.get(grid, {adj_x, adj_y}) == :floor and
            Grid.point_in_any_room?({adj_x, adj_y}, rooms)
        end) and
        valid_door_position?(grid, {x, y}, rooms)
    end)
  end

  defp valid_door_position?(grid, {x, y}, rooms) do
    # Determine the door orientation based on adjacent room
    room_directions = [
      # Room to the west
      {x - 1, y, :west},
      # Room to the east
      {x + 1, y, :east},
      # Room to the north
      {x, y - 1, :north},
      # Room to the south
      {x, y + 1, :south}
    ]

    # Find which direction has the room
    room_direction =
      Enum.find(room_directions, fn {adj_x, adj_y, _dir} ->
        Map.get(grid, {adj_x, adj_y}) == :floor and Grid.point_in_any_room?({adj_x, adj_y}, rooms)
      end)

    case room_direction do
      {_adj_x, _adj_y, orientation} ->
        check_door_barrier(grid, {x, y}, orientation)

      nil ->
        false
    end
  end

  defp check_door_barrier(grid, {x, y}, orientation) do
    case orientation do
      :north ->
        # Room is north, check east/west sides have barriers
        east_blocked =
          Map.get(grid, {x + 1, y}) in [
            :wall,
            :door,
            :locked_door,
            :trapped_door,
            :locked_trapped_door,
            :secret_door
          ]

        west_blocked =
          Map.get(grid, {x - 1, y}) in [
            :wall,
            :door,
            :locked_door,
            :trapped_door,
            :locked_trapped_door,
            :secret_door
          ]

        east_blocked and west_blocked

      :south ->
        # Room is south, check east/west sides have barriers
        east_blocked =
          Map.get(grid, {x + 1, y}) in [
            :wall,
            :door,
            :locked_door,
            :trapped_door,
            :locked_trapped_door,
            :secret_door
          ]

        west_blocked =
          Map.get(grid, {x - 1, y}) in [
            :wall,
            :door,
            :locked_door,
            :trapped_door,
            :locked_trapped_door,
            :secret_door
          ]

        east_blocked and west_blocked

      :east ->
        # Room is east, check north/south sides have barriers
        north_blocked =
          Map.get(grid, {x, y - 1}) in [
            :wall,
            :door,
            :locked_door,
            :trapped_door,
            :locked_trapped_door,
            :secret_door
          ]

        south_blocked =
          Map.get(grid, {x, y + 1}) in [
            :wall,
            :door,
            :locked_door,
            :trapped_door,
            :locked_trapped_door,
            :secret_door
          ]

        north_blocked and south_blocked

      :west ->
        # Room is west, check north/south sides have barriers
        north_blocked =
          Map.get(grid, {x, y - 1}) in [
            :wall,
            :door,
            :locked_door,
            :trapped_door,
            :locked_trapped_door,
            :secret_door
          ]

        south_blocked =
          Map.get(grid, {x, y + 1}) in [
            :wall,
            :door,
            :locked_door,
            :trapped_door,
            :locked_trapped_door,
            :secret_door
          ]

        north_blocked and south_blocked
    end
  end

  # Private functions - Staircases

  defp add_starting_staircase(grid, room) do
    case find_staircase_position(grid, room) do
      # Fallback if we can't place starting staircase
      nil -> grid
      {x, y} -> Map.put(grid, {x, y}, {:starting_stair, "S"})
    end
  end

  defp place_staircases(grid, _rooms, 0, _theme_direction), do: grid
  defp place_staircases(grid, [], _count, _theme_direction), do: grid

  defp place_staircases(grid, [room | remaining_rooms], count, theme_direction) do
    case find_staircase_position(grid, room) do
      nil ->
        # Couldn't place staircase in this room, try next
        place_staircases(grid, remaining_rooms, count, theme_direction)

      {x, y} ->
        # Choose stair type based on theme direction
        stair_type = if theme_direction == :up, do: :stair_up, else: :stair_down
        updated_grid = Map.put(grid, {x, y}, stair_type)
        place_staircases(updated_grid, remaining_rooms, count - 1, theme_direction)
    end
  end

  def find_staircase_position(grid, room) do
    # Find available floor positions in the room that aren't occupied
    potential_positions =
      for x <- room.x..(room.x + room.width - 1),
          y <- room.y..(room.y + room.height - 1),
          Map.get(grid, {x, y}) == :floor,
          do: {x, y}

    # Shuffle and try to find a position that's not too close to room center
    # (to avoid conflicts with room labels)
    center_x = room.x + div(room.width, 2)
    center_y = room.y + div(room.height, 2)

    # Prefer positions that are not in the immediate center
    preferred_positions =
      Enum.filter(potential_positions, fn {x, y} ->
        abs(x - center_x) > 1 or abs(y - center_y) > 1
      end)

    case preferred_positions do
      [] ->
        # Fall back to any available position
        case potential_positions do
          [] -> nil
          positions -> Enum.random(positions)
        end

      positions ->
        Enum.random(positions)
    end
  end

  # Private functions - Room Traps

  defp add_trap_to_room(grid, room) do
    case find_room_trap_position(grid, room) do
      # Couldn't place trap
      nil -> grid
      {x, y} -> Map.put(grid, {x, y}, :room_trap)
    end
  end

  defp find_room_trap_position(grid, room) do
    # Find available floor positions that aren't occupied by other features
    potential_positions =
      for x <- room.x..(room.x + room.width - 1),
          y <- room.y..(room.y + room.height - 1),
          Map.get(grid, {x, y}) == :floor,
          do: {x, y}

    # Avoid the center area where room labels are placed
    center_x = room.x + div(room.width, 2)
    center_y = room.y + div(room.height, 2)

    # Filter out positions too close to center (to avoid room label conflicts)
    available_positions =
      Enum.filter(potential_positions, fn {x, y} ->
        abs(x - center_x) > 1 or abs(y - center_y) > 1
      end)

    case available_positions do
      # No available positions
      [] -> nil
      positions -> Enum.random(positions)
    end
  end

  # Private functions - Encounters

  defp add_room_encounters(grid, rooms, encounter_counter, theme, max_level) do
    # Skip R1 (first room) - it's the starting room
    [_first_room | other_rooms] = rooms

    Enum.reduce(other_rooms, {grid, encounter_counter}, fn room, {acc_grid, counter} ->
      # 2 in 3 rooms should have encounters
      if Enum.random(1..3) <= 2 do
        add_encounter_to_room(acc_grid, room, counter, theme, max_level)
      else
        {acc_grid, counter}
      end
    end)
  end

  defp add_encounter_to_room(grid, room, counter, theme, max_level) do
    case find_encounter_position_in_room(grid, room) do
      nil ->
        {grid, counter}

      {x, y} ->
        encounter_label = "E#{counter + 1}"
        # Select random monster during generation (theme-aware with fog_type logic)
        monster =
          Dungeon.Monster.get_random_monster_for_theme_with_fog_type(theme, max_level, max_level)

        new_grid = Map.put(grid, {x, y}, {:encounter, encounter_label, monster})
        {new_grid, counter + 1}
    end
  end

  defp add_corridor_encounters(grid, corridors, rooms, encounter_counter, theme, max_level) do
    Enum.reduce(corridors, {grid, encounter_counter}, fn corridor, {acc_grid, counter} ->
      # 1 in 4 corridors should have encounters
      if Enum.random(1..4) == 1 do
        add_encounter_to_corridor(acc_grid, corridor, rooms, counter, theme, max_level)
      else
        {acc_grid, counter}
      end
    end)
  end

  defp add_encounter_to_corridor(grid, corridor, rooms, counter, theme, max_level) do
    case find_encounter_position_in_corridor(grid, corridor, rooms) do
      nil ->
        {grid, counter}

      {x, y} ->
        encounter_label = "E#{counter + 1}"
        # Select random monster during generation (theme-aware with fog_type logic)
        monster =
          Dungeon.Monster.get_random_monster_for_theme_with_fog_type(theme, max_level, max_level)

        new_grid = Map.put(grid, {x, y}, {:encounter, encounter_label, monster})
        {new_grid, counter + 1}
    end
  end

  defp find_encounter_position_in_room(grid, room) do
    # Find available floor positions that aren't occupied by other features
    potential_positions =
      for x <- room.x..(room.x + room.width - 1),
          y <- room.y..(room.y + room.height - 1),
          Map.get(grid, {x, y}) == :floor,
          do: {x, y}

    # Avoid the center area where room labels are placed
    center_x = room.x + div(room.width, 2)
    center_y = room.y + div(room.height, 2)

    # Filter out positions too close to center (to avoid room label conflicts)
    available_positions =
      Enum.filter(potential_positions, fn {x, y} ->
        abs(x - center_x) > 1 or abs(y - center_y) > 1
      end)

    case available_positions do
      # No available positions
      [] -> nil
      positions -> Enum.random(positions)
    end
  end

  defp find_encounter_position_in_corridor(grid, corridor, rooms) do
    # Find corridor segments that are NOT in rooms and available
    pure_corridor_positions =
      Enum.filter(corridor.path, fn {x, y} ->
        Map.get(grid, {x, y}) == :corridor and not Grid.point_in_any_room?({x, y}, rooms)
      end)

    # Filter out positions that already have corridor labels
    available_positions =
      Enum.filter(pure_corridor_positions, fn {x, y} ->
        case Map.get(grid, {x, y}) do
          :corridor -> true
          _ -> false
        end
      end)

    case available_positions do
      # No available positions
      [] -> nil
      positions -> Enum.random(positions)
    end
  end

  # Private functions - Treasures

  defp add_room_treasures(grid, rooms) do
    # Skip R1 (first room) - it's the starting room
    [_first_room | other_rooms] = rooms

    Enum.reduce(other_rooms, grid, fn room, acc_grid ->
      # 1 in 2 rooms should have treasure
      if Enum.random(1..2) == 1 do
        add_treasure_to_room(acc_grid, room)
      else
        acc_grid
      end
    end)
  end

  defp add_corridor_treasures(grid, corridors, rooms) do
    Enum.reduce(corridors, grid, fn corridor, acc_grid ->
      # 1 in 4 corridors should have treasure
      if Enum.random(1..4) == 1 do
        add_treasure_to_corridor(acc_grid, corridor, rooms)
      else
        acc_grid
      end
    end)
  end

  defp add_treasure_to_room(grid, room) do
    case find_treasure_position_in_room(grid, room) do
      nil ->
        grid

      {x, y} ->
        treasure_type = if Enum.random(1..10) == 1, do: :trapped_treasure, else: :treasure
        Map.put(grid, {x, y}, treasure_type)
    end
  end

  defp add_treasure_to_corridor(grid, corridor, rooms) do
    case find_treasure_position_in_corridor(grid, corridor, rooms) do
      nil ->
        grid

      {x, y} ->
        # 1 in 4 chance treasure is trapped
        treasure_type = if Enum.random(1..4) == 1, do: :trapped_treasure, else: :treasure
        Map.put(grid, {x, y}, treasure_type)
    end
  end

  defp find_treasure_position_in_room(grid, room) do
    # Find available floor positions that aren't occupied by other features
    potential_positions =
      for x <- room.x..(room.x + room.width - 1),
          y <- room.y..(room.y + room.height - 1),
          Grid.position_available_for_treasure?(grid, {x, y}),
          do: {x, y}

    # Avoid the center area where room labels are placed
    center_x = room.x + div(room.width, 2)
    center_y = room.y + div(room.height, 2)

    # Filter out positions too close to center (to avoid room label conflicts)
    available_positions =
      Enum.filter(potential_positions, fn {x, y} ->
        abs(x - center_x) > 1 or abs(y - center_y) > 1
      end)

    case available_positions do
      [] -> nil
      positions -> Enum.random(positions)
    end
  end

  defp find_treasure_position_in_corridor(grid, corridor, rooms) do
    # Find corridor segments that are NOT in rooms and available
    pure_corridor_positions =
      Enum.filter(corridor.path, fn {x, y} ->
        Grid.position_available_for_treasure?(grid, {x, y}) and
          not Grid.point_in_any_room?({x, y}, rooms)
      end)

    case pure_corridor_positions do
      [] -> nil
      positions -> Enum.random(positions)
    end
  end

  # Private functions - Special Features

  defp add_features_to_room(grid, room, counter, theme_features) do
    room_area = room.width * room.height
    num_features = calculate_feature_count(room_area)
    place_features_in_room(grid, room, counter, num_features, theme_features)
  end

  # Calculate number of features based on room size
  defp calculate_feature_count(room_area) when room_area < 30 do
    # Small rooms: 70% chance of 0, 30% chance of 1
    if Enum.random(1..10) <= 7, do: 0, else: 1
  end

  defp calculate_feature_count(room_area) when room_area < 80 do
    # Medium rooms: 20% chance of 0, 50% chance of 1, 30% chance of 2
    case Enum.random(1..10) do
      n when n <= 2 -> 0
      n when n <= 7 -> 1
      _ -> 2
    end
  end

  defp calculate_feature_count(_room_area) do
    # Large rooms: 10% chance of 0, 20% chance of 1, 40% chance of 2, 30% chance of 3
    case Enum.random(1..10) do
      1 -> 0
      n when n <= 3 -> 1
      n when n <= 7 -> 2
      _ -> 3
    end
  end

  defp place_features_in_room(grid, room, counter, num_features, theme_features)
  defp place_features_in_room(grid, _room, counter, 0, _theme_features), do: {grid, counter}

  defp place_features_in_room(grid, room, counter, num_features, theme_features) do
    case find_feature_position(grid, room) do
      nil ->
        # Couldn't place feature, stop trying for this room
        {grid, counter}

      {x, y} ->
        # Use sequential labels for map display (F1, F2, F3...)
        feature_label = "F#{counter}"
        # Select a random specific feature name for the dialog/LLM context (theme-aware)
        feature_name = get_random_special_feature(theme_features)
        # Store both the display label and the specific feature name
        updated_grid = Map.put(grid, {x, y}, {:special_feature, feature_label, feature_name})
        place_features_in_room(updated_grid, room, counter + 1, num_features - 1, theme_features)
    end
  end

  defp find_feature_position(grid, room) do
    # Find available floor positions that aren't occupied by other features
    potential_positions =
      for x <- room.x..(room.x + room.width - 1),
          y <- room.y..(room.y + room.height - 1),
          Grid.position_available_for_treasure?(grid, {x, y}),
          do: {x, y}

    # Avoid the center area where room labels are placed
    center_x = room.x + div(room.width, 2)
    center_y = room.y + div(room.height, 2)

    # Filter out positions too close to center (to avoid room label conflicts)
    available_positions =
      Enum.filter(potential_positions, fn {x, y} ->
        abs(x - center_x) > 1 or abs(y - center_y) > 1
      end)

    case available_positions do
      [] -> nil
      positions -> Enum.random(positions)
    end
  end

  # Private functions - Torches

  defp add_torch_to_room(grid, room) do
    case find_torch_position(grid, room) do
      nil ->
        # Couldn't place torch
        grid

      {x, y} ->
        Map.put(grid, {x, y}, :torch)
    end
  end

  defp find_torch_position(grid, room) do
    # Find available floor positions that aren't occupied by other features
    # Be more specific about what positions are available for torches
    potential_positions =
      for x <- room.x..(room.x + room.width - 1),
          y <- room.y..(room.y + room.height - 1),
          position_available_for_torch?(grid, {x, y}),
          do: {x, y}

    # Avoid the center area where room labels are placed
    center_x = room.x + div(room.width, 2)
    center_y = room.y + div(room.height, 2)

    # Filter out positions too close to center (to avoid room label conflicts)
    available_positions =
      Enum.filter(potential_positions, fn {x, y} ->
        abs(x - center_x) > 1 or abs(y - center_y) > 1
      end)

    case available_positions do
      [] -> nil
      positions -> Enum.random(positions)
    end
  end

  # Check if position is available specifically for torch placement
  defp position_available_for_torch?(grid, {x, y}) do
    case Map.get(grid, {x, y}) do
      :floor -> true
      _ -> false
    end
  end

  # Private functions - Food

  defp add_food_to_room(grid, room) do
    case find_food_position(grid, room) do
      nil ->
        # Couldn't place food
        grid

      {x, y} ->
        # Choose specific food type during generation
        food_type = random_food_type()
        Map.put(grid, {x, y}, food_type)
    end
  end

  defp find_food_position(grid, room) do
    # Find available floor positions that aren't occupied by other features
    potential_positions =
      for x <- room.x..(room.x + room.width - 1),
          y <- room.y..(room.y + room.height - 1),
          position_available_for_food?(grid, {x, y}),
          do: {x, y}

    # Avoid the center area where room labels are placed
    center_x = room.x + div(room.width, 2)
    center_y = room.y + div(room.height, 2)

    # Filter out positions too close to center (to avoid room label conflicts)
    available_positions =
      Enum.filter(potential_positions, fn {x, y} ->
        abs(x - center_x) > 1 or abs(y - center_y) > 1
      end)

    case available_positions do
      [] -> nil
      positions -> Enum.random(positions)
    end
  end

  # Check if position is available specifically for food placement
  defp position_available_for_food?(grid, {x, y}) do
    case Map.get(grid, {x, y}) do
      :floor -> true
      _ -> false
    end
  end

  # Choose random food type
  defp random_food_type do
    Enum.random([:bread, :cheese, :grapes])
  end

  # Private functions - Healing Potions

  defp add_healing_potions_to_rooms(grid, rooms) do
    # Skip R1 (first room) - it's the starting room
    [_first_room | other_rooms] = rooms

    Enum.reduce(other_rooms, grid, fn room, acc_grid ->
      # 1 in 4 rooms should have healing potion (doubled from 1 in 8, using d20)
      # Roll 1d20: 1-5 = spawn healing potion (25% chance)
      d20_roll = Enum.random(1..20)

      if d20_roll <= 5 do
        add_healing_potion_to_room(acc_grid, room)
      else
        acc_grid
      end
    end)
  end

  defp add_healing_potions_to_corridors(grid, corridors, rooms) do
    Enum.reduce(corridors, grid, fn corridor, acc_grid ->
      # 1 in 4 corridors should have healing potion (doubled from 1 in 8, using d20)
      # Roll 1d20: 1-5 = spawn healing potion (25% chance)
      d20_roll = Enum.random(1..20)

      if d20_roll <= 5 do
        add_healing_potion_to_corridor(acc_grid, corridor, rooms)
      else
        acc_grid
      end
    end)
  end

  defp add_healing_potion_to_room(grid, room) do
    case find_healing_potion_position(grid, room) do
      nil ->
        # Couldn't place healing potion
        grid

      {x, y} ->
        Map.put(grid, {x, y}, :healing_potion)
    end
  end

  defp add_healing_potion_to_corridor(grid, corridor, rooms) do
    case find_healing_potion_position_in_corridor(grid, corridor, rooms) do
      nil ->
        grid

      {x, y} ->
        Map.put(grid, {x, y}, :healing_potion)
    end
  end

  defp find_healing_potion_position(grid, room) do
    # Find available floor positions that aren't occupied by other features
    potential_positions =
      for x <- room.x..(room.x + room.width - 1),
          y <- room.y..(room.y + room.height - 1),
          position_available_for_healing_potion?(grid, {x, y}),
          do: {x, y}

    # Avoid the center area where room labels are placed
    center_x = room.x + div(room.width, 2)
    center_y = room.y + div(room.height, 2)

    # Filter out positions too close to center (to avoid room label conflicts)
    available_positions =
      Enum.filter(potential_positions, fn {x, y} ->
        abs(x - center_x) > 1 or abs(y - center_y) > 1
      end)

    case available_positions do
      [] -> nil
      positions -> Enum.random(positions)
    end
  end

  defp find_healing_potion_position_in_corridor(grid, corridor, rooms) do
    # Find corridor segments that are NOT in rooms and available
    pure_corridor_positions =
      Enum.filter(corridor.path, fn {x, y} ->
        position_available_for_healing_potion?(grid, {x, y}) and
          not Grid.point_in_any_room?({x, y}, rooms)
      end)

    case pure_corridor_positions do
      [] -> nil
      positions -> Enum.random(positions)
    end
  end

  # Check if position is available specifically for healing potion placement
  defp position_available_for_healing_potion?(grid, {x, y}) do
    case Map.get(grid, {x, y}) do
      :floor -> true
      :corridor -> true
      _ -> false
    end
  end

  # Cavern-specific feature placement functions

  @doc """
  Add staircases to caverns
  """
  def add_staircases_to_caverns(grid, caverns, theme_direction) do
    if Enum.empty?(caverns),
      do: grid,
      else: do_add_staircases_to_caverns(grid, caverns, theme_direction)
  end

  defp do_add_staircases_to_caverns(grid, caverns, theme_direction) do
    # Add starting staircase to first cavern
    [first_cavern | other_caverns] = caverns
    grid = add_starting_staircase_to_cavern(grid, first_cavern)

    # Add 1-3 additional staircases to other caverns
    num_staircases = Enum.random(1..3)
    available_caverns = Enum.shuffle(other_caverns)

    place_staircases_in_caverns(grid, available_caverns, num_staircases, theme_direction)
  end

  @doc """
  Add encounters to caverns
  """
  def add_encounters_to_caverns(grid, caverns, theme \\ nil, max_level \\ 1) do
    encounter_counter = 0

    # Add encounters to caverns (2 in 3 caverns)
    {grid, _encounter_counter} =
      add_cavern_encounters(grid, caverns, encounter_counter, theme, max_level)

    grid
  end

  @doc """
  Add encounters to city areas with indoor/outdoor monster differentiation
  """
  def add_encounters_to_city_areas(grid, city_blocks, theme_data, max_level \\ 1) do
    encounter_counter = 0

    # Add city encounters (theme-aware for indoor vs outdoor)
    {grid, _encounter_counter} =
      add_city_encounters(grid, city_blocks, encounter_counter, theme_data, max_level)

    grid
  end

  @doc """
  Add treasures to caverns
  """
  def add_treasures_to_caverns(grid, caverns) do
    # Add treasures to caverns (1 in 2 caverns)
    add_cavern_treasures(grid, caverns)
  end

  @doc """
  Add food to caverns
  """
  def add_food_to_caverns(grid, caverns) do
    # Skip first cavern (starting cavern)
    if length(caverns) <= 1 do
      grid
    else
      [_first_cavern | other_caverns] = caverns
      add_food_to_cavern_list(grid, other_caverns)
    end
  end

  @doc """
  Add healing potions to caverns
  """
  def add_healing_potions_to_caverns(grid, caverns) do
    Enum.reduce(caverns, grid, fn cavern, acc_grid ->
      # 1 in 4 caverns should have healing potion (doubled from 1 in 8, using d20)
      # Roll 1d20: 1-5 = spawn healing potion (25% chance)
      d20_roll = Enum.random(1..20)

      if d20_roll <= 5 do
        add_healing_potion_to_cavern(acc_grid, cavern)
      else
        acc_grid
      end
    end)
  end

  @doc """
  Add torches to caverns
  """
  def add_torches_to_caverns(grid, caverns) do
    # Skip first cavern (starting cavern)
    if length(caverns) <= 1 do
      grid
    else
      [_first_cavern | other_caverns] = caverns
      add_torches_to_cavern_list(grid, other_caverns)
    end
  end

  @doc """
  Add torches to caverns with level-aware placement
  """
  def add_torches_to_caverns_with_level(grid, caverns, level) do
    if Enum.empty?(caverns) do
      grid
    else
      [first_cavern | other_caverns] = caverns

      # Always add torch to first cavern if level >= 2
      grid =
        if level >= 2 do
          add_torch_to_cavern(grid, first_cavern)
        else
          grid
        end

      # Add torches to other caverns normally
      add_torches_to_cavern_list(grid, other_caverns)
    end
  end

  @doc """
  Add special features to caverns
  """
  def add_special_features_to_caverns(grid, caverns, theme \\ nil) do
    # Skip first cavern (starting cavern)
    if length(caverns) <= 1 do
      grid
    else
      [_first_cavern | other_caverns] = caverns
      theme_features = if theme, do: Map.get(theme, :special_features), else: nil

      Enum.reduce(other_caverns, grid, fn cavern, acc_grid ->
        # Each cavern starts its feature counter at 1
        {new_grid, _final_counter} = add_features_to_cavern(acc_grid, cavern, 1, theme_features)
        new_grid
      end)
    end
  end

  # Private functions for cavern features

  defp add_starting_staircase_to_cavern(grid, cavern) do
    # Ensure we place the starting stair in a guaranteed floor position
    case find_guaranteed_floor_position(grid, cavern) do
      nil ->
        # If no floor position found, force create one in the center
        {center_x, center_y} = Caverns.center(cavern)
        grid = Map.put(grid, {center_x, center_y}, :floor)
        Map.put(grid, {center_x, center_y}, {:starting_stair, "S"})

      {x, y} ->
        Map.put(grid, {x, y}, {:starting_stair, "S"})
    end
  end

  defp place_staircases_in_caverns(grid, caverns, num_staircases, theme_direction) do
    caverns
    |> Enum.take(num_staircases)
    |> Enum.reduce(grid, fn cavern, acc_grid ->
      case find_cavern_position(acc_grid, cavern) do
        nil ->
          acc_grid

        {x, y} ->
          Map.put(acc_grid, {x, y}, stair_type(theme_direction))
      end
    end)
  end

  defp add_cavern_encounters(grid, caverns, encounter_counter, theme, max_level) do
    # Skip first cavern (starting cavern)
    if length(caverns) <= 1 do
      {grid, encounter_counter}
    else
      [_first_cavern | other_caverns] = caverns

      add_encounters_to_cavern_list(
        grid,
        other_caverns,
        encounter_counter,
        theme,
        max_level
      )
    end
  end

  defp add_encounters_to_cavern_list(grid, caverns, encounter_counter, theme, max_level) do
    Enum.reduce(caverns, {grid, encounter_counter}, fn cavern, {acc_grid, counter} ->
      # 2 in 3 caverns should have encounter
      if Enum.random(1..3) <= 2 do
        add_encounter_to_cavern(acc_grid, cavern, counter, theme, max_level)
      else
        {acc_grid, counter}
      end
    end)
  end

  defp add_encounter_to_cavern(grid, cavern, counter, theme, max_level) do
    case find_cavern_position(grid, cavern) do
      nil ->
        {grid, counter}

      {x, y} ->
        new_counter = counter + 1
        encounter_label = "E#{new_counter}"
        # Select random monster during generation (theme-aware with fog_type logic)
        monster =
          Dungeon.Monster.get_random_monster_for_theme_with_fog_type(theme, max_level, max_level)

        {Map.put(grid, {x, y}, {:encounter, encounter_label, monster}), new_counter}
    end
  end

  defp add_cavern_treasures(grid, caverns) do
    Enum.reduce(caverns, grid, fn cavern, acc_grid ->
      # 1 in 2 caverns should have treasure
      if Enum.random(1..2) == 1 do
        add_treasure_to_cavern(acc_grid, cavern)
      else
        acc_grid
      end
    end)
  end

  defp add_treasure_to_cavern(grid, cavern) do
    case find_cavern_position(grid, cavern) do
      nil ->
        grid

      {x, y} ->
        treasure_type = random_treasure_type()
        Map.put(grid, {x, y}, treasure_type)
    end
  end

  defp add_food_to_cavern_list(grid, caverns) do
    Enum.reduce(caverns, grid, fn cavern, acc_grid ->
      # 1 in 4 caverns should have food
      if Enum.random(1..4) == 1 do
        add_food_to_cavern(acc_grid, cavern)
      else
        acc_grid
      end
    end)
  end

  defp add_food_to_cavern(grid, cavern) do
    case find_cavern_position(grid, cavern) do
      nil ->
        grid

      {x, y} ->
        # Choose specific food type during generation
        food_type = random_food_type()
        Map.put(grid, {x, y}, food_type)
    end
  end

  defp add_healing_potion_to_cavern(grid, cavern) do
    case find_cavern_position(grid, cavern) do
      nil ->
        grid

      {x, y} ->
        Map.put(grid, {x, y}, :healing_potion)
    end
  end

  defp add_torches_to_cavern_list(grid, caverns) do
    Enum.reduce(caverns, grid, fn cavern, acc_grid ->
      # 1 in 2 caverns should have a torch
      if Enum.random(1..2) == 1 do
        add_torch_to_cavern(acc_grid, cavern)
      else
        acc_grid
      end
    end)
  end

  defp add_torch_to_cavern(grid, cavern) do
    case find_cavern_position(grid, cavern) do
      nil ->
        grid

      {x, y} ->
        Map.put(grid, {x, y}, :torch)
    end
  end

  defp add_features_to_cavern(grid, cavern, feature_counter, theme_features) do
    # Calculate number of features based on cavern size (reduced frequency)
    cavern_size = length(cavern.cells)
    # Roughly 1 feature per 20 cells (was 15, ~33% reduction)
    base_features = div(cavern_size, 20)

    # Use d20 roll for random bonus (roughly 1/3 reduction from 0-2 range)
    # Roll 1d20: 1-7 = 0 bonus, 8-14 = 1 bonus, 15-20 = 2 bonus
    d20_roll = Enum.random(1..20)

    random_bonus =
      cond do
        d20_roll <= 7 -> 0
        d20_roll <= 14 -> 1
        true -> 2
      end

    num_features = max(1, base_features + random_bonus)

    # Add features
    add_features_to_cavern_recursive(grid, cavern, feature_counter, num_features, theme_features)
  end

  defp add_features_to_cavern_recursive(
         grid,
         cavern,
         feature_counter,
         remaining_features,
         theme_features
       )

  defp add_features_to_cavern_recursive(grid, _cavern, feature_counter, 0, _theme_features) do
    {grid, feature_counter}
  end

  defp add_features_to_cavern_recursive(
         grid,
         cavern,
         feature_counter,
         remaining_features,
         theme_features
       ) do
    case find_cavern_position(grid, cavern) do
      nil ->
        # Can't place more features
        {grid, feature_counter}

      {x, y} ->
        # Place feature (theme-aware)
        feature_name = get_random_special_feature(theme_features)
        feature_label = "F#{feature_counter}"
        new_grid = Map.put(grid, {x, y}, {:special_feature, feature_label, feature_name})

        # Recurse for remaining features
        add_features_to_cavern_recursive(
          new_grid,
          cavern,
          feature_counter + 1,
          remaining_features - 1,
          theme_features
        )
    end
  end

  def find_cavern_position(grid, cavern) do
    # Find available floor positions within the cavern
    available_positions =
      Enum.filter(cavern.cells, fn {x, y} ->
        case Map.get(grid, {x, y}) do
          :floor -> true
          :corridor -> true
          _ -> false
        end
      end)

    case available_positions do
      [] -> nil
      positions -> Enum.random(positions)
    end
  end

  defp find_guaranteed_floor_position(grid, cavern) do
    # Find definitely available floor positions within the cavern
    floor_positions =
      Enum.filter(cavern.cells, fn {x, y} ->
        Map.get(grid, {x, y}) == :floor
      end)

    case floor_positions do
      [] -> nil
      positions -> Enum.random(positions)
    end
  end

  # Public functions - Waypoints for outdoor areas

  def add_waypoints_to_areas(grid, areas) do
    # First, add starting waypoint to first area (similar to starting staircase)
    [first_area | other_areas] = areas
    grid = add_starting_waypoint_to_area(grid, first_area)

    # Add 1-2 additional waypoints to other areas
    count = Enum.random(1..2)
    place_waypoints(grid, other_areas, count)
  end

  # Private functions - Waypoints

  defp place_waypoints(grid, _areas, 0), do: grid
  defp place_waypoints(grid, [], _count), do: grid

  defp place_waypoints(grid, [area | remaining_areas], count) do
    case find_waypoint_position(grid, area) do
      nil ->
        # Couldn't place waypoint in this area, try next
        place_waypoints(grid, remaining_areas, count)

      {x, y} ->
        # Choose random waypoint image (1-4)
        waypoint_number = Enum.random(1..4)
        waypoint_type = {:waypoint, waypoint_number}
        updated_grid = Map.put(grid, {x, y}, waypoint_type)
        place_waypoints(updated_grid, remaining_areas, count - 1)
    end
  end

  def find_waypoint_position(grid, area) do
    # Find available floor positions in the area that aren't occupied
    potential_positions =
      Enum.filter(area.cells, fn {x, y} ->
        Map.get(grid, {x, y}) == :floor
      end)

    # Prefer positions that are not in the immediate center (to avoid conflicts with area labels)
    {center_x, center_y} = Outdoor.center(area)

    preferred_positions =
      Enum.filter(potential_positions, fn {x, y} ->
        abs(x - center_x) > 1 or abs(y - center_y) > 1
      end)

    case preferred_positions do
      [] ->
        # Fall back to any available position
        case potential_positions do
          [] -> nil
          positions -> Enum.random(positions)
        end

      positions ->
        Enum.random(positions)
    end
  end

  defp add_starting_waypoint_to_area(grid, area) do
    # Ensure we place the starting waypoint in a guaranteed floor position
    case find_guaranteed_floor_position(grid, area) do
      nil ->
        # If no floor position found, force create one in the center
        {center_x, center_y} = Outdoor.center(area)
        grid = Map.put(grid, {center_x, center_y}, :floor)
        Map.put(grid, {center_x, center_y}, {:starting_waypoint, "S"})

      {x, y} ->
        Map.put(grid, {x, y}, {:starting_waypoint, "S"})
    end
  end

  # Helper functions for cavern generation
  defp random_treasure_type do
    if Enum.random(1..4) == 1, do: :trapped_treasure, else: :treasure
  end

  defp stair_type(theme_direction) do
    if theme_direction == :up, do: :stair_up, else: :stair_down
  end

  # Public functions - City-specific waypoints

  def add_waypoints_to_city_areas(grid, city_blocks, generation_type) do
    # First, add starting waypoint to edge of city (like arriving to town)
    grid = add_city_starting_waypoint(grid, generation_type)

    # Filter to only road intersection blocks for waypoint placement
    road_blocks = Enum.filter(city_blocks, fn block -> block.type == :road_intersection end)

    # Add 1-2 additional waypoints to road intersections near edges
    count = Enum.random(1..2)
    place_city_waypoints(grid, road_blocks, count, generation_type)
  end

  # Private functions - City Waypoints

  defp add_city_starting_waypoint(grid, generation_type) do
    # Find a road position near the edge of the map for the starting waypoint
    case find_city_edge_road_position(grid, generation_type) do
      nil ->
        # Fallback to any road position if no edge position found
        case find_any_city_road_position(grid, generation_type) do
          nil ->
            # Last resort: place at map center and make it a road
            center_x = div(Grid.map_width(), 2)
            center_y = div(Grid.map_height(), 2)
            grid = Map.put(grid, {center_x, center_y}, :road)
            Map.put(grid, {center_x, center_y}, {:starting_waypoint, "S"})

          {x, y} ->
            Map.put(grid, {x, y}, {:starting_waypoint, "S"})
        end

      {x, y} ->
        Map.put(grid, {x, y}, {:starting_waypoint, "S"})
    end
  end

  defp place_city_waypoints(grid, _road_blocks, 0, _generation_type), do: grid
  defp place_city_waypoints(grid, [], _count, _generation_type), do: grid

  defp place_city_waypoints(grid, [road_block | remaining_blocks], count, generation_type) do
    case find_city_waypoint_position(grid, road_block, generation_type) do
      nil ->
        # Couldn't place waypoint in this road block, try next
        place_city_waypoints(grid, remaining_blocks, count, generation_type)

      {x, y} ->
        # Choose random waypoint image (1-4)
        waypoint_number = Enum.random(1..4)
        waypoint_type = {:waypoint, waypoint_number}
        updated_grid = Map.put(grid, {x, y}, waypoint_type)
        place_city_waypoints(updated_grid, remaining_blocks, count - 1, generation_type)
    end
  end

  defp find_city_edge_road_position(grid, generation_type) do
    road_tile = get_road_tile_for_generation_type(generation_type)
    map_width = Grid.map_width()
    map_height = Grid.map_height()

    # Define edge boundaries (outer 20% of map)
    edge_margin = 8

    # Find road positions near the edges
    edge_road_positions =
      for x <- 0..(map_width - 1),
          y <- 0..(map_height - 1),
          Map.get(grid, {x, y}) == road_tile,
          near_edge?(x, y, map_width, map_height, edge_margin),
          do: {x, y}

    case edge_road_positions do
      [] -> nil
      positions -> Enum.random(positions)
    end
  end

  defp find_any_city_road_position(grid, generation_type) do
    road_tile = get_road_tile_for_generation_type(generation_type)

    # Find any road position
    road_positions =
      for x <- 0..(Grid.map_width() - 1),
          y <- 0..(Grid.map_height() - 1),
          Map.get(grid, {x, y}) == road_tile,
          do: {x, y}

    case road_positions do
      [] -> nil
      positions -> Enum.random(positions)
    end
  end

  defp find_city_waypoint_position(grid, road_block, generation_type) do
    road_tile = get_road_tile_for_generation_type(generation_type)

    # Find available road positions in the block that are near edges
    edge_positions =
      Enum.filter(road_block.cells || [], fn {x, y} ->
        Map.get(grid, {x, y}) == road_tile and
          near_edge?(x, y, Grid.map_width(), Grid.map_height(), 12)
      end)

    case edge_positions do
      [] ->
        # Fallback to any road position in the block
        road_positions =
          Enum.filter(road_block.cells || [], fn {x, y} ->
            Map.get(grid, {x, y}) == road_tile
          end)

        case road_positions do
          [] -> nil
          positions -> Enum.random(positions)
        end

      positions ->
        Enum.random(positions)
    end
  end

  defp near_edge?(x, y, map_width, map_height, margin) do
    x <= margin or x >= map_width - margin - 1 or y <= margin or y >= map_height - margin - 1
  end

  defp get_road_tile_for_generation_type("city"), do: :road
  defp get_road_tile_for_generation_type(_), do: :corridor

  @doc """
  Adds waypoints to outdoor areas that link to city themes.
  """
  def add_city_linking_waypoints(grid, areas) do
    # Place exactly 2 waypoints that will link to cities.
    shuffled_areas = Enum.shuffle(areas)
    place_city_linking_waypoints(grid, shuffled_areas, 2)
  end

  defp place_city_linking_waypoints(grid, _areas, 0), do: grid
  defp place_city_linking_waypoints(grid, [], _count), do: grid

  defp place_city_linking_waypoints(grid, [area | remaining_areas], count) do
    case find_waypoint_position(grid, area) do
      nil ->
        # Couldn't find a spot in this area, try the next one.
        place_city_linking_waypoints(grid, remaining_areas, count)

      {x, y} ->
        # Use a standard waypoint tile. The LiveView logic will check the map theme.
        waypoint_number = Enum.random(1..4)
        waypoint_type = {:waypoint, waypoint_number}
        updated_grid = Map.put(grid, {x, y}, waypoint_type)

        place_city_linking_waypoints(updated_grid, remaining_areas, count - 1)
    end
  end

  # Private functions for city encounters

  defp add_city_encounters(grid, city_blocks, encounter_counter, theme_data, max_level) do
    # Skip first city block (starting area)
    if length(city_blocks) <= 1 do
      {grid, encounter_counter}
    else
      [_first_block | other_blocks] = city_blocks

      add_encounters_to_city_block_list(
        grid,
        other_blocks,
        encounter_counter,
        theme_data,
        max_level
      )
    end
  end

  defp add_encounters_to_city_block_list(
         grid,
         city_blocks,
         encounter_counter,
         theme_data,
         max_level
       ) do
    Enum.reduce(city_blocks, {grid, encounter_counter}, fn block, {acc_grid, counter} ->
      # 2 in 3 city blocks should have encounter
      if Enum.random(1..3) <= 2 do
        add_encounter_to_city_block(acc_grid, block, counter, theme_data, max_level)
      else
        {acc_grid, counter}
      end
    end)
  end

  defp add_encounter_to_city_block(grid, block, counter, theme_data, max_level) do
    case find_city_block_position(grid, block) do
      nil ->
        {grid, counter}

      {x, y} ->
        new_counter = counter + 1
        encounter_label = "E#{new_counter}"

        # Select monster based on block type (indoor vs outdoor)
        monster = get_monster_for_city_block(block, theme_data, max_level)
        {Map.put(grid, {x, y}, {:encounter, encounter_label, monster}), new_counter}
    end
  end

  defp find_city_block_position(grid, block) do
    # Find available positions within the city block based on type
    suitable_cells =
      case block.type do
        :building ->
          # For buildings, use floor cells
          Enum.filter(block.floor_cells || [], fn {x, y} ->
            Map.get(grid, {x, y}) == :floor
          end)

        :road_intersection ->
          # For road intersections, use road cells
          Enum.filter(block.cells || [], fn {x, y} ->
            Map.get(grid, {x, y}) == :road
          end)

        _ ->
          # Fallback for unknown block types
          Enum.filter(block.cells || [], fn {x, y} ->
            tile = Map.get(grid, {x, y})
            tile in [:floor, :corridor, :road]
          end)
      end

    case suitable_cells do
      [] -> nil
      positions -> Enum.random(positions)
    end
  end

  defp get_monster_for_city_block(block, theme_data, max_level) do
    case block.type do
      :building ->
        # Use indoor monsters for buildings
        indoor_monsters = Map.get(theme_data, :indoor_monsters, [])

        if indoor_monsters != [] do
          # Create a temporary theme with indoor monsters for fog_type logic
          indoor_theme = %{theme_data | monsters: indoor_monsters}

          Dungeon.Monster.get_random_monster_for_theme_with_fog_type(
            indoor_theme,
            max_level,
            max_level
          )
        else
          # Fallback to general monsters list with fog_type logic
          Dungeon.Monster.get_random_monster_for_theme_with_fog_type(
            theme_data,
            max_level,
            max_level
          )
        end

      :road_intersection ->
        # Use outdoor monsters for road intersections
        outdoor_monsters = Map.get(theme_data, :outdoor_monsters, [])

        if outdoor_monsters != [] do
          # Create a temporary theme with outdoor monsters for fog_type logic
          outdoor_theme = %{theme_data | monsters: outdoor_monsters}

          Dungeon.Monster.get_random_monster_for_theme_with_fog_type(
            outdoor_theme,
            max_level,
            max_level
          )
        else
          # Fallback to general monsters list with fog_type logic
          Dungeon.Monster.get_random_monster_for_theme_with_fog_type(
            theme_data,
            max_level,
            max_level
          )
        end

      _ ->
        # Fallback for unknown block types - use general monsters list with fog_type logic
        Dungeon.Monster.get_random_monster_for_theme_with_fog_type(
          theme_data,
          max_level,
          max_level
        )
    end
  end
end
