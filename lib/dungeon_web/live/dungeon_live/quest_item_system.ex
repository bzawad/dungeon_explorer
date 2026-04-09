defmodule DungeonWeb.DungeonLive.QuestItemSystem do
  @moduledoc """
  Quest item system for spawning quest items on maps with matching themes
  and handling quest completion when items are found.
  """

  require Logger

  @doc """
  Spawn quest items on the dungeon grid for active quests that match the current theme
  """
  def spawn_quest_items(socket, dungeon) do
    current_theme = dungeon.theme
    active_quests = Dungeon.Quest.get_active_quests(socket.assigns.quests)

    Logger.info("Quest item spawning: Current theme = #{current_theme}")
    Logger.info("Quest item spawning: Found #{length(active_quests)} active quests")

    # Find quests that should spawn items on this theme
    matching_quests =
      Enum.filter(active_quests, fn quest ->
        Dungeon.Quest.should_spawn_quest_item?(quest, current_theme)
      end)

    Logger.info(
      "Quest item spawning: Found #{length(matching_quests)} matching quests for #{current_theme}"
    )

    if matching_quests != [] do
      matching_quest_details =
        Enum.map(matching_quests, fn quest ->
          magic_item_name = get_magic_item_name(quest.magic_item)
          "#{magic_item_name} (target: #{quest.target_theme})"
        end)

      Logger.info("Quest item spawning: Matching quests = #{inspect(matching_quest_details)}")
    end

    # Spawn one quest item per matching quest with high priority placement
    {updated_grid, spawned_count} =
      Enum.reduce(matching_quests, {dungeon.grid, 0}, fn quest, {grid, count} ->
        case find_quest_item_spawn_position(grid, dungeon, count) do
          {:ok, position} ->
            quest_item = %{
              type: :quest_item,
              quest_id: quest.id,
              magic_item: quest.magic_item
            }

            magic_item_name = get_magic_item_name(quest.magic_item)

            Logger.info(
              "Quest item spawning: Successfully spawned #{magic_item_name} at #{inspect(position)}"
            )

            {Map.put(grid, position, {:quest_item, quest_item}), count + 1}

          :error ->
            # Couldn't find suitable position, skip this quest item
            magic_item_name = get_magic_item_name(quest.magic_item)

            Logger.warning(
              "Quest item spawning: Could not find suitable position for #{magic_item_name}"
            )

            {grid, count}
        end
      end)

    Logger.info(
      "Quest item spawning: Successfully spawned #{spawned_count} out of #{length(matching_quests)} quest items"
    )

    Map.put(dungeon, :grid, updated_grid)
  end

  @doc """
  Check if a position contains a quest item and process quest completion if found
  """
  def process_quest_item_discovery(socket, position) do
    dungeon = socket.assigns.dungeon

    case Map.get(dungeon.grid, position) do
      {:quest_item, quest_item_data} ->
        handle_quest_item_found(socket, position, quest_item_data)

      _ ->
        {false, socket}
    end
  end

  # Extract quest completion logic to reduce nesting
  defp handle_quest_item_found(socket, position, quest_item_data) do
    %{quest_id: quest_id, magic_item: magic_item} = quest_item_data
    quest = find_active_quest(socket.assigns.quests, quest_id)

    case quest do
      nil -> {false, socket}
      quest -> complete_quest_discovery(socket, position, quest, magic_item)
    end
  end

  defp find_active_quest(quests, quest_id) do
    Enum.find(quests, fn q -> q.id == quest_id && q.status == :active end)
  end

  defp complete_quest_discovery(socket, position, quest, magic_item) do
    current_level = socket.assigns.dungeon_level
    completed_quest = Dungeon.Quest.complete_quest(quest, current_level)
    xp_reward = completed_quest.xp_reward

    updated_quests = update_quest_in_list(socket.assigns.quests, completed_quest)
    completion_narrative = generate_completion_narrative(magic_item, quest.target_theme)
    item_data = create_quest_item_data(magic_item, completion_narrative)
    special_items = socket.assigns.special_items ++ [item_data]

    socket =
      socket
      |> assign(:quests, updated_quests)
      |> assign(:completed_quest, completed_quest)
      |> assign(:quest_completion_xp, xp_reward)
      |> assign(:show_quest_completed_dialog, true)
      |> assign(:completed_quest_item_position, position)
      |> assign(:special_items, special_items)
      |> award_xp_with_level_check(xp_reward)
      |> Phoenix.LiveView.push_event("play_audio", %{sound: "orch_hit"})
      |> recalculate_stats_after_item_added()

    {true, socket}
  end

  defp update_quest_in_list(quests, completed_quest) do
    Enum.map(quests, fn q ->
      if q.id == completed_quest.id, do: completed_quest, else: q
    end)
  end

  defp generate_completion_narrative(magic_item, target_theme) do
    magic_item_name = get_magic_item_name(magic_item)
    magic_item_category = get_magic_item_category(magic_item)

    "You have found the legendary #{magic_item_name}! Your quest is complete. This #{magic_item_category} was said to be lost in the #{target_theme}, and here it was, waiting for a worthy adventurer like yourself."
  end

  defp create_quest_item_data(magic_item, completion_narrative) do
    magic_item_name = get_magic_item_name(magic_item)
    magic_item_description = get_magic_item_description(magic_item)

    %{
      item: magic_item,
      item_name: magic_item_name,
      description: "#{magic_item_description}\n\nQuest History: #{completion_narrative}"
    }
  end

  @doc """
  Generate magical glow effect positions around quest items
  """
  def get_quest_item_glow_positions(dungeon) do
    Enum.reduce(dungeon.grid, [], fn {position, tile}, acc ->
      case tile do
        {:quest_item, _} ->
          glow_positions = generate_glow_positions(position)
          [%{position: position, glow_positions: glow_positions} | acc]

        _ ->
          acc
      end
    end)
  end

  # Private helper functions

  defp find_quest_item_spawn_position(grid, dungeon, attempt) do
    # High priority placement - prefer rooms, then corridors, avoid walls/doors
    suitable_positions =
      Enum.filter(grid, fn {position, tile} ->
        suitable_for_quest_item?(tile, position, grid, dungeon)
      end)
      |> Enum.map(fn {position, _} -> position end)

    # Add some randomization but prefer central positions
    sorted_positions =
      suitable_positions
      |> Enum.sort_by(fn {x, y} ->
        # Prefer positions closer to center with some randomness
        center_x = div(dungeon.width, 2)
        center_y = div(dungeon.height, 2)
        distance = abs(x - center_x) + abs(y - center_y)
        # Spread out multiple items
        distance + :rand.uniform(10) + attempt * 5
      end)

    case sorted_positions do
      [position | _] -> {:ok, position}
      [] -> :error
    end
  end

  defp suitable_for_quest_item?(tile, position, grid, dungeon) do
    cond do
      perfect_location?(tile, position, grid, dungeon) -> true
      blocked_tile?(tile) -> false
      existing_feature_or_item?(tile) -> false
      # Allow other floor types
      true -> true
    end
  end

  defp perfect_location?(tile, position, grid, dungeon) do
    tile == :room_floor or (tile == :floor and in_room_or_corridor?(position, grid, dungeon))
  end

  defp blocked_tile?(tile) do
    tile in [
      :wall,
      :door,
      :locked_door,
      :trapped_door,
      :locked_trapped_door,
      :stair_up,
      :stair_down
    ]
  end

  defp existing_feature_or_item?(tile) do
    match?({:encounter, _}, tile) or
      match?({:special_feature, _}, tile) or
      match?({:treasure, _}, tile) or
      match?({:quest_item, _}, tile) or
      match?({:map_link, _}, tile) or
      match?({:waypoint, _}, tile)
  end

  defp in_room_or_corridor?({x, y}, grid, _dungeon) do
    # Check if position is in a reasonable open area
    surrounding_floors =
      for dx <- -1..1, dy <- -1..1, {dx, dy} != {0, 0} do
        pos = {x + dx, y + dy}

        case Map.get(grid, pos, :wall) do
          :floor -> true
          :room_floor -> true
          _ -> false
        end
      end
      |> Enum.count(& &1)

    # Prefer positions with several open adjacent squares
    surrounding_floors >= 2
  end

  defp generate_glow_positions({x, y}) do
    # Generate positions in a radius around the quest item for magical glow effect
    # Create a shifting pink/blue gradient pattern
    for radius <- 1..3,
        dx <- -radius..radius,
        dy <- -radius..radius,
        abs(dx) + abs(dy) <= radius + 1 do
      %{
        x: x + dx,
        y: y + dy,
        intensity: max(0, 1.0 - (abs(dx) + abs(dy)) / 4.0),
        # For shifting colors
        color_shift: :rand.uniform()
      }
    end
  end

  # Helper function for socket assignment
  defp assign(socket, key, value) do
    Phoenix.Component.assign(socket, key, value)
  end

  # Helper function to award XP and check for level ups
  defp award_xp_with_level_check(socket, amount) do
    current_xp = socket.assigns.player_xp
    new_xp = current_xp + amount

    socket = assign(socket, :player_xp, new_xp)

    # Check for level up and send message to main live view for handling
    if Dungeon.PlayerStats.leveled_up?(current_xp, new_xp) do
      send(self(), {:level_up_occurred, current_xp, new_xp})
    end

    socket
  end

  # Helper function to recalculate stats after adding items
  defp recalculate_stats_after_item_added(socket) do
    talent_bonuses =
      Map.get(socket.assigns, :talent_bonuses, Dungeon.PlayerStats.default_talents())

    special_items = Map.get(socket.assigns, :special_items, [])
    level_hit_points = Map.get(socket.assigns, :level_hit_points, 0)

    total_stats =
      Dungeon.PlayerStats.calculate_total_stats(special_items, talent_bonuses, level_hit_points)

    socket
    |> assign(:max_hit_points, total_stats.max_hit_points)
    |> assign(:attack_bonus, total_stats.attack_bonus)
    |> assign(:dexterity_bonus, total_stats.dexterity_bonus)
    |> assign(
      :armor_class,
      Dungeon.PlayerStats.calculate_total_armor_class(
        special_items,
        talent_bonuses,
        level_hit_points
      )
    )
    |> assign(:player_weapon, total_stats.weapon)
    |> assign(:weapon_damage_dice, total_stats.weapon_damage_dice)
  end

  # Helper function to extract magic item name from either string or object format
  defp get_magic_item_name(magic_item) do
    case magic_item do
      %{name: name} -> name
      name when is_binary(name) -> name
      _ -> "Unknown Item"
    end
  end

  # Helper function to extract magic item category from either string or object format
  defp get_magic_item_category(magic_item) do
    case magic_item do
      %{category: category} -> category
      _string_or_other -> "artifact"
    end
  end

  # Helper function to extract magic item description from either string or object format
  defp get_magic_item_description(magic_item) do
    case magic_item do
      %{description: description} -> description
      name when is_binary(name) -> "A legendary #{name} of great power."
      _ -> "A mysterious magical item."
    end
  end
end
