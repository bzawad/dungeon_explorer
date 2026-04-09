defmodule Dungeon.SpecialItem do
  @moduledoc """
  Special item definitions for magic items, weapons, armor, and other treasures
  """

  defstruct [
    :name,
    :description,
    :category,
    :rarity,
    :type,
    :consumable,
    :uses,
    :weapon_bonus,
    :damage_bonus,
    :armor_bonus,
    :dexterity_bonus,
    :wearable,
    :wearable_slot,
    :gold_value,
    :xp_value
  ]

  @type t :: %__MODULE__{
          name: String.t(),
          description: String.t(),
          category: String.t(),
          rarity: :common | :uncommon | :rare,
          type: :mundane | :magic,
          consumable: boolean(),
          uses: String.t() | nil,
          weapon_bonus: integer() | nil,
          damage_bonus: String.t() | nil,
          armor_bonus: integer() | nil,
          dexterity_bonus: integer() | nil,
          wearable: boolean(),
          wearable_slot: String.t() | nil,
          gold_value: integer(),
          xp_value: integer()
        }

  @doc """
  Get all available special items
  """
  def all_special_items do
    [
      %__MODULE__{
        name: "Dagger of the Silent Step",
        description:
          "This sleek dagger emits no sound when drawn or used, ideal for silent kills.",
        category: "weapons",
        rarity: :uncommon,
        type: :magic,
        consumable: false,
        uses: nil,
        weapon_bonus: 1,
        damage_bonus: "1d6",
        armor_bonus: nil,
        dexterity_bonus: 1,
        wearable: true,
        wearable_slot: "weapon",
        gold_value: 50,
        xp_value: 10
      },
      %__MODULE__{
        name: "Shadowweave Cloak",
        description: "A dark, enchanted cloak that helps the wearer blend into the shadows.",
        category: "armor",
        rarity: :uncommon,
        type: :magic,
        consumable: false,
        uses: nil,
        weapon_bonus: nil,
        damage_bonus: nil,
        armor_bonus: 2,
        dexterity_bonus: nil,
        wearable: true,
        wearable_slot: "back",
        gold_value: 90,
        xp_value: 18
      },
      %__MODULE__{
        name: "Ring of Evasion",
        description: "This ring subtly enhances the wearer's agility, aiding in avoiding danger.",
        category: "rings",
        rarity: :uncommon,
        type: :magic,
        consumable: false,
        uses: nil,
        weapon_bonus: nil,
        damage_bonus: nil,
        armor_bonus: nil,
        dexterity_bonus: 1,
        wearable: true,
        wearable_slot: "finger",
        gold_value: 70,
        xp_value: 14
      },
      %__MODULE__{
        name: "Whisperfang",
        description:
          "A finely crafted shortsword enchanted to strike swiftly and silently. Ideal for backstabs.",
        category: "weapons",
        rarity: :rare,
        type: :magic,
        consumable: false,
        uses: nil,
        weapon_bonus: 2,
        damage_bonus: "1d6",
        armor_bonus: nil,
        dexterity_bonus: nil,
        wearable: true,
        wearable_slot: "weapon",
        gold_value: 110,
        xp_value: 22
      },
      %__MODULE__{
        name: "Ring of Protection",
        description: "A silver ring inscribed with protective runes that ward off harm.",
        category: "rings",
        rarity: :rare,
        type: :magic,
        consumable: false,
        uses: nil,
        weapon_bonus: nil,
        damage_bonus: nil,
        armor_bonus: 1,
        dexterity_bonus: nil,
        wearable: true,
        wearable_slot: "finger",
        gold_value: 120,
        xp_value: 20
      },
      %__MODULE__{
        name: "Leather of the Cat",
        description:
          "This enchanted armor is silent as a shadow and allows greater freedom of movement.",
        category: "armor",
        rarity: :uncommon,
        type: :magic,
        consumable: false,
        uses: nil,
        weapon_bonus: nil,
        damage_bonus: nil,
        armor_bonus: 1,
        dexterity_bonus: nil,
        wearable: true,
        wearable_slot: "torso",
        gold_value: 70,
        xp_value: 14
      },
      %__MODULE__{
        name: "Boots of Quiet Step",
        description: "These soft-soled boots dampen all noise, aiding in stealth and escape.",
        category: "armor",
        rarity: :uncommon,
        type: :magic,
        consumable: false,
        uses: nil,
        weapon_bonus: nil,
        damage_bonus: nil,
        armor_bonus: nil,
        dexterity_bonus: 1,
        wearable: true,
        wearable_slot: "feet",
        gold_value: 60,
        xp_value: 12
      },
      %__MODULE__{
        name: "Gloves of Lock Picking",
        description:
          "Thin, nimble gloves enchanted to improve precision and tactile sensitivity.",
        category: "miscellaneous",
        rarity: :uncommon,
        type: :magic,
        consumable: false,
        uses: nil,
        weapon_bonus: nil,
        damage_bonus: nil,
        armor_bonus: nil,
        dexterity_bonus: 1,
        wearable: true,
        wearable_slot: "hands",
        gold_value: 50,
        xp_value: 10
      },
      %__MODULE__{
        name: "Gloves of Dexterity",
        description:
          "These enchanted gloves subtly boost the wearer’s agility and sleight of hand.",
        category: "armor",
        rarity: :rare,
        type: :magic,
        consumable: false,
        uses: nil,
        weapon_bonus: 1,
        damage_bonus: nil,
        armor_bonus: nil,
        dexterity_bonus: 2,
        wearable: true,
        wearable_slot: "hands",
        gold_value: 90,
        xp_value: 18
      },
      %__MODULE__{
        name: "Bag of Holding",
        description: "A magical satchel that can hold far more than its size would suggest.",
        category: "containers",
        rarity: :rare,
        type: :magic,
        consumable: false,
        uses: nil,
        weapon_bonus: nil,
        damage_bonus: nil,
        armor_bonus: nil,
        dexterity_bonus: nil,
        wearable: true,
        wearable_slot: "container",
        gold_value: 200,
        xp_value: 30
      }
    ]
  end

  @doc """
  Get special items by category
  """
  def by_category(category) do
    all_special_items()
    |> Enum.filter(&(&1.category == category))
  end

  @doc """
  Get special items by rarity
  """
  def by_rarity(rarity) do
    all_special_items()
    |> Enum.filter(&(&1.rarity == rarity))
  end

  @doc """
  Get wearable items only
  """
  def wearable_items do
    all_special_items()
    |> Enum.filter(& &1.wearable)
  end

  @doc """
  Get consumable items only
  """
  def consumable_items do
    all_special_items()
    |> Enum.filter(& &1.consumable)
  end

  @doc """
  Get a random special item by rarity
  """
  def random_by_rarity(rarity) do
    rarity
    |> by_rarity()
    |> Enum.random()
  end

  @doc """
  Get a random special item
  """
  def random do
    all_special_items()
    |> Enum.random()
  end

  @doc """
  Get a random special item using rarity-based selection (similar to monster system)
  """
  def random_by_rarity_system do
    rarity = determine_rarity()
    items_of_rarity = by_rarity(rarity)

    case items_of_rarity do
      [] ->
        # Fallback: if no items of selected rarity, pick any item
        random()

      items ->
        Enum.random(items)
    end
  end

  # Private helper function to determine rarity using same probabilities as monsters
  defp determine_rarity do
    case :rand.uniform(100) do
      # 60% common
      n when n <= 60 -> :common
      # 25% uncommon
      n when n <= 85 -> :uncommon
      # 15% rare (higher than monster elite chance since we don't have elite items)
      _ -> :rare
    end
  end
end
