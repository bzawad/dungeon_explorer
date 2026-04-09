defmodule DungeonWeb.DungeonLive.MapTransitionSystem do
  @moduledoc """
  Handles map transition logic for stair navigation, waypoint travel, and map link transitions.
  """

  require Logger

  alias Dungeon.{Generator, MapLinkSystem}

  alias DungeonWeb.DungeonLive.{
    FogOfWar,
    Movement,
    NpcQuestSystem,
    QuestItemSystem
  }

  # Public API functions

  def generate_new_level(socket) do
    # For level progression, keep the same theme but increment level
    current_theme = socket.assigns.dungeon.theme
    new_level = socket.assigns.dungeon_level + 1

    # Generate new dungeon with the same theme and incremented level
    dungeon = Generator.generate_with_theme_and_level(current_theme, new_level)

    {updated_socket, transition_data} =
      complete_map_transition(socket, dungeon, new_level, current_theme)

    # Return both the updated socket and transition data for main LiveView to assign
    {updated_socket, transition_data}
  end

  def generate_new_game(socket) do
    # For new game, always start at level 1 with a fresh random theme
    player_level = socket.assigns.player_level
    dungeon = Generator.generate_with_player_level(player_level, 1)
    new_level = 1
    new_theme = dungeon.theme

    {updated_socket, transition_data} =
      complete_map_transition(socket, dungeon, new_level, new_theme)

    # Return both the updated socket and transition data for main LiveView to assign
    {updated_socket, transition_data}
  end

  def generate_new_level_from_waypoint_destination(socket) do
    case socket.assigns.selected_waypoint do
      {x, y} = _position ->
        # Get stored destination theme to maintain consistency with dialog
        description_key = "#{x}_#{y}"
        stored_data = Map.get(socket.assigns.waypoint_descriptions, description_key)

        player_level = socket.assigns.player_level

        dungeon =
          case stored_data do
            %{destination_theme: theme} ->
              Generator.generate_with_theme_and_levels(theme, player_level, 1)

            _ ->
              # Fallback to random generation if no stored theme
              Generator.generate_with_player_level(player_level, 1)
          end

        # Calculate level based on theme progression rules
        current_theme = socket.assigns.dungeon.theme
        new_theme = dungeon.theme
        current_level = socket.assigns.dungeon_level

        new_level =
          if current_theme == new_theme do
            current_level + 1
          else
            1
          end

        # Regenerate with the appropriate level and player level
        player_level = socket.assigns.player_level
        dungeon = Generator.generate_with_theme_and_levels(new_theme, player_level, new_level)

        {updated_socket, transition_data} =
          complete_map_transition(socket, dungeon, new_level, new_theme)

        # Return both the updated socket and transition data for main LiveView to assign
        {updated_socket, transition_data}

      nil ->
        {socket, nil}
    end
  end

  def generate_new_level_for_map_link(socket) do
    case socket.assigns.selected_map_link do
      {x, y} = position ->
        # Get the map link tile and determine destination
        tile = Map.get(socket.assigns.dungeon.grid, position)

        # Get stored destination theme to maintain consistency with dialog
        description_key = "#{x}_#{y}"
        stored_data = Map.get(socket.assigns.map_link_descriptions, description_key)

        player_level = socket.assigns.player_level

        dungeon =
          case stored_data do
            %{destination_theme: theme} ->
              Generator.generate_with_theme_and_levels(theme, player_level, 1)

            _ ->
              # Fallback to random generation if no stored theme (shouldn't happen)
              destination_type = MapLinkSystem.get_destination_type(tile)
              Generator.generate_with_theme_type_and_levels(destination_type, player_level, 1)
          end

        # Calculate level based on theme progression rules
        current_theme = socket.assigns.dungeon.theme
        new_theme = dungeon.theme
        current_level = socket.assigns.dungeon_level

        new_level =
          if current_theme == new_theme do
            # Same theme - increment level
            current_level + 1
          else
            # Different theme - reset to level 1
            1
          end

        # Regenerate with the appropriate level and player level
        player_level = socket.assigns.player_level
        dungeon = Generator.generate_with_theme_and_levels(new_theme, player_level, new_level)

        {updated_socket, transition_data} =
          complete_map_link_transition(socket, dungeon, new_level, new_theme)

        # Return both the updated socket and transition data for main LiveView to assign
        {updated_socket, transition_data}

      nil ->
        {socket, nil}
    end
  end

  # Private helper functions

  defp complete_map_transition(socket, dungeon, new_level, theme) do
    # Spawn quest items for any matching active quests
    dungeon = QuestItemSystem.spawn_quest_items(socket, dungeon)

    # Create temporary socket for quest monster spawning (doesn't update LiveView)
    temp_socket = %{
      socket
      | assigns: Map.merge(socket.assigns, %{dungeon: dungeon, dungeon_level: new_level})
    }

    # Spawn quest monsters for any matching active NPC quests
    temp_socket = NpcQuestSystem.spawn_quest_monsters_for_theme(temp_socket, theme)

    # Get the updated dungeon after quest monster spawning
    dungeon = temp_socket.assigns.dungeon

    player_position = Movement.find_starting_position(dungeon)

    # Initialize revealed squares (including light areas)
    final_revealed = FogOfWar.initialize_revealed_with_light(dungeon, player_position)

    # Calculate viewport for the new dungeon
    {viewport_x, viewport_y, viewport_width, viewport_height} =
      calculate_viewport_for_player(socket, player_position, dungeon)

    # Prepare transition data for main LiveView to assign
    transition_data = %{
      dungeon: dungeon,
      player_position: player_position,
      dungeon_level: new_level,
      revealed_squares: final_revealed,
      viewport_x: viewport_x,
      viewport_y: viewport_y,
      viewport_width: viewport_width,
      viewport_height: viewport_height,
      reset_state: true
    }

    # Return original socket (no updates) and transition data
    {socket, transition_data}
  end

  defp complete_map_link_transition(socket, dungeon, new_level, new_theme) do
    # Spawn quest items for any matching active quests
    dungeon = QuestItemSystem.spawn_quest_items(socket, dungeon)

    # Create temporary socket for quest monster spawning (doesn't update LiveView)
    temp_socket = %{
      socket
      | assigns: Map.merge(socket.assigns, %{dungeon: dungeon, dungeon_level: new_level})
    }

    # Spawn quest monsters for any matching active NPC quests
    temp_socket = NpcQuestSystem.spawn_quest_monsters_for_theme(temp_socket, new_theme)

    # Get the updated dungeon after quest monster spawning
    dungeon = temp_socket.assigns.dungeon

    player_position = Movement.find_starting_position(dungeon)

    # Initialize revealed squares (including light areas)
    final_revealed = FogOfWar.initialize_revealed_with_light(dungeon, player_position)

    # Calculate viewport for the new dungeon
    {viewport_x, viewport_y, viewport_width, viewport_height} =
      calculate_viewport_for_player(socket, player_position, dungeon)

    # Prepare transition data for main LiveView to assign
    transition_data = %{
      dungeon: dungeon,
      player_position: player_position,
      dungeon_level: new_level,
      revealed_squares: final_revealed,
      viewport_x: viewport_x,
      viewport_y: viewport_y,
      viewport_width: viewport_width,
      viewport_height: viewport_height,
      reset_state: true
    }

    # Return original socket (no updates) and transition data
    {socket, transition_data}
  end

  # Viewport management functions - removed socket updates, just calculate values
  defp get_viewport_size(:mobile), do: {6, 6}
  defp get_viewport_size(:normal), do: {16, 16}

  # Calculate viewport for a specific position and dungeon
  defp calculate_viewport_for_player(socket, {player_x, player_y}, dungeon) do
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

    {viewport_x, viewport_y, viewport_width, viewport_height}
  end
end
