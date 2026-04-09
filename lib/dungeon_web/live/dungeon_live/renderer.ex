defmodule DungeonWeb.DungeonLive.Renderer do
  @moduledoc """
  Template rendering and grid display logic
  """

  alias DungeonWeb.DungeonLive.{FogOfWar, Movement}

  # List of room tile types
  @room_tiles [
    :floor,
    :room_trap,
    :treasure,
    :trapped_treasure,
    :stair_up,
    :stair_down,
    :pillar,
    :torch,
    :bread,
    :cheese,
    :grapes,
    :healing_potion,
    :pile_of_bones
  ]

  @doc """
  Get door orientation based on adjacent room positions
  """
  def get_door_orientation(grid, x, y, tile) do
    case tile do
      t when t in [:door, :locked_door, :trapped_door, :locked_trapped_door, :secret_door] ->
        # Check adjacent tiles to determine which side faces a room
        north = Map.get(grid, {x, y - 1})
        south = Map.get(grid, {x, y + 1})
        east = Map.get(grid, {x + 1, y})
        west = Map.get(grid, {x - 1, y})

        cond do
          room_tile?(north) -> :north
          room_tile?(south) -> :south
          room_tile?(east) -> :east
          room_tile?(west) -> :west
          # default
          true -> :north
        end

      _ ->
        nil
    end
  end

  @doc """
  Check if a tile is a room tile type
  """
  def room_tile?(tile) do
    tile in @room_tiles or match?({:room_label, _}, tile) or
      match?({:encounter, _, _}, tile) or match?({:starting_stair, _}, tile) or
      match?({:starting_waypoint, _}, tile) or
      match?({:special_feature, _, _}, tile) or match?({:waypoint, _}, tile) or
      map_link_tile?(tile)
  end

  @doc """
  Determine click action for a grid square
  """
  def click_action(x, y, dungeon, revealed_squares, fog_enabled, player_position, unlocked_doors) do
    tile = Map.get(dungeon.grid, {x, y})
    revealed = FogOfWar.square_revealed?(x, y, revealed_squares, fog_enabled)

    determine_click_action(tile, {x, y}, revealed, player_position, unlocked_doors)
  end

  @doc """
  Get CSS classes for a tile based on its type and reveal status
  """
  def tile_classes(
        tile,
        revealed,
        position \\ nil,
        rooms \\ [],
        generation_type \\ "dungeon",
        fog_type \\ nil
      ) do
    border_class = tile_border_class(generation_type)

    base_classes =
      "dungeon-tile w-[48px] h-[48px] #{border_class} relative cursor-pointer touch-manipulation"

    color_class =
      if revealed,
        do: revealed_tile_color(tile, position, rooms, generation_type),
        else: fog_opacity_class(fog_type)

    "#{base_classes} #{color_class}"
  end

  @doc """
  Get border class based on generation type
  """
  def tile_border_class(_generation_type) do
    # No borders for any generation type in interactive view
    "border-0"
  end

  @doc """
  Get background color class for revealed tiles
  """
  def revealed_tile_color(tile, position \\ nil, rooms \\ [], generation_type \\ "dungeon") do
    cond do
      floor_tile?(tile) -> random_floor_texture(position, generation_type)
      corridor_tile?(tile) -> random_corridor_texture(position, generation_type)
      # Secret doors should look like walls when not revealed
      tile == :secret_door -> random_wall_texture(position, generation_type)
      door_tile?(tile) -> "bg-gray-600"
      pillar_tile?(tile) -> "bg-gray-800 rounded-full"
      wall_tile?(tile) -> random_wall_texture(position, generation_type)
      shrub_tile?(tile) -> random_shrub_texture(position, generation_type)
      true -> get_complex_tile_color(tile, position, rooms, generation_type)
    end
  end

  defp get_complex_tile_color(tile, position, rooms, generation_type) do
    cond do
      encounter_tile?(tile) ->
        encounter_background_color(position, rooms, generation_type)

      special_feature_tile?(tile) ->
        special_feature_background_color(position, rooms, generation_type)

      quest_item_tile?(tile) ->
        # Quest items should show floor background like other walkable items
        random_floor_texture(position, generation_type)

      map_link_tile?(tile) ->
        map_link_background_color(position, rooms, generation_type)

      true ->
        "bg-gray-900"
    end
  end

  @doc """
  Get random floor texture variation based on position
  """
  def random_floor_texture(position, generation_type \\ "dungeon") do
    case generation_type do
      "city" -> get_city_floor_texture(position)
      type when type in ["cavern", "outdoor"] -> "bg-gray-400"
      _ -> get_dungeon_floor_texture(position)
    end
  end

  # Helper function for traditional dungeon floor textures
  defp get_dungeon_floor_texture({x, y}) do
    # Use position to seed random variation for consistent results
    hash = rem(x * 31 + y * 17, 6)

    case hash do
      0 -> "bg-gray-500"
      1 -> "bg-gray-400"
      2 -> "bg-stone-400"
      3 -> "bg-stone-500"
      4 -> "bg-slate-400"
      _ -> "bg-slate-500"
    end
  end

  defp get_dungeon_floor_texture(nil), do: "bg-gray-500"

  # Helper function for city floor textures (wood floors)
  defp get_city_floor_texture({x, y}) do
    # Use position to seed random variation for consistent results
    hash = rem(x * 59 + y * 79, 6)

    case hash do
      0 -> "bg-amber-700"
      1 -> "bg-amber-800"
      2 -> "bg-yellow-700"
      3 -> "bg-yellow-800"
      4 -> "bg-orange-700"
      _ -> "bg-orange-800"
    end
  end

  defp get_city_floor_texture(nil), do: "bg-amber-700"

  @doc """
  Get random floor tileset background position based on position and theme
  """
  def random_floor_tileset_style(position, theme \\ "light_cracked_stone.png") do
    tileset_path = "/images/tilesets/#{theme}"
    background_position = get_random_tile_position(position, 37, 23)

    "background-image: url('#{tileset_path}'); background-position: #{background_position}; background-size: 192px 192px; background-repeat: no-repeat;"
  end

  @doc """
  Get random wall tileset background position based on position and theme
  """
  def random_wall_tileset_style(position, theme \\ "dark_stone_with_vines.png") do
    tileset_path = "/images/tilesets/#{theme}"
    background_position = get_random_tile_position(position, 47, 19)

    "background-image: url('#{tileset_path}'); background-position: #{background_position}; background-size: 192px 192px; background-repeat: no-repeat;"
  end

  @doc """
  Get random corridor tileset background position based on position and theme
  """
  def random_corridor_tileset_style(
        position,
        road_theme \\ "dirt_and_grass.png",
        floor_theme \\ "light_cracked_stone.png",
        generation_type \\ "dungeon"
      ) do
    theme =
      case generation_type do
        "city" -> road_theme
        _ -> floor_theme
      end

    tileset_path = "/images/tilesets/#{theme}"
    background_position = get_random_tile_position(position, 43, 31)

    "background-image: url('#{tileset_path}'); background-position: #{background_position}; background-size: 192px 192px; background-repeat: no-repeat;"
  end

  @doc """
  Get random shrub tileset background position based on position and theme
  """
  def random_shrub_tileset_style(position, shrub_theme \\ "green_shrubs.png") do
    tileset_path = "/images/tilesets/#{shrub_theme}"
    background_position = get_random_tile_position(position, 79, 101)

    "background-image: url('#{tileset_path}'); background-position: #{background_position}; background-size: 192px 192px; background-repeat: no-repeat;"
  end

  # Helper function to calculate random tile position within a 4x4 grid
  defp get_random_tile_position(position, seed_x, seed_y) do
    case position do
      {x, y} ->
        # Use position to seed random variation for consistent results
        # Create a simple hash from coordinates for tile selection (0-15 for 4x4 grid)
        hash = rem(x * seed_x + y * seed_y, 16)

        # Convert hash to grid position (0-3 for both x and y)
        grid_x = rem(hash, 4)
        grid_y = div(hash, 4)

        # Convert grid position to background-position in pixels
        # Each tile is 48px in the scaled 192px background, so positions are 0px, -48px, -96px, -144px
        pos_x = grid_x * -48
        pos_y = grid_y * -48

        "#{pos_x}px #{pos_y}px"

      nil ->
        "0px 0px"
    end
  end

  @doc """
  Get random corridor texture variation based on position
  """
  def random_corridor_texture(position, generation_type \\ "dungeon") do
    case generation_type do
      "city" -> get_city_road_texture(position)
      type when type in ["cavern", "outdoor"] -> "bg-gray-400"
      _ -> get_dungeon_corridor_texture(position)
    end
  end

  # Helper function for traditional dungeon corridor textures
  defp get_dungeon_corridor_texture({x, y}) do
    # Use position to seed random variation for consistent results
    # Create a simple hash from coordinates (offset from floor hash)
    hash = rem(x * 37 + y * 23, 6)

    case hash do
      0 -> "bg-gray-600"
      1 -> "bg-gray-500"
      2 -> "bg-stone-500"
      3 -> "bg-stone-600"
      4 -> "bg-slate-500"
      _ -> "bg-slate-600"
    end
  end

  defp get_dungeon_corridor_texture(nil), do: "bg-gray-600"

  # Helper function for city road textures (cobblestone)
  defp get_city_road_texture({x, y}) do
    # Use position to seed random variation for consistent results
    hash = rem(x * 67 + y * 91, 6)

    case hash do
      0 -> "bg-slate-500"
      1 -> "bg-slate-600"
      2 -> "bg-gray-500"
      3 -> "bg-gray-600"
      4 -> "bg-stone-500"
      _ -> "bg-stone-600"
    end
  end

  defp get_city_road_texture(nil), do: "bg-slate-500"

  @doc """
  Get random stair tile image variation based on position and transition theme
  """
  def random_stair_tile_image(position, transition_theme \\ "dungeon_stairs") do
    case position do
      {x, y} ->
        # Use position to seed random variation for consistent results
        # Create a simple hash from coordinates for stair tile selection (1-4)
        hash = rem(x * 53 + y * 67, 4) + 1
        "/images/map_links/#{transition_theme}#{hash}.png"

      nil ->
        "/images/map_links/#{transition_theme}1.png"
    end
  end

  @doc """
  Get random door image variation based on position
  """
  def random_door_image(position) do
    case position do
      {x, y} ->
        # Use position to seed random variation for consistent results
        # Create a simple hash from coordinates for door selection (1-16)
        hash = rem(x * 73 + y * 97, 16) + 1
        door_number = String.pad_leading(to_string(hash), 2, "0")
        "/images/doors/door#{door_number}.png"

      nil ->
        "/images/doors/door01.png"
    end
  end

  @doc """
  Get random wall texture variation based on position and generation type
  """
  def random_wall_texture(position, generation_type \\ "dungeon") do
    case generation_type do
      "city" -> get_city_wall_texture(position)
      # Default wall color for dungeons/caverns/outdoor
      _ -> "bg-gray-800"
    end
  end

  @doc """
  Get random shrub texture variation based on position and generation type
  """
  def random_shrub_texture(position, _generation_type \\ "city") do
    get_city_shrub_texture(position)
  end

  # Helper function for city wall textures
  defp get_city_wall_texture({x, y}) do
    # Use position to seed random variation for consistent results
    hash = rem(x * 61 + y * 83, 6)

    case hash do
      0 -> "bg-stone-600"
      1 -> "bg-stone-700"
      2 -> "bg-gray-600"
      3 -> "bg-gray-700"
      4 -> "bg-slate-600"
      _ -> "bg-slate-700"
    end
  end

  defp get_city_wall_texture(nil), do: "bg-stone-600"

  # Helper function for city shrub textures
  defp get_city_shrub_texture({x, y}) do
    # Use position to seed random variation for consistent results
    hash = rem(x * 71 + y * 89, 6)

    case hash do
      0 -> "bg-green-600"
      1 -> "bg-green-700"
      2 -> "bg-emerald-600"
      3 -> "bg-emerald-700"
      4 -> "bg-lime-600"
      _ -> "bg-lime-700"
    end
  end

  defp get_city_shrub_texture(nil), do: "bg-green-600"

  # Determine background color for encounters based on location
  defp encounter_background_color(position, rooms, generation_type)

  # Default to floor color
  defp encounter_background_color(nil, _rooms, generation_type),
    do: random_floor_texture(nil, generation_type)

  defp encounter_background_color(position, rooms, generation_type) do
    case generation_type do
      "city" ->
        # For cities, check the type of room
        case point_in_city_building?(position, rooms) do
          true -> random_floor_texture(position, generation_type)
          false -> random_corridor_texture(position, generation_type)
        end

      _ ->
        # For other generation types, use original logic
        if point_in_any_room?(position, rooms) do
          random_floor_texture(position, generation_type)
        else
          random_corridor_texture(position, generation_type)
        end
    end
  end

  # Determine background color for special features based on location
  defp special_feature_background_color(position, rooms, generation_type)

  # Default to floor color
  defp special_feature_background_color(nil, _rooms, generation_type),
    do: random_floor_texture(nil, generation_type)

  defp special_feature_background_color(position, rooms, generation_type) do
    case generation_type do
      "city" ->
        # For cities, check the type of room
        case point_in_city_building?(position, rooms) do
          true -> random_floor_texture(position, generation_type)
          false -> random_corridor_texture(position, generation_type)
        end

      _ ->
        # For other generation types, use original logic
        if point_in_any_room?(position, rooms) do
          random_floor_texture(position, generation_type)
        else
          random_corridor_texture(position, generation_type)
        end
    end
  end

  # Determine background color for map links based on location
  defp map_link_background_color(position, rooms, generation_type)

  # Default to floor color
  defp map_link_background_color(nil, _rooms, generation_type),
    do: random_floor_texture(nil, generation_type)

  defp map_link_background_color(position, rooms, generation_type) do
    case generation_type do
      "city" ->
        # For cities, check the type of room
        case point_in_city_building?(position, rooms) do
          true -> random_floor_texture(position, generation_type)
          false -> random_corridor_texture(position, generation_type)
        end

      _ ->
        # For other generation types, use original logic
        if point_in_any_room?(position, rooms) do
          random_floor_texture(position, generation_type)
        else
          random_corridor_texture(position, generation_type)
        end
    end
  end

  # Check if a position is within any room
  defp point_in_any_room?({x, y}, rooms) do
    Enum.any?(rooms, fn room ->
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
    end)
  end

  # Check if a position is within a city building (not road intersection)
  defp point_in_city_building?({x, y}, rooms) do
    Enum.any?(rooms, fn room ->
      case room do
        # City building format - only return true for :building type
        %{type: :building, cells: cells} ->
          {x, y} in cells

        # Road intersection format - explicitly exclude these
        %{type: :road_intersection} ->
          false

        # Traditional room format (for backwards compatibility, non-city dungeons)
        %{x: room_x, y: room_y, width: width, height: height} when not is_map_key(room, :type) ->
          x >= room_x and x < room_x + width and
            y >= room_y and y < room_y + height

        # Fallback
        _ ->
          false
      end
    end)
  end

  @doc """
  Check if lock icon should be shown for a door
  """
  def show_lock_icon?(tile, position, unlocked_doors) do
    tile in [:locked_door, :locked_trapped_door] and
      not MapSet.member?(unlocked_doors, position)
  end

  @doc """
  Check if trap warning should be shown (for doors and treasures)
  """
  def show_trap_warning?(tile, position, clicked_squares, fog_enabled) do
    tile in [:trapped_door, :locked_trapped_door, :trapped_treasure] and
      FogOfWar.show_door_trap?(elem(position, 0), elem(position, 1), clicked_squares, fog_enabled)
  end

  @doc """
  Check if secret door should be shown (revealed or fog disabled)
  """
  def show_secret_door?(tile, position, revealed_secret_doors, fog_enabled) do
    tile == :secret_door and
      (not fog_enabled or MapSet.member?(revealed_secret_doors || MapSet.new(), position))
  end

  @doc """
  Get stair arrow for stairs
  """
  def stair_arrow(:stair_up), do: "↑"
  def stair_arrow(:stair_down), do: "↓"
  def stair_arrow({:starting_stair, label}), do: label
  def stair_arrow(_), do: ""

  @doc """
  Check if room trap should bounce (animate)
  """
  def room_trap_bounce?(position, sprung_traps) do
    MapSet.member?(sprung_traps, position)
  end

  # Public tile classification helpers for template usage

  @doc """
  Check if tile is a floor tile
  """
  def floor_tile?(tile) do
    tile in [
      :floor,
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
    ] or match?({:starting_stair, _}, tile) or
      map_link_tile?(tile)
  end

  @doc """
  Check if tile is a corridor tile
  """
  def corridor_tile?(tile) do
    tile in [:corridor, :road] or match?({:corridor_label, _}, tile)
  end

  @doc """
  Check if tile is a wall tile
  """
  def wall_tile?(tile) do
    tile in [:wall, :secret_door]
  end

  @doc """
  Check if tile is a shrub tile (city terrain)
  """
  def shrub_tile?(tile) do
    tile == :shrub
  end

  @doc """
  Check if tile is an encounter tile
  """
  def encounter_tile?(tile) do
    match?({:encounter, _, _}, tile)
  end

  @doc """
  Check if tile is a monster tile (surprise monsters from special features)
  """
  def monster_tile?(tile) do
    match?({:monster, _}, tile)
  end

  @doc """
  Check if tile is a special feature tile
  """
  def special_feature_tile?(tile) do
    match?({:special_feature, _, _}, tile)
  end

  @doc """
  Check if tile is a door tile
  """
  def door_tile?(tile) do
    tile in [:door, :locked_door, :trapped_door, :locked_trapped_door, :secret_door]
  end

  @doc """
  Check if tile is a pillar tile (special feature pillar)
  """
  def pillar_tile?(tile) do
    case tile do
      {:special_feature, _, "Pillar"} -> true
      _ -> false
    end
  end

  @doc """
  Check if tile is a stair tile
  """
  def stair_tile?(tile) do
    tile in [:stair_up, :stair_down] or match?({:starting_stair, _}, tile)
  end

  @doc """
  Check if tile is a waypoint tile
  """
  def waypoint_tile?(tile) do
    match?({:waypoint, _}, tile) or match?({:starting_waypoint, _}, tile)
  end

  @doc """
  Check if tile is a map link tile (entrance/exit)
  """
  def map_link_tile?(tile) do
    match?({:cavern_entrance, _}, tile) or
      match?({:dungeon_entrance, _}, tile) or
      match?({:cavern_exit, _}, tile) or
      match?({:dungeon_exit, _}, tile)
  end

  @doc """
  Check if tile is a quest item tile
  """
  def quest_item_tile?(tile) do
    match?({:quest_item, _}, tile)
  end

  @doc """
  Check if tile contains label
  """
  def label_tile?(tile) do
    match?({:room_label, _}, tile) or match?({:corridor_label, _}, tile) or
      match?({:area_label, _}, tile) or match?({:building_label, _}, tile)
  end

  @doc """
  Check if tile is a label that needs background texture.
  Labels need city-aware background selection.
  """
  def label_with_background_tile?(tile) do
    match?({:room_label, _}, tile) or match?({:corridor_label, _}, tile) or
      match?({:area_label, _}, tile) or match?({:building_label, _}, tile)
  end

  @doc """
  Check if position should use floor texture (vs corridor texture) for overlay items.
  This is city-aware - only returns true for actual buildings, not road intersections.
  """
  def should_use_floor_texture?(position, rooms, generation_type) do
    case generation_type do
      "city" ->
        point_in_city_building?(position, rooms)

      _ ->
        point_in_any_room?(position, rooms)
    end
  end

  @doc """
  Check if position should use road-themed background texture for city maps.
  This is the inverse of should_use_floor_texture? for cities.
  """
  def should_use_road_fog?(tile, position, rooms, generation_type) do
    case generation_type do
      "city" ->
        # Use road background for road tiles and items placed on roads (not in buildings)
        corridor_tile?(tile) or not point_in_city_building?(position, rooms)

      _ ->
        false
    end
  end

  # Private tile classification helpers

  defp determine_click_action(tile, position, revealed, player_position, unlocked_doors) do
    if revealed do
      revealed_tile_action(tile, position, player_position, unlocked_doors)
    else
      "reveal_square"
    end
  end

  defp revealed_tile_action(tile, position, player_position, unlocked_doors) do
    # Check if player is adjacent to this position
    adjacent = Movement.adjacent_to_player?(position, player_position)

    action = determine_primary_action(tile, position, player_position, adjacent, unlocked_doors)
    action || fallback_action(position, player_position)
  end

  defp determine_primary_action(tile, position, player_position, adjacent, unlocked_doors) do
    # First check for encounter actions (require adjacency)
    if encounter_action_available?(tile, adjacent) do
      "click_encounter"
    else
      # Check for other types of actions
      determine_non_encounter_action(tile, position, player_position, adjacent, unlocked_doors)
    end
  end

  defp encounter_action_available?(tile, adjacent) do
    clickable_encounter_tile?(tile) and adjacent
  end

  defp determine_non_encounter_action(tile, position, player_position, adjacent, unlocked_doors) do
    cond do
      # Other adjacent clickable tiles (labels, features): move player to them
      adjacent and adjacent_clickable_non_encounter_tile?(tile) ->
        "move_player"

      # Non-encounter dialog tiles (labels, features): clickable from any distance
      clickable_non_encounter_dialog_tile?(tile) ->
        get_dialog_action(tile)

      clickable_door_tile?(tile, position, player_position, unlocked_doors) ->
        "click_door"

      clickable_stair_tile?(tile, position, player_position) ->
        "click_stair"

      clickable_waypoint_tile?(tile, position, player_position) ->
        "click_waypoint"

      clickable_map_link_tile?(tile, position, player_position) ->
        "click_map_link"

      true ->
        nil
    end
  end

  defp fallback_action(position, player_position) do
    if player_position != position do
      "move_player"
    else
      "reveal_square"
    end
  end

  # Helper to check if tile is clickable when adjacent (excluding encounters)
  defp adjacent_clickable_non_encounter_tile?(tile) do
    clickable_label_tile?(tile) or clickable_feature_tile?(tile)
  end

  # Helper to check if tile shows dialogs when clicked (excluding encounters)
  defp clickable_non_encounter_dialog_tile?(tile) do
    clickable_label_tile?(tile) or clickable_feature_tile?(tile)
  end

  # Helper to get the appropriate dialog action
  defp get_dialog_action(tile) do
    cond do
      clickable_label_tile?(tile) -> "click_label"
      clickable_feature_tile?(tile) -> "click_feature"
      clickable_encounter_tile?(tile) -> "click_encounter"
      true -> "reveal_square"
    end
  end

  defp clickable_label_tile?(tile) do
    match?({:room_label, _}, tile) or match?({:corridor_label, _}, tile) or
      match?({:building_label, _}, tile)
  end

  defp clickable_feature_tile?(tile) do
    case tile do
      # Pillars are not clickable
      {:special_feature, _, "Pillar"} -> false
      {:special_feature, _, _} -> true
      _ -> false
    end
  end

  defp clickable_encounter_tile?(tile) do
    match?({:encounter, _, _}, tile) or match?({:monster, _}, tile)
  end

  defp clickable_door_tile?(tile, position, player_position, _unlocked_doors) do
    # Check if it's any door type adjacent to the player
    door_tile?(tile) and Movement.adjacent_to_player?(position, player_position)
  end

  defp clickable_stair_tile?(tile, position, player_position) do
    # Check if it's any stair type where the player is standing
    stair_tile?(tile) and position == player_position
  end

  defp clickable_waypoint_tile?(tile, position, player_position) do
    # Check if it's a waypoint where the player is standing
    waypoint_tile?(tile) and position == player_position
  end

  defp clickable_map_link_tile?(tile, position, player_position) do
    # Check if it's a map link where the player is standing
    map_link_tile?(tile) and position == player_position
  end

  @doc """
  Check if an image should be horizontally flipped based on adjacent walls/shrubs
  Returns true if there's a wall/shrub on the right (so image should face left)
  """
  def should_flip_image?(x, y, dungeon_grid) do
    # Check for walls/shrubs on the left and right
    left_tile = Map.get(dungeon_grid, {x - 1, y})
    right_tile = Map.get(dungeon_grid, {x + 1, y})

    has_wall_left = wall_or_shrub_tile?(left_tile)
    has_wall_right = wall_or_shrub_tile?(right_tile)

    cond do
      # If there's a wall/shrub on the right but not the left, flip to face left
      has_wall_right and not has_wall_left ->
        true

      # If there's a wall/shrub on the left but not the right, don't flip (face right - default)
      has_wall_left and not has_wall_right ->
        false

      # If neither side has walls/shrubs, add randomness (50% chance to flip)
      not has_wall_left and not has_wall_right ->
        # Use position-based seed for consistent randomness per position
        random_seed = rem(x * 37 + y * 23, 2)
        random_seed == 1

      # If both sides have walls, don't flip (keep default right-facing)
      true ->
        false
    end
  end

  @doc """
  Get CSS transform style for image flipping based on adjacent walls/shrubs
  """
  def get_image_flip_style(x, y, dungeon_grid) do
    if should_flip_image?(x, y, dungeon_grid) do
      "transform: scaleX(-1);"
    else
      ""
    end
  end

  @doc """
  Create a background-image style with optional transform for flipping.
  This consolidates image loading by using CSS background-image instead of img tags.
  Allows optional background-size override via extra_styles.
  """
  def bg_image_style(image_path, x, y, dungeon_grid, extra_styles \\ "") do
    flip_style = get_image_flip_style(x, y, dungeon_grid)

    # Default to contain, but allow override via extra_styles
    base_size =
      if String.contains?(extra_styles, "background-size:"),
        do: "",
        else: "background-size: contain; "

    combined_styles =
      "background-image: url('#{image_path}'); #{base_size}background-position: center; background-repeat: no-repeat; #{flip_style} #{extra_styles}"

    String.trim(combined_styles)
  end

  @doc """
  Create a background-image style without flip detection (for static icons).
  Allows optional background-size override via extra_styles.
  """
  def bg_image_style_static(image_path, extra_styles \\ "") do
    # Default to contain, but allow override via extra_styles
    base_size =
      if String.contains?(extra_styles, "background-size:"),
        do: "",
        else: "background-size: contain; "

    combined_styles =
      "background-image: url('#{image_path}'); #{base_size}background-position: center; background-repeat: no-repeat; #{extra_styles}"

    String.trim(combined_styles)
  end

  @doc """
  Create a background-image style with custom transform (for player sprite).
  """
  def bg_image_style_custom(image_path, custom_styles) do
    combined_styles =
      "background-image: url('#{image_path}'); background-size: contain; background-position: center; background-repeat: no-repeat; #{custom_styles}"

    String.trim(combined_styles)
  end

  @doc """
  Get background-size style for a specific size class.
  Extracts pixel dimensions from Tailwind classes like "w-[96px] h-[96px]" and
  returns explicit background-size to ensure images render at their intended size.
  """
  def bg_size_from_class(size_class) when is_binary(size_class) do
    case Regex.run(~r/w-\[(\d+)px\]/, size_class) do
      [_, pixels] -> "background-size: #{pixels}px #{pixels}px;"
      _ -> ""
    end
  end

  def bg_size_from_class(_), do: ""

  # Helper function to check if a tile is a wall or shrub
  defp wall_or_shrub_tile?(tile) do
    tile == :wall or tile == :shrub
  end

  @doc """
  Get fog opacity class based on fog type
  """
  def fog_opacity_class(fog_type) do
    case fog_type do
      "dark" -> "bg-black bg-opacity-80"
      "dim" -> "bg-black bg-opacity-60"
      "daylight" -> "bg-gray-200 bg-opacity-20"
      # Default to dark fog if fog_type is nil or unknown
      _ -> "bg-black"
    end
  end

  @doc """
  Get floor tile opacity class based on generation type
  For dungeons: opacity-50 (shows checkered pattern)
  For caverns/outdoor: opacity-75 (less drastic transparency)
  For cities: full opacity (no checkerboard pattern)
  """
  def floor_tile_opacity_class(generation_type) do
    case generation_type do
      "dungeon" -> "w-full h-full object-cover opacity-75 tile-background"
      "cavern" -> "w-full h-full object-cover opacity-85 tile-background"
      "outdoor" -> "w-full h-full object-cover opacity-95 tile-background"
      "city" -> "w-full h-full object-cover tile-background"
      # Default to dungeon style
      _ -> "w-full h-full object-cover opacity-50 tile-background"
    end
  end

  @doc """
  Get the appropriate tileset style for a tile based on its type and position
  """
  def get_tile_background_style(tile, position, dungeon) do
    cond do
      floor_tile?(tile) or encounter_tile?(tile) or special_feature_tile?(tile) or
        monster_tile?(tile) or label_with_background_tile?(tile) ->
        if should_use_floor_texture?(position, dungeon.rooms, dungeon.generation_type) do
          random_floor_tileset_style(position, dungeon.floor_theme)
        else
          random_corridor_tileset_style(
            position,
            Map.get(dungeon, :road_theme, "dirt_and_grass.png"),
            dungeon.floor_theme,
            dungeon.generation_type
          )
        end

      corridor_tile?(tile) ->
        random_corridor_tileset_style(
          position,
          Map.get(dungeon, :road_theme, "dirt_and_grass.png"),
          dungeon.floor_theme,
          dungeon.generation_type
        )

      wall_tile?(tile) ->
        random_wall_tileset_style(position, dungeon.wall_theme)

      shrub_tile?(tile) ->
        random_shrub_tileset_style(
          position,
          Map.get(dungeon, :shrub_theme, "green_shrubs.png")
        )

      door_tile?(tile) ->
        random_floor_tileset_style(position, dungeon.floor_theme)

      true ->
        # Default to floor tileset for other tile types
        if dungeon.generation_type == "city" and
             should_use_road_fog?(tile, position, dungeon.rooms, dungeon.generation_type) do
          random_corridor_tileset_style(
            position,
            Map.get(dungeon, :road_theme, "dirt_and_grass.png"),
            dungeon.floor_theme,
            dungeon.generation_type
          )
        else
          random_floor_tileset_style(position, dungeon.floor_theme)
        end
    end
  end

  @doc """
  Get the appropriate CSS class for tile opacity based on tile type and generation type
  """
  def get_tile_opacity_class(tile, generation_type) do
    if wall_tile?(tile) or shrub_tile?(tile) do
      "w-full h-full tile-background"
    else
      floor_tile_opacity_class(generation_type)
    end
  end
end
