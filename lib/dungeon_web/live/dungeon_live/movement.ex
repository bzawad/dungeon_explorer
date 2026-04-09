defmodule DungeonWeb.DungeonLive.Movement do
  @moduledoc """
  Player movement, walkability, and position logic
  """

  alias DungeonWeb.DungeonLive.{
    EncounterSystem,
    FogOfWar,
    FoodSystem,
    HealingPotionSystem,
    QuestItemSystem,
    RoomLabelSystem,
    SpecialFeatureSystem,
    TrapSystem,
    TreasureSystem
  }

  alias Dungeon.Dice
  alias DungeonWeb.UISizing

  # Key mapping for WASD movement
  @key_directions %{
    # Up
    "w" => {0, -1},
    # Left
    "a" => {-1, 0},
    # Down
    "s" => {0, 1},
    # Right
    "d" => {1, 0},
    # Up (uppercase)
    "W" => {0, -1},
    # Left (uppercase)
    "A" => {-1, 0},
    # Down (uppercase)
    "S" => {0, 1},
    # Right (uppercase)
    "D" => {1, 0},
    # Arrow keys
    "ArrowUp" => {0, -1},
    "ArrowLeft" => {-1, 0},
    "ArrowDown" => {0, 1},
    "ArrowRight" => {1, 0}
  }

  # Terrain walkable for movement (excludes locked doors)
  @movement_walkable_terrain [
    :floor,
    :corridor,
    :road,
    :door,
    :trapped_door,
    :secret_door,
    :stair_up,
    :stair_down,
    :room_trap,
    :treasure,
    :trapped_treasure,
    :torch,
    :bread,
    :cheese,
    :grapes,
    :healing_potion,
    :pile_of_bones
  ]

  @doc """
  Convert key press to direction vector
  """
  def key_to_direction(key) do
    Map.get(@key_directions, key)
  end

  @doc """
  Move player in a direction (from keyboard input)
  """
  def move_player_direction(socket, {dx, dy}) do
    {player_x, player_y} = socket.assigns.player_position
    new_x = player_x + dx
    new_y = player_y + dy

    # Update facing direction based on movement
    new_facing = update_facing_direction(socket.assigns.player_facing, {dx, dy})
    socket = Phoenix.Component.assign(socket, :player_facing, new_facing)

    move_player_to_position(socket, {new_x, new_y})
  end

  @doc """
  Move player to specific position (from click or keyboard)
  """
  def move_player_to_position(socket, {x, y}, opts \\ []) do
    is_pathfinding = Keyword.get(opts, :pathfinding, false)

    cond do
      # Check for locked door first (before valid_movement check)
      locked_door_destination?(socket, {x, y}) ->
        show_locked_door_dialog_for_movement(socket, {x, y})

      # Check for encounter destination only if moving ONTO an encounter tile (not adjacent)
      # During pathfinding, suppress NPC dialogs (like special features)
      not is_pathfinding and direct_encounter_destination?(socket, {x, y}) ->
        show_encounter_dialog_for_movement(socket, {x, y})

      # Then check if movement is valid for other cases
      valid_movement?(socket, {x, y}) ->
        cond do
          trapped_door_destination?(socket, {x, y}) ->
            show_trapped_door_dialog_for_movement(socket, {x, y})

          open_door_destination?(socket, {x, y}) ->
            show_open_door_dialog_for_movement(socket, {x, y})

          true ->
            perform_movement(socket, {x, y}, is_pathfinding)
        end

      true ->
        {:noreply, socket}
    end
  end

  @doc """
  Move player to specific position bypassing door dialog (used when movement is confirmed through dialog)
  """
  def move_player_to_position_confirmed(socket, {x, y}) do
    if valid_movement?(socket, {x, y}) do
      perform_movement(socket, {x, y}, false)
    else
      {:noreply, socket}
    end
  end

  @doc """
  Find starting position from dungeon grid
  """
  def find_starting_position(dungeon) do
    # Find the starting staircase or waypoint position
    # Fallback to top-left if no starting stair/waypoint found
    Enum.find_value(dungeon.grid, fn {{x, y}, tile} ->
      case tile do
        {:starting_stair, _} -> {x, y}
        {:starting_waypoint, _} -> {x, y}
        _ -> nil
      end
    end) || {0, 0}
  end

  @doc """
  Check if position is adjacent to player (including diagonally)
  """
  def adjacent_to_player?({x, y}, {player_x, player_y}) do
    # Check if position is adjacent (including diagonally) to player
    abs(x - player_x) <= 1 and abs(y - player_y) <= 1 and {x, y} != {player_x, player_y}
  end

  @doc """
  Check for secret doors adjacent to player position and attempt detection
  """
  def check_secret_doors_adjacent(socket, {player_x, player_y}) do
    dungeon = socket.assigns.dungeon
    revealed_secret_doors = socket.assigns.revealed_secret_doors || MapSet.new()

    # Check all 8 adjacent positions for secret doors
    adjacent_positions = [
      {player_x - 1, player_y - 1},
      {player_x, player_y - 1},
      {player_x + 1, player_y - 1},
      {player_x - 1, player_y},
      {player_x + 1, player_y},
      {player_x - 1, player_y + 1},
      {player_x, player_y + 1},
      {player_x + 1, player_y + 1}
    ]

    # Check each adjacent position for unrevealed secret doors
    Enum.reduce_while(adjacent_positions, {socket, revealed_secret_doors}, fn position,
                                                                              {acc_socket,
                                                                               acc_revealed} ->
      tile = Map.get(dungeon.grid, position)

      if tile == :secret_door and not MapSet.member?(acc_revealed, position) do
        # Attempt to detect the secret door (DC15 check)
        # d20 + 0 modifier
        detection_roll = Dice.roll_attack(0)

        if detection_roll >= 15 do
          # Secret door detected!
          new_revealed = MapSet.put(acc_revealed, position)
          new_socket = assign(acc_socket, :revealed_secret_doors, new_revealed)

          # Send message to show secret door dialog
          send(self(), {:show_secret_door_dialog, position})

          {:halt, {new_socket, new_revealed}}
        else
          # Not detected this time, continue checking
          {:cont, {acc_socket, acc_revealed}}
        end
      else
        {:cont, {acc_socket, acc_revealed}}
      end
    end)
    # Return just the socket
    |> elem(0)
  end

  @doc """
  Update player facing direction based on movement delta
  """
  def update_facing_direction(_current_facing, {dx, dy}) do
    cond do
      # Moving right (east)
      dx > 0 -> :right
      # Moving left (west)
      dx < 0 -> :left
      # Moving down (south)
      dy > 0 -> :forward
      # Moving up (north)
      dy < 0 -> :back
      # No movement, default to forward
      true -> :forward
    end
  end

  @doc """
  Check if terrain is walkable for movement
  """
  def walkable_for_movement?(tile, position, unlocked_doors, guards_hostile \\ false) do
    basic_walkable_terrain?(tile) or
      unlocked_door_available?(tile, position, unlocked_doors) or
      guard_walkable?(tile, guards_hostile)
  end

  defp basic_walkable_terrain?(tile) do
    # Check basic walkable terrain (encounters are NOT walkable - they trigger dialog instead)
    # Exception: Non-hostile NPCs are walkable like special features
    tile in @movement_walkable_terrain or
      label_tile?(tile) or
      special_tile?(tile) or
      feature_tile?(tile) or
      npc_walkable?(tile)
  end

  # Non-hostile NPCs and non-hostile guards are walkable like special features
  defp npc_walkable?({:encounter, _label, monster}) do
    case monster do
      %{role: "npc"} -> true
      # Guards walkability depends on hostility - handled separately
      %{role: "guard"} -> false
      _ -> false
    end
  end

  defp npc_walkable?(_), do: false

  # Non-hostile guards are walkable like NPCs
  defp guard_walkable?({:encounter, _label, monster}, guards_hostile) do
    case monster do
      # Only walkable if not hostile
      %{role: "guard"} -> not guards_hostile
      _ -> false
    end
  end

  defp guard_walkable?(_, _), do: false

  defp label_tile?(tile) do
    match?({:room_label, _}, tile) or
      match?({:corridor_label, _}, tile) or
      match?({:area_label, _}, tile) or
      match?({:building_label, _}, tile)
  end

  defp special_tile?(tile) do
    match?({:starting_stair, _}, tile) or
      match?({:starting_waypoint, _}, tile) or
      match?({:waypoint, _}, tile) or
      match?({:cavern_entrance, _}, tile) or
      match?({:dungeon_entrance, _}, tile) or
      match?({:cavern_exit, _}, tile) or
      match?({:dungeon_exit, _}, tile) or
      match?({:quest_item, _}, tile)
  end

  defp feature_tile?(tile) do
    case tile do
      # Pillars are not walkable
      {:special_feature, _, "Pillar"} -> false
      {:special_feature, _, _} -> true
      _ -> false
    end
  end

  defp unlocked_door_available?(tile, position, unlocked_doors) do
    # Check if it's a locked door that has been unlocked
    tile in [:locked_door, :locked_trapped_door] and
      MapSet.member?(unlocked_doors, position)
  end

  @doc """
  Check if the destination is an open door that should show a dialog
  """
  def open_door_destination?(socket, {x, y}) do
    dungeon = socket.assigns.dungeon
    tile = Map.get(dungeon.grid, {x, y})

    # Check if it's an open door (regular door, trapped door, or unlocked locked door)
    tile in [:door, :trapped_door] or
      (tile in [:locked_door, :locked_trapped_door] and
         MapSet.member?(socket.assigns.unlocked_doors, {x, y}))
  end

  @doc """
  Check if the destination is a trapped door that should show trap detection dialog
  """
  def trapped_door_destination?(socket, {x, y}) do
    dungeon = socket.assigns.dungeon
    tile = Map.get(dungeon.grid, {x, y})

    # Check if it's a trapped door
    tile in [:trapped_door, :locked_trapped_door]
  end

  @doc """
  Check if the destination is a locked door that should show unlock dialog
  """
  def locked_door_destination?(socket, {x, y}) do
    dungeon = socket.assigns.dungeon
    tile = Map.get(dungeon.grid, {x, y})
    {player_x, player_y} = socket.assigns.player_position

    # Check if it's adjacent, revealed, and a locked door that hasn't been unlocked
    adjacent = adjacent_to_player?({x, y}, {player_x, player_y})

    revealed =
      FogOfWar.square_revealed?(x, y, socket.assigns.revealed_squares, socket.assigns.fog_enabled)

    locked_door =
      tile in [:locked_door, :locked_trapped_door] and
        not MapSet.member?(socket.assigns.unlocked_doors, {x, y})

    adjacent and revealed and locked_door
  end

  @doc """
  Check if the destination is a direct encounter tile (moving onto the monster)
  """
  def direct_encounter_destination?(socket, {x, y}) do
    check_direct_encounter_at_destination(socket, {x, y})
  end

  # Check if the destination tile itself is an encounter
  defp check_direct_encounter_at_destination(socket, {x, y}) do
    dungeon = socket.assigns.dungeon
    tile = Map.get(dungeon.grid, {x, y})
    {player_x, player_y} = socket.assigns.player_position

    # Check if it's adjacent, revealed, and an encounter that hasn't been triggered
    adjacent = adjacent_to_player?({x, y}, {player_x, player_y})

    revealed =
      FogOfWar.square_revealed?(x, y, socket.assigns.revealed_squares, socket.assigns.fog_enabled)

    encounter_tile =
      EncounterSystem.encounter_tile?(tile) and
        not MapSet.member?(socket.assigns.triggered_encounters, {x, y})

    adjacent and revealed and encounter_tile
  end

  @doc """
  Show open door dialog for movement attempt
  """
  def show_open_door_dialog_for_movement(socket, {x, y}) do
    dungeon = socket.assigns.dungeon
    tile = Map.get(dungeon.grid, {x, y})

    # Call the LiveView's show_open_door_dialog function
    send(self(), {:show_open_door_dialog_for_movement, {x, y}, tile})
    {:noreply, socket}
  end

  @doc """
  Show encounter dialog for movement attempt (only for direct encounters on the destination tile)
  """
  def show_encounter_dialog_for_movement(socket, {x, y}) do
    # This is only called for direct encounters (moving onto the monster)
    # Adjacent encounters are now handled post-movement
    case EncounterSystem.process_encounter_with_guards(socket, {x, y}) do
      {true, icon, message, monster} ->
        # Send message to show encounter dialog
        send(self(), {:show_encounter_dialog_for_movement, {x, y}, icon, message, monster})
        {:noreply, socket}

      {false, _, _, _} ->
        {:noreply, socket}
    end
  end

  @doc """
  Show stair dialog for movement attempt
  """
  def show_stair_dialog_for_movement(socket, {x, y}) do
    dungeon = socket.assigns.dungeon
    tile = Map.get(dungeon.grid, {x, y})

    # Call the LiveView's show_stair_dialog function
    send(self(), {:show_stair_dialog_for_movement, {x, y}, tile})
    {:noreply, socket}
  end

  @doc """
  Show trapped door dialog for movement attempt
  """
  def show_trapped_door_dialog_for_movement(socket, {x, y}) do
    # Send trap detection attempt to LiveView for movement into trapped door
    send(
      self(),
      {:attempt_trap_detection_for_movement, {x, y}, :door_trap, {:move_through_door, {x, y}}}
    )

    {:noreply, socket}
  end

  @doc """
  Show locked door dialog for movement attempt
  """
  def show_locked_door_dialog_for_movement(socket, {x, y}) do
    dungeon = socket.assigns.dungeon
    tile = Map.get(dungeon.grid, {x, y})

    # Call the LiveView's show_unlock_dialog function
    send(self(), {:show_unlock_dialog_for_movement, {x, y}, tile})
    {:noreply, socket}
  end

  # Private functions

  defp valid_movement?(socket, {x, y}) do
    dungeon = socket.assigns.dungeon
    {player_x, player_y} = socket.assigns.player_position

    tile = Map.get(dungeon.grid, {x, y})
    adjacent = adjacent_to_player?({x, y}, {player_x, player_y})

    revealed =
      FogOfWar.square_revealed?(x, y, socket.assigns.revealed_squares, socket.assigns.fog_enabled)

    walkable = walkable_for_movement?(tile, {x, y}, socket.assigns.unlocked_doors)

    adjacent and revealed and walkable
  end

  defp perform_movement(socket, {x, y}, is_pathfinding) do
    dungeon = socket.assigns.dungeon
    tile = Map.get(dungeon.grid, {x, y})

    # Track clicked squares and check for traps
    new_clicked = MapSet.put(socket.assigns.clicked_squares, {x, y})
    {player_trapped, trap_dialog_data} = process_tile_traps(tile, {x, y}, socket)

    # Handle fog revelation
    final_revealed = process_fog_revelation(socket, {x, y}, dungeon)

    # Handle room traps (skull traps)
    {room_trap_dialog_data, new_sprung_traps} =
      process_room_traps(socket, {x, y}, dungeon, final_revealed, trap_dialog_data)

    # Handle encounters (check both fog-revealed and post-movement adjacency encounters)
    {encounter_dialog_data, new_triggered_encounters} =
      process_all_encounters(
        socket,
        {x, y},
        final_revealed,
        dungeon,
        room_trap_dialog_data,
        is_pathfinding
      )

    # Handle torch collection
    {torch_dialog_data, updated_grid} = process_torch_collection(socket, {x, y}, dungeon)

    # Process all dialog types with priority handling
    # Only show dialogs if this is not part of a pathfinding sequence
    dialog_results =
      if is_pathfinding do
        # During pathfinding, only process critical dialogs (traps, encounters, torch)
        process_critical_dialogs_only(
          socket,
          {x, y},
          room_trap_dialog_data,
          encounter_dialog_data,
          torch_dialog_data
        )
      else
        # Normal movement - process all dialogs
        process_all_dialogs(
          socket,
          {x, y},
          room_trap_dialog_data,
          encounter_dialog_data,
          torch_dialog_data
        )
      end

    # Extract potentially updated socket from quest item discovery
    # Quest item is always a 5-tuple: {show_dialog, icon, message, position, socket}
    {_, _, _, _, quest_item_socket} = dialog_results.quest_item

    # Trigger background music on first movement
    if not quest_item_socket.assigns.background_music_played do
      send(
        self(),
        {:play_background_music, quest_item_socket.assigns.dungeon_level,
         quest_item_socket.assigns.dungeon.theme}
      )
    end

    # Update socket with all changes
    movement_context = %{
      position: {x, y},
      clicked: new_clicked,
      revealed: final_revealed,
      player_trapped: player_trapped,
      sprung_traps: new_sprung_traps,
      trap_dialog: room_trap_dialog_data,
      encounter_dialog: encounter_dialog_data,
      treasure_dialog: dialog_results.treasure,
      food_dialog: dialog_results.food_dialog,
      healing_potion_dialog: dialog_results.healing_potion_dialog,
      torch: torch_dialog_data,
      special_feature: dialog_results.special_feature,
      label: dialog_results.label,
      quest_item: dialog_results.quest_item,
      triggered_encounters: new_triggered_encounters,
      updated_grid: updated_grid,
      is_pathfinding: is_pathfinding
    }

    socket = update_socket_after_movement(quest_item_socket, movement_context)

    {:noreply, socket}
  end

  defp process_tile_traps(tile, position, _socket) do
    player_trapped = TrapSystem.trapped_tile?(tile)
    dialog_data = handle_trapped_tile(player_trapped, tile, position)
    {player_trapped, dialog_data}
  end

  defp handle_trapped_tile(false, _tile, _position) do
    {false, "", "", nil}
  end

  defp handle_trapped_tile(true, tile, position) do
    trap_type = determine_trap_type(tile)

    if trap_type != :unknown_trap do
      handle_known_trap(trap_type, position)
    else
      handle_unknown_trap(tile, position)
    end
  end

  defp determine_trap_type(tile) do
    cond do
      tile in [:trapped_door, :locked_trapped_door] -> :door_trap
      tile == :room_trap -> :room_trap
      tile == :trapped_treasure -> :treasure_trap
      true -> :unknown_trap
    end
  end

  defp handle_known_trap(trap_type, position) do
    pending_action = get_pending_action_for_trap(trap_type, position)
    send(self(), {:attempt_trap_detection, position, trap_type, pending_action})
    {false, "", "", nil}
  end

  defp handle_unknown_trap(tile, position) do
    {icon, message, _damage} = TrapSystem.get_trap_message(tile)
    {true, icon, message, position}
  end

  defp get_pending_action_for_trap(trap_type, position) do
    case trap_type do
      :room_trap -> {:enter_room, position}
      :treasure_trap -> {:collect_treasure, position}
      _ -> {:enter_room, position}
    end
  end

  defp process_fog_revelation(socket, {x, y}, dungeon) do
    # For daylight themes, torch is always active (stays at 100)
    # For other themes, check if torch will still be burning after this movement
    torch_will_be_active =
      if socket.assigns.dungeon.fog_type == "daylight" do
        # Always active for daylight themes
        true
      else
        # (torch_burn_time - 1 because it will be decremented)
        socket.assigns.torch_burn_time > 1
      end

    {new_revealed, newly_revealed_count} =
      if torch_will_be_active do
        # Reveal area around new player position using theme-based radius
        player_surroundings = FogOfWar.get_surrounding_squares(x, y, dungeon)

        # Count newly revealed squares for XP awarding
        newly_revealed_count =
          Enum.count(player_surroundings, fn square ->
            not MapSet.member?(socket.assigns.revealed_squares, square)
          end)

        new_revealed =
          Enum.reduce(player_surroundings, socket.assigns.revealed_squares, fn square, acc ->
            MapSet.put(acc, square)
          end)

        {new_revealed, newly_revealed_count}
      else
        # Don't reveal new squares if torch is about to burn out
        {socket.assigns.revealed_squares, 0}
      end

    # Auto-reveal room/corridor labels when player enters them (only if fog is enabled AND torch is available)
    final_revealed =
      if socket.assigns.fog_enabled and torch_will_be_active do
        FogOfWar.reveal_area_labels(new_revealed, {x, y}, dungeon)
      else
        new_revealed
      end

    # Award XP for newly revealed squares during movement (1 + dungeon level per square)
    # Skip exploration XP for daylight themes as they have larger reveal ranges and are less dangerous
    if newly_revealed_count > 0 and socket.assigns.dungeon.fog_type != "daylight" do
      exploration_xp = newly_revealed_count * (1 + socket.assigns.dungeon_level)

      # Send XP award message to the LiveView process
      send(self(), {:award_exploration_xp, exploration_xp, newly_revealed_count})
    end

    final_revealed
  end

  defp process_room_traps(
         _socket,
         {x, y},
         dungeon,
         final_revealed,
         {show_trap_dialog, trap_icon, trap_message, triggered_trap_position}
       ) do
    # Check for adjacent room traps (skull traps) and spring them
    adjacent_room_traps = find_adjacent_room_traps({x, y}, dungeon, final_revealed)
    new_sprung_traps = MapSet.new(adjacent_room_traps)

    # Show trap detection for adjacent skull traps if any were sprung
    dialog_data =
      if not show_trap_dialog and adjacent_room_traps != [] do
        # Send trap detection for the first adjacent room trap
        first_trap = List.first(adjacent_room_traps)
        send(self(), {:attempt_trap_detection, first_trap, :room_trap, {:enter_room, first_trap}})

        # Return no dialog for now - the detection will handle showing dialogs
        {false, "", "", nil}
      else
        {show_trap_dialog, trap_icon, trap_message, triggered_trap_position}
      end

    {dialog_data, new_sprung_traps}
  end

  defp process_all_encounters(
         socket,
         {player_x, player_y},
         _final_revealed,
         dungeon,
         {final_show_trap_dialog, _, _, _},
         is_pathfinding
       ) do
    # During pathfinding, suppress NPC encounter dialogs (like special features)
    # Only check for encounters adjacent to the new player position
    encounter_position =
      check_adjacent_encounters_at_position(socket, {player_x, player_y}, dungeon)

    if encounter_position != nil and not final_show_trap_dialog and not is_pathfinding do
      # Trigger encounter dialog (guard-aware processing)
      {true, encounter_icon, encounter_message, _monster} =
        EncounterSystem.process_encounter_with_guards(socket, encounter_position)

      # Don't mark as triggered yet - only mark as triggered when encounter is actually resolved
      # (either through combat victory or successful evasion that removes the monster)
      {{true, encounter_icon, encounter_message, encounter_position},
       socket.assigns.triggered_encounters}
    else
      {{false, "", "", nil}, socket.assigns.triggered_encounters}
    end
  end

  # Check if the current player position is adjacent to any encounters
  # Note: NPCs are excluded from adjacent encounter detection to avoid intrusive dialogs
  defp check_adjacent_encounters_at_position(socket, {player_x, player_y}, dungeon) do
    # Get all positions adjacent to the player's current position
    adjacent_positions = [
      {player_x - 1, player_y - 1},
      {player_x, player_y - 1},
      {player_x + 1, player_y - 1},
      {player_x - 1, player_y},
      {player_x + 1, player_y},
      {player_x - 1, player_y + 1},
      {player_x, player_y + 1},
      {player_x + 1, player_y + 1}
    ]

    # Check if any adjacent position has an untriggered non-NPC encounter
    # Adjacent encounters should trigger even when torch is out - you can sense monsters next to you
    # But NPCs are excluded to avoid intrusive dialogs that block item interaction
    Enum.find_value(adjacent_positions, &check_position_for_encounter(socket, dungeon, &1))
  end

  defp check_position_for_encounter(socket, dungeon, {adj_x, adj_y}) do
    tile = Map.get(dungeon.grid, {adj_x, adj_y})

    is_untriggered_encounter =
      EncounterSystem.encounter_tile?(tile) and
        not MapSet.member?(socket.assigns.triggered_encounters, {adj_x, adj_y})

    if is_untriggered_encounter do
      evaluate_encounter_for_adjacency(
        tile,
        {adj_x, adj_y},
        socket.assigns.guards_hostile,
        socket.assigns.player_alignment
      )
    else
      nil
    end
  end

  defp evaluate_encounter_for_adjacency(tile, position, guards_hostile, player_alignment) do
    case tile do
      {:encounter, _label, monster} ->
        evaluate_monster_for_adjacency(monster, position, guards_hostile, player_alignment)

      _ ->
        position
    end
  end

  defp evaluate_monster_for_adjacency(nil, _position, _guards_hostile, _player_alignment), do: nil

  defp evaluate_monster_for_adjacency(
         %{role: "npc"} = monster,
         _position,
         _guards_hostile,
         player_alignment
       ) do
    player_alignment_desc = Dungeon.PlayerStats.get_alignment_description(player_alignment)
    # Opposing alignments trigger hostility
    if monster.alignment in [:lawful, :neutral] and player_alignment_desc == :chaotic do
      # Don't trigger adjacency dialog if hostile
      nil
    else
      # NPCs don't trigger adjacency encounters anyway
      nil
    end
  end

  defp evaluate_monster_for_adjacency(
         %{role: "guard"} = monster,
         position,
         guards_hostile,
         player_alignment
       ) do
    player_alignment_desc = Dungeon.PlayerStats.get_alignment_description(player_alignment)

    if guards_hostile or
         ((monster.alignment == :lawful and player_alignment_desc == :chaotic) or
            (monster.alignment == :chaotic and player_alignment_desc == :lawful)) do
      position
    else
      nil
    end
  end

  # Regular monsters (role nil or e.g. "quest_monster") — adjacency triggers encounter
  defp evaluate_monster_for_adjacency(_monster, position, _guards_hostile, _player_alignment),
    do: position

  defp process_treasure(socket, {x, y}) do
    dungeon = socket.assigns.dungeon
    tile = Map.get(dungeon.grid, {x, y})

    if TreasureSystem.treasure_tile?(tile) and tile != :trapped_treasure do
      # Only show treasure dialog for non-trapped treasure
      # Trapped treasure will be handled after trap is dismissed
      case TreasureSystem.process_treasure(socket, {x, y}) do
        {true, icon, message, position, gold_amount} ->
          {true, icon, message, position, gold_amount}

        {false, _, _, _, _} ->
          {false, "", "", nil, 0}
      end
    else
      {false, "", "", nil, 0}
    end
  end

  defp process_food(socket, {x, y}) do
    case FoodSystem.process_food(socket, {x, y}) do
      {true, icon, message, position, healing_amount} ->
        {true, icon, message, position, healing_amount}

      {false, _, _, _, _} ->
        {false, "", "", nil, 0}
    end
  end

  defp process_healing_potion(socket, {x, y}) do
    case HealingPotionSystem.process_healing_potion(socket, {x, y}) do
      {true, icon, message, position, healing_amount} ->
        {true, icon, message, position, healing_amount}

      {false, _, _, _, _} ->
        {false, "", "", nil, 0}
    end
  end

  defp process_special_feature(socket, {x, y}) do
    case SpecialFeatureSystem.process_special_feature(socket, {x, y}) do
      {true, icon, message} ->
        {true, icon, message, {x, y}}

      {false, _, _} ->
        {false, "", "", nil}
    end
  end

  defp process_label(socket, {x, y}) do
    case RoomLabelSystem.process_label(socket, {x, y}) do
      {true, icon, message} ->
        {true, icon, message, {x, y}}

      {false, _, _} ->
        {false, "", "", nil}
    end
  end

  defp process_torch_collection(_socket, {x, y}, dungeon) do
    tile = Map.get(dungeon.grid, {x, y})

    if tile == :torch do
      # Don't remove torch from grid yet - wait for dialog dismissal
      # Return dialog data without modifying grid
      {{true, DungeonWeb.UISizing.img_tag("/images/torch.png", "Torch", :medium_icon),
        "You found a torch! It has been added to your inventory.", {x, y}}, dungeon}
    else
      # No torch found
      {{false, "", "", nil}, dungeon}
    end
  end

  defp check_r1_auto_trigger(socket, {x, y}) do
    # Check if player is entering any room for the first time
    dungeon = socket.assigns.dungeon

    # Find which room the player is currently in
    current_room = Enum.find(dungeon.rooms, fn room -> player_in_room?(x, y, room) end)

    cond do
      # Player is not in any room
      current_room == nil ->
        {false, "", ""}

      # Room has already been visited
      Map.get(socket.assigns.room_descriptions, current_room.number) != nil ->
        {false, "", ""}

      # No room label tile found
      is_nil(find_room_label_tile(dungeon.grid, current_room.number)) ->
        {false, "", ""}

      # Player is entering a room for the first time - trigger room dialog
      true ->
        room_tile = find_room_label_tile(dungeon.grid, current_room.number)

        # Handle different room types
        if current_room.number == "R1" do
          RoomLabelSystem.handle_r1_access(socket, room_tile)
        else
          RoomLabelSystem.handle_room_access(socket, room_tile, current_room.number)
        end
    end
  end

  defp player_in_room?(x, y, room) do
    case room do
      # Traditional room format
      %{x: room_x, y: room_y, width: width, height: height} ->
        x >= room_x and x < room_x + width and
          y >= room_y and y < room_y + height

      # Cavern format with cells
      %{cells: cells} ->
        {x, y} in cells

      # Fallback
      _ ->
        false
    end
  end

  defp find_room_label_tile(grid, room_number) do
    Enum.find_value(grid, fn {_pos, tile} ->
      case tile do
        {:room_label, ^room_number} -> tile
        _ -> nil
      end
    end)
  end

  defp process_critical_dialogs_only(
         socket,
         {_x, _y},
         _room_trap_dialog_data,
         _encounter_dialog_data,
         torch_dialog_data
       ) do
    # During pathfinding, only process critical dialogs that should interrupt movement
    # Skip labels, special features, treasure, food, healing potions, quest items, and encounters (NPCs)
    %{
      treasure: {false, "", "", nil, 0},
      food_dialog: {false, "", "", nil, 0},
      healing_potion_dialog: {false, "", "", nil, 0},
      torch: torch_dialog_data,
      special_feature: {false, "", "", nil},
      label: {false, "", "", nil},
      quest_item: {false, "", "", nil, socket}
    }
  end

  defp process_all_dialogs(
         socket,
         {x, y},
         room_trap_dialog_data,
         encounter_dialog_data,
         torch_dialog_data
       ) do
    # Extract active dialog flags
    dialog_flags = extract_dialog_flags(room_trap_dialog_data, encounter_dialog_data)

    # Process each dialog type with priority handling
    treasure_dialog_data = process_treasure_dialog(socket, {x, y}, dialog_flags)
    food_dialog_data = process_food_dialog(socket, {x, y}, dialog_flags, treasure_dialog_data)

    healing_potion_dialog_data =
      process_healing_potion_dialog(
        socket,
        {x, y},
        dialog_flags,
        treasure_dialog_data,
        food_dialog_data
      )

    special_feature_dialog_data =
      process_special_feature_dialog(
        socket,
        {x, y},
        dialog_flags,
        treasure_dialog_data,
        food_dialog_data,
        healing_potion_dialog_data,
        torch_dialog_data
      )

    label_dialog_data =
      process_label_dialog(socket, {x, y}, dialog_flags, special_feature_dialog_data)

    quest_item_dialog_data =
      process_quest_item_dialog(socket, {x, y}, dialog_flags, label_dialog_data)

    %{
      treasure: treasure_dialog_data,
      food_dialog: food_dialog_data,
      healing_potion_dialog: healing_potion_dialog_data,
      torch: torch_dialog_data,
      special_feature: special_feature_dialog_data,
      label: label_dialog_data,
      quest_item: quest_item_dialog_data
    }
  end

  defp extract_dialog_flags(room_trap_dialog_data, encounter_dialog_data) do
    {final_show_trap_dialog, _, _, _} = room_trap_dialog_data
    {show_encounter_dialog, _, _, _} = encounter_dialog_data

    %{
      trap: final_show_trap_dialog,
      encounter: show_encounter_dialog
    }
  end

  defp process_treasure_dialog(socket, {x, y}, dialog_flags) do
    if not dialog_flags.trap and not dialog_flags.encounter do
      process_treasure(socket, {x, y})
    else
      {false, "", "", nil, 0}
    end
  end

  defp process_food_dialog(socket, {x, y}, dialog_flags, treasure_dialog_data) do
    {show_treasure_dialog, _, _, _, _} = treasure_dialog_data

    if not dialog_flags.trap and not dialog_flags.encounter and not show_treasure_dialog do
      process_food(socket, {x, y})
    else
      {false, "", "", nil, 0}
    end
  end

  defp process_healing_potion_dialog(
         socket,
         {x, y},
         dialog_flags,
         treasure_dialog_data,
         food_dialog_data
       ) do
    {show_treasure_dialog, _, _, _, _} = treasure_dialog_data
    {show_food_dialog, _, _, _, _} = food_dialog_data

    if not dialog_flags.trap and not dialog_flags.encounter and not show_treasure_dialog and
         not show_food_dialog do
      process_healing_potion(socket, {x, y})
    else
      {false, "", "", nil, 0}
    end
  end

  defp process_special_feature_dialog(
         socket,
         {x, y},
         dialog_flags,
         treasure_dialog_data,
         food_dialog_data,
         healing_potion_dialog_data,
         torch_dialog_data
       ) do
    {show_treasure_dialog, _, _, _, _} = treasure_dialog_data
    {show_food_dialog, _, _, _, _} = food_dialog_data
    {show_healing_potion_dialog, _, _, _, _} = healing_potion_dialog_data
    {show_torch_dialog, _, _, _} = torch_dialog_data

    if not dialog_flags.trap and not dialog_flags.encounter and not show_treasure_dialog and
         not show_food_dialog and not show_healing_potion_dialog and not show_torch_dialog do
      process_special_feature(socket, {x, y})
    else
      {false, "", "", nil}
    end
  end

  defp process_label_dialog(socket, {x, y}, dialog_flags, special_feature_dialog_data) do
    {show_special_feature_dialog, _, _, _} = special_feature_dialog_data

    if not dialog_flags.trap and not dialog_flags.encounter and not show_special_feature_dialog do
      check_auto_triggers_or_process_label(socket, {x, y})
    else
      {false, "", "", nil}
    end
  end

  defp process_quest_item_dialog(socket, {x, y}, dialog_flags, label_dialog_data) do
    {show_label_dialog, _, _, _} = label_dialog_data

    if not dialog_flags.trap and not dialog_flags.encounter and not show_label_dialog do
      case QuestItemSystem.process_quest_item_discovery(socket, {x, y}) do
        {true, updated_socket} ->
          {true, UISizing.img_tag("/images/special_item.png", "Quest Item", :medium_icon),
           "Quest item found!", {x, y}, updated_socket}

        {false, _} ->
          {false, "", "", nil, socket}
      end
    else
      {false, "", "", nil, socket}
    end
  end

  defp check_auto_triggers_or_process_label(socket, {x, y}) do
    # Try auto-triggers in order: R1, then areas, then fall back to normal processing
    r1_result = check_r1_auto_trigger(socket, {x, y})
    area_result = check_area_auto_trigger(socket, {x, y})

    cond do
      elem(r1_result, 0) ->
        {true, elem(r1_result, 1), elem(r1_result, 2), {x, y}}

      elem(area_result, 0) ->
        {true, elem(area_result, 1), elem(area_result, 2), {x, y}}

      true ->
        process_label(socket, {x, y})
    end
  end

  defp check_area_auto_trigger(socket, {x, y}) do
    # Check if player is entering any area for the first time
    dungeon = socket.assigns.dungeon

    # Find which area the player is currently in
    current_area = Enum.find(dungeon.rooms, fn area -> player_in_area?(x, y, area) end)

    cond do
      # Player is not in any area, or the area doesn't have an area number (not a cavern area)
      current_area == nil or not String.starts_with?(current_area.number, "A") ->
        {false, "", ""}

      # Area has already been visited
      Map.get(socket.assigns, :area_descriptions, %{}) |> Map.get(current_area.number) != nil ->
        {false, "", ""}

      # No area label tile found
      is_nil(find_area_label_tile(dungeon.grid, current_area.number)) ->
        {false, "", ""}

      # Player is entering an area for the first time - trigger area dialog
      true ->
        area_tile = find_area_label_tile(dungeon.grid, current_area.number)
        RoomLabelSystem.handle_area_access(socket, area_tile, current_area.number)
    end
  end

  defp player_in_area?(x, y, area) do
    case area do
      # Cavern format with cells (areas use this format)
      %{cells: cells} ->
        {x, y} in cells

      # Traditional room format (not used for areas, but included for completeness)
      %{x: area_x, y: area_y, width: width, height: height} ->
        x >= area_x and x < area_x + width and
          y >= area_y and y < area_y + height

      # Fallback
      _ ->
        false
    end
  end

  defp find_area_label_tile(grid, area_number) do
    Enum.find_value(grid, fn {_pos, tile} ->
      case tile do
        {:area_label, ^area_number} -> tile
        _ -> nil
      end
    end)
  end

  defp update_socket_after_movement(socket, context) do
    {final_show_trap_dialog, final_trap_icon, final_trap_message, triggered_trap_position} =
      context.trap_dialog

    {show_encounter_dialog, encounter_icon, encounter_message, encounter_position} =
      context.encounter_dialog

    {show_treasure_dialog, treasure_icon, treasure_message, collected_treasure_position,
     gold_amount} =
      context.treasure_dialog

    {show_food_dialog, food_icon, food_message, collected_food_position, food_healing} =
      context.food_dialog

    {show_healing_potion_dialog, healing_potion_icon, healing_potion_message,
     collected_healing_potion_position, healing_potion_healing} =
      context.healing_potion_dialog

    {show_torch_dialog, torch_icon, torch_message, torch_position} = context.torch

    {show_special_feature_dialog, special_feature_icon, special_feature_message,
     discovered_feature_position} =
      context.special_feature

    {show_label_dialog, label_icon, label_message, discovered_label_position} =
      context.label

    # Handle quest item discovery (which may have updated the socket already)
    # Quest item data is always a 5-tuple: {show_dialog, icon, message, position, socket}
    {_show_quest_item_dialog, _quest_item_icon, _quest_item_message, _quest_item_position,
     _quest_socket} =
      context.quest_item

    # Room entry tracking removed - we now use existing room_descriptions to check first entry

    # Handle torch burn time
    # Torch burn time is no longer reset when collecting - we use torch count instead
    # Don't decrement torch for daylight themes (keep at 100)
    new_torch_time =
      if socket.assigns.dungeon.fog_type == "daylight" do
        # Keep torch at 100 for daylight themes
        100
      else
        max(0, socket.assigns.torch_burn_time - 1)
      end

    # Play chest opening sound when treasure dialog is shown
    socket =
      if show_treasure_dialog do
        Phoenix.LiveView.push_event(socket, "play_audio", %{sound: "chest_open"})
      else
        socket
      end

    socket =
      socket
      |> assign(:player_position, context.position)
      |> assign(:clicked_squares, context.clicked)
      |> assign(:revealed_squares, context.revealed)

    # Check for secret doors adjacent to new position
    socket = check_secret_doors_adjacent(socket, context.position)

    # Trigger smooth animation by updating visual position with a slight delay
    Process.send_after(self(), {:animate_player_to, context.position}, 50)

    # Check for stair dialog after player has moved to the position
    # Skip during pathfinding (like special features)
    socket =
      if should_show_stair_dialog?(socket, context.position, context.is_pathfinding) do
        # Send message to show stair dialog
        send(
          self(),
          {:show_stair_dialog_for_movement, context.position,
           Map.get(socket.assigns.dungeon.grid, context.position)}
        )

        socket
      else
        socket
      end

    # Check for waypoint dialog after player has moved to the position
    # Skip during pathfinding (like special features)
    socket =
      if should_show_waypoint_dialog?(socket, context.position, context.is_pathfinding) do
        # Send message to show waypoint dialog
        send(
          self(),
          {:show_waypoint_dialog_for_movement, context.position,
           Map.get(socket.assigns.dungeon.grid, context.position)}
        )

        socket
      else
        socket
      end

    # Check for map link dialog after player has moved to the position
    # Skip during pathfinding (like special features)
    socket =
      if should_show_map_link_dialog?(socket, context.position, context.is_pathfinding) do
        # Send message to show map link dialog
        send(
          self(),
          {:show_map_link_dialog_for_movement, context.position,
           Map.get(socket.assigns.dungeon.grid, context.position)}
        )

        socket
      else
        socket
      end

    socket =
      socket
      |> assign(:player_trapped, context.player_trapped)
      |> assign(:sprung_traps, context.sprung_traps)
      |> assign(:show_trap_dialog, final_show_trap_dialog)
      |> assign(:trap_icon, final_trap_icon)
      |> assign(:trap_message, final_trap_message)
      |> assign(:triggered_trap_position, triggered_trap_position)
      |> assign(:triggered_encounters, context.triggered_encounters)
      |> assign(:show_encounter_dialog, show_encounter_dialog)
      |> assign(:encounter_icon, encounter_icon)
      |> assign(:encounter_message, encounter_message)
      |> assign(:current_encounter_position, encounter_position)
      |> assign(:show_treasure_dialog, show_treasure_dialog)
      |> assign(:treasure_icon, treasure_icon)
      |> assign(:treasure_message, treasure_message)
      |> assign(:collected_treasure_position, collected_treasure_position)
      |> assign(:collected_treasure_gold, gold_amount)
      |> assign(:show_food_dialog, show_food_dialog)
      |> assign(:food_icon, food_icon)
      |> assign(:food_message, food_message)
      |> assign(:collected_food_position, collected_food_position)
      |> assign(:collected_food_healing, food_healing)
      |> assign(:show_healing_potion_dialog, show_healing_potion_dialog)
      |> assign(:healing_potion_icon, healing_potion_icon)
      |> assign(:healing_potion_message, healing_potion_message)
      |> assign(:collected_healing_potion_position, collected_healing_potion_position)
      |> assign(:collected_healing_potion_healing, healing_potion_healing)
      |> assign(:show_torch_dialog, show_torch_dialog)
      |> assign(:torch_icon, torch_icon)
      |> assign(:torch_message, torch_message)
      |> assign(:torch_position, torch_position)
      |> assign(:torch_burn_time, new_torch_time)
      |> assign(:show_special_feature_dialog, show_special_feature_dialog)
      |> assign(:special_feature_icon, special_feature_icon)
      |> assign(:special_feature_message, special_feature_message)
      |> assign(:discovered_feature_position, discovered_feature_position)
      |> assign(:show_label_dialog, show_label_dialog)
      |> assign(:label_icon, label_icon)
      |> assign(:label_message, label_message)
      |> assign(:discovered_label_position, discovered_label_position)
      |> assign(:dungeon, context.updated_grid)

    # If torch goes out, reset fog automatically (but not for daylight themes)
    if new_torch_time == 0 and socket.assigns.dungeon.fog_type != "daylight" do
      send(self(), :torch_expired)
    end

    socket
  end

  defp find_adjacent_room_traps({player_x, player_y}, dungeon, revealed_squares) do
    # Check all 8 adjacent squares for room traps
    adjacent_offsets = [
      {-1, -1},
      {0, -1},
      {1, -1},
      {-1, 0},
      {1, 0},
      {-1, 1},
      {0, 1},
      {1, 1}
    ]

    for {dx, dy} <- adjacent_offsets,
        trap_x = player_x + dx,
        trap_y = player_y + dy,
        # Only check revealed squares
        MapSet.member?(revealed_squares, {trap_x, trap_y}),
        # Only check for room traps (skull traps)
        Map.get(dungeon.grid, {trap_x, trap_y}) == :room_trap,
        do: {trap_x, trap_y}
  end

  defp should_show_stair_dialog?(socket, {x, y}, is_pathfinding) do
    dungeon = socket.assigns.dungeon
    tile = Map.get(dungeon.grid, {x, y})

    # Check if it's a stair (excluding starting stairs) and no other dialogs are showing
    # Skip during pathfinding (like special features)
    stair_tile = tile in [:stair_up, :stair_down]
    no_other_dialogs = not any_dialog_showing?(socket)
    not_pathfinding = not is_pathfinding

    stair_tile and no_other_dialogs and not_pathfinding
  end

  defp should_show_waypoint_dialog?(socket, {x, y}, is_pathfinding) do
    dungeon = socket.assigns.dungeon
    tile = Map.get(dungeon.grid, {x, y})

    # Check if it's a waypoint (excluding starting waypoints) and no other dialogs are showing
    # Skip during pathfinding (like special features)
    waypoint_tile = match?({:waypoint, _}, tile)
    no_other_dialogs = not any_dialog_showing?(socket)
    not_pathfinding = not is_pathfinding

    waypoint_tile and no_other_dialogs and not_pathfinding
  end

  defp should_show_map_link_dialog?(socket, {x, y}, is_pathfinding) do
    dungeon = socket.assigns.dungeon
    tile = Map.get(dungeon.grid, {x, y})

    # Check if it's a map link and no other dialogs are showing
    # Skip during pathfinding (like special features)
    map_link_tile =
      match?({:cavern_entrance, _}, tile) or
        match?({:dungeon_entrance, _}, tile) or
        match?({:cavern_exit, _}, tile) or
        match?({:dungeon_exit, _}, tile)

    no_other_dialogs = not any_dialog_showing?(socket)
    not_pathfinding = not is_pathfinding

    map_link_tile and no_other_dialogs and not_pathfinding
  end

  defp any_dialog_showing?(socket) do
    interaction_dialogs_showing?(socket) or
      item_dialogs_showing?(socket) or
      navigation_dialogs_showing?(socket)
  end

  defp interaction_dialogs_showing?(socket) do
    socket.assigns.show_trap_dialog or
      socket.assigns.show_encounter_dialog or
      socket.assigns.show_npc_dialog or
      socket.assigns.show_special_feature_dialog or
      socket.assigns.show_label_dialog
  end

  defp item_dialogs_showing?(socket) do
    socket.assigns.show_treasure_dialog or
      socket.assigns.show_food_dialog or
      socket.assigns.show_healing_potion_dialog or
      socket.assigns.show_torch_dialog
  end

  defp navigation_dialogs_showing?(socket) do
    socket.assigns.show_stair_dialog or
      socket.assigns.show_waypoint_dialog or
      socket.assigns.show_map_link_dialog or
      socket.assigns.show_secret_door_dialog
  end

  defp assign(socket, key, value) do
    Phoenix.Component.assign(socket, key, value)
  end
end
