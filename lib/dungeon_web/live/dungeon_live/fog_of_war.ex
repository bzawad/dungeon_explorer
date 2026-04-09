defmodule DungeonWeb.DungeonLive.FogOfWar do
  @moduledoc """
  Fog of war revelation and area discovery logic
  """

  alias Dungeon.Generator.Features
  alias DungeonWeb.DungeonLive.EncounterSystem

  @doc """
  Initialize revealed squares starting with R1 room and player position
  """
  def initialize_revealed(dungeon, player_position) do
    # Find R1 room to start exploration
    r1_room = Enum.find(dungeon.rooms, fn room -> room.number == "R1" end)

    # Initialize revealed squares - start with R1 and surrounding area
    initial_revealed =
      if r1_room do
        reveal_room_and_surroundings(r1_room, dungeon)
      else
        MapSet.new()
      end

    # Always ensure area around player starting position is revealed (using theme-based radius)
    {player_x, player_y} = player_position
    player_surroundings = get_surrounding_squares(player_x, player_y, dungeon)

    Enum.reduce(player_surroundings, initial_revealed, fn square, acc ->
      MapSet.put(acc, square)
    end)
  end

  @doc """
  Check if a square is revealed given fog state
  """
  def square_revealed?(x, y, revealed_squares, fog_enabled) do
    not fog_enabled or MapSet.member?(revealed_squares, {x, y})
  end

  @doc """
  Check if door trap should be shown
  """
  def show_door_trap?(x, y, clicked_squares, fog_enabled) do
    not fog_enabled or MapSet.member?(clicked_squares, {x, y})
  end

  @doc """
  Check if a square can be revealed (for click reveals)
  """
  def can_reveal_square?(x, y, revealed_squares, dungeon, player_position) do
    # Check if the square is already revealed
    if MapSet.member?(revealed_squares, {x, y}) do
      true
    else
      # Check if the square is within the theme-based fog radius of the player
      {player_x, player_y} = player_position
      radius = get_fog_radius(dungeon.fog_type)
      within_radius?({x, y}, {player_x, player_y}, radius)
    end
  end

  # Helper function to check if a position is within a given radius
  defp within_radius?({x, y}, {center_x, center_y}, radius) do
    abs(x - center_x) <= radius and abs(y - center_y) <= radius
  end

  @doc """
  Get surrounding area around a position based on theme fog_type
  daylight = 5, dim = 2, dark = 1
  """
  def get_surrounding_squares(x, y, dungeon) do
    radius = get_fog_radius(dungeon.fog_type)
    get_squares_in_radius(x, y, radius, dungeon)
  end

  @doc """
  Get squares in a specific radius around a position
  """
  def get_squares_in_radius(x, y, radius, dungeon) do
    for dx <- -radius..radius,
        dy <- -radius..radius,
        new_x = x + dx,
        new_y = y + dy,
        new_x >= 0 and new_x < dungeon.width and new_y >= 0 and new_y < dungeon.height,
        do: {new_x, new_y}
  end

  @doc """
  Get fog radius based on fog_type
  """
  def get_fog_radius(fog_type) do
    case fog_type do
      "daylight" -> 5
      "dim" -> 2
      "dark" -> 1
      # Default to dark fog if fog_type is nil or unknown
      _ -> 1
    end
  end

  @doc """
  Reveal room and its surrounding area
  """
  def reveal_room_and_surroundings(room, dungeon) do
    # Get all squares in the room (handle both traditional rooms and caverns)
    room_squares = get_room_squares(room)

    # Get surrounding squares (1 tile border around the room/cavern)
    surrounding_squares = get_room_surrounding_squares(room, room_squares, dungeon)

    MapSet.new(room_squares ++ surrounding_squares)
  end

  @doc """
  Auto-reveal room/corridor labels when player enters them
  """
  def reveal_area_labels(revealed_squares, {player_x, player_y}, dungeon) do
    # Find which room the player is in
    room_label = find_room_label_at_position({player_x, player_y}, dungeon)

    # Find which corridor the player is in
    corridor_label = find_corridor_label_at_position({player_x, player_y}, dungeon)

    # Add the labels to revealed squares
    revealed_squares
    |> add_label_if_found(room_label)
    |> add_label_if_found(corridor_label)
  end

  @doc """
  Check for newly revealed encounters
  """
  def check_for_revealed_encounters(old_revealed, new_revealed, dungeon, triggered_encounters) do
    # Find newly revealed squares
    newly_revealed = MapSet.difference(new_revealed, old_revealed)

    # Check if any newly revealed squares contain encounters
    newly_revealed
    |> Enum.filter(fn {x, y} ->
      tile = Map.get(dungeon.grid, {x, y})

      EncounterSystem.encounter_tile?(tile) and
        not MapSet.member?(triggered_encounters, {x, y})
    end)
    # Only trigger one encounter at a time
    |> List.first()
  end

  @doc """
  Check if a tile creates light

  Currently supports:
  - :torch

  Future plans when special features get attributes system:
  - {:special_feature, "brazier", %{creates_light: true}}
  - {:special_feature, "campfire", %{creates_light: true}}
  - {:special_feature, "candle", %{creates_light: true}}

  The creates_light attribute will be added to special features, allowing
  any feature to specify whether it creates light.
  """
  def creates_light?(tile) do
    case tile do
      :torch ->
        true

      {:special_feature, _label, feature_name} ->
        # Extract the actual feature name from tuple format if needed
        actual_feature_name = extract_feature_name(feature_name)
        Features.special_feature_creates_light?(actual_feature_name)

      # Map links create light (like sunlight coming from outside)
      {:cavern_entrance, _} ->
        true

      {:dungeon_entrance, _} ->
        true

      {:cavern_exit, _} ->
        true

      {:dungeon_exit, _} ->
        true

      # Quest items create magical light
      {:quest_item, _} ->
        true

      _ ->
        false
    end
  end

  @doc """
  Get all light-creating positions in the dungeon
  """
  def get_light_creating_positions(dungeon) do
    Enum.filter(dungeon.grid, fn {_position, tile} ->
      creates_light?(tile)
    end)
    |> Enum.map(fn {position, _tile} -> position end)
  end

  @doc """
  Reveal areas around all light-creating features
  """
  def reveal_light_areas(revealed_squares, dungeon) do
    light_positions = get_light_creating_positions(dungeon)

    Enum.reduce(light_positions, revealed_squares, fn position, acc ->
      {x, y} = position
      light_area = get_surrounding_squares(x, y, dungeon)
      Enum.reduce(light_area, acc, &MapSet.put(&2, &1))
    end)
  end

  @doc """
  Initialize revealed squares with R1 room, player position, and light areas
  """
  def initialize_revealed_with_light(dungeon, player_position) do
    # Start with standard initialization
    initial_revealed = initialize_revealed(dungeon, player_position)

    # Add areas around light-creating features
    reveal_light_areas(initial_revealed, dungeon)
  end

  # Helper function to extract feature name from different formats
  defp extract_feature_name({feature_name, _rarity}) when is_binary(feature_name),
    do: feature_name

  defp extract_feature_name(feature_name) when is_binary(feature_name), do: feature_name
  defp extract_feature_name(_), do: "Unknown Feature"

  # Private functions
  defp find_room_label_at_position({x, y}, dungeon) do
    # Check if the player is in any room (handle both traditional rooms and caverns)
    Enum.find_value(dungeon.rooms, fn room ->
      player_in_room =
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

      if player_in_room do
        # Find the room label position in the grid
        find_label_in_grid(dungeon.grid, {:room_label, room.number})
      end
    end)
  end

  defp find_corridor_label_at_position({x, y}, dungeon) do
    # Check if the player is on a corridor-related tile or part of any corridor path
    tile = Map.get(dungeon.grid, {x, y})
    corridor_tiles = [:corridor, :door, :locked_door, :trapped_door, :locked_trapped_door]

    if tile in corridor_tiles or corridor_position?({x, y}, dungeon) do
      # Find nearby corridor labels by checking surrounding area
      find_nearby_corridor_label({x, y}, dungeon)
    end
  end

  defp corridor_position?({x, y}, dungeon) do
    # Check if this position is part of any corridor path
    Enum.any?(dungeon.corridors, fn corridor ->
      {x, y} in corridor.path
    end)
  end

  defp find_nearby_corridor_label({x, y}, dungeon) do
    # Search in a wider area around the player for corridor labels (expanded to 7x7)
    search_radius = 3

    for dx <- -search_radius..search_radius,
        dy <- -search_radius..search_radius,
        # Sort by distance, closer first
        reduce: nil do
      acc ->
        if acc do
          acc
        else
          check_x = x + dx
          check_y = y + dy

          case Map.get(dungeon.grid, {check_x, check_y}) do
            {:corridor_label, _} -> {check_x, check_y}
            _ -> nil
          end
        end
    end
  end

  defp find_label_in_grid(grid, target_label) do
    Enum.find_value(grid, fn {{x, y}, tile} ->
      if tile == target_label do
        {x, y}
      end
    end)
  end

  defp add_label_if_found(revealed_squares, nil), do: revealed_squares
  defp add_label_if_found(revealed_squares, {x, y}), do: MapSet.put(revealed_squares, {x, y})

  defp get_room_squares(room) do
    case room do
      # Traditional room format
      %{x: room_x, y: room_y, width: width, height: height} ->
        for x <- room_x..(room_x + width - 1),
            y <- room_y..(room_y + height - 1),
            do: {x, y}

      # Cavern format with cells
      %{cells: cells} ->
        cells

      # Fallback
      _ ->
        []
    end
  end

  defp get_room_surrounding_squares(room, room_squares, dungeon) do
    case room do
      # Traditional room format
      %{x: room_x, y: room_y, width: width, height: height} ->
        for x <- (room_x - 1)..(room_x + width),
            y <- (room_y - 1)..(room_y + height + 1),
            x >= 0 and x < dungeon.width and y >= 0 and y < dungeon.height,
            {x, y} not in room_squares,
            do: {x, y}

      # Cavern format with cells - get surrounding area
      %{cells: cells} ->
        get_cavern_surrounding_squares(cells, room_squares, dungeon)

      # Fallback
      _ ->
        []
    end
  end

  defp get_cavern_surrounding_squares(cells, room_squares, dungeon) do
    cells
    |> Enum.flat_map(fn {x, y} ->
      # Get 8 surrounding positions for each cell
      for dx <- -1..1, dy <- -1..1, dx != 0 or dy != 0 do
        {x + dx, y + dy}
      end
    end)
    |> Enum.uniq()
    |> Enum.filter(fn {x, y} ->
      x >= 0 and x < dungeon.width and y >= 0 and y < dungeon.height and
        {x, y} not in room_squares
    end)
  end
end
