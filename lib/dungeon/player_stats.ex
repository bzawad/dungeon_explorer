defmodule Dungeon.PlayerStats do
  @moduledoc """
  Constants for player stats - centralized to avoid hard-coding values in multiple places
  Includes player advancement system with levels and talents
  Includes special item inventory system with wearable slots and auto-equipment
  """

  # Base player stats (before any bonuses)
  @base_player_hit_points 4
  @base_max_hit_points 4
  @hit_points_die "d4"
  @base_player_weapon "Dagger"
  @base_weapon_damage_dice "1d4"
  @base_attack_bonus 1
  @base_dexterity_bonus 1
  @base_armor_bonus 1
  @base_armor_class 10
  @torch_burn_time 100
  @player_gold 0

  # Player advancement
  @starting_level 1
  @xp_per_level_multiplier 500

  # Player alignment system
  # Neutral (0), Lawful (positive), Chaotic (negative)
  @starting_alignment 0
  # How much alignment shifts per gold received from quests
  @alignment_shift_per_gold 1

  # Wearable slots for special items
  @wearable_slots [
    "weapon",
    "head",
    "neck",
    "torso",
    "back",
    "belt",
    "wrists",
    "hands",
    "finger",
    "legs",
    "feet",
    "container"
  ]

  @doc "Initial player hit points (base value)"
  def player_hit_points, do: @base_player_hit_points

  @doc "Base maximum player hit points (before bonuses)"
  def base_max_hit_points, do: @base_max_hit_points

  @doc "Calculate total maximum hit points including bonuses"
  def max_hit_points(bonus_hit_points \\ 0) do
    @base_max_hit_points + bonus_hit_points
  end

  @doc "Calculate total maximum hit points including bonuses and level-based hit points"
  def max_hit_points_with_levels(bonus_hit_points \\ 0, level_hit_points \\ 0) do
    @base_max_hit_points + bonus_hit_points + level_hit_points
  end

  @doc "Roll hit points for a new level using the hit points die"
  def roll_hit_points_for_level do
    # Parse the hit points die string (e.g., "d4" -> 4)
    die_size = String.replace(@hit_points_die, "d", "") |> String.to_integer()
    Enum.random(1..die_size)
  end

  @doc "Base player weapon (before equipment)"
  def base_player_weapon, do: @base_player_weapon

  @doc "Base weapon damage dice (before equipment)"
  def base_weapon_damage_dice, do: @base_weapon_damage_dice

  @doc "Base player attack bonus (before bonuses)"
  def base_attack_bonus, do: @base_attack_bonus

  @doc "Calculate total attack bonus including bonuses"
  def attack_bonus(bonus_attack \\ 0) do
    @base_attack_bonus + bonus_attack
  end

  @doc "Base player dexterity bonus (before bonuses)"
  def base_dexterity_bonus, do: @base_dexterity_bonus

  @doc "Calculate total dexterity bonus including bonuses"
  def dexterity_bonus(bonus_dexterity \\ 0) do
    @base_dexterity_bonus + bonus_dexterity
  end

  @doc "Base player armor bonus (before equipment)"
  def base_armor_bonus, do: @base_armor_bonus

  @doc "Calculate total armor class including bonuses"
  def armor_class(bonus_dexterity \\ 0) do
    @base_armor_class + @base_armor_bonus + dexterity_bonus(bonus_dexterity)
  end

  @doc "Initial torch burn time"
  def torch_burn_time, do: @torch_burn_time

  @doc "Initial player gold"
  def player_gold, do: @player_gold

  @doc "Starting player level"
  def starting_level, do: @starting_level

  @doc "Starting player alignment (neutral)"
  def starting_alignment, do: @starting_alignment

  @doc "Get all wearable slots"
  def wearable_slots, do: @wearable_slots

  @doc "Calculate XP required to reach a specific level"
  def xp_required_for_level(level) do
    if level <= 1 do
      0
    else
      # Sum of XP requirements: 500 + 1000 + 1500 + ... + (level-1)*500
      Enum.map(1..(level - 1), fn l -> l * @xp_per_level_multiplier end)
      |> Enum.sum()
    end
  end

  @doc "Calculate current level based on XP"
  def calculate_level(xp) do
    # Start from level 1 and find the highest level the player has reached
    Stream.iterate(1, &(&1 + 1))
    |> Enum.find(fn level ->
      xp < xp_required_for_level(level + 1)
    end)
  end

  @doc "Calculate XP needed for next level"
  def xp_needed_for_next_level(current_xp) do
    current_level = calculate_level(current_xp)
    next_level_xp = xp_required_for_level(current_level + 1)
    next_level_xp - current_xp
  end

  @doc "Check if player has leveled up"
  def leveled_up?(old_xp, new_xp) do
    calculate_level(old_xp) < calculate_level(new_xp)
  end

  @doc "Generate a random talent bonus"
  def generate_random_talent do
    case Enum.random(1..3) do
      1 ->
        # 1d4
        hit_point_bonus = Enum.random(1..4)
        {:hit_points, hit_point_bonus, "You gained +#{hit_point_bonus} to Maximum Hit Points!"}

      2 ->
        {:attack, 1, "You gained +1 to Attack Bonus!"}

      3 ->
        {:dexterity, 1, "You gained +1 to Dexterity Bonus!"}
    end
  end

  @doc "Apply talent bonus to existing bonuses"
  def apply_talent_bonus(talents, new_talent) do
    case new_talent do
      {:hit_points, bonus, _message} ->
        Map.update(talents, :hit_points, bonus, &(&1 + bonus))

      {:attack, bonus, _message} ->
        Map.update(talents, :attack, bonus, &(&1 + bonus))

      {:dexterity, bonus, _message} ->
        Map.update(talents, :dexterity, bonus, &(&1 + bonus))
    end
  end

  @doc "Get default talent bonuses"
  def default_talents do
    %{
      hit_points: 0,
      attack: 0,
      dexterity: 0
    }
  end

  # Special Item Inventory System

  @doc """
  Parse special items from socket assigns format into structured format
  """
  def parse_special_items(socket_special_items) do
    Enum.map(socket_special_items || [], fn item ->
      case item do
        %{item: special_item, item_name: name, description: desc} ->
          %{
            item_data: special_item,
            name: name,
            description: desc,
            wearable: Map.get(special_item, :wearable, false),
            wearable_slot: Map.get(special_item, :wearable_slot),
            xp_value: Map.get(special_item, :xp_value, 0),
            weapon_bonus: Map.get(special_item, :weapon_bonus, 0),
            damage_bonus: Map.get(special_item, :damage_bonus),
            armor_bonus: Map.get(special_item, :armor_bonus, 0),
            dexterity_bonus: Map.get(special_item, :dexterity_bonus, 0)
          }

        description when is_binary(description) ->
          %{
            item_data: nil,
            name: "Unknown Item",
            description: description,
            wearable: false,
            wearable_slot: nil,
            xp_value: 0,
            weapon_bonus: 0,
            damage_bonus: nil,
            armor_bonus: 0,
            dexterity_bonus: 0
          }

        _ ->
          %{
            item_data: nil,
            name: "Unknown Item",
            description: "Unknown item",
            wearable: false,
            wearable_slot: nil,
            xp_value: 0,
            weapon_bonus: 0,
            damage_bonus: nil,
            armor_bonus: 0,
            dexterity_bonus: 0
          }
      end
    end)
  end

  @doc """
  Get equipped items by automatically selecting highest XP value item per slot
  """
  def get_equipped_items(socket_special_items) do
    parsed_items = parse_special_items(socket_special_items)
    wearable_items = Enum.filter(parsed_items, & &1.wearable)

    # Group by slot and select highest XP value item per slot
    Enum.reduce(@wearable_slots, %{}, fn slot, acc ->
      items_for_slot = Enum.filter(wearable_items, &(&1.wearable_slot == slot))

      case items_for_slot do
        [] ->
          acc

        items ->
          best_item = Enum.max_by(items, & &1.xp_value)
          Map.put(acc, slot, best_item)
      end
    end)
  end

  @doc """
  Get inventory status for items (Worn or Stored)
  """
  def get_inventory_status(socket_special_items) do
    parsed_items = parse_special_items(socket_special_items)
    equipped_items = get_equipped_items(socket_special_items)

    Enum.map(parsed_items, fn item ->
      status = inventory_item_status(item, equipped_items)
      Map.put(item, :status, status)
    end)
  end

  defp inventory_item_status(item, equipped_items) do
    if item.wearable and item.wearable_slot do
      equipped_item = Map.get(equipped_items, item.wearable_slot)
      if equipped_item && equipped_item.name == item.name, do: "Worn", else: "Stored"
    else
      "Stored"
    end
  end

  @doc """
  Calculate total stats with equipped item bonuses
  """
  def calculate_total_stats(socket_special_items, talent_bonuses, level_hit_points \\ 0) do
    equipped_items = get_equipped_items(socket_special_items)

    # Calculate base stats with talents and level-based hit points
    base_stats = %{
      max_hit_points: max_hit_points_with_levels(talent_bonuses.hit_points, level_hit_points),
      attack_bonus: attack_bonus(talent_bonuses.attack),
      dexterity_bonus: dexterity_bonus(talent_bonuses.dexterity),
      armor_bonus: @base_armor_bonus,
      weapon: @base_player_weapon,
      weapon_damage_dice: @base_weapon_damage_dice
    }

    # Apply equipment bonuses
    Enum.reduce(equipped_items, base_stats, fn {_slot, item}, stats ->
      stats
      |> Map.update!(:max_hit_points, &(&1 + (item.armor_bonus || 0)))
      |> Map.update!(:attack_bonus, &(&1 + (item.weapon_bonus || 0)))
      |> Map.update!(:dexterity_bonus, &(&1 + (item.dexterity_bonus || 0)))
      |> Map.update!(:armor_bonus, &(&1 + (item.armor_bonus || 0)))
      |> update_weapon_if_equipped(item)
    end)
  end

  defp update_weapon_if_equipped(stats, item) do
    if item.wearable_slot == "weapon" and item.damage_bonus do
      stats
      |> Map.put(:weapon, item.name)
      |> Map.put(:weapon_damage_dice, item.damage_bonus)
    else
      stats
    end
  end

  @doc """
  Calculate total armor class with all bonuses
  """
  def calculate_total_armor_class(socket_special_items, talent_bonuses, level_hit_points \\ 0) do
    total_stats = calculate_total_stats(socket_special_items, talent_bonuses, level_hit_points)
    @base_armor_class + total_stats.armor_bonus + total_stats.dexterity_bonus
  end

  # Legacy compatibility functions (keeping old function names for backwards compatibility)

  @doc "Player weapon (with equipment bonuses)"
  def player_weapon(
        socket_special_items \\ [],
        talent_bonuses \\ default_talents(),
        level_hit_points \\ 0
      ) do
    total_stats = calculate_total_stats(socket_special_items, talent_bonuses, level_hit_points)
    total_stats.weapon
  end

  @doc "Weapon damage dice (with equipment bonuses)"
  def weapon_damage_dice(
        socket_special_items \\ [],
        talent_bonuses \\ default_talents(),
        level_hit_points \\ 0
      ) do
    total_stats = calculate_total_stats(socket_special_items, talent_bonuses, level_hit_points)
    total_stats.weapon_damage_dice
  end

  @doc "Armor bonus (with equipment bonuses)"
  def armor_bonus(
        socket_special_items \\ [],
        talent_bonuses \\ default_talents(),
        level_hit_points \\ 0
      ) do
    total_stats = calculate_total_stats(socket_special_items, talent_bonuses, level_hit_points)
    total_stats.armor_bonus
  end

  @doc "Calculate alignment shift based on quest completion"
  def calculate_alignment_shift(quest_alignment, gold_amount) do
    case quest_alignment do
      :lawful -> gold_amount * @alignment_shift_per_gold
      :chaotic -> -gold_amount * @alignment_shift_per_gold
      :neutral -> 0
    end
  end

  @doc "Get alignment description from numeric value"
  def get_alignment_description(alignment_value) do
    cond do
      alignment_value > 0 -> :lawful
      alignment_value < 0 -> :chaotic
      true -> :neutral
    end
  end

  @doc "Get alignment color for UI display"
  def get_alignment_color(alignment_value) do
    cond do
      # Lawful is blue
      alignment_value > 0 -> "text-blue-400"
      # Chaotic is red
      alignment_value < 0 -> "text-red-400"
      # Neutral is gray
      true -> "text-gray-400"
    end
  end

  @doc "Get alignment gradient CSS class based on alignment value"
  def get_alignment_gradient_class(alignment_value) do
    # Normalize alignment to a percentage (assuming max alignment is around ±100)
    normalized = max(-100, min(100, alignment_value))

    cond do
      # Very Lawful
      normalized > 50 -> "bg-gradient-to-r from-blue-300 to-blue-600"
      # Lawful
      normalized > 20 -> "bg-gradient-to-r from-blue-200 to-blue-400"
      # Slightly Lawful
      normalized > 0 -> "bg-gradient-to-r from-gray-300 to-blue-200"
      # Very Chaotic
      normalized < -50 -> "bg-gradient-to-r from-red-600 to-red-300"
      # Chaotic
      normalized < -20 -> "bg-gradient-to-r from-red-400 to-red-200"
      # Slightly Chaotic
      normalized < 0 -> "bg-gradient-to-r from-red-200 to-gray-300"
      # Neutral
      true -> "bg-gray-300"
    end
  end
end
