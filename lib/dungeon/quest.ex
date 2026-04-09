defmodule Dungeon.Quest do
  @moduledoc """
  Quest system for special items and NPC quests
  Supports both special item quests and NPC alignment-based quests
  """

  require Logger
  alias Dungeon.{Dice, Monster, SpecialItem, Themes}

  defstruct [
    :id,
    :type,
    :description,
    :target_location,
    :target_theme,
    :magic_item,
    :reward_gold,
    :xp_reward,
    :status,
    :quest_giver,
    :quest_giver_theme,
    :quest_alignment,
    :target_monster,
    :target_npc,
    :tldr_description,
    :completion_narrative
  ]

  @type quest_type :: :special_item | :monster_kill | :npc_kill
  @type quest_status :: :active | :completed | :failed

  @type t :: %__MODULE__{
          id: String.t(),
          type: quest_type(),
          description: String.t(),
          target_location: {integer(), integer()},
          target_theme: String.t(),
          magic_item: String.t() | SpecialItem.t() | nil,
          reward_gold: integer(),
          xp_reward: integer(),
          status: quest_status(),
          quest_giver: String.t() | nil,
          quest_giver_theme: String.t() | nil,
          quest_alignment: :lawful | :chaotic | :neutral,
          target_monster: String.t() | nil,
          target_npc: String.t() | nil,
          tldr_description: String.t() | nil,
          completion_narrative: String.t() | nil
        }

  @doc """
  Create a special item quest from a rumor (updated to use actual special items)
  """
  def create_quest_from_rumor(socket, position) do
    # Get available themes, excluding current theme
    current_theme = socket.assigns.dungeon.theme
    all_themes = Themes.get_themes()
    available_themes = Enum.filter(all_themes, fn theme -> theme.name != current_theme end)

    selected_theme =
      if available_themes != [] do
        Enum.random(available_themes)
      else
        Enum.random(all_themes)
      end

    target_theme = selected_theme.name

    # Get a random actual special item instead of generating a fake name
    magic_item = SpecialItem.random_by_rarity_system()

    # Calculate XP reward based on item XP value and dungeon level
    base_xp = magic_item.xp_value || 20
    level_bonus = socket.assigns.dungeon_level * 5
    xp_reward = base_xp + level_bonus

    # Create quest ID
    quest_id = "rumor_#{:erlang.unique_integer([:positive])}"

    %__MODULE__{
      id: quest_id,
      type: :special_item,
      description: "Find the #{magic_item.name} in the #{target_theme}",
      target_location: position,
      target_theme: target_theme,
      magic_item: magic_item,
      reward_gold: magic_item.gold_value || 0,
      xp_reward: xp_reward,
      status: :active,
      quest_giver: nil,
      quest_giver_theme: nil,
      quest_alignment: :neutral,
      target_monster: nil,
      target_npc: nil,
      tldr_description: nil,
      completion_narrative: nil
    }
  end

  @doc """
  Create an NPC quest based on the NPC's alignment
  """
  def create_npc_quest(npc_monster, dungeon_level, current_theme, player_alignment) do
    quest_id = "npc_#{:erlang.unique_integer([:positive])}"
    reward_gold = calculate_quest_reward(dungeon_level)

    # Get a random theme different from the current one
    target_theme = get_random_different_theme(current_theme)

    case npc_monster.alignment do
      :lawful ->
        # Lawful NPCs give quests to lawful and neutral players (not chaotic enemies)
        case player_alignment do
          :lawful ->
            create_monster_kill_quest(
              quest_id,
              npc_monster,
              reward_gold,
              dungeon_level,
              target_theme,
              current_theme
            )

          :neutral ->
            create_monster_kill_quest(
              quest_id,
              npc_monster,
              reward_gold,
              dungeon_level,
              target_theme,
              current_theme
            )

          :chaotic ->
            # Lawful NPCs don't give quests to chaotic players (enemies)
            nil
        end

      :chaotic ->
        # Chaotic NPCs give quests to chaotic and neutral players (not lawful enemies)
        case player_alignment do
          :chaotic ->
            create_npc_kill_quest(
              quest_id,
              npc_monster,
              reward_gold,
              dungeon_level,
              target_theme,
              current_theme
            )

          :neutral ->
            create_npc_kill_quest(
              quest_id,
              npc_monster,
              reward_gold,
              dungeon_level,
              target_theme,
              current_theme
            )

          :lawful ->
            # Chaotic NPCs don't give quests to lawful players (enemies)
            nil
        end

      :neutral ->
        # Neutral NPCs give quests to all players regardless of alignment
        create_monster_kill_quest(
          quest_id,
          npc_monster,
          reward_gold,
          dungeon_level,
          target_theme,
          current_theme
        )
    end
  end

  @doc """
  Check if a quest is completed based on current game state
  """
  def check_quest_completion(quest, socket) do
    case quest.type do
      :special_item ->
        # Special item quests are completed when the item is found
        # This is handled elsewhere in the codebase
        quest

      :monster_kill ->
        check_monster_kill_completion(quest, socket)

      :npc_kill ->
        check_npc_kill_completion(quest, socket)
    end
  end

  @doc """
  Get quest target location for spawning
  """
  def get_quest_target_location(quest, socket) do
    case quest.type do
      :special_item ->
        # Special item quests use existing location system
        quest.target_location

      :monster_kill ->
        # Find a suitable location for the target monster
        find_suitable_monster_location(socket)

      :npc_kill ->
        # Find a suitable location for the target NPC
        find_suitable_npc_location(socket)
    end
  end

  @doc """
  Spawn quest target on the dungeon grid
  """
  def spawn_quest_target(socket, quest) do
    Logger.info("=== SPAWN_QUEST_TARGET DEBUG ===")
    Logger.info("Quest type: #{quest.type}")
    Logger.info("Quest ID: #{quest.id}")
    Logger.info("Quest target theme: '#{quest.target_theme}'")
    Logger.info("Current dungeon theme: '#{socket.assigns.dungeon.theme}'")
    Logger.info("Themes match?: #{socket.assigns.dungeon.theme == quest.target_theme}")

    case quest.type do
      :special_item ->
        # Special item spawning is handled elsewhere
        Logger.info("Special item quest - skipping monster spawn")
        socket

      :monster_kill ->
        # Only spawn if we're in the target theme
        if socket.assigns.dungeon.theme == quest.target_theme do
          Logger.info("Theme match confirmed - calling spawn_quest_monster")
          spawn_quest_monster(socket, quest)
        else
          Logger.info("Theme mismatch - skipping quest monster spawn")
          socket
        end

      :npc_kill ->
        # Only spawn if we're in the target theme
        if socket.assigns.dungeon.theme == quest.target_theme do
          Logger.info("Theme match confirmed - calling spawn_quest_npc")
          spawn_quest_npc(socket, quest)
        else
          Logger.info("Theme mismatch - skipping quest NPC spawn")
          socket
        end
    end
  end

  @doc """
  Get active quests from a list of quests
  """
  def get_active_quests(quests) do
    Enum.filter(quests || [], fn quest -> quest.status == :active end)
  end

  @doc """
  Check if a quest item should spawn for a given quest and theme
  """
  def should_spawn_quest_item?(quest, current_theme) do
    quest.type == :special_item and quest.target_theme == current_theme
  end

  @doc """
  Complete a quest and return the completed quest with narrative
  """
  def complete_quest(quest, current_level) do
    magic_item_name = get_magic_item_name(quest.magic_item)

    narrative =
      "Your quest for the #{magic_item_name} has been completed successfully on level #{current_level}!"

    %{quest | status: :completed, completion_narrative: narrative}
  end

  # Private functions

  defp create_monster_kill_quest(
         quest_id,
         npc_monster,
         reward_gold,
         dungeon_level,
         target_theme,
         quest_giver_theme
       ) do
    # Get a random chaotic monster appropriate for the level
    target_monster = get_random_chaotic_monster(dungeon_level)

    # Calculate XP reward (same as gold reward for monster kill quests)
    xp_reward = reward_gold

    %__MODULE__{
      id: quest_id,
      type: :monster_kill,
      description:
        "Slay the #{target_monster.name} that terrorizes the #{target_theme}. Reward: #{reward_gold} gold.",
      # Will be determined when spawning
      target_location: nil,
      target_theme: target_theme,
      magic_item: nil,
      reward_gold: reward_gold,
      xp_reward: xp_reward,
      status: :active,
      quest_giver: npc_monster.name,
      quest_giver_theme: quest_giver_theme,
      quest_alignment: :lawful,
      target_monster: target_monster.name,
      target_npc: nil,
      tldr_description: "Kill #{target_monster.name} in #{target_theme}",
      completion_narrative: nil
    }
  end

  defp create_npc_kill_quest(
         quest_id,
         npc_monster,
         reward_gold,
         _dungeon_level,
         target_theme,
         quest_giver_theme
       ) do
    # Get a random lawful NPC to target
    target_npc = get_random_lawful_npc()

    # Calculate XP reward (same as gold reward for NPC kill quests)
    xp_reward = reward_gold

    %__MODULE__{
      id: quest_id,
      type: :npc_kill,
      description:
        "Eliminate the #{target_npc.name} who opposes our cause in the #{target_theme}. Reward: #{reward_gold} gold.",
      # Will be determined when spawning
      target_location: nil,
      target_theme: target_theme,
      magic_item: nil,
      reward_gold: reward_gold,
      xp_reward: xp_reward,
      status: :active,
      quest_giver: npc_monster.name,
      quest_giver_theme: quest_giver_theme,
      quest_alignment: :chaotic,
      target_monster: nil,
      target_npc: target_npc.name,
      tldr_description: "Kill #{target_npc.name} in #{target_theme}",
      completion_narrative: nil
    }
  end

  defp calculate_quest_reward(dungeon_level) do
    # Base reward scales with dungeon level
    base_reward = 10 + dungeon_level * 5
    # Add some randomness
    base_reward + Dice.roll(1, 10)
  end

  defp get_random_chaotic_monster(dungeon_level) do
    chaotic_monsters =
      Monster.all_monsters()
      |> Enum.filter(fn monster ->
        monster.alignment == :chaotic and (monster.role == nil or monster.role == "")
      end)

    # Use challenge_rating logic: target player_level + 1, fallback by decrementing
    target_level = dungeon_level + 1

    # Try to find a chaotic monster with the target challenge_rating
    case Monster.get_monsters_by_exact_challenge_rating(target_level) do
      [] ->
        # No monsters at target level, try decrementing until we find one
        find_chaotic_monster_by_decrementing_level(chaotic_monsters, target_level - 1)

      monsters_at_level ->
        # Filter to only chaotic monsters
        chaotic_monsters_at_level =
          monsters_at_level
          |> Enum.filter(fn monster ->
            monster.alignment == :chaotic and (monster.role == nil or monster.role == "")
          end)

        case chaotic_monsters_at_level do
          [] ->
            # No chaotic monsters at this level, try decrementing
            find_chaotic_monster_by_decrementing_level(chaotic_monsters, target_level - 1)

          monsters ->
            Enum.random(monsters)
        end
    end
  end

  defp find_chaotic_monster_by_decrementing_level(chaotic_monsters, level) when level > 0 do
    case Monster.get_monsters_by_exact_challenge_rating(level) do
      [] ->
        # No monsters at this level, try next level down
        find_chaotic_monster_by_decrementing_level(chaotic_monsters, level - 1)

      monsters_at_level ->
        # Filter to only chaotic monsters
        chaotic_monsters_at_level =
          monsters_at_level
          |> Enum.filter(fn monster ->
            monster.alignment == :chaotic and (monster.role == nil or monster.role == "")
          end)

        case chaotic_monsters_at_level do
          [] ->
            # No chaotic monsters at this level, try next level down
            find_chaotic_monster_by_decrementing_level(chaotic_monsters, level - 1)

          monsters ->
            Enum.random(monsters)
        end
    end
  end

  defp find_chaotic_monster_by_decrementing_level(chaotic_monsters, _level) do
    # Fallback: if no appropriate chaotic monsters found, use any chaotic monster
    case chaotic_monsters do
      [] ->
        # Ultimate fallback - get any monster
        Monster.all_monsters() |> Enum.random()

      monsters ->
        Enum.random(monsters)
    end
  end

  defp get_random_lawful_npc do
    lawful_npcs =
      Monster.all_monsters()
      |> Enum.filter(fn monster ->
        monster.alignment == :lawful and (monster.role == "npc" or monster.role == "guard")
      end)

    lawful_aligned =
      Monster.all_monsters()
      |> Enum.filter(fn monster -> monster.alignment == :lawful end)

    cond do
      lawful_npcs != [] ->
        Enum.random(lawful_npcs)

      lawful_aligned != [] ->
        Enum.random(lawful_aligned)

      true ->
        # Ultimate fallback - get any monster
        Monster.all_monsters() |> Enum.random()
    end
  end

  defp check_monster_kill_completion(quest, socket) do
    # Check if the target monster has been killed
    # This would be tracked in the socket assigns
    killed_monsters = Map.get(socket.assigns, :killed_quest_monsters, [])

    if quest.target_monster in killed_monsters do
      %{quest | status: :completed}
    else
      quest
    end
  end

  defp check_npc_kill_completion(quest, socket) do
    # Check if the target NPC has been killed
    killed_npcs = Map.get(socket.assigns, :killed_quest_npcs, [])

    if quest.target_npc in killed_npcs do
      %{quest | status: :completed}
    else
      quest
    end
  end

  defp find_suitable_monster_location(socket) do
    # Use the same logic as regular monster placement
    dungeon = socket.assigns.dungeon

    # Get all available positions using the same logic as regular encounters
    available_positions = find_all_available_encounter_positions(dungeon)

    Logger.info(
      "Found #{length(available_positions)} available positions for quest monster spawning"
    )

    if available_positions != [] do
      selected_location = Enum.random(available_positions)
      Logger.info("Selected position for quest monster: #{inspect(selected_location)}")
      selected_location
    else
      # Fallback: try to find ANY floor tile not occupied by player
      fallback_positions =
        dungeon.grid
        |> Enum.filter(fn {{x, y}, tile} ->
          tile == :floor and {x, y} != socket.assigns.player_position
        end)
        |> Enum.map(fn {{x, y}, _tile} -> {x, y} end)

      if fallback_positions != [] do
        fallback_location = Enum.random(fallback_positions)
        Logger.info("Using fallback floor tile for quest monster: #{inspect(fallback_location)}")
        fallback_location
      else
        # Last resort fallback
        fallback_location = {Dice.roll(5, 15), Dice.roll(5, 15)}

        Logger.warning(
          "No available positions, using random fallback: #{inspect(fallback_location)}"
        )

        fallback_location
      end
    end
  end

  # Find all available positions for encounters using the same logic as regular monster placement
  defp find_all_available_encounter_positions(dungeon) do
    # Check what type of map structure we have
    rooms = Map.get(dungeon, :rooms, [])
    areas = Map.get(dungeon, :areas, [])
    caverns = Map.get(dungeon, :caverns, [])

    # Find available positions based on the actual structure type
    structure_positions =
      cond do
        rooms != [] ->
          # Check if rooms are actually traditional rooms or areas/caverns
          first_room = List.first(rooms)

          if traditional_room?(first_room) do
            # Traditional dungeon with rooms
            Logger.info("Processing traditional rooms: #{length(rooms)}")

            Enum.flat_map(rooms, fn room ->
              find_available_positions_in_room(dungeon.grid, room)
            end)
          else
            # Rooms list contains areas/caverns
            Logger.info("Processing rooms as areas: #{length(rooms)}")

            Enum.flat_map(rooms, fn area ->
              find_available_positions_in_area(dungeon.grid, area)
            end)
          end

        areas != [] ->
          # Outdoor areas
          Logger.info("Processing areas: #{length(areas)}")

          Enum.flat_map(areas, fn area ->
            find_available_positions_in_area(dungeon.grid, area)
          end)

        caverns != [] ->
          # Cavern system
          Logger.info("Processing caverns: #{length(caverns)}")

          Enum.flat_map(caverns, fn cavern ->
            find_available_positions_in_area(dungeon.grid, cavern)
          end)

        true ->
          # No structured areas, use any floor tile
          Logger.info("No structured areas found")
          []
      end

    # Find available corridor positions (if applicable)
    corridor_positions = find_available_corridor_positions(dungeon.grid, rooms)

    # Combine all available positions, prioritizing structure positions
    all_positions = structure_positions ++ corridor_positions

    Logger.info(
      "Structure positions: #{length(structure_positions)}, Corridor positions: #{length(corridor_positions)}"
    )

    all_positions
  end

  # Check if a structure is a traditional room (has x, y, width, height)
  defp traditional_room?(room) do
    Map.has_key?(room, :x) and Map.has_key?(room, :y) and
      Map.has_key?(room, :width) and Map.has_key?(room, :height)
  end

  # Find available positions in a traditional room (same logic as regular encounter placement)
  defp find_available_positions_in_room(grid, room) do
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
    Enum.filter(potential_positions, fn {x, y} ->
      abs(x - center_x) > 1 or abs(y - center_y) > 1
    end)
  end

  # Find available positions in an area/cavern (uses cells list)
  defp find_available_positions_in_area(grid, area) do
    # Find available floor positions from the area's cells
    potential_positions =
      Enum.filter(area.cells, fn {x, y} ->
        Map.get(grid, {x, y}) == :floor
      end)

    # For areas with cells, avoid positions too close to the center
    if potential_positions != [] do
      # Calculate rough center of the area
      {center_x, center_y} = calculate_area_center(area.cells)

      # Filter out positions too close to center (to avoid area label conflicts)
      preferred_positions =
        Enum.filter(potential_positions, fn {x, y} ->
          abs(x - center_x) > 1 or abs(y - center_y) > 1
        end)

      # Return preferred positions, or all positions if no preferred ones
      if preferred_positions != [], do: preferred_positions, else: potential_positions
    else
      []
    end
  end

  # Calculate the center of an area from its cells
  defp calculate_area_center(cells) do
    if cells == [] do
      {0, 0}
    else
      {sum_x, sum_y} =
        Enum.reduce(cells, {0, 0}, fn {x, y}, {acc_x, acc_y} ->
          {acc_x + x, acc_y + y}
        end)

      count = length(cells)
      {div(sum_x, count), div(sum_y, count)}
    end
  end

  # Find available corridor positions (same logic as regular encounter placement)
  defp find_available_corridor_positions(grid, rooms) do
    grid
    |> Enum.filter(fn {{x, y}, tile} ->
      tile == :corridor and not point_in_any_room?({x, y}, rooms)
    end)
    |> Enum.map(fn {{x, y}, _tile} -> {x, y} end)
  end

  # Check if a point is in any room (only works for traditional rooms)
  defp point_in_any_room?({x, y}, rooms) do
    Enum.any?(rooms, fn room ->
      # Check if this is a traditional room with x, y, width, height
      if Map.has_key?(room, :x) and Map.has_key?(room, :y) and
           Map.has_key?(room, :width) and Map.has_key?(room, :height) do
        x >= room.x and x < room.x + room.width and
          y >= room.y and y < room.y + room.height
      else
        false
      end
    end)
  end

  defp find_suitable_npc_location(socket) do
    # Use the same logic as quest monsters
    find_suitable_monster_location(socket)
  end

  defp spawn_quest_monster(socket, quest) do
    Logger.info("=== QUEST MONSTER SPAWNING DEBUG ===")
    Logger.info("Attempting to spawn quest monster for quest: #{quest.id}")
    Logger.info("Quest target monster: #{quest.target_monster}")
    Logger.info("Quest target theme: #{quest.target_theme}")
    Logger.info("Current theme: #{socket.assigns.dungeon.theme}")

    location = get_quest_target_location(quest, socket)
    Logger.info("Selected spawn location: #{inspect(location)}")

    monster = Monster.get_monster_by_name(quest.target_monster)
    Logger.info("Monster found: #{if monster, do: "YES - #{monster.name}", else: "NO"}")

    if is_map(monster) and not is_nil(location) do
      # Add quest glow effect to the monster - quest monsters can spawn in any theme
      quest_monster = %{monster | role: "quest_monster"}

      # Check what's currently at the location
      current_tile = Map.get(socket.assigns.dungeon.grid, location)
      Logger.info("Current tile at location #{inspect(location)}: #{inspect(current_tile)}")

      # Update the dungeon grid - override any existing tile at this location
      updated_grid =
        Map.put(
          socket.assigns.dungeon.grid,
          location,
          {:encounter, "Quest Target", quest_monster}
        )

      updated_dungeon = Map.put(socket.assigns.dungeon, :grid, updated_grid)

      # Verify the monster was actually placed
      new_tile = Map.get(updated_grid, location)
      Logger.info("New tile at location #{inspect(location)}: #{inspect(new_tile)}")

      # Track active quest monsters
      active_quest_monsters = Map.get(socket.assigns, :active_quest_monsters, [])
      updated_quest_monsters = [{quest.id, location, quest_monster} | active_quest_monsters]

      Logger.info(
        "✅ Quest monster successfully spawned: #{quest_monster.name} at #{inspect(location)} for quest #{quest.id}"
      )

      Logger.info("Active quest monsters count: #{length(updated_quest_monsters)}")

      socket
      |> Phoenix.Component.assign(:dungeon, updated_dungeon)
      |> Phoenix.Component.assign(:active_quest_monsters, updated_quest_monsters)
    else
      Logger.warning(
        "❌ Failed to spawn quest monster: #{inspect(quest.target_monster)} at #{inspect(location)}"
      )

      Logger.warning("Monster map: #{inspect(monster)}")
      Logger.warning("Location nil?: #{is_nil(location)}")

      socket
    end
  end

  defp spawn_quest_npc(socket, quest) do
    Logger.info("=== QUEST NPC SPAWNING DEBUG ===")
    Logger.info("Attempting to spawn quest NPC for quest: #{quest.id}")
    Logger.info("Quest target NPC: #{quest.target_npc}")

    location = get_quest_target_location(quest, socket)
    Logger.info("Selected spawn location: #{inspect(location)}")

    npc = Monster.get_monster_by_name(quest.target_npc)

    Logger.info(
      "Original NPC found: #{if npc, do: "YES - #{npc.name} (role: #{npc.role})", else: "NO"}"
    )

    if is_map(npc) and not is_nil(location) do
      # Add quest glow effect to the NPC - quest NPCs can spawn in any theme
      quest_npc = %{npc | role: "quest_npc"}
      Logger.info("Quest NPC after role change: #{quest_npc.name} (role: #{quest_npc.role})")

      # Update the dungeon grid - override any existing tile at this location
      updated_grid =
        Map.put(
          socket.assigns.dungeon.grid,
          location,
          {:encounter, "Quest Target", quest_npc}
        )

      updated_dungeon = Map.put(socket.assigns.dungeon, :grid, updated_grid)

      # Verify the NPC was actually placed with correct role
      new_tile = Map.get(updated_grid, location)

      case new_tile do
        {:encounter, _label, monster} ->
          Logger.info("✅ Quest NPC placed in grid: #{monster.name} (role: #{monster.role})")

        _ ->
          Logger.warning("❌ Unexpected tile type in grid: #{inspect(new_tile)}")
      end

      # Track active quest NPCs
      active_quest_npcs = Map.get(socket.assigns, :active_quest_npcs, [])
      updated_quest_npcs = [{quest.id, location, quest_npc} | active_quest_npcs]

      Logger.info(
        "Quest NPC spawned: #{quest_npc.name} at #{inspect(location)} for quest #{quest.id}"
      )

      socket
      |> Phoenix.Component.assign(:dungeon, updated_dungeon)
      |> Phoenix.Component.assign(:active_quest_npcs, updated_quest_npcs)
    else
      Logger.warning(
        "Failed to spawn quest NPC: #{inspect(quest.target_npc)} at #{inspect(location)}"
      )

      socket
    end
  end

  defp get_random_different_theme(current_theme) do
    # Get all themes and filter out the current one by name
    all_themes = Themes.get_themes()
    available_themes = Enum.filter(all_themes, fn theme -> theme.name != current_theme end)

    selected_theme =
      if available_themes != [] do
        Enum.random(available_themes)
      else
        # Fallback to any theme if somehow no others are available
        Enum.random(all_themes)
      end

    # Return just the theme name, not the full theme map
    selected_theme.name
  end

  # Helper function to extract magic item name from either string or SpecialItem struct
  defp get_magic_item_name(magic_item) do
    case magic_item do
      %SpecialItem{name: name} -> name
      %{name: name} -> name
      name when is_binary(name) -> name
      _ -> "Unknown Item"
    end
  end
end
