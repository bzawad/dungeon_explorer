defmodule DungeonWeb.DungeonLive do
  use DungeonWeb, :live_view

  require Logger

  alias DungeonWeb.DungeonLive.{
    CombatSystem,
    DoorSystem,
    EncounterSystem,
    FogOfWar,
    FoodSystem,
    MapTemplate,
    MapTransitionSystem,
    MonsterTurnSystem,
    Movement,
    NpcQuestSystem,
    QuestItemSystem,
    RoomLabelSystem,
    SpecialFeatureSystem,
    TrapSystem,
    TreasureSystem,
    WanderingMonsterSystem
  }

  alias Dungeon.{Dice, Generator, PlayerStats}
  alias Dungeon.Generator.Grid
  alias Dungeon.Services.DescriptionService

  def mount(_params, _session, socket) do
    # Get starting player level
    player_level = PlayerStats.starting_level()

    # Generate dungeon with player level consideration
    dungeon = Generator.generate_with_player_level(player_level, 1)

    # Find starting position (where the starting staircase is)
    player_position = Movement.find_starting_position(dungeon)

    # Initialize revealed squares (including light areas)
    final_revealed = FogOfWar.initialize_revealed_with_light(dungeon, player_position)

    socket =
      socket
      |> assign(:dungeon, dungeon)
      |> assign(:revealed_squares, final_revealed)
      |> assign(:clicked_squares, MapSet.new())
      |> assign(:fog_enabled, true)
      |> assign(:player_position, player_position)
      |> assign(:player_trapped, false)
      |> assign(:sprung_traps, MapSet.new())
      |> assign(:unlocked_doors, MapSet.new())
      |> assign(:revealed_secret_doors, MapSet.new())
      |> assign(:unpickable_doors, MapSet.new())
      |> assign(:show_unlock_dialog, false)
      |> assign(:selected_door, nil)
      |> assign(:show_lock_pick_result_dialog, false)
      |> assign(:lock_pick_success, false)
      |> assign(:lock_pick_roll, 0)
      |> assign(:lock_pick_d20_roll, 0)
      |> assign(:lock_pick_dex_bonus, 0)
      |> assign(:show_trap_dialog, false)
      |> assign(:trap_icon, "")
      |> assign(:trap_message, "")
      |> assign(:triggered_trap_position, nil)
      |> assign(:triggered_encounters, MapSet.new())
      |> assign(:show_encounter_dialog, false)
      |> assign(:encounter_icon, "")
      |> assign(:encounter_message, "")
      |> assign(:current_encounter_position, nil)
      |> assign(:show_npc_dialog, false)
      |> assign(:npc_dialog_icon, "")
      |> assign(:npc_dialog_message, "")
      |> assign(:show_evade_dialog, false)
      |> assign(:evade_success, false)
      |> assign(:evade_roll, 0)
      |> assign(:evade_message, "")
      |> assign(:show_treasure_dialog, false)
      |> assign(:treasure_icon, "")
      |> assign(:treasure_message, "")
      |> assign(:collected_treasure_position, nil)
      |> assign(:show_special_feature_dialog, false)
      |> assign(:special_feature_icon, "")
      |> assign(:special_feature_message, "")
      |> assign(:discovered_features, MapSet.new())
      |> assign(:investigated_features, MapSet.new())
      |> assign(:discovered_feature_position, nil)
      |> assign(:show_label_dialog, false)
      |> assign(:label_icon, "")
      |> assign(:label_message, "")
      |> assign(:discovered_labels, MapSet.new())
      |> assign(:discovered_label_position, nil)
      |> assign(:dungeon_level, 1)
      |> assign(:room_descriptions, %{})
      |> assign(:door_descriptions, %{})
      |> assign(:door_description, nil)
      |> assign(:corridor_descriptions, %{})
      |> assign(:feature_descriptions, %{})
      |> assign(:rooms_entered_count, 0)
      |> assign(:previous_room, nil)
      |> assign(:last_room_for_corridor_context, nil)
      |> assign(:show_open_door_dialog, false)
      |> assign(:selected_open_door, nil)
      |> assign(:open_door_description, nil)
      |> assign(:door_trap_descriptions, %{})
      |> assign(:room_trap_descriptions, %{})
      |> assign(:treasure_descriptions, %{})
      |> assign(:treasure_trap_descriptions, %{})
      |> assign(:show_rumor_dialog, false)
      |> assign(:rumor_icon, "")
      |> assign(:rumor_message, "")
      |> assign(:show_achievement_dialog, false)
      |> assign(:achievement_icon, "")
      |> assign(:achievement_message, "")
      |> assign(:rumors, [])
      |> assign(:show_rumors_list_dialog, false)
      |> assign(:show_special_item_dialog, false)
      |> assign(:special_item_icon, "")
      |> assign(:special_item_message, "")
      |> assign(:special_items, [])
      |> assign(:show_special_items_list_dialog, false)
      |> assign(:current_room_description, nil)
      |> assign(:previous_room_description, nil)
      |> assign(:current_area_description, nil)
      |> assign(:previous_area_description, nil)
      |> assign(:area_descriptions, %{})
      |> assign(:building_descriptions, %{})
      |> assign(:special_item_descriptions, %{})
      |> assign(:quests, [])
      |> assign(:achievements, [])
      |> assign(:show_achievements_list_dialog, false)
      |> assign(:show_quest_completed_dialog, false)
      |> assign(:show_game_controls, false)
      |> assign(:show_map_mobile, true)
      |> assign(:completed_quest, nil)
      |> assign(:quest_completion_xp, 0)
      |> assign(:completed_quest_item_position, nil)
      |> assign(:viewport_x, 0)
      |> assign(:viewport_y, 0)
      |> assign(:viewport_width, 40)
      |> assign(:viewport_height, 30)
      |> assign(:zoom_level, :normal)
      |> assign(:player_gold, PlayerStats.player_gold())
      |> assign(:player_xp, 0)
      |> assign(:player_level, PlayerStats.starting_level())
      |> assign(:talent_bonuses, PlayerStats.default_talents())
      |> assign(:level_hit_points, 0)
      |> assign(:player_hit_points, PlayerStats.player_hit_points())
      |> assign(:max_hit_points, PlayerStats.max_hit_points())
      |> assign(:player_weapon, PlayerStats.base_player_weapon())
      |> assign(:weapon_damage_dice, PlayerStats.base_weapon_damage_dice())
      |> assign(:attack_bonus, PlayerStats.base_attack_bonus())
      |> assign(:dexterity_bonus, PlayerStats.base_dexterity_bonus())
      |> assign(:armor_bonus, PlayerStats.base_armor_bonus())
      |> assign(:armor_class, PlayerStats.armor_class())
      |> assign(:show_level_up_dialog, false)
      |> assign(:level_up_message, "")
      |> assign(:talent_gained, "")
      |> assign(
        :torch_burn_time,
        if(dungeon.fog_type == "daylight", do: 100, else: PlayerStats.torch_burn_time())
      )
      |> assign(:torch_count, 1)
      |> assign(:healing_potion_count, 0)
      |> assign(:show_death_dialog, false)
      |> assign(:show_revival_dialog, false)
      |> assign(:player_dead, false)
      |> assign(:show_stair_dialog, false)
      |> assign(:selected_stair, nil)
      |> assign(:stair_description, nil)
      |> assign(:stair_descriptions, %{})
      |> assign(:show_waypoint_dialog, false)
      |> assign(:selected_waypoint, nil)
      |> assign(:waypoint_description, nil)
      |> assign(:waypoint_descriptions, %{})
      |> assign(:show_secret_door_dialog, false)
      |> assign(:selected_secret_door, nil)
      |> assign(:show_map_link_dialog, false)
      |> assign(:selected_map_link, nil)
      |> assign(:map_link_description, nil)
      |> assign(:map_link_descriptions, %{})
      |> assign(:show_torch_dialog, false)
      |> assign(:torch_icon, "")
      |> assign(:torch_message, "")
      |> assign(:torch_position, nil)
      |> assign(:show_food_dialog, false)
      |> assign(:food_icon, "")
      |> assign(:food_message, "")
      |> assign(:collected_food_position, nil)
      |> assign(:collected_food_healing, 0)
      |> assign(:show_healing_potion_dialog, false)
      |> assign(:healing_potion_icon, "")
      |> assign(:healing_potion_message, "")
      |> assign(:collected_healing_potion_position, nil)
      |> assign(:collected_healing_potion_healing, 0)
      |> assign(:show_trap_detection_dialog, false)
      |> assign(:trap_detection_message, "")
      |> assign(:detected_trap_position, nil)
      |> assign(:detected_trap_type, nil)
      |> assign(:pending_trap_action, nil)
      |> assign(:trap_detection_success, nil)
      |> assign(:trap_detection_roll, nil)
      |> assign(:show_combat_dialog, false)
      |> assign(:combat_monster, nil)
      |> assign(:combat_current_turn, nil)
      |> assign(:combat_round, 0)
      |> assign(:combat_log, [])
      |> assign(:combat_current_event, "")
      |> assign(:combat_awaiting_player_action, false)
      |> assign(:combat_player_has_acted, false)
      |> assign(:combat_monster_has_acted, false)
      |> assign(:combat_player_attacking, false)
      |> assign(:combat_monster_attacking, false)
      |> assign(:combat_player_taking_damage, false)
      |> assign(:combat_monster_taking_damage, false)
      |> assign(:show_victory_dialog, false)
      |> assign(:victory_treasure_gold, 0)
      # Wandering monster system
      |> assign(:show_wandering_monster_dialog, false)
      |> assign(:wandering_monster, nil)
      |> assign(:wandering_monster_icon, "")
      |> assign(:wandering_monster_message, "")
      |> assign(:show_wandering_evade_dialog, false)
      |> assign(:wandering_evade_success, false)
      |> assign(:wandering_evade_roll, 0)
      |> assign(:wandering_evade_message, "")
      # Break door system
      |> assign(:show_break_door_result_dialog, false)
      |> assign(:break_door_success, false)
      |> assign(:break_door_roll, 0)
      # Will be updated when client connects
      |> assign(:screen_size, :unknown)
      |> assign(:player_facing, :right)
      # For smooth animation
      |> assign(:player_visual_position, player_position)
      # Monster visual positions for animation
      |> assign(:monster_visual_positions, %{})
      # Background music tracking
      |> assign(:background_music_played, false)
      # Guard system tracking
      |> assign(:guards_hostile, false)
      |> assign(:doors_broken_count, 0)
      |> assign(:npcs_killed_count, 0)
      |> assign(:player_alignment, PlayerStats.starting_alignment())
      |> NpcQuestSystem.initialize_quest_assigns()
      |> update_viewport_for_player(player_position)

    {:ok, socket}
  end

  def handle_event("toggle_fog", _params, socket) do
    {:noreply, assign(socket, :fog_enabled, !socket.assigns.fog_enabled)}
  end

  def handle_event("toggle_game_controls", _params, socket) do
    {:noreply, assign(socket, :show_game_controls, !socket.assigns.show_game_controls)}
  end

  def handle_event("toggle_map_mobile", _params, socket) do
    {:noreply, assign(socket, :show_map_mobile, !socket.assigns.show_map_mobile)}
  end

  def handle_event("generate_new", _params, socket) do
    dungeon = Generator.generate()

    # Spawn quest items for any matching active quests
    dungeon = QuestItemSystem.spawn_quest_items(socket, dungeon)

    # Spawn quest monsters for any matching active NPC quests
    socket_with_dungeon = %{
      socket
      | assigns: Map.merge(socket.assigns, %{dungeon: dungeon, dungeon_level: 1})
    }

    socket_with_dungeon =
      NpcQuestSystem.spawn_quest_monsters_for_theme(
        socket_with_dungeon,
        dungeon.theme
      )

    dungeon = socket_with_dungeon.assigns.dungeon

    player_position = Movement.find_starting_position(dungeon)

    # Initialize revealed squares (including light areas)
    final_revealed = FogOfWar.initialize_revealed_with_light(dungeon, player_position)

    socket =
      socket
      |> assign(:dungeon, dungeon)
      |> assign(:revealed_squares, final_revealed)
      |> assign(:clicked_squares, MapSet.new())
      |> assign(:fog_enabled, true)
      |> assign(:player_position, player_position)
      |> assign(:player_trapped, false)
      |> assign(:sprung_traps, MapSet.new())
      |> assign(:unlocked_doors, MapSet.new())
      |> assign(:revealed_secret_doors, MapSet.new())
      |> assign(:unpickable_doors, MapSet.new())
      |> assign(:show_unlock_dialog, false)
      |> assign(:selected_door, nil)
      |> assign(:show_lock_pick_result_dialog, false)
      |> assign(:lock_pick_success, false)
      |> assign(:lock_pick_roll, 0)
      |> assign(:lock_pick_d20_roll, 0)
      |> assign(:lock_pick_dex_bonus, 0)
      |> assign(:show_trap_dialog, false)
      |> assign(:trap_icon, "")
      |> assign(:trap_message, "")
      |> assign(:triggered_trap_position, nil)
      |> assign(:trap_damage, 0)
      |> assign(:triggered_encounters, MapSet.new())
      |> assign(:show_encounter_dialog, false)
      |> assign(:encounter_icon, "")
      |> assign(:encounter_message, "")
      |> assign(:show_treasure_dialog, false)
      |> assign(:treasure_icon, "")
      |> assign(:treasure_message, "")
      |> assign(:collected_treasure_position, nil)
      |> assign(:show_food_dialog, false)
      |> assign(:food_icon, "")
      |> assign(:food_message, "")
      |> assign(:collected_food_position, nil)
      |> assign(:collected_food_healing, 0)
      |> assign(:show_special_feature_dialog, false)
      |> assign(:special_feature_icon, "")
      |> assign(:special_feature_message, "")
      |> assign(:discovered_features, MapSet.new())
      |> assign(:investigated_features, MapSet.new())
      |> assign(:discovered_feature_position, nil)
      |> assign(:show_label_dialog, false)
      |> assign(:label_icon, "")
      |> assign(:label_message, "")
      |> assign(:discovered_labels, MapSet.new())
      |> assign(:discovered_label_position, nil)
      |> assign(:dungeon_level, 1)
      |> assign(:room_descriptions, %{})
      |> assign(:door_descriptions, %{})
      |> assign(:door_description, nil)
      |> assign(:corridor_descriptions, %{})
      |> assign(:feature_descriptions, %{})
      |> assign(:rooms_entered_count, 0)
      |> assign(:previous_room, nil)
      |> assign(:last_room_for_corridor_context, nil)
      |> assign(:show_open_door_dialog, false)
      |> assign(:selected_open_door, nil)
      |> assign(:open_door_description, nil)
      |> assign(:door_trap_descriptions, %{})
      |> assign(:room_trap_descriptions, %{})
      |> assign(:treasure_descriptions, %{})
      |> assign(:treasure_trap_descriptions, %{})
      |> assign(:show_rumor_dialog, false)
      |> assign(:rumor_icon, "")
      |> assign(:rumor_message, "")
      |> assign(:show_achievement_dialog, false)
      |> assign(:achievement_icon, "")
      |> assign(:achievement_message, "")
      |> assign(:rumors, [])
      |> assign(:show_rumors_list_dialog, false)
      |> assign(:show_special_item_dialog, false)
      |> assign(:special_item_icon, "")
      |> assign(:special_item_message, "")
      |> assign(:special_items, [])
      |> assign(:show_special_items_list_dialog, false)
      |> assign(:current_room_description, nil)
      |> assign(:previous_room_description, nil)
      |> assign(:current_area_description, nil)
      |> assign(:previous_area_description, nil)
      |> assign(:area_descriptions, %{})
      |> assign(:special_item_descriptions, %{})
      |> assign(:quests, [])
      |> assign(:achievements, [])
      |> assign(:show_quest_completed_dialog, false)
      |> assign(:completed_quest, nil)
      |> assign(:quest_completion_xp, 0)
      |> assign(:player_gold, PlayerStats.player_gold())
      |> assign(:player_xp, 0)
      |> assign(:player_level, PlayerStats.starting_level())
      |> assign(:talent_bonuses, PlayerStats.default_talents())
      |> assign(:level_hit_points, 0)
      |> assign(:player_hit_points, PlayerStats.player_hit_points())
      |> assign(:max_hit_points, PlayerStats.max_hit_points())
      |> assign(:player_weapon, PlayerStats.base_player_weapon())
      |> assign(:weapon_damage_dice, PlayerStats.base_weapon_damage_dice())
      |> assign(
        :torch_burn_time,
        if(dungeon.fog_type == "daylight", do: 100, else: PlayerStats.torch_burn_time())
      )
      |> assign(:torch_count, 1)
      |> assign(:healing_potion_count, 0)
      |> assign(:show_death_dialog, false)
      |> assign(:show_revival_dialog, false)
      |> assign(:player_dead, false)
      |> assign(:show_stair_dialog, false)
      |> assign(:selected_stair, nil)
      |> assign(:stair_description, nil)
      |> assign(:stair_descriptions, %{})
      |> assign(:show_waypoint_dialog, false)
      |> assign(:selected_waypoint, nil)
      |> assign(:waypoint_description, nil)
      |> assign(:waypoint_descriptions, %{})
      |> assign(:show_secret_door_dialog, false)
      |> assign(:selected_secret_door, nil)
      |> assign(:show_map_link_dialog, false)
      |> assign(:selected_map_link, nil)
      |> assign(:map_link_description, nil)
      |> assign(:map_link_descriptions, %{})
      |> assign(:show_trap_detection_dialog, false)
      |> assign(:trap_detection_message, "")
      |> assign(:detected_trap_position, nil)
      |> assign(:detected_trap_type, nil)
      |> assign(:pending_trap_action, nil)
      |> assign(:show_combat_dialog, false)
      |> assign(:combat_monster, nil)
      |> assign(:combat_current_turn, nil)
      |> assign(:combat_round, 0)
      |> assign(:combat_log, [])
      |> assign(:combat_current_event, "")
      |> assign(:combat_awaiting_player_action, false)
      |> assign(:combat_player_has_acted, false)
      |> assign(:combat_monster_has_acted, false)
      |> assign(:combat_player_attacking, false)
      |> assign(:combat_monster_attacking, false)
      |> assign(:combat_player_taking_damage, false)
      |> assign(:combat_monster_taking_damage, false)
      |> assign(:show_victory_dialog, false)
      |> assign(:victory_treasure_gold, 0)
      # Wandering monster system
      |> assign(:show_wandering_monster_dialog, false)
      |> assign(:wandering_monster, nil)
      |> assign(:wandering_monster_icon, "")
      |> assign(:wandering_monster_message, "")
      |> assign(:show_wandering_evade_dialog, false)
      |> assign(:wandering_evade_success, false)
      |> assign(:wandering_evade_roll, 0)
      |> assign(:wandering_evade_message, "")
      # Break door system
      |> assign(:show_break_door_result_dialog, false)
      |> assign(:break_door_success, false)
      |> assign(:break_door_roll, 0)
      |> assign(:attack_bonus, PlayerStats.base_attack_bonus())
      |> assign(:dexterity_bonus, PlayerStats.base_dexterity_bonus())
      |> assign(:armor_bonus, PlayerStats.base_armor_bonus())
      |> assign(:armor_class, PlayerStats.armor_class())
      |> assign(:player_facing, :right)
      # For smooth animation
      |> assign(:player_visual_position, player_position)
      # Monster visual positions for animation
      |> assign(:monster_visual_positions, %{})
      # Reset background music for new level
      |> assign(:background_music_played, false)
      # Reset guard system for new level
      |> assign(:guards_hostile, false)
      |> assign(:doors_broken_count, 0)
      |> assign(:npcs_killed_count, 0)
      |> assign(:player_alignment, PlayerStats.starting_alignment())
      |> assign(:npc_quests, [])
      |> assign(:active_quest_monsters, [])
      |> assign(:active_quest_npcs, [])
      |> assign(:killed_quest_monsters, [])
      |> assign(:killed_quest_npcs, [])
      |> assign(:show_quest_offer_dialog, false)
      |> assign(:quest_offer_icon, "")
      |> assign(:quest_offer_message, "")
      |> assign(:offered_quest, nil)
      |> Phoenix.LiveView.push_event("stop_background_music", %{})
      |> update_viewport_for_player(player_position)
      |> update_pathfinding_data()

    {:noreply, socket}
  end

  # Handle screen size detection for responsive viewport
  def handle_event("screen_size", %{"width" => width}, socket) when is_integer(width) do
    # Use mobile viewport for screens smaller than 1024px (lg breakpoint)
    zoom_level = if width < 1024, do: :mobile, else: :normal
    screen_size = if width < 1024, do: :mobile, else: :desktop

    socket =
      socket
      |> assign(:zoom_level, zoom_level)
      |> assign(:screen_size, screen_size)
      |> update_viewport_for_player(socket.assigns.player_position)

    {:noreply, socket}
  end

  def handle_event("screen_size", %{"width" => width}, socket) when is_binary(width) do
    case Integer.parse(width) do
      {width_int, _} -> handle_event("screen_size", %{"width" => width_int}, socket)
      :error -> {:noreply, socket}
    end
  end

  def handle_event("move_viewport", %{"direction" => direction}, socket) do
    {dx, dy} =
      case direction do
        "up" -> {0, -5}
        "down" -> {0, 5}
        "left" -> {-5, 0}
        "right" -> {5, 0}
        _ -> {0, 0}
      end

    dungeon = socket.assigns.dungeon

    new_x =
      max(0, min(socket.assigns.viewport_x + dx, dungeon.width - socket.assigns.viewport_width))

    new_y =
      max(0, min(socket.assigns.viewport_y + dy, dungeon.height - socket.assigns.viewport_height))

    socket =
      socket
      |> assign(:viewport_x, new_x)
      |> assign(:viewport_y, new_y)

    {:noreply, socket}
  end

  def handle_event("move_player_mobile", %{"direction" => direction}, socket) do
    # Block movement if any dialog is open or player is dead
    if any_dialog_open?(socket) or socket.assigns.player_dead do
      {:noreply, socket}
    else
      {dx, dy} =
        case direction do
          "up" -> {0, -1}
          "down" -> {0, 1}
          "left" -> {-1, 0}
          "right" -> {1, 0}
          _ -> {0, 0}
        end

      {:noreply, new_socket} = Movement.move_player_direction(socket, {dx, dy})

      # Process monster turns after player movement
      new_socket = MonsterTurnSystem.process_monster_turns(new_socket)

      handle_movement_animation(socket, new_socket)
    end
  end

  def handle_event("center_on_player", _params, socket) do
    socket = update_viewport_for_player(socket, socket.assigns.player_position)
    {:noreply, socket}
  end

  def handle_event("toggle_game_menu", _params, socket) do
    show_menu = !Map.get(socket.assigns, :show_game_menu, true)
    {:noreply, assign(socket, :show_game_menu, show_menu)}
  end

  def handle_event("keydown", %{"key" => key} = params, socket) do
    # OS key repeat sends extra keydown events while a key is held; ignore those so one step
    # per physical press (combine with tap-to-move or later hold-to-step UX if desired).
    if params["repeat"] == true do
      {:noreply, socket}
    else
      # Block movement if any dialog is open or player is dead
      if any_dialog_open?(socket) or socket.assigns.player_dead do
        {:noreply, socket}
      else
        case Movement.key_to_direction(key) do
          {dx, dy} ->
            # Interrupt any pathfinding movement when WASD is used
            socket = Phoenix.LiveView.push_event(socket, "movement_interrupted", %{})

            {:noreply, new_socket} = Movement.move_player_direction(socket, {dx, dy})

            # Process monster turns after player movement
            new_socket = MonsterTurnSystem.process_monster_turns(new_socket)

            handle_movement_animation(socket, new_socket)

          nil ->
            {:noreply, socket}
        end
      end
    end
  end

  def handle_event("move_player", %{"x" => x_str, "y" => y_str} = params, socket) do
    # Block movement if any dialog is open
    if any_dialog_open?(socket) do
      {:noreply, socket}
    else
      x = String.to_integer(x_str)
      y = String.to_integer(y_str)

      # Check if this is part of a pathfinding sequence
      is_pathfinding = Map.get(params, "pathfinding", false)

      # Update facing direction based on clicked position relative to current position
      {player_x, player_y} = socket.assigns.player_position
      dx = x - player_x
      dy = y - player_y
      new_facing = Movement.update_facing_direction(socket.assigns.player_facing, {dx, dy})
      socket = assign(socket, :player_facing, new_facing)

      {:noreply, new_socket} =
        Movement.move_player_to_position(socket, {x, y}, pathfinding: is_pathfinding)

      # Update pathfinding data after movement
      new_socket = update_pathfinding_data(new_socket)

      # Process monster turns after player movement
      new_socket = MonsterTurnSystem.process_monster_turns(new_socket)

      handle_movement_animation(socket, new_socket)
    end
  end

  def handle_event("click_door", %{"x" => x_str, "y" => y_str}, socket) do
    DoorSystem.handle_door_click(socket, x_str, y_str)
  end

  def handle_event("click_stair", %{"x" => x_str, "y" => y_str}, socket) do
    x = String.to_integer(x_str)
    y = String.to_integer(y_str)
    position = {x, y}

    case can_interact_with_stair?(socket, position) do
      true -> process_stair_click(socket, position)
      false -> {:noreply, socket}
    end
  end

  def handle_event("click_waypoint", %{"x" => x_str, "y" => y_str}, socket) do
    x = String.to_integer(x_str)
    y = String.to_integer(y_str)
    position = {x, y}

    case can_interact_with_waypoint?(socket, position) do
      true -> process_waypoint_click(socket, position)
      false -> {:noreply, socket}
    end
  end

  def handle_event("pick_lock", _params, socket) do
    DoorSystem.pick_lock(socket)
  end

  def handle_event("cancel_unlock", _params, socket) do
    DoorSystem.cancel_unlock(socket)
  end

  def handle_event("dismiss_lock_pick_result", _params, socket) do
    DoorSystem.dismiss_lock_pick_result(socket)
  end

  def handle_event("break_door", _params, socket) do
    DoorSystem.break_door(socket)
  end

  def handle_event("dismiss_break_door_result", _params, socket) do
    DoorSystem.dismiss_break_door_result(socket)
  end

  def handle_event("enter_door", _params, socket) do
    DoorSystem.enter_door(socket)
  end

  def handle_event("cancel_open_door", _params, socket) do
    DoorSystem.cancel_open_door(socket)
  end

  def handle_event("use_stair", _params, socket) do
    case socket.assigns.selected_stair do
      {_x, _y} ->
        # Play stairs sound when using stairs (starting stairs don't use this event)
        socket = Phoenix.LiveView.push_event(socket, "play_audio", %{sound: "stairs"})

        # Close the dialog first
        socket =
          socket
          |> assign(:show_stair_dialog, false)
          |> assign(:selected_stair, nil)
          |> assign(:stair_description, nil)

        # Generate new dungeon for the same theme but increment level
        {updated_socket, transition_data} = MapTransitionSystem.generate_new_level(socket)

        # Apply transition data using proper assign/3 calls
        final_socket =
          updated_socket
          |> assign(:dungeon, transition_data.dungeon)
          |> assign(:player_position, transition_data.player_position)
          |> assign(:dungeon_level, transition_data.dungeon_level)
          |> assign(:revealed_squares, transition_data.revealed_squares)
          |> assign(:viewport_x, transition_data.viewport_x)
          |> assign(:viewport_y, transition_data.viewport_y)
          |> assign(:viewport_width, transition_data.viewport_width)
          |> assign(:viewport_height, transition_data.viewport_height)
          |> assign(:clicked_squares, MapSet.new())
          |> assign(:fog_enabled, true)
          |> assign(:player_trapped, false)
          |> assign(:sprung_traps, MapSet.new())
          |> assign(:unlocked_doors, MapSet.new())
          |> assign(:unpickable_doors, MapSet.new())
          |> assign(:triggered_encounters, MapSet.new())
          |> assign(:discovered_features, MapSet.new())
          |> assign(:investigated_features, MapSet.new())
          |> assign(:discovered_labels, MapSet.new())
          |> assign(:room_descriptions, %{})
          |> assign(:door_descriptions, %{})
          |> assign(:corridor_descriptions, %{})
          |> assign(:feature_descriptions, %{})
          |> assign(:door_trap_descriptions, %{})
          |> assign(:room_trap_descriptions, %{})
          |> assign(:treasure_descriptions, %{})
          |> assign(:treasure_trap_descriptions, %{})
          |> assign(:stair_descriptions, %{})
          |> assign(:waypoint_descriptions, %{})
          |> assign(:map_link_descriptions, %{})
          |> assign(:area_descriptions, %{})
          |> assign(:special_item_descriptions, %{})
          |> assign(:rooms_entered_count, 0)
          |> assign(:previous_room, nil)
          |> assign(:last_room_for_corridor_context, nil)
          |> assign(:current_room_description, nil)
          |> assign(:previous_room_description, nil)
          |> assign(:current_area_description, nil)
          |> assign(:previous_area_description, nil)
          |> assign(:player_facing, :right)
          |> assign(:player_visual_position, transition_data.player_position)
          |> assign(:background_music_played, false)
          |> update_pathfinding_data()

        {:noreply, final_socket}

      nil ->
        {:noreply, socket}
    end
  end

  def handle_event("cancel_stair", _params, socket) do
    socket =
      socket
      |> assign(:show_stair_dialog, false)
      |> assign(:selected_stair, nil)
      |> assign(:stair_description, nil)

    {:noreply, socket}
  end

  def handle_event("use_waypoint", _params, socket) do
    case socket.assigns.selected_waypoint do
      {_x, _y} = _position ->
        # In cities or outdoor maps, waypoints link to a different theme without level increase.
        # In other areas (dungeons, caverns), they link to the next level of the same theme.
        {updated_socket, transition_data} =
          case socket.assigns.dungeon.generation_type do
            "city" ->
              MapTransitionSystem.generate_new_level_from_waypoint_destination(socket)

            "outdoor" ->
              MapTransitionSystem.generate_new_level_from_waypoint_destination(socket)

            _ ->
              MapTransitionSystem.generate_new_level(socket)
          end

        # Close the dialog after successful transition
        updated_socket =
          updated_socket
          |> assign(:show_waypoint_dialog, false)
          |> assign(:selected_waypoint, nil)
          |> assign(:waypoint_description, nil)

        final_socket =
          case transition_data do
            %{
              dungeon: dungeon,
              player_position: player_position,
              dungeon_level: dungeon_level,
              revealed_squares: revealed_squares,
              viewport_x: viewport_x,
              viewport_y: viewport_y,
              viewport_width: viewport_width,
              viewport_height: viewport_height,
              reset_state: true
            } ->
              # Apply transition data using proper assign/3 calls
              updated_socket
              |> assign(:dungeon, dungeon)
              |> assign(:player_position, player_position)
              |> assign(:dungeon_level, dungeon_level)
              |> assign(:revealed_squares, revealed_squares)
              |> assign(:viewport_x, viewport_x)
              |> assign(:viewport_y, viewport_y)
              |> assign(:viewport_width, viewport_width)
              |> assign(:viewport_height, viewport_height)
              |> assign(:clicked_squares, MapSet.new())
              |> assign(:fog_enabled, true)
              |> assign(:player_trapped, false)
              |> assign(:sprung_traps, MapSet.new())
              |> assign(:unlocked_doors, MapSet.new())
              |> assign(:unpickable_doors, MapSet.new())
              |> assign(:triggered_encounters, MapSet.new())
              |> assign(:discovered_features, MapSet.new())
              |> assign(:investigated_features, MapSet.new())
              |> assign(:discovered_labels, MapSet.new())
              |> assign(:room_descriptions, %{})
              |> assign(:door_descriptions, %{})
              |> assign(:corridor_descriptions, %{})
              |> assign(:feature_descriptions, %{})
              |> assign(:door_trap_descriptions, %{})
              |> assign(:room_trap_descriptions, %{})
              |> assign(:treasure_descriptions, %{})
              |> assign(:treasure_trap_descriptions, %{})
              |> assign(:stair_descriptions, %{})
              |> assign(:waypoint_descriptions, %{})
              |> assign(:map_link_descriptions, %{})
              |> assign(:area_descriptions, %{})
              |> assign(:special_item_descriptions, %{})
              |> assign(:rooms_entered_count, 0)
              |> assign(:previous_room, nil)
              |> assign(:last_room_for_corridor_context, nil)
              |> assign(:current_room_description, nil)
              |> assign(:previous_room_description, nil)
              |> assign(:current_area_description, nil)
              |> assign(:previous_area_description, nil)
              |> assign(:player_facing, :right)
              |> assign(:player_visual_position, player_position)
              |> assign(:background_music_played, false)
              |> update_pathfinding_data()

            nil ->
              updated_socket
          end

        {:noreply, final_socket}

      nil ->
        {:noreply, socket}
    end
  end

  def handle_event("cancel_waypoint", _params, socket) do
    {:noreply,
     socket
     |> assign(:show_waypoint_dialog, false)
     |> assign(:selected_waypoint, nil)
     |> assign(:waypoint_description, nil)}
  end

  def handle_event("dismiss_secret_door", _params, socket) do
    DoorSystem.dismiss_secret_door(socket)
  end

  def handle_event("click_map_link", %{"x" => x_str, "y" => y_str}, socket) do
    x = String.to_integer(x_str)
    y = String.to_integer(y_str)
    position = {x, y}

    case can_interact_with_map_link?(socket, position) do
      true -> process_map_link_click(socket, position)
      false -> {:noreply, socket}
    end
  end

  def handle_event("use_map_link", _params, socket) do
    case socket.assigns.selected_map_link do
      {_x, _y} = _position ->
        {updated_socket, transition_data} =
          MapTransitionSystem.generate_new_level_for_map_link(socket)

        # Debug logging
        require Logger
        Logger.info("=== MAP LINK MAIN LIVEVIEW DEBUG ===")
        Logger.info("Updated socket dungeon theme: #{updated_socket.assigns.dungeon.theme}")
        Logger.info("Transition data dungeon theme: #{transition_data.dungeon.theme}")

        transition_socket =
          case transition_data do
            %{
              dungeon: dungeon,
              player_position: player_position,
              dungeon_level: dungeon_level,
              revealed_squares: revealed_squares,
              viewport_x: viewport_x,
              viewport_y: viewport_y,
              viewport_width: viewport_width,
              viewport_height: viewport_height,
              reset_state: true
            } ->
              # Apply transition data using proper assign/3 calls
              updated_socket
              |> assign(:dungeon, dungeon)
              |> assign(:player_position, player_position)
              |> assign(:dungeon_level, dungeon_level)
              |> assign(:revealed_squares, revealed_squares)
              |> assign(:viewport_x, viewport_x)
              |> assign(:viewport_y, viewport_y)
              |> assign(:viewport_width, viewport_width)
              |> assign(:viewport_height, viewport_height)
              |> assign(:clicked_squares, MapSet.new())
              |> assign(:fog_enabled, true)
              |> assign(:player_trapped, false)
              |> assign(:sprung_traps, MapSet.new())
              |> assign(:unlocked_doors, MapSet.new())
              |> assign(:unpickable_doors, MapSet.new())
              |> assign(:triggered_encounters, MapSet.new())
              |> assign(:discovered_features, MapSet.new())
              |> assign(:investigated_features, MapSet.new())
              |> assign(:discovered_labels, MapSet.new())
              |> assign(:room_descriptions, %{})
              |> assign(:door_descriptions, %{})
              |> assign(:corridor_descriptions, %{})
              |> assign(:feature_descriptions, %{})
              |> assign(:door_trap_descriptions, %{})
              |> assign(:room_trap_descriptions, %{})
              |> assign(:treasure_descriptions, %{})
              |> assign(:treasure_trap_descriptions, %{})
              |> assign(:stair_descriptions, %{})
              |> assign(:waypoint_descriptions, %{})
              |> assign(:map_link_descriptions, %{})
              |> assign(:area_descriptions, %{})
              |> assign(:special_item_descriptions, %{})
              |> assign(:rooms_entered_count, 0)
              |> assign(:previous_room, nil)
              |> assign(:last_room_for_corridor_context, nil)
              |> assign(:current_room_description, nil)
              |> assign(:previous_room_description, nil)
              |> assign(:current_area_description, nil)
              |> assign(:previous_area_description, nil)
              |> assign(:player_facing, :right)
              |> assign(:player_visual_position, player_position)
              |> assign(:background_music_played, false)
              |> update_pathfinding_data()

            nil ->
              updated_socket
          end

        # Close the dialog after generation
        final_socket =
          transition_socket
          |> assign(:show_map_link_dialog, false)
          |> assign(:selected_map_link, nil)
          |> assign(:map_link_description, nil)
          # Force re-render by updating a timestamp
          |> assign(:last_transition_time, :os.system_time(:millisecond))

        # Debug final socket
        Logger.info("=== FINAL SOCKET DEBUG ===")
        Logger.info("Final socket dungeon theme: #{final_socket.assigns.dungeon.theme}")

        {:noreply, final_socket}

      nil ->
        {:noreply, socket}
    end
  end

  def handle_event("cancel_map_link", _params, socket) do
    socket =
      socket
      |> assign(:show_map_link_dialog, false)
      |> assign(:selected_map_link, nil)
      |> assign(:map_link_description, nil)

    {:noreply, socket}
  end

  def handle_event("dismiss_trap", _params, socket) do
    {:noreply, TrapSystem.dismiss_trap(socket)}
  end

  def handle_event("disarm_trap", _params, socket) do
    {:noreply, attempt_disarm_trap(socket)}
  end

  def handle_event("skip_trap", _params, socket) do
    {:noreply, skip_detected_trap(socket)}
  end

  def handle_event("dismiss_trap_detection", _params, socket) do
    {:noreply, skip_detected_trap(socket)}
  end

  def handle_event("dismiss_treasure", _params, socket) do
    # Award XP for treasure gold before processing
    treasure_gold = socket.assigns[:collected_treasure_gold] || 0
    socket = award_xp(socket, treasure_gold, "treasure gold")

    {:noreply, TreasureSystem.dismiss_treasure(socket)}
  end

  def handle_event("dismiss_food", _params, socket) do
    {:noreply, FoodSystem.dismiss_food(socket)}
  end

  def handle_event("dismiss_healing_potion", _params, socket) do
    # Play pickup sound when taking healing potion
    socket = Phoenix.LiveView.push_event(socket, "play_audio", %{sound: "pickup"})

    # Increment healing potion count
    new_potion_count = socket.assigns.healing_potion_count + 1

    # Remove healing potion from grid
    position = socket.assigns.collected_healing_potion_position

    updated_grid =
      if position do
        # Determine if this position is in a room or corridor
        underlying_tile =
          if Grid.point_in_any_room?(position, socket.assigns.dungeon.rooms) do
            :floor
          else
            :corridor
          end

        Map.put(socket.assigns.dungeon.grid, position, underlying_tile)
      else
        socket.assigns.dungeon.grid
      end

    updated_dungeon = Map.put(socket.assigns.dungeon, :grid, updated_grid)

    socket =
      socket
      |> assign(:dungeon, updated_dungeon)
      |> assign(:show_healing_potion_dialog, false)
      |> assign(:healing_potion_icon, "")
      |> assign(:healing_potion_message, "")
      |> assign(:collected_healing_potion_position, nil)
      |> assign(:collected_healing_potion_healing, 0)
      |> assign(:healing_potion_count, new_potion_count)
      |> award_xp(15, "healing potion discovered")

    {:noreply, socket}
  end

  def handle_event("dismiss_special_feature", _params, socket) do
    {:noreply, SpecialFeatureSystem.dismiss_special_feature(socket)}
  end

  def handle_event("investigate_feature", _params, socket) do
    case socket.assigns.discovered_feature_position do
      nil ->
        {:noreply, socket}

      position ->
        {:noreply, process_feature_investigation(socket, position)}
    end
  end

  def handle_event("dismiss_label", _params, socket) do
    {:noreply, RoomLabelSystem.dismiss_label(socket)}
  end

  def handle_event("use_healing_potion", _params, socket) do
    current_potion_count = socket.assigns.healing_potion_count

    if current_potion_count > 0 and
         socket.assigns.player_hit_points < socket.assigns.max_hit_points do
      # Play pickup sound when drinking potion
      socket = Phoenix.LiveView.push_event(socket, "play_audio", %{sound: "pickup"})

      # Roll 1d6 for healing amount
      healing_amount = Dice.roll_dice_string("1d6")

      # Calculate actual healing (don't heal above max HP)
      current_hp = socket.assigns.player_hit_points
      max_hp = socket.assigns.max_hit_points
      new_hp = min(current_hp + healing_amount, max_hp)

      # Decrement potion count
      new_potion_count = current_potion_count - 1

      socket =
        socket
        |> assign(:player_hit_points, new_hp)
        |> assign(:healing_potion_count, new_potion_count)

      {:noreply, socket}
    else
      {:noreply, socket}
    end
  end

  def handle_event("dismiss_torch", _params, socket) do
    # Play pickup sound when taking torch
    socket = Phoenix.LiveView.push_event(socket, "play_audio", %{sound: "pickup"})

    # Handle torch collection
    current_torch_count = socket.assigns.torch_count
    current_burn_time = socket.assigns.torch_burn_time

    {new_torch_count, new_burn_time} =
      if current_torch_count == 0 and current_burn_time == 0 do
        # Player has no torches - set count to 1 and reset burn time
        {1, 100}
      else
        # Player has torches - just increment count
        {current_torch_count + 1, current_burn_time}
      end

    # Remove torch from dungeon grid
    position = socket.assigns.torch_position

    updated_grid =
      if position do
        # Determine if this position is in a room or corridor
        underlying_tile =
          if Grid.point_in_any_room?(position, socket.assigns.dungeon.rooms) do
            :floor
          else
            :corridor
          end

        Map.put(socket.assigns.dungeon.grid, position, underlying_tile)
      else
        socket.assigns.dungeon.grid
      end

    updated_dungeon = Map.put(socket.assigns.dungeon, :grid, updated_grid)

    socket =
      socket
      |> assign(:dungeon, updated_dungeon)
      |> assign(:show_torch_dialog, false)
      |> assign(:torch_icon, "")
      |> assign(:torch_message, "")
      |> assign(:torch_position, nil)
      |> assign(:torch_count, new_torch_count)
      |> assign(:torch_burn_time, new_burn_time)
      |> award_xp(15, "torch discovered")

    {:noreply, socket}
  end

  def handle_event("fight_encounter", _params, socket) do
    # Play fight sound when entering combat
    socket = Phoenix.LiveView.push_event(socket, "play_audio", %{sound: "fight"})

    # Get the full monster object based on the current encounter position
    monster =
      NpcQuestSystem.get_monster_object_from_encounter_position(
        socket.assigns.current_encounter_position,
        socket
      )

    # Start combat with the monster (pass object to preserve quest role)
    socket = CombatSystem.start_combat(socket, monster)
    {:noreply, socket}
  end

  # Combat event handlers
  def handle_event("combat_attack", _params, socket) do
    socket = CombatSystem.player_attack(socket)
    {:noreply, socket}
  end

  def handle_event("combat_flee", _params, socket) do
    socket = CombatSystem.flee_combat(socket)
    {:noreply, socket}
  end

  def handle_event("dismiss_victory", _params, socket) do
    # Use the enhanced dismiss_victory that handles XP calculation
    {socket, xp_awards} = CombatSystem.dismiss_victory_with_xp(socket)

    # Award XP for each award returned by the combat system
    socket =
      Enum.reduce(xp_awards, socket, fn {amount, reason}, acc_socket ->
        award_xp(acc_socket, amount, reason)
      end)

    {:noreply, socket}
  end

  def handle_event("evade_encounter", _params, socket) do
    # Roll d20 + dexterity bonus for evade attempt (DC 12)
    evade_roll = Dice.roll(1, 20)
    dex_bonus = socket.assigns.dexterity_bonus
    total_roll = evade_roll + dex_bonus
    evade_success = total_roll >= 12

    # Generate evade message based on success/failure
    evade_message =
      if evade_success do
        "Success! You quickly evade the encounter.\n\n(Rolled #{evade_roll} + #{dex_bonus} dexterity = #{total_roll} vs DC 12)"
      else
        "Failed! You cannot escape the encounter and must fight.\n\n(Rolled #{evade_roll} + #{dex_bonus} dexterity = #{total_roll} vs DC 12)"
      end

    # Show evade result dialog
    socket =
      socket
      |> assign(:show_encounter_dialog, false)
      |> assign(:show_evade_dialog, true)
      |> assign(:evade_success, evade_success)
      |> assign(:evade_roll, total_roll)
      |> assign(:evade_message, evade_message)

    {:noreply, socket}
  end

  def handle_event("dismiss_evade", _params, socket) do
    case {socket.assigns.evade_success, socket.assigns.combat_monster} do
      {true, monster} when not is_nil(monster) ->
        handle_successful_combat_flee(socket)

      {true, nil} ->
        handle_successful_encounter_evade(socket)

      {false, monster} when not is_nil(monster) ->
        handle_failed_combat_flee(socket)

      {false, nil} ->
        handle_failed_encounter_evade(socket)
    end
  end

  def handle_event("death_new_game", _params, socket) do
    # Stop death music and generate a completely new dungeon
    socket = Phoenix.LiveView.push_event(socket, "stop_background_music", %{})
    handle_event("generate_new", %{}, socket)
  end

  def handle_event("death_continue", _params, socket) do
    # Close death dialog and show revival dialog
    socket =
      socket
      |> assign(:show_death_dialog, false)
      |> assign(:show_revival_dialog, true)

    {:noreply, socket}
  end

  def handle_event("dismiss_revival", _params, socket) do
    # Play coins sound and restore player to full health, but set gold to 0
    socket =
      socket
      |> Phoenix.LiveView.push_event("play_audio", %{sound: "coins"})
      |> Phoenix.LiveView.push_event("stop_background_music", %{})
      |> assign(:player_hit_points, socket.assigns.max_hit_points)
      |> assign(:show_revival_dialog, false)
      |> assign(:player_dead, false)
      |> assign(:player_gold, 0)

    # Start fresh background music for the new lease on life
    level = socket.assigns.dungeon_level
    theme = socket.assigns.dungeon.theme

    socket =
      Phoenix.LiveView.push_event(socket, "play_background_music", %{level: level, theme: theme})

    {:noreply, socket}
  end

  # Wandering monster event handlers
  def handle_event("fight_wandering_monster", _params, socket) do
    # Play fight sound when entering combat
    socket = Phoenix.LiveView.push_event(socket, "play_audio", %{sound: "fight"})
    WanderingMonsterSystem.start_wandering_monster_combat(socket)
  end

  def handle_event("evade_wandering_monster", _params, socket) do
    WanderingMonsterSystem.evade_wandering_monster(socket)
  end

  def handle_event("dismiss_wandering_evade", _params, socket) do
    WanderingMonsterSystem.dismiss_wandering_evade(socket)
  end

  def handle_event("dismiss_rumor", _params, socket) do
    # Play pickup sound when noting rumor
    socket = Phoenix.LiveView.push_event(socket, "play_audio", %{sound: "pickup"})

    # Only award XP if this is a first-time discovery
    socket =
      if Map.get(socket.assigns, :rumor_first_found, false) do
        socket |> award_xp(25, "rumor discovered")
      else
        socket
      end

    socket =
      socket
      |> assign(:show_rumor_dialog, false)
      |> assign(:rumor_icon, "")
      |> assign(:rumor_message, "")
      |> assign(:rumor_first_found, false)

    {:noreply, socket}
  end

  def handle_event("dismiss_achievement", _params, socket) do
    socket =
      socket
      |> assign(:show_achievement_dialog, false)
      |> assign(:achievement_icon, "")
      |> assign(:achievement_message, "")

    {:noreply, socket}
  end

  def handle_event("dismiss_level_up", _params, socket) do
    # Create achievement text with level and talent details
    level = socket.assigns.player_level
    talent_message = socket.assigns.talent_gained

    # Get level hit points gain from the level_up_message
    level_hp_gain =
      case Regex.run(
             ~r/You gained (\d+) hit points from leveling up!/,
             socket.assigns.level_up_message
           ) do
        [_, hp_gain] -> String.to_integer(hp_gain)
        _ -> 0
      end

    achievement_text =
      "Level #{level} Achieved!\n\n" <>
        "You have reached level #{level}! " <>
        "You gained #{level_hp_gain} hit points from leveling up! " <>
        "#{talent_message}"

    # Add achievement to the achievements list
    achievements = socket.assigns.achievements ++ [achievement_text]

    socket =
      socket
      |> assign(:achievements, achievements)
      |> assign(:show_level_up_dialog, false)
      |> assign(:level_up_message, "")
      |> assign(:talent_gained, "")

    {:noreply, socket}
  end

  def handle_event("show_rumors_list", _params, socket) do
    socket = assign(socket, :show_rumors_list_dialog, true)
    {:noreply, socket}
  end

  def handle_event("dismiss_rumors_list", _params, socket) do
    socket = assign(socket, :show_rumors_list_dialog, false)
    {:noreply, socket}
  end

  def handle_event("view_rumor", %{"index" => index_str}, socket) do
    index = String.to_integer(index_str)

    if index >= 0 and index < length(socket.assigns.rumors) do
      rumor = Enum.at(socket.assigns.rumors, index)

      socket =
        socket
        |> assign(:show_rumors_list_dialog, false)
        |> assign(:show_rumor_dialog, true)
        |> assign(:rumor_first_found, false)
        |> assign(
          :rumor_icon,
          DungeonWeb.UISizing.img_tag("/images/open_scroll.png", "Rumor", :medium_icon)
        )
        |> assign(:rumor_message, rumor)

      {:noreply, socket}
    else
      {:noreply, socket}
    end
  end

  def handle_event("show_achievements_list", _params, socket) do
    socket = assign(socket, :show_achievements_list_dialog, true)
    {:noreply, socket}
  end

  def handle_event("dismiss_achievements_list", _params, socket) do
    socket = assign(socket, :show_achievements_list_dialog, false)
    {:noreply, socket}
  end

  def handle_event("view_achievement", %{"index" => index_str}, socket) do
    index = String.to_integer(index_str)

    if index >= 0 and index < length(socket.assigns.achievements) do
      achievement = Enum.at(socket.assigns.achievements, index)

      socket =
        socket
        |> assign(:show_achievements_list_dialog, false)
        |> assign(:show_achievement_dialog, true)
        |> assign(
          :achievement_icon,
          DungeonWeb.UISizing.img_tag("/images/victory.png", "Achievement", :medium_icon)
        )
        |> assign(:achievement_message, achievement)

      {:noreply, socket}
    else
      {:noreply, socket}
    end
  end

  def handle_event("dismiss_special_item", _params, socket) do
    # Play pickup sound when collecting special item
    socket = Phoenix.LiveView.push_event(socket, "play_audio", %{sound: "pickup"})

    # Only award XP if this is a first-time discovery
    socket =
      if Map.get(socket.assigns, :special_item_first_found, false) do
        socket |> award_xp(20, "special item discovered")
      else
        socket
      end

    socket =
      socket
      |> assign(:show_special_item_dialog, false)
      |> assign(:special_item_icon, "")
      |> assign(:special_item_message, "")
      |> assign(:special_item_first_found, false)

    {:noreply, socket}
  end

  def handle_event("show_special_items_list", _params, socket) do
    socket = assign(socket, :show_special_items_list_dialog, true)
    {:noreply, socket}
  end

  def handle_event("dismiss_special_items_list", _params, socket) do
    socket = assign(socket, :show_special_items_list_dialog, false)
    {:noreply, socket}
  end

  def handle_event("dismiss_quest_completed", _params, socket) do
    # Play pickup sound when magic item is added to inventory
    socket = Phoenix.LiveView.push_event(socket, "play_audio", %{sound: "pickup"})

    # Get the completed quest before clearing it
    completed_quest = socket.assigns.completed_quest

    # Create achievement text and add to achievements
    socket =
      if completed_quest do
        # Generate achievement text based on quest type
        achievement_text =
          case completed_quest.type do
            :special_item ->
              magic_item_name =
                if completed_quest.magic_item,
                  do: completed_quest.magic_item.name,
                  else: "mysterious item"

              magic_item_category =
                if completed_quest.magic_item,
                  do: completed_quest.magic_item.category,
                  else: "artifact"

              "Quest Completed: #{completed_quest.tldr_description}\n\n" <>
                "You successfully found the #{magic_item_name} in the #{completed_quest.target_theme}! " <>
                "This legendary #{magic_item_category} was worth #{completed_quest.xp_reward} XP."

            :npc_kill ->
              "Quest Completed: #{completed_quest.tldr_description}\n\n" <>
                "You successfully eliminated the #{completed_quest.target_npc} in the #{completed_quest.target_theme}! " <>
                "#{completed_quest.quest_giver} will be pleased with your work. You earned #{completed_quest.reward_gold} gold and #{completed_quest.xp_reward} XP."

            :monster_kill ->
              "Quest Completed: #{completed_quest.tldr_description}\n\n" <>
                "You successfully defeated the #{completed_quest.target_monster} in the #{completed_quest.target_theme}! " <>
                "#{completed_quest.quest_giver} will be grateful for your heroic deed. You earned #{completed_quest.reward_gold} gold and #{completed_quest.xp_reward} XP."

            _ ->
              "Quest Completed: #{completed_quest.tldr_description}\n\n" <>
                "Your quest has been completed successfully! You earned #{completed_quest.xp_reward} XP."
          end

        # Find and remove the associated rumor from rumors list
        updated_rumors =
          case completed_quest.type do
            :special_item ->
              # For special item quests, remove rumor containing magic item name and target theme
              if completed_quest.magic_item do
                Enum.reject(socket.assigns.rumors, fn rumor ->
                  String.contains?(rumor, completed_quest.magic_item.name) and
                    String.contains?(rumor, completed_quest.target_theme)
                end)
              else
                socket.assigns.rumors
              end

            :npc_kill ->
              # For NPC kill quests, remove the quest rumor
              quest_rumor =
                "Quest from #{completed_quest.quest_giver}: #{completed_quest.tldr_description}"

              Enum.reject(socket.assigns.rumors, fn rumor -> rumor == quest_rumor end)

            :monster_kill ->
              # For monster kill quests, remove the quest rumor
              quest_rumor =
                "Quest from #{completed_quest.quest_giver}: #{completed_quest.tldr_description}"

              Enum.reject(socket.assigns.rumors, fn rumor -> rumor == quest_rumor end)

            _ ->
              socket.assigns.rumors
          end

        achievements = socket.assigns.achievements ++ [achievement_text]

        socket
        |> assign(:achievements, achievements)
        |> assign(:rumors, updated_rumors)
      else
        socket
      end

    # Remove quest item from the map if a position is stored
    socket =
      case socket.assigns[:completed_quest_item_position] do
        position when is_tuple(position) ->
          # Remove quest item from grid and replace with floor
          updated_grid = Map.put(socket.assigns.dungeon.grid, position, :floor)
          updated_dungeon = Map.put(socket.assigns.dungeon, :grid, updated_grid)

          socket
          |> assign(:dungeon, updated_dungeon)
          |> assign(:completed_quest_item_position, nil)

        _ ->
          # No quest item position stored, just continue
          socket
      end

    socket =
      socket
      |> assign(:show_quest_completed_dialog, false)
      |> assign(:completed_quest, nil)
      |> assign(:quest_completion_xp, 0)

    {:noreply, socket}
  end

  def handle_event("dismiss_npc_dialog", _params, socket) do
    # Close NPC dialog and clear related assigns
    socket =
      socket
      |> assign(:show_npc_dialog, false)
      |> assign(:npc_dialog_icon, "")
      |> assign(:npc_dialog_message, "")
      |> assign(:current_encounter_position, nil)

    {:noreply, socket}
  end

  def handle_event("talk_to_npc", _params, socket) do
    Logger.info("=== MAIN TALK TO NPC DEBUG ===")
    Logger.info("Main handle_event(\"talk_to_npc\") called")
    Logger.info("Current socket assigns - show_npc_dialog: #{socket.assigns.show_npc_dialog}")

    Logger.info(
      "Current socket assigns - show_quest_offer_dialog: #{socket.assigns.show_quest_offer_dialog}"
    )

    # Get quest data from NPC quest system
    case NpcQuestSystem.get_quest_data_for_npc(socket) do
      {:quest_offer, quest_data} ->
        Logger.info("Quest offer received, showing quest offer dialog")

        socket =
          socket
          |> assign(:show_npc_dialog, false)
          |> assign(:show_quest_offer_dialog, true)
          |> assign(:quest_offer_icon, quest_data.icon)
          |> assign(:quest_offer_message, quest_data.message)
          |> assign(:offered_quest, quest_data.quest)

        {:noreply, socket}

      {:no_quest, message_data} ->
        Logger.info("No quest available, showing message dialog")

        socket =
          socket
          |> assign(:show_npc_dialog, false)
          |> assign(:show_quest_offer_dialog, true)
          |> assign(:quest_offer_icon, message_data.icon)
          |> assign(:quest_offer_message, message_data.message)
          |> assign(:offered_quest, nil)

        {:noreply, socket}

      :close_dialog ->
        Logger.info("Closing NPC dialog")

        socket =
          socket
          |> assign(:show_npc_dialog, false)
          |> assign(:npc_dialog_icon, "")
          |> assign(:npc_dialog_message, "")

        {:noreply, socket}
    end
  end

  def handle_event("accept_quest", _params, socket) do
    case NpcQuestSystem.get_quest_acceptance_data(socket) do
      {:accept_quest, quest_data} ->
        # Add quest to the NPC quest list and rumors
        socket =
          socket
          |> assign(:npc_quests, quest_data.updated_npc_quests)
          |> assign(:rumors, quest_data.updated_rumors)
          |> Dungeon.Quest.spawn_quest_target(quest_data.quest)
          |> Phoenix.LiveView.push_event("play_audio", %{sound: "pickup"})

        # Close quest offer dialog
        socket =
          socket
          |> assign(:show_quest_offer_dialog, false)
          |> assign(:quest_offer_icon, "")
          |> assign(:quest_offer_message, "")
          |> assign(:offered_quest, nil)

        {:noreply, socket}

      {:no_quest, _} ->
        # No quest to accept, just close dialog
        socket =
          socket
          |> assign(:show_quest_offer_dialog, false)
          |> assign(:quest_offer_icon, "")
          |> assign(:quest_offer_message, "")
          |> assign(:offered_quest, nil)

        {:noreply, socket}
    end
  end

  def handle_event("decline_quest", _params, socket) do
    # Since quests are only added to lists when accepted, we just need to clear the dialog
    socket =
      socket
      |> assign(:show_quest_offer_dialog, false)
      |> assign(:quest_offer_icon, "")
      |> assign(:quest_offer_message, "")
      |> assign(:offered_quest, nil)

    {:noreply, socket}
  end

  def handle_event("fight_npc", _params, socket) do
    case NpcQuestSystem.get_fight_npc_data(socket) do
      {:fight_npc, fight_data} ->
        # Close NPC dialog and start combat
        socket =
          socket
          |> assign(:show_npc_dialog, false)
          |> assign(:npc_dialog_icon, "")
          |> assign(:npc_dialog_message, "")

        # Start combat with the NPC (pass monster object to preserve role)
        socket = CombatSystem.start_combat(socket, fight_data.monster)
        {:noreply, socket}

      {:no_encounter, _} ->
        # No valid encounter found, just close dialog
        socket =
          socket
          |> assign(:show_npc_dialog, false)
          |> assign(:npc_dialog_icon, "")
          |> assign(:npc_dialog_message, "")

        {:noreply, socket}
    end
  end

  def handle_event("view_special_item", %{"index" => index_str}, socket) do
    index = String.to_integer(index_str)

    if index >= 0 and index < length(socket.assigns.special_items) do
      special_item = Enum.at(socket.assigns.special_items, index)

      # Format the item display message properly based on the item format
      display_message =
        case special_item do
          %{item_name: name, description: desc} -> "#{name} - #{desc}"
          description when is_binary(description) -> description
          _ -> "Unknown item"
        end

      socket =
        socket
        |> assign(:show_special_items_list_dialog, false)
        |> assign(:show_special_item_dialog, true)
        |> assign(:special_item_first_found, false)
        |> assign(
          :special_item_icon,
          DungeonWeb.UISizing.img_tag("/images/special_item.png", "Special Item", :medium_icon)
        )
        |> assign(:special_item_message, display_message)

      {:noreply, socket}
    else
      {:noreply, socket}
    end
  end

  def handle_event("click_label", %{"x" => x_str, "y" => y_str}, socket) do
    x = String.to_integer(x_str)
    y = String.to_integer(y_str)

    # Only allow clicking if the tile is revealed
    if FogOfWar.square_revealed?(
         x,
         y,
         socket.assigns.revealed_squares,
         socket.assigns.fog_enabled
       ) do
      case RoomLabelSystem.process_label_click(socket, {x, y}) do
        {true, icon, message} ->
          socket =
            socket
            |> assign(:show_label_dialog, true)
            |> assign(:label_icon, icon)
            |> assign(:label_message, message)
            |> assign(:discovered_label_position, {x, y})

          {:noreply, socket}

        {false, _, _} ->
          {:noreply, socket}
      end
    else
      {:noreply, socket}
    end
  end

  def handle_event("click_feature", %{"x" => x_str, "y" => y_str}, socket) do
    x = String.to_integer(x_str)
    y = String.to_integer(y_str)

    # Only allow clicking if the tile is revealed
    if FogOfWar.square_revealed?(
         x,
         y,
         socket.assigns.revealed_squares,
         socket.assigns.fog_enabled
       ) do
      case SpecialFeatureSystem.process_feature_click(socket, {x, y}) do
        {true, icon, message} ->
          socket =
            socket
            |> assign(:show_special_feature_dialog, true)
            |> assign(:special_feature_icon, icon)
            |> assign(:special_feature_message, message)
            |> assign(:discovered_feature_position, {x, y})

          {:noreply, socket}

        {false, _, _} ->
          {:noreply, socket}
      end
    else
      {:noreply, socket}
    end
  end

  def handle_event("click_encounter", %{"x" => x_str, "y" => y_str}, socket) do
    Logger.info("=== CLICK ENCOUNTER DEBUG ===")
    Logger.info("click_encounter event received")
    Logger.info("x: #{x_str}, y: #{y_str}")
    Logger.info("Player dead: #{socket.assigns.player_dead}")

    x = String.to_integer(x_str)
    y = String.to_integer(y_str)

    Logger.info("Parsed coordinates: {#{x}, #{y}}")

    # Only allow clicking if the tile is revealed
    if FogOfWar.square_revealed?(
         x,
         y,
         socket.assigns.revealed_squares,
         socket.assigns.fog_enabled
       ) do
      Logger.info("Square is revealed, processing encounter click")
      process_encounter_click(socket, {x, y})
    else
      Logger.info("Square is not revealed, ignoring click")
      {:noreply, socket}
    end
  end

  def handle_event("reveal_square", %{"x" => x_str, "y" => y_str}, socket) do
    # Block all interactions if player is dead
    if socket.assigns.player_dead do
      {:noreply, socket}
    else
      x = String.to_integer(x_str)
      y = String.to_integer(y_str)
      process_square_reveal(socket, x, y)
    end
  end

  def handle_event("open_print", _params, socket) do
    # Store current dungeon state in temporary storage and open print page
    session_key = :crypto.strong_rand_bytes(16) |> Base.url_encode64()
    dungeon_data = socket.assigns.dungeon

    # Store in ETS table for temporary access
    store_dungeon_data(session_key, dungeon_data)

    url = "/dungeon/print?session_key=#{session_key}"

    {:noreply,
     socket
     |> Phoenix.LiveView.push_event("open_url", %{url: url})}
  end

  def handle_event("open_download_png", _params, socket) do
    # Store current dungeon state in temporary storage and open download page
    session_key = :crypto.strong_rand_bytes(16) |> Base.url_encode64()

    # Make sure we get the current dungeon state including any quest monsters
    dungeon_data = socket.assigns.dungeon

    # Store in ETS table for temporary access
    store_dungeon_data(session_key, dungeon_data)

    url = "/dungeon/download_image?session_key=#{session_key}"

    {:noreply,
     socket
     |> Phoenix.LiveView.push_event("open_url", %{url: url})}
  end

  defp store_dungeon_data(key, dungeon_data) do
    # Ensure ETS table exists
    unless :ets.whereis(:dungeon_temp_storage) != :undefined do
      :ets.new(:dungeon_temp_storage, [:set, :public, :named_table])
    end

    # Store with TTL (automatically expire after 10 minutes)
    # 10 minutes
    expire_time = System.system_time(:second) + 600
    :ets.insert(:dungeon_temp_storage, {key, dungeon_data, expire_time})
  end

  defp process_encounter_click(socket, position) do
    Logger.info("=== PROCESS ENCOUNTER CLICK DEBUG ===")
    Logger.info("process_encounter_click called with position: #{inspect(position)}")
    Logger.info("Player position: #{inspect(socket.assigns.player_position)}")

    Logger.info(
      "Current encounter position: #{inspect(socket.assigns.current_encounter_position)}"
    )

    case EncounterSystem.process_encounter_click(socket, position) do
      {true, icon, message, monster} ->
        Logger.info("EncounterSystem.process_encounter_click returned success")
        Logger.info("Icon: #{inspect(icon)}")
        Logger.info("Message: #{message}")
        Logger.info("Monster: #{inspect(monster)}")
        handle_encounter_click_result(socket, position, icon, message, monster)

      {false, _, _, _} ->
        Logger.info("EncounterSystem.process_encounter_click returned false")
        {:noreply, socket}
    end
  end

  defp handle_encounter_click_result(socket, position, icon, message, monster) do
    Logger.info("=== ENCOUNTER CLICK RESULT DEBUG ===")
    Logger.info("handle_encounter_click_result called")
    Logger.info("Position: #{inspect(position)}")
    Logger.info("Monster: #{inspect(monster)}")
    Logger.info("Monster role: #{inspect(monster && monster.role)}")
    Logger.info("Guards hostile: #{socket.assigns.guards_hostile}")

    # Determine dialog type based on monster role and guard hostility state
    should_show_npc_dialog =
      NpcQuestSystem.npc_dialog_encounter?(
        monster,
        socket.assigns.guards_hostile,
        socket.assigns.player_alignment
      )

    Logger.info("Should show NPC dialog: #{should_show_npc_dialog}")

    if should_show_npc_dialog do
      Logger.info("Showing NPC dialog")
      # Show NPC dialog directly in main LiveView context
      socket =
        socket
        |> assign(:show_npc_dialog, true)
        |> assign(:npc_dialog_icon, icon)
        |> assign(:npc_dialog_message, message)
        |> assign(:current_encounter_position, position)

      Logger.info("NPC dialog result - show_npc_dialog: #{socket.assigns.show_npc_dialog}")
      {:noreply, socket}
    else
      Logger.info("Showing regular encounter dialog")
      show_encounter_dialog(socket, position, icon, message)
    end
  end

  defp show_encounter_dialog(socket, position, icon, message) do
    socket =
      socket
      |> assign(:show_encounter_dialog, true)
      |> assign(:encounter_icon, icon)
      |> assign(:encounter_message, message)
      |> assign(:current_encounter_position, position)

    {:noreply, socket}
  end

  defp process_square_reveal(socket, x, y) do
    dungeon = socket.assigns.dungeon

    # Only allow revealing if the clicked square is adjacent to player position
    if FogOfWar.can_reveal_square?(
         x,
         y,
         socket.assigns.revealed_squares,
         dungeon,
         socket.assigns.player_position
       ) do
      perform_square_reveal(socket, x, y)
    else
      # Don't reveal anything if not adjacent to revealed areas
      {:noreply, socket}
    end
  end

  defp perform_square_reveal(socket, x, y) do
    # Check if clicked on a trapped tile
    {show_trap_dialog, trap_icon, trap_message, trap_damage} =
      TrapSystem.process_click_trap(socket, x, y)

    # Reveal the clicked square and all surrounding squares (minesweeper style)
    squares_to_reveal = FogOfWar.get_surrounding_squares(x, y, socket.assigns.dungeon)

    new_revealed =
      Enum.reduce(squares_to_reveal, socket.assigns.revealed_squares, fn square, acc ->
        MapSet.put(acc, square)
      end)

    # Track the directly clicked square
    new_clicked = MapSet.put(socket.assigns.clicked_squares, {x, y})

    # Track the trap position if one was triggered
    triggered_trap_position = if show_trap_dialog, do: {x, y}, else: nil

    socket =
      socket
      |> assign(:revealed_squares, new_revealed)
      |> assign(:clicked_squares, new_clicked)
      |> assign(:show_trap_dialog, show_trap_dialog)
      |> assign(:trap_icon, trap_icon)
      |> assign(:trap_message, trap_message)
      |> assign(:triggered_trap_position, triggered_trap_position)
      |> assign(:trap_damage, trap_damage)

    {:noreply, socket}
  end

  defp can_interact_with_stair?(socket, {x, y}) do
    FogOfWar.square_revealed?(
      x,
      y,
      socket.assigns.revealed_squares,
      socket.assigns.fog_enabled
    ) and socket.assigns.player_position == {x, y}
  end

  defp can_interact_with_waypoint?(socket, {x, y}) do
    FogOfWar.square_revealed?(
      x,
      y,
      socket.assigns.revealed_squares,
      socket.assigns.fog_enabled
    ) and socket.assigns.player_position == {x, y}
  end

  defp process_stair_click(socket, {_x, _y} = position) do
    dungeon = socket.assigns.dungeon
    tile = Map.get(dungeon.grid, position)

    # Only show dialog for non-starting stairs
    if tile in [:stair_up, :stair_down] do
      show_stair_dialog(socket, position, tile)
    else
      {:noreply, socket}
    end
  end

  defp process_waypoint_click(socket, {_x, _y} = position) do
    dungeon = socket.assigns.dungeon
    tile = Map.get(dungeon.grid, position)

    # Show dialog for waypoints
    if match?({:waypoint, _}, tile) do
      show_waypoint_dialog(socket, position, tile)
    else
      {:noreply, socket}
    end
  end

  defp show_stair_dialog(socket, position, tile) do
    stair_description = get_or_generate_stair_description(socket, position, tile)

    socket =
      socket
      |> assign(:show_stair_dialog, true)
      |> assign(:selected_stair, position)
      |> assign(:stair_description, stair_description)

    {:noreply, socket}
  end

  defp show_waypoint_dialog(socket, position, tile) do
    {waypoint_description, updated_socket} =
      get_or_generate_waypoint_description(socket, position, tile)

    socket =
      updated_socket
      |> assign(:show_waypoint_dialog, true)
      |> assign(:selected_waypoint, position)
      |> assign(:waypoint_description, waypoint_description)

    {:noreply, socket}
  end

  defp can_interact_with_map_link?(socket, {x, y}) do
    FogOfWar.square_revealed?(
      x,
      y,
      socket.assigns.revealed_squares,
      socket.assigns.fog_enabled
    ) and socket.assigns.player_position == {x, y}
  end

  defp process_map_link_click(socket, {_x, _y} = position) do
    dungeon = socket.assigns.dungeon
    tile = Map.get(dungeon.grid, position)

    # Show dialog for map links
    if Dungeon.MapLinkSystem.map_link_tile?(tile) do
      show_map_link_dialog(socket, position, tile)
    else
      {:noreply, socket}
    end
  end

  defp show_map_link_dialog(socket, position, tile) do
    {map_link_description, updated_socket} =
      get_or_generate_map_link_description(socket, position, tile)

    socket =
      updated_socket
      |> assign(:show_map_link_dialog, true)
      |> assign(:selected_map_link, position)
      |> assign(:map_link_description, map_link_description)

    {:noreply, socket}
  end

  defp get_or_generate_stair_description(socket, {_x, _y} = position, tile) do
    # Use current room description for context
    room_description =
      socket.assigns.current_room_description ||
        "a mysterious chamber in the #{socket.assigns.dungeon.theme}"

    context = %{
      position: position,
      theme: socket.assigns.dungeon.theme,
      level: socket.assigns.dungeon_level,
      room_description: room_description,
      stair_direction: if(tile == :stair_up, do: "up", else: "down"),
      theme_direction: socket.assigns.dungeon.theme_direction
    }

    alias Dungeon.Services.DescriptionService
    DescriptionService.get_or_generate(:stair, socket, context)
  end

  defp get_or_generate_waypoint_description(
         socket,
         {x, y},
         {:waypoint, waypoint_number}
       ) do
    case socket.assigns.dungeon.generation_type do
      "city" ->
        # From a city, waypoints lead to outdoor themes.
        get_or_generate_destination_description(socket, {x, y}, "outdoor")

      "outdoor" ->
        # From an outdoor map, waypoints lead to city themes.
        get_or_generate_destination_description(socket, {x, y}, "city")

      _ ->
        # For standard dungeons/caverns, waypoints lead to the next level.
        get_or_generate_standard_waypoint_description(socket, {x, y}, waypoint_number)
    end
  end

  defp get_or_generate_waypoint_description(
         socket,
         {x, y},
         {:starting_waypoint, _label}
       ) do
    waypoint_number = 1
    get_or_generate_standard_waypoint_description(socket, {x, y}, waypoint_number)
  end

  defp get_or_generate_standard_waypoint_description(socket, position, waypoint_number) do
    room_description =
      socket.assigns.current_room_description ||
        "a mysterious area in the #{socket.assigns.dungeon.theme}"

    context = %{
      position: position,
      theme: socket.assigns.dungeon.theme,
      level: socket.assigns.dungeon_level,
      room_description: room_description,
      waypoint_number: waypoint_number
    }

    alias Dungeon.Services.DescriptionService
    description = DescriptionService.get_or_generate(:waypoint, socket, context)
    {description, socket}
  end

  defp get_or_generate_destination_description(socket, {x, y}, destination_type) do
    description_key = "#{x}_#{y}"

    case Map.get(socket.assigns.waypoint_descriptions, description_key) do
      nil ->
        destination_theme = Dungeon.MapLinkSystem.get_random_destination_theme(destination_type)

        description =
          "**Waypoint to a Different Land**\n\nA signpost decorated with carvings points towards new lands. It reads: #{destination_theme}.\n\nDo you wish to travel there?"

        updated_descriptions =
          Map.put(socket.assigns.waypoint_descriptions, description_key, %{
            description: description,
            destination_theme: destination_theme,
            destination_type: destination_type
          })

        socket = assign(socket, :waypoint_descriptions, updated_descriptions)
        {description, socket}

      stored_data ->
        {stored_data.description, socket}
    end
  end

  defp get_or_generate_map_link_description(socket, {x, y}, tile) do
    # Check if we already have a stored description with destination theme
    description_key = "#{x}_#{y}"

    case Map.get(socket.assigns.map_link_descriptions, description_key) do
      nil ->
        # Generate new description and store destination theme
        destination_type = Dungeon.MapLinkSystem.get_destination_type(tile)

        destination_theme =
          Dungeon.MapLinkSystem.get_random_destination_theme(
            destination_type,
            socket.assigns.dungeon.theme_data
          )

        # Get the description from the MapLinkSystem
        description = Dungeon.MapLinkSystem.get_map_link_description(tile, destination_theme)

        # Store both description and destination theme for consistency
        updated_descriptions =
          Map.put(socket.assigns.map_link_descriptions, description_key, %{
            description: description,
            destination_theme: destination_theme,
            destination_type: destination_type
          })

        socket = assign(socket, :map_link_descriptions, updated_descriptions)
        {description, socket}

      stored_data ->
        # Use existing description
        {stored_data.description, socket}
    end
  end

  # Helper function to process feature investigation
  defp process_feature_investigation(socket, position) do
    if MapSet.member?(socket.assigns.investigated_features, position) do
      # Feature already investigated, just close dialog - button should be disabled
      close_special_feature_dialog(socket)
    else
      perform_feature_investigation(socket, position)
    end
  end

  # Helper function to perform new investigation
  defp perform_feature_investigation(socket, position) do
    socket = close_special_feature_dialog(socket)

    case SpecialFeatureSystem.process_feature_investigation(socket, position) do
      {:treasure, icon, message} ->
        handle_treasure_investigation_result(socket, icon, message, position)

      {:special_item, icon, message, updated_socket} ->
        handle_special_item_investigation_result(updated_socket, icon, message, position)

      {:rumor, icon, message, updated_socket} ->
        handle_rumor_investigation_result(updated_socket, icon, message, position)

      {:trap, icon, message} ->
        handle_trap_investigation_result(socket, icon, message, position)

      {:monster, icon, message} ->
        handle_monster_investigation_result(socket, icon, message, position)

      {:nothing, icon, message} ->
        handle_nothing_investigation_result(socket, icon, message, position)

      {false, _, _} ->
        socket
    end
  end

  # Helper function to close special feature dialog
  defp close_special_feature_dialog(socket) do
    socket
    |> assign(:show_special_feature_dialog, false)
    |> assign(:special_feature_icon, "")
    |> assign(:special_feature_message, "")
  end

  # Helper function for trap investigation results
  defp handle_trap_investigation_result(socket, icon, message, position) do
    # Calculate damage for feature trap (default to 1d6 room trap damage)
    trap_damage = Dice.roll_dice_string("1d6")

    socket
    |> assign(:show_trap_dialog, true)
    |> assign(:trap_icon, icon)
    |> assign(:trap_message, message)
    |> assign(:triggered_trap_position, position)
    |> assign(:trap_damage, trap_damage)
    |> assign(:investigated_features, MapSet.put(socket.assigns.investigated_features, position))
  end

  # Helper function for rumor investigation results
  defp handle_rumor_investigation_result(socket, icon, message, position) do
    socket
    |> assign(:show_rumor_dialog, true)
    |> assign(:rumor_icon, icon)
    |> assign(:rumor_message, message)
    |> assign(:rumor_first_found, true)
    |> assign(:investigated_features, MapSet.put(socket.assigns.investigated_features, position))
  end

  # Helper function for special item investigation results
  defp handle_special_item_investigation_result(socket, icon, message, position) do
    socket
    |> assign(:show_special_item_dialog, true)
    |> assign(:special_item_icon, icon)
    |> assign(:special_item_message, message)
    |> assign(:special_item_first_found, true)
    |> assign(:investigated_features, MapSet.put(socket.assigns.investigated_features, position))
  end

  # Helper function for treasure investigation results
  defp handle_treasure_investigation_result(socket, icon, message, position) do
    socket
    |> assign(:show_treasure_dialog, true)
    |> assign(:treasure_icon, icon)
    |> assign(:treasure_message, message)
    |> assign(:investigated_features, MapSet.put(socket.assigns.investigated_features, position))
  end

  # Helper function for monster investigation results
  defp handle_monster_investigation_result(socket, icon, message, position) do
    # Show temporary combat message and mark as investigated
    socket
    |> assign(:show_encounter_dialog, true)
    |> assign(:encounter_icon, icon)
    |> assign(:encounter_message, message)
    |> assign(:current_encounter_position, position)
    |> assign(:investigated_features, MapSet.put(socket.assigns.investigated_features, position))
  end

  # Helper function for nothing found investigation results
  defp handle_nothing_investigation_result(socket, icon, message, position) do
    socket
    |> assign(:show_special_feature_dialog, true)
    |> assign(:special_feature_icon, icon)
    |> assign(:special_feature_message, message)
    |> assign(:investigated_features, MapSet.put(socket.assigns.investigated_features, position))
  end

  # Helper function to award XP and check for level ups
  defp award_xp(socket, amount, _reason) do
    current_xp = socket.assigns.player_xp
    new_xp = current_xp + amount

    socket = assign(socket, :player_xp, new_xp)
    check_for_level_up(socket, current_xp, new_xp)
  end

  # Helper functions for dismiss_evade to reduce nesting
  defp handle_successful_combat_flee(socket) do
    # Award XP for successful evasion (5 XP)
    socket = award_xp(socket, 5, "successful combat flee")

    # Resume background music after successful flee
    socket = Phoenix.LiveView.push_event(socket, "resume_background_music", %{})

    # Remove monster from grid if there's a current encounter position
    socket =
      if socket.assigns.current_encounter_position do
        {x, y} = socket.assigns.current_encounter_position
        updated_grid = Map.put(socket.assigns.dungeon.grid, {x, y}, :floor)
        updated_dungeon = Map.put(socket.assigns.dungeon, :grid, updated_grid)
        assign(socket, :dungeon, updated_dungeon)
      else
        socket
      end

    # This was from a combat flee - clean up combat state
    socket =
      socket
      |> assign(:show_evade_dialog, false)
      |> assign(:combat_monster, nil)
      |> assign(:combat_log, [])
      |> assign(:combat_current_event, "")
      |> assign(:combat_awaiting_player_action, false)
      |> assign(:combat_player_has_acted, false)
      |> assign(:combat_monster_has_acted, false)
      |> assign(:current_encounter_position, nil)
      |> assign(:evade_success, false)
      |> assign(:evade_roll, 0)
      |> assign(:evade_message, "")

    {:noreply, socket}
  end

  defp handle_successful_encounter_evade(socket) do
    # Award XP for successful evasion (5 XP)
    socket = award_xp(socket, 5, "successful encounter evade")

    # This was from an encounter evade - just close dialog without marking as triggered
    # The encounter should remain active for future approaches
    socket =
      socket
      |> assign(:show_evade_dialog, false)
      |> assign(:encounter_icon, "")
      |> assign(:encounter_message, "")
      |> assign(:current_encounter_position, nil)
      |> assign(:evade_success, false)
      |> assign(:evade_roll, 0)
      |> assign(:evade_message, "")

    {:noreply, socket}
  end

  defp handle_failed_combat_flee(socket) do
    # This was from a combat flee - restart combat with fresh log
    socket = Phoenix.LiveView.push_event(socket, "play_audio", %{sound: "fight"})

    # Get the monster that was being fought
    monster = socket.assigns.combat_monster

    # Close evade dialog and restart combat cleanly
    socket =
      socket
      |> assign(:show_evade_dialog, false)
      |> assign(:evade_success, false)
      |> assign(:evade_roll, 0)
      |> assign(:evade_message, "")

    # Restart combat with the same monster to get a fresh combat log
    socket = CombatSystem.start_combat(socket, monster)
    {:noreply, socket}
  end

  defp handle_failed_encounter_evade(socket) do
    # This was from an encounter - start combat
    socket = Phoenix.LiveView.push_event(socket, "play_audio", %{sound: "fight"})

    # Get the full monster object based on the current encounter position
    monster =
      NpcQuestSystem.get_monster_object_from_encounter_position(
        socket.assigns.current_encounter_position,
        socket
      )

    # Close evade dialog and start combat
    socket =
      socket
      |> assign(:show_evade_dialog, false)
      |> assign(:evade_success, false)
      |> assign(:evade_roll, 0)
      |> assign(:evade_message, "")

    # Start combat with the monster (pass object to preserve quest role)
    socket = CombatSystem.start_combat(socket, monster)
    {:noreply, socket}
  end

  # Unified handler for all description generation responses
  def handle_info({:attempt_trap_detection, position, trap_type, pending_action}, socket) do
    {:noreply, updated_socket} =
      attempt_trap_detection(socket, position, trap_type, pending_action)

    {:noreply, updated_socket}
  end

  def handle_info(
        {:attempt_trap_detection_for_movement, position, trap_type, pending_action},
        socket
      ) do
    {:noreply, updated_socket} =
      attempt_trap_detection(socket, position, trap_type, pending_action)

    {:noreply, updated_socket}
  end

  def handle_info({:description_generated, type, description, response_data}, socket) do
    handle_description_generated_by_type(type, socket, description, response_data)
  end

  def handle_info({:description_error, type, response_data}, socket) do
    handle_description_error_by_type(type, socket, response_data)
  end

  # Legacy handlers (keep for now during migration)
  def handle_info({:feature_description_generated, description, position, feature_label}, socket) do
    response_data = %{position: position, feature_label: feature_label}
    handle_description_generated_by_type(:feature, socket, description, response_data)
  end

  def handle_info({:feature_description_error, position, _feature_label}, socket) do
    response_data = %{position: position}
    handle_description_error_by_type(:feature, socket, response_data)
  end

  # Generic description generation handler
  def handle_info({:generate_description, type, context}, socket) do
    alias Dungeon.Services.DescriptionService

    DescriptionService.generate_async(type, context, self(), %{
      type: type,
      context: context
    })

    {:noreply, socket}
  end

  # Handle quest narrative generation
  def handle_info({:generate_quest_narrative, quest, position}, socket) do
    NpcQuestSystem.handle_generate_quest_narrative(socket, quest, position)
  end

  # Handle quest completion
  def handle_info({:quest_completed, quest, xp_reward, completion_narrative}, socket) do
    case NpcQuestSystem.handle_quest_completed(socket, quest, xp_reward, completion_narrative) do
      {:quest_completed, quest_data} ->
        # Award XP and show completion dialog
        socket = award_xp(socket, quest_data.xp_reward, "quest completion")

        socket =
          socket
          |> assign(:quests, quest_data.updated_quests)
          |> assign(:completed_quest, quest_data.completed_quest)
          |> assign(:quest_completion_xp, quest_data.xp_reward)
          |> assign(:show_quest_completed_dialog, true)

        {:noreply, socket}
    end
  end

  # Handle level up notifications from other systems
  def handle_info({:level_up_occurred, old_xp, new_xp}, socket) do
    socket = check_for_level_up(socket, old_xp, new_xp)
    {:noreply, socket}
  end

  # Handle surprise monster combat from feature investigation
  def handle_info({:surprise_monster_combat, monster_position, monster, _feature_name}, socket) do
    socket = CombatSystem.start_surprise_combat(socket, monster_position, monster)
    {:noreply, socket}
  end

  # Rumor generation handler
  def handle_info({:generate_rumor, position, feature_name}, socket) do
    # Create quest first so we have magic item and target theme for the rumor
    quest = Dungeon.Quest.create_quest_from_rumor(socket, position)

    # Get feature description using the feature name
    feature_description =
      SpecialFeatureSystem.get_or_generate_feature_description(
        socket,
        position,
        "F?",
        feature_name
      )

    # Use current room description (player must be in the room with the feature)
    room_description =
      socket.assigns.current_room_description ||
        "a mysterious chamber in the #{socket.assigns.dungeon.theme}"

    # Prepare context for rumor generation including quest details
    context = %{
      theme: socket.assigns.dungeon.theme,
      level: socket.assigns.dungeon_level,
      feature_description: feature_description,
      room_description: room_description,
      existing_rumors: socket.assigns.rumors,
      feature_label: feature_name,
      magic_item: quest.magic_item,
      target_theme: quest.target_theme
    }

    # Generate rumor description with quest details using streaming DescriptionService
    alias Dungeon.Services.DescriptionService

    DescriptionService.generate_async(:rumor, context, self(), %{
      position: position,
      feature_label: feature_name,
      quest: quest
    })

    {:noreply, socket}
  end

  # Special item generation handler (new 5-parameter format)
  def handle_info(
        {:generate_special_item, position, source_type, source_name, selected_item},
        socket
      ) do
    # Use the common special item system to build context
    alias DungeonWeb.DungeonLive.SpecialItemSystem

    context =
      SpecialItemSystem.build_special_item_context(
        socket,
        position,
        source_type,
        source_name,
        selected_item
      )

    # Add existing special items to context
    context = Map.put(context, :existing_special_items, socket.assigns[:special_items] || [])

    # For special features, add feature description to context
    context =
      if source_type == :special_feature do
        feature_description =
          SpecialFeatureSystem.get_or_generate_feature_description(
            socket,
            position,
            "F?",
            source_name
          )

        Map.put(context, :feature_description, feature_description)
      else
        context
      end

    # Generate custom description for the selected item using streaming DescriptionService
    alias Dungeon.Services.DescriptionService

    DescriptionService.generate_async(:selected_special_item, context, self(), %{
      position: position,
      source_type: source_type,
      source_name: source_name,
      selected_item: selected_item
    })

    {:noreply, socket}
  end

  # Legacy special item generation handler (3-parameter format for backwards compatibility)
  def handle_info({:generate_special_item, position, feature_name, selected_item}, socket) do
    # Convert to new format and delegate
    handle_info(
      {:generate_special_item, position, :special_feature, feature_name, selected_item},
      socket
    )
  end

  def handle_info({:show_open_door_dialog_for_movement, position, tile}, socket) do
    DoorSystem.show_open_door_dialog_for_movement(socket, position, tile)
  end

  def handle_info({:show_unlock_dialog_for_movement, position, tile}, socket) do
    DoorSystem.show_unlock_dialog_for_movement(socket, position, tile)
  end

  def handle_info({:show_stair_dialog_for_movement, position, tile}, socket) do
    # Show stair dialog when player tries to move onto a stair
    stair_description = get_or_generate_stair_description(socket, position, tile)

    socket =
      socket
      |> assign(:show_stair_dialog, true)
      |> assign(:selected_stair, position)
      |> assign(:stair_description, stair_description)

    {:noreply, socket}
  end

  def handle_info({:show_waypoint_dialog_for_movement, position, tile}, socket) do
    # Show waypoint dialog when player tries to move onto a waypoint
    {waypoint_description, updated_socket} =
      get_or_generate_waypoint_description(socket, position, tile)

    socket =
      updated_socket
      |> assign(:show_waypoint_dialog, true)
      |> assign(:selected_waypoint, position)
      |> assign(:waypoint_description, waypoint_description)

    {:noreply, socket}
  end

  def handle_info({:show_secret_door_dialog, position}, socket) do
    DoorSystem.show_secret_door_dialog(socket, position)
  end

  def handle_info({:show_map_link_dialog_for_movement, position, tile}, socket) do
    # Show map link dialog when player tries to move onto a map link
    {map_link_description, updated_socket} =
      get_or_generate_map_link_description(socket, position, tile)

    socket =
      updated_socket
      |> assign(:show_map_link_dialog, true)
      |> assign(:selected_map_link, position)
      |> assign(:map_link_description, map_link_description)

    {:noreply, socket}
  end

  def handle_info({:show_encounter_dialog_for_movement, position, icon, message, monster}, socket) do
    # Determine dialog type based on monster role and guard hostility state
    should_show_npc_dialog =
      NpcQuestSystem.npc_dialog_encounter?(
        monster,
        socket.assigns.guards_hostile,
        socket.assigns.player_alignment
      )

    if should_show_npc_dialog do
      # Show NPC dialog directly in main LiveView context
      socket =
        socket
        |> assign(:show_npc_dialog, true)
        |> assign(:npc_dialog_icon, icon)
        |> assign(:npc_dialog_message, message)
        |> assign(:current_encounter_position, position)

      {:noreply, socket}
    else
      # Show regular encounter dialog
      socket =
        socket
        |> assign(:show_encounter_dialog, true)
        |> assign(:encounter_icon, icon)
        |> assign(:encounter_message, message)
        |> assign(:current_encounter_position, position)

      {:noreply, socket}
    end
  end

  def handle_info(:torch_expired, socket) do
    require Logger
    Logger.info("🔥 Torch expired - processing torch expiration")

    # Check if player has more torches
    current_torch_count = socket.assigns.torch_count

    if current_torch_count > 1 do
      Logger.info("🔥 Player has more torches (#{current_torch_count - 1} remaining)")
      # Player has more torches - use the next one
      socket =
        socket
        |> assign(:torch_count, current_torch_count - 1)
        |> assign(:torch_burn_time, 100)
        |> update_pathfinding_data()
        |> Phoenix.LiveView.push_event("focus_map", %{})

      {:noreply, socket}
    else
      Logger.info("🔥 Last torch burned out - resetting fog")
      # Last torch has burned out - reset fog automatically but keep torch at 0
      dungeon = socket.assigns.dungeon
      player_position = socket.assigns.player_position

      # Re-initialize revealed squares (including light areas)
      final_revealed = FogOfWar.initialize_revealed_with_light(dungeon, player_position)

      socket =
        socket
        |> assign(:revealed_squares, final_revealed)
        |> assign(:fog_enabled, true)
        |> assign(:torch_count, 0)

      # Add a small delay before updating pathfinding data to ensure all assigns are processed
      Process.send_after(self(), :update_pathfinding_after_torch_reset, 100)

      socket = Phoenix.LiveView.push_event(socket, "focus_map", %{})

      Logger.info("🔥 Torch expiration complete - pathfinding update scheduled")
      # Keep torch at 0 - torches will be found later to refill

      {:noreply, socket}
    end
  end

  # Streaming description handlers for typewriter effect
  def handle_info({{:description_stream, type, response_data}, :partial, partial_text}, socket) do
    handle_description_partial_by_type(type, socket, partial_text, response_data)
  end

  def handle_info({{:description_stream, type, response_data}, :complete, final_text}, socket) do
    # Handle final complete text - same as non-streaming completion
    handle_info({:description_generated, type, final_text, response_data}, socket)
  end

  def handle_info({{:description_stream, type, response_data}, :error, error}, socket) do
    # Handle streaming error - use fallback description instead of leaving dialog hanging
    Logger.warning(
      "Streaming generation failed for #{type}: #{inspect(error)}. Using fallback description."
    )

    # Get appropriate context for fallback
    context =
      case response_data do
        %{context: ctx} ->
          ctx

        %{position: pos, feature_label: label} ->
          %{position: pos, feature_label: label, theme: socket.assigns.dungeon.theme}

        %{tile: _tile} = rd ->
          Map.put(rd, :theme, socket.assigns.dungeon.theme)

        _ ->
          %{theme: socket.assigns.dungeon.theme}
      end

    # Generate fallback and send as successful completion
    alias Dungeon.Services.DescriptionService
    fallback_description = DescriptionService.get_fallback_description(type, context)
    handle_info({:description_generated, type, fallback_description, response_data}, socket)
  end

  # Handle delayed combat events
  def handle_info(:process_monster_turn, socket) do
    # Only process if combat is still active
    if socket.assigns.show_combat_dialog do
      socket = CombatSystem.process_monster_turn(socket)
      {:noreply, socket}
    else
      {:noreply, socket}
    end
  end

  def handle_info(:maybe_start_next_round, socket) do
    # Only process if combat is still active
    if socket.assigns.show_combat_dialog do
      socket = CombatSystem.maybe_start_next_round(socket)
      {:noreply, socket}
    else
      {:noreply, socket}
    end
  end

  def handle_info({:award_xp, xp_amount, reason}, socket) do
    socket = award_xp(socket, xp_amount, reason)
    {:noreply, socket}
  end

  def handle_info(:show_death_dialog, socket) do
    socket = CombatSystem.show_death_dialog(socket)
    {:noreply, socket}
  end

  def handle_info(:show_victory_dialog, socket) do
    socket = CombatSystem.show_victory_dialog(socket)
    {:noreply, socket}
  end

  def handle_info(:attempt_combat_flee_evade, socket) do
    # Only process if combat is still active (player didn't die)
    if socket.assigns.show_combat_dialog do
      socket = CombatSystem.process_flee_evade(socket)
      {:noreply, socket}
    else
      {:noreply, socket}
    end
  end

  def handle_info({:award_exploration_xp, xp_amount, square_count}, socket) do
    socket = award_xp(socket, xp_amount, "#{square_count} squares explored")
    {:noreply, socket}
  end

  def handle_info({:award_discovery_xp, xp_amount, discovery_type}, socket) do
    socket = award_xp(socket, xp_amount, "#{discovery_type} discovered")
    {:noreply, socket}
  end

  def handle_info({:play_background_music, level, theme}, socket) do
    # Only play music if it hasn't been played for this level yet
    if socket.assigns.background_music_played do
      {:noreply, socket}
    else
      # Send event to JavaScript to play background music
      socket =
        socket
        |> assign(:background_music_played, true)
        |> Phoenix.LiveView.push_event("play_background_music", %{level: level, theme: theme})

      {:noreply, socket}
    end
  end

  def handle_info({:animate_player_to, target_position}, socket) do
    require Logger
    # Only update if the target position matches the current logical position
    # This prevents race conditions with multiple rapid movements
    if socket.assigns.player_position == target_position do
      Logger.info("✅ Player animation: Position matches, sending movement_completed")

      socket =
        socket
        |> assign(:player_visual_position, target_position)
        |> Phoenix.LiveView.push_event("movement_completed", %{})

      {:noreply, socket}
    else
      Logger.warning(
        "❌ Player animation: Position mismatch! Current: #{inspect(socket.assigns.player_position)}, Target: #{inspect(target_position)}"
      )

      {:noreply, socket}
    end
  end

  def handle_info({:update_viewport_smooth, target_position}, socket) do
    # Only update viewport if the target position matches the current logical position
    # This prevents viewport jumping during rapid movements
    if socket.assigns.player_position == target_position do
      socket = update_viewport_for_player(socket, target_position)
      {:noreply, socket}
    else
      {:noreply, socket}
    end
  end

  def handle_info(:clear_player_attack_animation, socket) do
    socket = assign(socket, :combat_player_attacking, false)
    {:noreply, socket}
  end

  def handle_info(:clear_monster_attack_animation, socket) do
    socket = assign(socket, :combat_monster_attacking, false)
    {:noreply, socket}
  end

  def handle_info(:clear_player_damage_animation, socket) do
    socket = assign(socket, :combat_player_taking_damage, false)
    {:noreply, socket}
  end

  def handle_info(:clear_monster_damage_animation, socket) do
    socket = assign(socket, :combat_monster_taking_damage, false)
    {:noreply, socket}
  end

  def handle_info(:update_pathfinding_after_torch_reset, socket) do
    require Logger
    Logger.info("🔥 Delayed pathfinding update after torch reset")

    socket =
      socket
      |> update_pathfinding_data()
      |> Phoenix.LiveView.push_event("reset_pathfinding", %{})

    {:noreply, socket}
  end

  def handle_info({:trigger_guard_hostility, reason}, socket) do
    socket = trigger_guard_hostility(socket, reason)
    {:noreply, socket}
  end

  def handle_info({:player_died, _reason}, socket) do
    socket =
      socket
      |> assign(:player_dead, true)
      |> assign(:show_death_dialog, true)

    {:noreply, socket}
  end

  def handle_info({:trigger_monster_combat, monster_pos, monster}, socket) do
    # Set up combat state similar to how encounter dialogs work
    socket =
      socket
      |> assign(:current_encounter_position, monster_pos)
      |> assign(:show_encounter_dialog, false)
      |> assign(:show_npc_dialog, false)

    # Start combat immediately
    socket = CombatSystem.start_combat(socket, monster)
    {:noreply, socket}
  end

  # Helper function to handle movement animation logic
  defp handle_movement_animation(old_socket, new_socket) do
    trigger_post_move_updates(old_socket, new_socket)
  end

  # Consolidated helper functions for description handling
  defp handle_description_generated_by_type(type, socket, description, response_data) do
    socket =
      cond do
        type in [:door, :door_trap, :room_trap, :treasure, :treasure_trap, :stair, :waypoint] ->
          handle_context_based_description(socket, type, description, response_data)

        type == :feature ->
          handle_feature_description(socket, description, response_data)

        type in [:room, :r1_room, :corridor, :area] ->
          handle_location_description(socket, type, description, response_data)

        type in [:rumor, :special_item, :selected_special_item] ->
          handle_rumor_or_special_item(socket, type, description, response_data)

        type == :quest ->
          handle_quest_description_generated(socket, description, response_data)

        true ->
          socket
      end

    {:noreply, socket}
  end

  defp handle_context_based_description(socket, type, description, response_data) do
    alias Dungeon.Services.DescriptionService
    %{context: context} = response_data
    assign_key = DescriptionService.get_assign_key(type)
    storage_key = DescriptionService.get_storage_key(type, context)

    # Append damage to trap descriptions for consistency
    final_description = maybe_append_trap_damage(description, type)

    descriptions =
      Map.put(Map.get(socket.assigns, assign_key, %{}), storage_key, final_description)

    socket
    |> assign(assign_key, descriptions)
    |> update_dialog_for_description(type, response_data, final_description)
  end

  defp handle_feature_description(socket, description, response_data) do
    position = Map.get(response_data, :position)
    # Support both old format (feature_label) and new format (source_name)
    feature_label =
      Map.get(response_data, :feature_label) || Map.get(response_data, :source_name, "feature")

    {x, y} = position
    feature_key = "#{x}_#{y}_#{feature_label}"

    feature_descriptions =
      Map.put(socket.assigns.feature_descriptions, feature_key, description)

    socket
    |> assign(:feature_descriptions, feature_descriptions)
    |> maybe_update_feature_dialog(position, description)
  end

  defp handle_location_description(socket, type, description, response_data) do
    alias Dungeon.Services.DescriptionService
    %{tile: tile} = response_data
    assign_key = DescriptionService.get_assign_key(type)
    storage_key = DescriptionService.get_storage_key(type, response_data)

    descriptions =
      Map.put(Map.get(socket.assigns, assign_key, %{}), storage_key, description)

    socket =
      socket
      |> assign(assign_key, descriptions)
      |> maybe_update_label_dialog(tile, description)

    # Update room description tracking for context chaining
    cond do
      type in [:room, :r1_room] ->
        socket
        |> assign(:previous_room_description, Map.get(socket.assigns, :current_room_description))
        |> assign(:current_room_description, description)

      # Update area description tracking for context chaining
      type == :area ->
        socket
        |> assign(:previous_area_description, Map.get(socket.assigns, :current_area_description))
        |> assign(:current_area_description, description)

      true ->
        socket
    end
  end

  defp handle_rumor_or_special_item(socket, type, description, response_data) do
    # Support both old format (feature_label) and new format (source_name/source_type)
    _position = Map.get(response_data, :position)

    _source_identifier =
      Map.get(response_data, :feature_label) || Map.get(response_data, :source_name)

    case type do
      :rumor ->
        # Quest was already created during rumor generation
        quest = Map.get(response_data, :quest)

        if quest do
          # Add quest to the list
          quests = socket.assigns.quests ++ [quest]

          # Store the rumor (which now includes quest details)
          rumors = socket.assigns.rumors ++ [description]

          socket
          |> assign(:rumors, rumors)
          |> assign(:quests, quests)
          |> assign(:rumor_message, description)
          |> assign(
            :rumor_icon,
            DungeonWeb.UISizing.img_tag("/images/open_scroll.png", "Quest", :medium_icon)
          )
          |> assign(:show_rumor_dialog, true)
          |> assign(:rumor_first_found, true)
        else
          # Fallback to old behavior if quest is missing
          position = Map.get(response_data, :position)
          quest = Dungeon.Quest.create_quest_from_rumor(socket, position)

          # Add quest to the list
          quests = socket.assigns.quests ++ [quest]

          # Still show rumor dialog, but now it represents a quest
          rumors = socket.assigns.rumors ++ [description]

          socket
          |> assign(:rumors, rumors)
          |> assign(:quests, quests)
          |> assign(:rumor_message, "Quest Received: #{quest.tldr_description}\n\n#{description}")
          |> assign(
            :rumor_icon,
            DungeonWeb.UISizing.img_tag("/images/open_scroll.png", "Quest", :medium_icon)
          )
          |> assign(:show_rumor_dialog, true)
          |> assign(:rumor_first_found, true)
        end

      :special_item ->
        special_items = socket.assigns.special_items ++ [description]

        socket
        |> assign(:special_items, special_items)
        |> assign(:special_item_message, description)
        |> assign(
          :special_item_icon,
          DungeonWeb.UISizing.img_tag("/images/special_item.png", "Special Item", :medium_icon)
        )
        |> assign(:show_special_item_dialog, true)
        |> assign(:special_item_first_found, true)

      :selected_special_item ->
        %{selected_item: selected_item} = response_data

        # Store both the item data and the custom description
        item_data = %{
          item: selected_item,
          item_name: selected_item.name,
          description: description
        }

        special_items = socket.assigns.special_items ++ [item_data]

        # Format the display message as "Item Name - Description"
        display_message = "#{selected_item.name} - #{description}"

        socket
        |> assign(:special_items, special_items)
        |> assign(:special_item_message, display_message)
        |> assign(
          :special_item_icon,
          DungeonWeb.UISizing.img_tag("/images/special_item.png", "Special Item", :medium_icon)
        )
        |> assign(:show_special_item_dialog, true)
        |> assign(:special_item_first_found, true)
        |> recalculate_stats_after_item_added()
    end
  end

  defp handle_quest_description_generated(socket, description, response_data) do
    case NpcQuestSystem.handle_quest_description_generated(socket, description, response_data) do
      {:quest_description_generated, quest_data} ->
        socket =
          socket
          |> assign(:quests, quest_data.updated_quests)
          |> assign(:rumor_message, quest_data.rumor_message)

        {:noreply, socket}
    end
  end

  defp maybe_append_trap_damage(description, type) do
    if type in [:door_trap, :room_trap, :treasure_trap] do
      alias Dungeon.Services.DescriptionService
      DescriptionService.append_trap_damage(description, type)
    else
      description
    end
  end

  defp handle_description_error_by_type(type, socket, response_data) do
    Logger.warning("Description generation failed for #{type}. Using fallback description.")

    # Get appropriate context for fallback
    context =
      case response_data do
        %{context: ctx} ->
          ctx

        %{position: pos, feature_label: label} ->
          %{position: pos, feature_label: label, theme: socket.assigns.dungeon.theme}

        %{position: pos, source_name: name} ->
          %{position: pos, feature_label: name, theme: socket.assigns.dungeon.theme}

        %{tile: _tile} = rd ->
          Map.put(rd, :theme, socket.assigns.dungeon.theme)

        _ ->
          %{theme: socket.assigns.dungeon.theme}
      end

    # Use fallback description instead of error message
    alias Dungeon.Services.DescriptionService
    fallback_description = DescriptionService.get_fallback_description(type, context)

    # Append damage to trap fallbacks for consistency
    final_fallback_description =
      if type in [:door_trap, :room_trap, :treasure_trap] do
        DescriptionService.append_trap_damage(fallback_description, type)
      else
        fallback_description
      end

    # Send fallback as successful generation
    handle_description_generated_by_type(type, socket, final_fallback_description, response_data)
  end

  defp handle_description_partial_by_type(type, socket, partial_text, response_data) do
    socket =
      cond do
        type in [:door, :door_trap, :room_trap, :treasure, :treasure_trap, :stair, :waypoint] ->
          update_dialog_for_description(socket, type, response_data, partial_text)

        type == :feature ->
          %{position: position} = response_data
          maybe_update_feature_dialog(socket, position, partial_text)

        type in [:room, :r1_room, :corridor, :area] ->
          %{tile: tile} = response_data
          maybe_update_label_dialog(socket, tile, partial_text)

        type in [:rumor, :special_item] ->
          # Update the current dialog with partial text
          case type do
            :rumor -> assign(socket, :rumor_message, partial_text)
            :special_item -> assign(socket, :special_item_message, partial_text)
          end

        true ->
          socket
      end

    {:noreply, socket}
  end

  # Helper to update dialogs based on description type
  defp update_dialog_for_description(socket, type, response_data, description) do
    case type do
      :door ->
        # Door dialogs open via DoorSystem but streaming completion must refresh the same
        # assigns the template reads (:door_description / :open_door_description); otherwise
        # the UI stays on "Generating description..." forever.
        %{context: %{position: position}} = response_data

        cond do
          socket.assigns.show_unlock_dialog and socket.assigns.selected_door == position ->
            assign(socket, :door_description, description)

          socket.assigns.show_open_door_dialog and socket.assigns.selected_open_door == position ->
            assign(socket, :open_door_description, description)

          true ->
            socket
        end

      type when type in [:door_trap, :room_trap, :treasure_trap] ->
        %{context: context} = response_data
        maybe_update_trap_dialog_with_description(socket, context, description)

      :treasure ->
        %{context: context} = response_data
        maybe_update_treasure_dialog_with_description(socket, context, description)

      :stair ->
        %{context: %{position: position}} = response_data
        maybe_update_stair_dialog(socket, position, description)

      :waypoint ->
        %{context: %{position: position}} = response_data
        maybe_update_waypoint_dialog(socket, position, description)

      _ ->
        socket
    end
  end

  # Shared helper functions for dialog updates

  defp maybe_update_feature_dialog(socket, position, description) do
    # Update special feature dialog if showing and the position matches
    if socket.assigns.show_special_feature_dialog and
         socket.assigns.discovered_feature_position == position do
      socket
      |> assign(:special_feature_message, description)
    else
      socket
    end
  end

  defp maybe_update_label_dialog(socket, tile, message) do
    # Only update if the label dialog is currently showing
    if socket.assigns.show_label_dialog do
      room_descriptions = Map.get(socket.assigns, :room_descriptions, %{})
      corridor_descriptions = Map.get(socket.assigns, :corridor_descriptions, %{})
      area_descriptions = Map.get(socket.assigns, :area_descriptions, %{})

      {icon, _} =
        RoomLabelSystem.get_label_message(
          tile,
          room_descriptions,
          corridor_descriptions,
          area_descriptions
        )

      socket
      |> assign(:label_icon, icon)
      |> assign(:label_message, message)
    else
      socket
    end
  end

  defp maybe_update_stair_dialog(socket, position, description) do
    # Update stair dialog if showing and the position matches
    if socket.assigns.show_stair_dialog and socket.assigns.selected_stair == position do
      socket
      |> assign(:stair_description, description)
    else
      socket
    end
  end

  defp maybe_update_waypoint_dialog(socket, position, description) do
    # Update waypoint dialog if showing and the position matches
    if socket.assigns.show_waypoint_dialog and socket.assigns.selected_waypoint == position do
      socket
      |> assign(:waypoint_description, description)
    else
      socket
    end
  end

  # Viewport management functions
  defp update_viewport_for_player(socket, {player_x, player_y}) do
    dungeon = socket.assigns.dungeon

    # Calculate viewport size based on zoom level and dungeon size
    {max_viewport_width, max_viewport_height} = get_viewport_size(socket.assigns.zoom_level)

    # For desktop (:normal), try to show the entire dungeon if it fits within max viewport
    {viewport_width, viewport_height} =
      if socket.assigns.zoom_level == :normal do
        {min(dungeon.width, max_viewport_width), min(dungeon.height, max_viewport_height)}
      else
        {max_viewport_width, max_viewport_height}
      end

    # Center viewport on player position, but show full map if viewport is larger than dungeon
    viewport_x =
      if viewport_width >= dungeon.width do
        0
      else
        max(0, min(player_x - div(viewport_width, 2), dungeon.width - viewport_width))
      end

    viewport_y =
      if viewport_height >= dungeon.height do
        0
      else
        max(0, min(player_y - div(viewport_height, 2), dungeon.height - viewport_height))
      end

    socket
    |> assign(:viewport_x, viewport_x)
    |> assign(:viewport_y, viewport_y)
    |> assign(:viewport_width, viewport_width)
    |> assign(:viewport_height, viewport_height)
  end

  defp get_viewport_size(:mobile), do: {6, 6}
  defp get_viewport_size(:normal), do: {16, 16}

  # Check if any dialog is currently open
  defp any_dialog_open?(socket) do
    dialog_keys = [
      :show_unlock_dialog,
      :show_break_door_result_dialog,
      :show_open_door_dialog,
      :show_stair_dialog,
      :show_waypoint_dialog,
      :show_map_link_dialog,
      :show_trap_dialog,
      :show_encounter_dialog,
      :show_evade_dialog,
      :show_treasure_dialog,
      :show_special_feature_dialog,
      :show_label_dialog,
      :show_rumor_dialog,
      :show_special_item_dialog,
      :show_death_dialog,
      :show_revival_dialog,
      :show_trap_detection_dialog,
      :show_combat_dialog,
      :show_victory_dialog,
      :show_wandering_monster_dialog,
      :show_wandering_evade_dialog,
      :show_npc_dialog
    ]

    Enum.any?(dialog_keys, &socket.assigns[&1])
  end

  defp maybe_update_trap_dialog_with_description(socket, %{position: position}, description) do
    # Update trap dialog if showing and the position matches
    if socket.assigns.show_trap_dialog and
         socket.assigns.triggered_trap_position == position do
      socket
      |> assign(:trap_message, description)
    else
      socket
    end
  end

  defp maybe_update_treasure_dialog_with_description(socket, %{position: position}, description) do
    # Update treasure dialog if showing and the position matches
    if socket.assigns.show_treasure_dialog and
         socket.assigns.collected_treasure_position == position do
      socket
      |> assign(:treasure_message, description)
    else
      socket
    end
  end

  # Trap detection helper functions

  defp attempt_trap_detection(socket, position, trap_type, pending_action) do
    # Roll d20 for detection (DC 15)
    detection_roll = Dice.roll(1, 20)

    if detection_roll >= 15 do
      # Trap detected! Show detection dialog
      trap_message = get_trap_detection_message(trap_type, detection_roll)

      socket =
        socket
        |> assign(:show_trap_detection_dialog, true)
        |> assign(:trap_detection_message, trap_message)
        |> assign(:detected_trap_position, position)
        |> assign(:detected_trap_type, trap_type)
        |> assign(:pending_trap_action, pending_action)

      {:noreply, socket}
    else
      # Trap not detected, trigger it normally
      trigger_undetected_trap(socket, position, trap_type)
    end
  end

  defp get_trap_detection_message(trap_type, roll) do
    base_message =
      case trap_type do
        :door_trap ->
          "You notice something suspicious about this door - there appears to be a trap mechanism! "

        :room_trap ->
          "Your keen senses detect a hidden trap in this room! "

        :treasure_trap ->
          "Something doesn't feel right about this treasure - you suspect it might be trapped! "
      end

    base_message <> "(Detected with roll #{roll} vs DC 15)\n\nWhat would you like to do?"
  end

  defp trigger_undetected_trap(socket, position, trap_type) do
    # Failed to detect trap, trigger it normally by showing trap dialog
    dungeon = socket.assigns.dungeon
    tile = Map.get(dungeon.grid, position)

    {icon, _, _damage} = TrapSystem.get_trap_message(tile)

    # Generate appropriate description based on trap type
    message =
      case trap_type do
        :door_trap ->
          TrapSystem.get_or_generate_door_trap_description(
            socket,
            position,
            tile
          )

        :room_trap ->
          TrapSystem.get_or_generate_room_trap_description(
            socket,
            position,
            tile
          )

        :treasure_trap ->
          TrapSystem.get_or_generate_treasure_trap_description(
            socket,
            position,
            tile
          )
      end

    socket =
      socket
      |> assign(:show_trap_dialog, true)
      |> assign(:trap_icon, icon)
      |> assign(:trap_message, message)
      |> assign(:triggered_trap_position, position)

    {:noreply, socket}
  end

  defp attempt_disarm_trap(socket) do
    if socket.assigns.detected_trap_position do
      execute_disarm_attempt(socket)
    else
      socket
    end
  end

  defp execute_disarm_attempt(socket) do
    # Play click sound when attempting to disarm trap
    socket = Phoenix.LiveView.push_event(socket, "play_audio", %{sound: "click"})

    # Roll 1d20 + dexterity_bonus vs DC 15
    roll = Dice.roll_dice_string("1d20")
    total = roll + socket.assigns.dexterity_bonus
    success = total >= 15

    # Store trap information before removing it
    trap_info = get_detected_trap_info(socket)

    if success do
      handle_successful_trap_disarm(socket, roll, trap_info)
    else
      handle_failed_trap_disarm(socket, roll, total, trap_info)
    end
  end

  defp get_detected_trap_info(socket) do
    {x, y} = socket.assigns.detected_trap_position
    dungeon = socket.assigns.dungeon
    tile = Map.get(dungeon.grid, {x, y})
    %{position: {x, y}, tile: tile, is_treasure_trap: tile == :trapped_treasure}
  end

  defp handle_successful_trap_disarm(socket, roll, trap_info) do
    # Remove the trap
    socket = remove_detected_trap(socket)

    # Show appropriate dialog based on trap type
    socket = show_success_dialog_or_treasure(socket, roll, trap_info)

    award_xp(socket, 10, "trap disarmed")
  end

  defp handle_failed_trap_disarm(socket, roll, total, trap_info) do
    # Calculate damage and apply it
    damage = TrapSystem.calculate_trap_damage(trap_info.tile)
    socket = TrapSystem.apply_damage(socket, damage)

    # Remove the trap after triggering
    socket = remove_detected_trap(socket)

    # Show appropriate dialog based on survival and trap type
    show_failure_dialog_or_treasure(socket, roll, total, damage, trap_info)
  end

  defp show_success_dialog_or_treasure(socket, roll, trap_info) do
    if trap_info.is_treasure_trap do
      show_treasure_dialog_after_trap_disarm(socket, trap_info.position)
    else
      show_trap_disarm_success_dialog(socket, roll)
    end
  end

  defp show_failure_dialog_or_treasure(socket, roll, total, damage, trap_info) do
    if trap_info.is_treasure_trap and socket.assigns.player_hit_points > 0 do
      show_treasure_dialog_after_trap_disarm(socket, trap_info.position)
    else
      show_trap_disarm_failure_dialog(socket, roll, total, damage)
    end
  end

  defp show_treasure_dialog_after_trap_disarm(socket, {x, y}) do
    # Get treasure information and show treasure dialog
    {treasure_icon, treasure_message, gold_amount} =
      TreasureSystem.get_treasure_message(socket, {x, y})

    # Play chest opening sound
    socket = Phoenix.LiveView.push_event(socket, "play_audio", %{sound: "chest_open"})

    socket
    |> assign(:show_trap_detection_dialog, false)
    |> assign(:trap_detection_message, "")
    |> assign(:trap_detection_success, nil)
    |> assign(:trap_detection_roll, nil)
    |> assign(:show_treasure_dialog, true)
    |> assign(:treasure_icon, treasure_icon)
    |> assign(:treasure_message, treasure_message)
    |> assign(:collected_treasure_position, {x, y})
    |> assign(:collected_treasure_gold, gold_amount)
  end

  defp show_trap_disarm_success_dialog(socket, roll) do
    socket
    |> assign(:show_trap_detection_dialog, true)
    |> assign(
      :trap_detection_message,
      "You successfully disarm the trap!\n(Rolled #{roll} + #{socket.assigns.dexterity_bonus} dexterity = #{roll + socket.assigns.dexterity_bonus} vs DC 15)\n\nThe trap is now safe to pass."
    )
    |> assign(:trap_detection_success, true)
    |> assign(:trap_detection_roll, roll)
  end

  defp show_trap_disarm_failure_dialog(socket, roll, total, damage) do
    socket
    |> assign(:show_trap_detection_dialog, true)
    |> assign(
      :trap_detection_message,
      "You fail to disarm the trap and trigger it!\n(Rolled #{roll} + #{socket.assigns.dexterity_bonus} dexterity = #{total} vs DC 15)\n\nYou take #{damage} damage."
    )
    |> assign(:trap_detection_success, false)
    |> assign(:trap_detection_roll, roll)
  end

  defp skip_detected_trap(socket) do
    socket
    |> assign(:show_trap_detection_dialog, false)
    |> assign(:trap_detection_message, "")
    |> assign(:detected_trap_position, nil)
    |> assign(:detected_trap_type, nil)
    |> assign(:pending_trap_action, nil)
    |> assign(:trap_detection_success, nil)
    |> assign(:trap_detection_roll, nil)
  end

  defp remove_detected_trap(socket) do
    if socket.assigns.detected_trap_position do
      {x, y} = socket.assigns.detected_trap_position
      dungeon = socket.assigns.dungeon
      tile = Map.get(dungeon.grid, {x, y})

      new_tile =
        case tile do
          :room_trap -> :floor
          :trapped_treasure -> :treasure
          :trapped_door -> :door
          :locked_trapped_door -> :locked_door
          _ -> tile
        end

      new_grid = Map.put(dungeon.grid, {x, y}, new_tile)
      new_dungeon = %{dungeon | grid: new_grid}

      socket
      |> assign(:dungeon, new_dungeon)
      |> assign(:detected_trap_position, nil)
      |> assign(:detected_trap_type, nil)
      |> assign(:pending_trap_action, nil)
    else
      socket
    end
  end

  def render(assigns) do
    MapTemplate.render(assigns)
  end

  defp do_level_up(socket, new_xp) do
    new_level = PlayerStats.calculate_level(new_xp)
    {talent_type, talent_bonus, talent_message} = PlayerStats.generate_random_talent()

    # Roll hit points for the new level
    level_hp_gain = PlayerStats.roll_hit_points_for_level()
    total_level_hit_points = socket.assigns.level_hit_points + level_hp_gain

    updated_talents =
      PlayerStats.apply_talent_bonus(
        socket.assigns.talent_bonuses,
        {talent_type, talent_bonus, talent_message}
      )

    # Calculate total hit points gained (level + talent if applicable)
    total_hp_gain = level_hp_gain + if talent_type == :hit_points, do: talent_bonus, else: 0

    socket =
      socket
      |> assign(:player_level, new_level)
      |> assign(:talent_bonuses, updated_talents)
      |> assign(:level_hit_points, total_level_hit_points)
      |> assign(:show_level_up_dialog, true)
      |> assign(
        :level_up_message,
        "**Level #{new_level} Achieved!**\n\nCongratulations! You have reached level #{new_level}!\n\nYou gained #{level_hp_gain} hit points from leveling up!"
      )
      |> assign(
        :talent_gained,
        case talent_type do
          :hit_points ->
            "Talent: You gained +#{talent_bonus} to Maximum Hit Points!\n\nTotal hit points gained: #{level_hp_gain + talent_bonus}"

          :attack ->
            "Talent: You gained +#{talent_bonus} to Attack Bonus!"

          :dexterity ->
            "Talent: You gained +#{talent_bonus} to Dexterity!"
        end
      )

    # Recalculate stats with the new talent bonuses and level hit points
    socket =
      socket
      |> assign(:max_hit_points, calculate_total_max_hit_points(socket))
      |> assign(:attack_bonus, calculate_total_attack_bonus(socket))
      |> assign(:dexterity_bonus, calculate_total_dexterity_bonus(socket))
      |> assign(:armor_class, calculate_total_armor_class(socket))
      |> assign(:player_weapon, calculate_total_weapon(socket))
      |> assign(:weapon_damage_dice, calculate_total_weapon_damage_dice(socket))

    # Always add total_hp_gain to current hit points (never exceeding new max)
    current_hp = socket.assigns.player_hit_points
    new_current_hp = min(current_hp + total_hp_gain, socket.assigns.max_hit_points)
    socket = assign(socket, :player_hit_points, new_current_hp)

    Phoenix.LiveView.push_event(socket, "play_audio", %{sound: "orch_hit"})
  end

  # Helper function to trigger UI updates after player position changes
  defp trigger_post_move_updates(old_socket, new_socket) do
    # Check if viewport will actually change
    old_viewport = {old_socket.assigns.viewport_x, old_socket.assigns.viewport_y}
    temp_socket = update_viewport_for_player(new_socket, new_socket.assigns.player_position)
    new_viewport = {temp_socket.assigns.viewport_x, temp_socket.assigns.viewport_y}

    if old_viewport != new_viewport do
      # Viewport will move - keep player visually stationary, update viewport smoothly
      Process.send_after(
        self(),
        {:update_viewport_smooth, new_socket.assigns.player_position},
        150
      )

      # Don't update visual position - let the transform offset keep player visually centered
      {:noreply, new_socket}
    else
      # Viewport stays same - animate player token
      Process.send_after(self(), {:animate_player_to, new_socket.assigns.player_position}, 300)
      {:noreply, new_socket}
    end
  end

  # Helper function to generate walkability grid for pathfinding
  defp get_walkability_grid(dungeon) do
    for y <- 0..(dungeon.height - 1) do
      for x <- 0..(dungeon.width - 1) do
        tile = Map.get(dungeon.grid, {x, y})
        walkable_tile?(tile)
      end
    end
  end

  # Update pathfinding data for JavaScript hook
  defp update_pathfinding_data(socket) do
    {player_x, player_y} = socket.assigns.player_position

    Phoenix.LiveView.push_event(socket, "update_walkability", %{
      walkability: get_walkability_grid(socket.assigns.dungeon),
      playerPosition: %{x: player_x, y: player_y},
      width: socket.assigns.dungeon.width,
      height: socket.assigns.dungeon.height,
      tileSize: 48,
      viewportX: socket.assigns.viewport_x,
      viewportY: socket.assigns.viewport_y
    })
  end

  # Determine if a tile is walkable for pathfinding
  # credo:disable-for-next-line Credo.Check.Refactor.CyclomaticComplexity
  defp walkable_tile?(tile) do
    case tile do
      :floor ->
        true

      :road ->
        true

      :corridor ->
        true

      {:door, _} ->
        true

      :door ->
        true

      :trapped_door ->
        true

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
        # Pillars are not walkable - they act as blockers like walls
        extract_feature_name(feature_name) != "Pillar"

      {:encounter, _, _} ->
        true

      {:monster, _} ->
        true

      :wall ->
        false

      :shrub ->
        false

      :locked_door ->
        true

      :locked_trapped_door ->
        true

      :secret_door ->
        true

      _ ->
        false
    end
  end

  # Helper function to extract feature name from different formats
  defp extract_feature_name({feature_name, _rarity}) when is_binary(feature_name),
    do: feature_name

  defp extract_feature_name(feature_name) when is_binary(feature_name), do: feature_name
  defp extract_feature_name(_), do: "Unknown Feature"

  # Player stat calculation functions with bonuses and equipment
  defp calculate_total_max_hit_points(socket) do
    talent_bonuses = Map.get(socket.assigns, :talent_bonuses, PlayerStats.default_talents())
    special_items = Map.get(socket.assigns, :special_items, [])
    level_hit_points = Map.get(socket.assigns, :level_hit_points, 0)

    total_stats =
      PlayerStats.calculate_total_stats(special_items, talent_bonuses, level_hit_points)

    total_stats.max_hit_points
  end

  defp calculate_total_attack_bonus(socket) do
    talent_bonuses = Map.get(socket.assigns, :talent_bonuses, PlayerStats.default_talents())
    special_items = Map.get(socket.assigns, :special_items, [])
    level_hit_points = Map.get(socket.assigns, :level_hit_points, 0)

    total_stats =
      PlayerStats.calculate_total_stats(special_items, talent_bonuses, level_hit_points)

    total_stats.attack_bonus
  end

  defp calculate_total_dexterity_bonus(socket) do
    talent_bonuses = Map.get(socket.assigns, :talent_bonuses, PlayerStats.default_talents())
    special_items = Map.get(socket.assigns, :special_items, [])
    level_hit_points = Map.get(socket.assigns, :level_hit_points, 0)

    total_stats =
      PlayerStats.calculate_total_stats(special_items, talent_bonuses, level_hit_points)

    total_stats.dexterity_bonus
  end

  defp calculate_total_armor_class(socket) do
    talent_bonuses = Map.get(socket.assigns, :talent_bonuses, PlayerStats.default_talents())
    special_items = Map.get(socket.assigns, :special_items, [])
    level_hit_points = Map.get(socket.assigns, :level_hit_points, 0)
    PlayerStats.calculate_total_armor_class(special_items, talent_bonuses, level_hit_points)
  end

  defp calculate_total_weapon(socket) do
    talent_bonuses = Map.get(socket.assigns, :talent_bonuses, PlayerStats.default_talents())
    special_items = Map.get(socket.assigns, :special_items, [])
    level_hit_points = Map.get(socket.assigns, :level_hit_points, 0)

    total_stats =
      PlayerStats.calculate_total_stats(special_items, talent_bonuses, level_hit_points)

    total_stats.weapon
  end

  defp calculate_total_weapon_damage_dice(socket) do
    talent_bonuses = Map.get(socket.assigns, :talent_bonuses, PlayerStats.default_talents())
    special_items = Map.get(socket.assigns, :special_items, [])
    level_hit_points = Map.get(socket.assigns, :level_hit_points, 0)

    total_stats =
      PlayerStats.calculate_total_stats(special_items, talent_bonuses, level_hit_points)

    total_stats.weapon_damage_dice
  end

  defp recalculate_stats_after_item_added(socket) do
    socket
    |> assign(:max_hit_points, calculate_total_max_hit_points(socket))
    |> assign(:attack_bonus, calculate_total_attack_bonus(socket))
    |> assign(:dexterity_bonus, calculate_total_dexterity_bonus(socket))
    |> assign(:armor_class, calculate_total_armor_class(socket))
    |> assign(:player_weapon, calculate_total_weapon(socket))
    |> assign(:weapon_damage_dice, calculate_total_weapon_damage_dice(socket))
  end

  # Level up system functions
  defp check_for_level_up(socket, old_xp, new_xp) do
    if PlayerStats.leveled_up?(old_xp, new_xp) do
      do_level_up(socket, new_xp)
    else
      socket
    end
  end

  # Guard system helper functions
  defp trigger_guard_hostility(socket, _reason) do
    # Make all guards on the current map hostile
    socket = assign(socket, :guards_hostile, true)

    socket
  end

  # Helper function to calculate player transform for smooth movement
end
