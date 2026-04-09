defmodule DungeonWeb.DungeonLive.MonsterTurnSystem do
  @moduledoc """
  Monster turn system for AI movement and combat initiation.

  After each player action, monsters in the viewport attempt to move toward the player.
  If a monster can path to an adjacent space to the player within 4 squares, it moves
  adjacent and triggers combat. If it cannot reach the player, it does not move.
  """

  alias Dungeon.Dice
  require Logger

  @max_monster_move_distance 4

  @doc """
  Process monster turns after a player action.

  Gets all monsters in the viewport, checks if they can path to the player within 4 squares,
  and moves them adjacent to the player if possible, triggering combat.
  """
  def process_monster_turns(socket) do
    # Skip monster turns if player is dead or in combat
    if socket.assigns.player_dead or socket.assigns.show_combat_dialog do
      socket
    else
      monsters_in_viewport = get_monsters_in_viewport(socket)

      Logger.info("=== MONSTER TURN SYSTEM ===")
      Logger.info("Found #{length(monsters_in_viewport)} monsters in viewport")

      # Process each monster's turn
      Enum.reduce(monsters_in_viewport, socket, fn monster_data, acc_socket ->
        process_single_monster_turn(acc_socket, monster_data)
      end)
    end
  end

  # Private functions

  defp get_monsters_in_viewport(socket) do
    dungeon = socket.assigns.dungeon
    viewport_x = socket.assigns.viewport_x
    viewport_y = socket.assigns.viewport_y
    viewport_width = socket.assigns.viewport_width
    viewport_height = socket.assigns.viewport_height

    # Get all positions in the viewport
    viewport_positions =
      for x <- viewport_x..(viewport_x + viewport_width - 1),
          y <- viewport_y..(viewport_y + viewport_height - 1),
          x >= 0 and x < dungeon.width and y >= 0 and y < dungeon.height,
          do: {x, y}

    # Find monsters at these positions
    Enum.filter(viewport_positions, fn {x, y} ->
      case Map.get(dungeon.grid, {x, y}) do
        {:encounter, _, monster} ->
          hostile_monster?(
            monster,
            socket.assigns.guards_hostile,
            socket.assigns.player_alignment
          )

        {:monster, _} ->
          true

        _ ->
          false
      end
    end)
    |> Enum.map(fn {x, y} ->
      tile = Map.get(dungeon.grid, {x, y})
      monster = extract_monster_from_tile(tile)
      %{position: {x, y}, monster: monster, tile: tile}
    end)
  end

  defp hostile_monster?(monster, guards_hostile, player_alignment) do
    player_alignment_desc = Dungeon.PlayerStats.get_alignment_description(player_alignment)

    case monster do
      %{role: "npc"} ->
        # Opposing alignments are hostile to each other
        (monster.alignment == :lawful and player_alignment_desc == :chaotic) or
          (monster.alignment == :chaotic and player_alignment_desc == :lawful)

      %{role: "guard"} ->
        guards_hostile or
          ((monster.alignment == :lawful and player_alignment_desc == :chaotic) or
             (monster.alignment == :chaotic and player_alignment_desc == :lawful))

      %{role: "quest_npc"} ->
        false

      %{role: "quest_monster"} ->
        true

      _ ->
        # Check if the monster hunts players
        Map.get(monster, :hunts_player?, false)
    end
  end

  defp extract_monster_from_tile(tile) do
    case tile do
      {:encounter, _, monster} ->
        monster

      {:monster, monster_name} ->
        # Create a basic monster instance for old-style tiles
        Dungeon.Monster.create_monster_instance(monster_name)

      _ ->
        nil
    end
  end

  defp process_single_monster_turn(socket, monster_data) do
    %{position: monster_pos, monster: monster} = monster_data
    player_pos = socket.assigns.player_position

    Logger.info("Processing turn for #{monster.name} at #{inspect(monster_pos)}")

    # First check if this monster hunts players
    hunts_player = Map.get(monster, :hunts_player?, false)
    Logger.info("#{monster.name} hunts_player?: #{hunts_player}")

    if hunts_player do
      # Check if monster can hear the player (DC10 on d20)
      hearing_roll = Dice.roll(1, 20)
      can_hear_player = hearing_roll >= 10

      Logger.info(
        "#{monster.name} hearing roll: #{hearing_roll}/20 (DC10) - #{if can_hear_player, do: "SUCCESS", else: "FAILED"}"
      )

      if can_hear_player do
        # Check if monster can path to player within 4 squares
        case find_path_to_player(socket, monster_pos, player_pos) do
          {:can_reach, path} ->
            Logger.info("#{monster.name} can reach player, moving and triggering combat")
            move_monster_and_trigger_combat(socket, monster_data, path)

          {:cannot_reach, _reason} ->
            Logger.info("#{monster.name} cannot reach player, staying put")
            socket
        end
      else
        Logger.info("#{monster.name} cannot hear player, staying put")
        socket
      end
    else
      Logger.info("#{monster.name} does not hunt players, staying put")
      socket
    end
  end

  defp find_path_to_player(socket, monster_pos, player_pos) do
    # Find path from monster to an adjacent square of the player
    adjacent_positions = get_adjacent_positions(player_pos)

    # Try to find a path to any adjacent position
    case find_shortest_path_to_any_target(socket, monster_pos, adjacent_positions) do
      {:ok, path} when length(path) <= @max_monster_move_distance + 1 ->
        {:can_reach, path}

      {:ok, path} ->
        {:cannot_reach, "path too long: #{length(path)} > #{@max_monster_move_distance + 1}"}

      {:no_path} ->
        {:cannot_reach, "no path found"}
    end
  end

  defp get_adjacent_positions({x, y}) do
    [
      # left
      {x - 1, y},
      # right
      {x + 1, y},
      # up
      {x, y - 1},
      # down
      {x, y + 1}
    ]
  end

  defp find_shortest_path_to_any_target(socket, start_pos, target_positions) do
    # Try pathfinding to each target position and return the shortest path
    paths =
      Enum.map(target_positions, fn target_pos ->
        case pathfind_a_star(socket, start_pos, target_pos) do
          {:ok, path} -> {length(path), path}
          {:no_path} -> {999, []}
        end
      end)

    case Enum.min_by(paths, fn {length, _path} -> length end) do
      {999, []} -> {:no_path}
      {_length, path} -> {:ok, path}
    end
  end

  defp pathfind_a_star(socket, start_pos, end_pos) do
    # A* pathfinding algorithm adapted for monsters
    # Monsters use the same walkability rules as players for pathfinding

    open_set = [
      %{pos: start_pos, g: 0, h: manhattan_distance(start_pos, end_pos), f: 0, parent: nil}
    ]

    closed_set = MapSet.new()

    pathfind_loop(socket, open_set, closed_set, end_pos)
  end

  defp pathfind_loop(_socket, [], _closed_set, _end_pos), do: {:no_path}

  defp pathfind_loop(socket, open_set, closed_set, end_pos) do
    # Find node with lowest f score
    current = Enum.min_by(open_set, fn node -> node.f end)

    if current.pos == end_pos do
      # Found path, reconstruct it
      path = reconstruct_path(current)
      {:ok, path}
    else
      # Continue searching
      open_set = List.delete(open_set, current)
      closed_set = MapSet.put(closed_set, current.pos)

      # Check neighbors
      neighbors = get_walkable_neighbors(socket, current.pos)

      {new_open_set, new_closed_set} =
        Enum.reduce(neighbors, {open_set, closed_set}, fn neighbor_pos, {acc_open, acc_closed} ->
          if MapSet.member?(acc_closed, neighbor_pos) do
            {acc_open, acc_closed}
          else
            tentative_g = current.g + 1

            existing_node = Enum.find(acc_open, fn node -> node.pos == neighbor_pos end)

            if existing_node == nil do
              # Add new node
              new_node = %{
                pos: neighbor_pos,
                g: tentative_g,
                h: manhattan_distance(neighbor_pos, end_pos),
                f: tentative_g + manhattan_distance(neighbor_pos, end_pos),
                parent: current
              }

              {[new_node | acc_open], acc_closed}
            else
              # Update existing node if this path is better
              if tentative_g < existing_node.g do
                updated_node = %{
                  existing_node
                  | g: tentative_g,
                    f: tentative_g + existing_node.h,
                    parent: current
                }

                updated_open =
                  List.replace_at(
                    acc_open,
                    Enum.find_index(acc_open, fn n -> n.pos == neighbor_pos end),
                    updated_node
                  )

                {updated_open, acc_closed}
              else
                {acc_open, acc_closed}
              end
            end
          end
        end)

      pathfind_loop(socket, new_open_set, new_closed_set, end_pos)
    end
  end

  defp get_walkable_neighbors(socket, {x, y}) do
    dungeon = socket.assigns.dungeon

    # 4-directional movement
    candidates = [
      {x - 1, y},
      {x + 1, y},
      {x, y - 1},
      {x, y + 1}
    ]

    Enum.filter(candidates, fn {nx, ny} ->
      # Check bounds
      # Check walkability (monsters use same rules as players for pathfinding)
      nx >= 0 and nx < dungeon.width and ny >= 0 and ny < dungeon.height and
        walkable_for_monster?(socket, {nx, ny})
    end)
  end

  defp walkable_for_monster?(socket, {x, y}) do
    dungeon = socket.assigns.dungeon
    tile = Map.get(dungeon.grid, {x, y})

    # Monsters use similar walkability rules as players but cannot go through doors
    case tile do
      :floor ->
        true

      :road ->
        true

      :corridor ->
        true

      # Doors are non-walkable for monsters
      {:door, _} ->
        false

      :door ->
        false

      :trapped_door ->
        false

      :stair_up ->
        true

      :stair_down ->
        true

      {:stair_up} ->
        true

      {:stair_down} ->
        true

      {:starting_stair, _} ->
        true

      {:waypoint, _} ->
        true

      {:starting_waypoint, _} ->
        true

      :room_trap ->
        true

      :treasure ->
        true

      :trapped_treasure ->
        true

      :torch ->
        true

      :bread ->
        true

      :cheese ->
        true

      :grapes ->
        true

      :healing_potion ->
        true

      :pile_of_bones ->
        true

      {:treasure, _} ->
        true

      {:food, _} ->
        true

      {:healing_potion, _} ->
        true

      {:torch, _} ->
        true

      {:quest_item, _} ->
        true

      {:room_label, _} ->
        true

      {:corridor_label, _} ->
        true

      {:area_label, _} ->
        true

      {:building_label, _} ->
        true

      {:cavern_entrance, _} ->
        true

      {:dungeon_entrance, _} ->
        true

      {:cavern_exit, _} ->
        true

      {:dungeon_exit, _} ->
        true

      {:special_feature, _, feature_name} ->
        # Pillars are not walkable
        extract_feature_name(feature_name) != "Pillar"

      {:encounter, _, _} ->
        true

      {:monster, _} ->
        true

      # Locked doors are also non-walkable for monsters
      :locked_door ->
        false

      :locked_trapped_door ->
        false

      # Secret doors are also non-walkable for monsters
      :secret_door ->
        false

      _ ->
        false
    end
  end

  # Helper function to extract feature name from different formats
  defp extract_feature_name({feature_name, _rarity}) when is_binary(feature_name),
    do: feature_name

  defp extract_feature_name(feature_name) when is_binary(feature_name), do: feature_name
  defp extract_feature_name(_), do: "Unknown"

  defp manhattan_distance({x1, y1}, {x2, y2}) do
    abs(x1 - x2) + abs(y1 - y2)
  end

  defp reconstruct_path(node) do
    reconstruct_path(node, [])
  end

  defp reconstruct_path(nil, path), do: path

  defp reconstruct_path(node, path) do
    reconstruct_path(node.parent, [node.pos | path])
  end

  defp move_monster_and_trigger_combat(socket, monster_data, path) do
    %{position: old_pos, monster: monster, tile: old_tile} = monster_data

    # The path includes the starting position, so the target is the last position
    target_pos = List.last(path)

    Logger.info("Moving #{monster.name} from #{inspect(old_pos)} to #{inspect(target_pos)}")

    # Initialize monster visual position if not already set
    monster_visual_positions = socket.assigns.monster_visual_positions
    monster_key = "#{elem(old_pos, 0)}_#{elem(old_pos, 1)}"

    monster_visual_positions =
      if Map.has_key?(monster_visual_positions, monster_key) do
        monster_visual_positions
      else
        Map.put(monster_visual_positions, monster_key, old_pos)
      end

    # Move the monster on the grid
    socket = move_monster_on_grid(socket, old_pos, target_pos, old_tile)

    # Update monster visual positions with new key
    new_monster_key = "#{elem(target_pos, 0)}_#{elem(target_pos, 1)}"

    monster_visual_positions =
      monster_visual_positions
      |> Map.delete(monster_key)
      |> Map.put(new_monster_key, target_pos)

    socket = Phoenix.Component.assign(socket, :monster_visual_positions, monster_visual_positions)

    # Trigger monster movement animation
    socket = trigger_monster_animation(socket, old_pos, target_pos, monster)

    # Trigger combat with the monster (delayed to allow animation)
    Process.send_after(self(), {:trigger_monster_combat, target_pos, monster}, 400)

    socket
  end

  defp move_monster_on_grid(socket, old_pos, new_pos, old_tile) do
    dungeon = socket.assigns.dungeon

    # Remove monster from old position (replace with underlying tile)
    underlying_tile = determine_underlying_tile(old_pos, dungeon.rooms)

    # Place monster at new position
    updated_grid =
      dungeon.grid
      |> Map.put(old_pos, underlying_tile)
      |> Map.put(new_pos, old_tile)

    new_dungeon = %{dungeon | grid: updated_grid}

    Phoenix.Component.assign(socket, :dungeon, new_dungeon)
  end

  defp determine_underlying_tile({x, y}, rooms) do
    # Determine what tile should be under the monster
    alias Dungeon.Generator.Grid

    if Grid.point_in_any_room?({x, y}, rooms) do
      :floor
    else
      :corridor
    end
  end

  defp trigger_monster_animation(socket, old_pos, new_pos, monster) do
    # Send animation event to JavaScript
    socket =
      Phoenix.LiveView.push_event(socket, "animate_monster", %{
        monster_name: monster.name,
        from_x: elem(old_pos, 0),
        from_y: elem(old_pos, 1),
        to_x: elem(new_pos, 0),
        to_y: elem(new_pos, 1)
      })

    Logger.info(
      "Triggering animation for #{monster.name} from #{inspect(old_pos)} to #{inspect(new_pos)}"
    )

    socket
  end
end
