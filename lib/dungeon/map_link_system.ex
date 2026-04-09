defmodule Dungeon.MapLinkSystem do
  @moduledoc """
  Handles map linking system with entrance/exit tokens that connect different themed maps.

  Map Link Rules:
  - Outdoor maps: spawn cavern_entrance -> cavern map, dungeon_entrance -> dungeon map
  - Dungeon maps: spawn 2x dungeon_exit -> outdoor maps
  - Cavern maps: spawn 2x cavern_exit -> outdoor maps

  Each map link provides light/glow effect and removes fog around it.
  """

  @doc """
  Add map links to a generated map based on its theme and generation type
  """
  def add_map_links(grid, areas, theme) do
    case theme.generation_type do
      "outdoor" -> add_outdoor_map_links(grid, areas, theme)
      "dungeon" -> add_dungeon_map_links(grid, areas, theme)
      "cavern" -> add_cavern_map_links(grid, areas, theme)
      "city" -> add_city_map_links(grid, areas, theme)
      _ -> grid
    end
  end

  @doc """
  Get all map link positions from a grid
  """
  def get_map_link_positions(grid) do
    grid
    |> Enum.filter(fn {_pos, tile} -> map_link_tile?(tile) end)
    |> Enum.map(fn {pos, _tile} -> pos end)
  end

  @doc """
  Check if a tile is a map link tile
  """
  def map_link_tile?(tile) do
    match?({:cavern_entrance, _}, tile) or
      match?({:dungeon_entrance, _}, tile) or
      match?({:cavern_exit, _}, tile) or
      match?({:dungeon_exit, _}, tile)
  end

  @doc """
  Get the destination theme type for a map link
  """
  def get_destination_type({:cavern_entrance, _}), do: "cavern"
  def get_destination_type({:dungeon_entrance, _}), do: "dungeon"
  def get_destination_type({:cavern_exit, _}), do: "outdoor"
  def get_destination_type({:dungeon_exit, _}), do: "outdoor"
  def get_destination_type(_), do: nil

  @doc """
  Generate a random destination theme name for a given type (city-aware)
  """
  def get_random_destination_theme(destination_type, current_theme \\ nil) do
    themes = get_themes_by_type(destination_type)

    # For cities, exclude other city themes to always link to outdoor areas
    filtered_themes =
      case current_theme do
        %{generation_type: "city"} ->
          Enum.filter(themes, fn theme -> theme.generation_type != "city" end)

        _ ->
          themes
      end

    case filtered_themes do
      [] -> "Unknown Area"
      list -> Enum.random(list).name
    end
  end

  @doc """
  Get the description for a map link based on its type and destination
  """
  def get_map_link_description(tile, destination_theme) do
    case tile do
      {:cavern_entrance, _} ->
        "**Cavern Entrance Discovered**\n\nYou've found a dark opening leading down into the earth. Cool, damp air flows from within, carrying the scent of stone and mystery. This entrance leads to: #{destination_theme}.\n\nDo you wish to venture into the depths?"

      {:dungeon_entrance, _} ->
        "**Ancient Entrance Discovered**\n\nBefore you stands an imposing entrance to an ancient structure. Weathered stone and iron hint at the secrets within. This entrance leads to: #{destination_theme}.\n\nDo you wish to explore what lies beyond?"

      {:cavern_exit, _} ->
        "**Exit to Surface**\n\nAhead, you can see natural light filtering down from above. Fresh air flows in, promising escape from these underground depths. This exit leads to: #{destination_theme}.\n\nDo you wish to return to the surface?"

      {:dungeon_exit, _} ->
        "**Exit to Outside**\n\nYou've found a way out of this ancient place. Sunlight streams in through the opening, and you can hear the sounds of the world beyond. This exit leads to: #{destination_theme}.\n\nDo you wish to leave this place behind?"

      _ ->
        "A mysterious passage leading to unknown lands."
    end
  end

  # Private functions

  defp add_outdoor_map_links(grid, areas, _theme) do
    # Outdoor maps get 2x cavern_entrance and 2x dungeon_entrance (4 total)
    grid = add_entrance_to_areas(grid, areas, :cavern_entrance, 2)
    grid = add_entrance_to_areas(grid, areas, :dungeon_entrance, 2)
    grid
  end

  defp add_dungeon_map_links(grid, areas, _theme) do
    # Dungeon maps get 4x dungeon_exit
    grid = add_exit_to_areas(grid, areas, :dungeon_exit, 4)
    grid
  end

  defp add_cavern_map_links(grid, areas, _theme) do
    # Cavern maps get 2x cavern_exit + 2x dungeon_exit (4 total)
    grid = add_exit_to_areas(grid, areas, :cavern_exit, 2)
    grid = add_exit_to_areas(grid, areas, :dungeon_exit, 2)
    grid
  end

  defp add_city_map_links(grid, _areas, _theme) do
    # Cities don't get traditional map links, they use waypoints that link to outdoor themes
    # This is handled by the waypoint system instead of map links
    grid
  end

  defp add_entrance_to_areas(grid, areas, entrance_type, count) do
    place_map_links(grid, areas, entrance_type, count)
  end

  defp add_exit_to_areas(grid, areas, exit_type, count) do
    place_map_links(grid, areas, exit_type, count)
  end

  defp place_map_links(grid, _areas, _link_type, 0), do: grid
  defp place_map_links(grid, [], _link_type, _count), do: grid

  defp place_map_links(grid, [area | remaining_areas], link_type, count) do
    # Get all existing map link positions to avoid clustering
    existing_map_links = get_map_link_positions(grid)

    case find_map_link_position(grid, area, existing_map_links) do
      nil ->
        # Couldn't place link in this area, try next
        place_map_links(grid, remaining_areas, link_type, count)

      {x, y} ->
        # Choose random image number (1 for now, can be expanded)
        link_number = 1
        link_tile = {link_type, link_number}
        updated_grid = Map.put(grid, {x, y}, link_tile)
        place_map_links(updated_grid, remaining_areas, link_type, count - 1)
    end
  end

  defp find_map_link_position(grid, %{cells: cells} = _area, existing_map_links)
       when is_list(cells) do
    find_position_in_cells(grid, cells, existing_map_links)
  end

  defp find_map_link_position(
         grid,
         %{x: x, y: y, width: width, height: height} = _area,
         existing_map_links
       ) do
    room_positions = generate_room_positions(x, y, width, height)
    find_position_in_room(grid, room_positions, existing_map_links)
  end

  defp find_map_link_position(_grid, _area, _existing_map_links), do: nil

  defp find_position_in_cells(grid, cells, existing_map_links) do
    case find_edge_positions_in_cells(grid, cells, existing_map_links) do
      [] -> find_fallback_positions_in_cells(grid, cells, existing_map_links)
      positions -> Enum.random(positions)
    end
  end

  defp find_position_in_room(grid, room_positions, existing_map_links) do
    case find_suitable_room_positions(grid, room_positions, existing_map_links) do
      [] -> find_fallback_room_positions(grid, room_positions, existing_map_links)
      positions -> Enum.random(positions)
    end
  end

  defp generate_room_positions(x, y, width, height) do
    for rx <- x..(x + width - 1), ry <- y..(y + height - 1), do: {rx, ry}
  end

  defp find_edge_positions_in_cells(grid, cells, existing_map_links) do
    Enum.filter(cells, fn {x, y} ->
      position_valid_for_map_link?(grid, {x, y}) and
        edge_position?(cells, {x, y}) and
        min_distance_from_existing_links?({x, y}, existing_map_links, 8) and
        min_distance_from_starting_points?({x, y}, 12)
    end)
  end

  defp find_fallback_positions_in_cells(grid, cells, existing_map_links) do
    Enum.find(cells, fn {x, y} ->
      position_valid_for_map_link?(grid, {x, y}) and
        min_distance_from_existing_links?({x, y}, existing_map_links, 5) and
        min_distance_from_starting_points?({x, y}, 8)
    end)
  end

  defp find_suitable_room_positions(grid, room_positions, existing_map_links) do
    Enum.filter(room_positions, fn {rx, ry} ->
      position_valid_for_map_link?(grid, {rx, ry}) and
        min_distance_from_existing_links?({rx, ry}, existing_map_links, 6) and
        min_distance_from_starting_points?({rx, ry}, 10)
    end)
  end

  defp find_fallback_room_positions(grid, room_positions, existing_map_links) do
    Enum.find(room_positions, fn {rx, ry} ->
      position_valid_for_map_link?(grid, {rx, ry}) and
        min_distance_from_existing_links?({rx, ry}, existing_map_links, 3)
    end)
  end

  defp position_valid_for_map_link?(grid, position) do
    Map.get(grid, position) == :floor and position_available_for_map_link?(grid, position)
  end

  defp edge_position?(cells, {x, y}) do
    # Check if position is on the edge of the area (has at least one non-area neighbor)
    neighbors = [{x - 1, y}, {x + 1, y}, {x, y - 1}, {x, y + 1}]
    Enum.any?(neighbors, fn pos -> pos not in cells end)
  end

  defp get_themes_by_type(type) do
    # Use the helper function from Generator module
    Dungeon.Generator.get_themes_by_type(type)
  end

  # Check if position is available for map link placement
  defp position_available_for_map_link?(grid, {x, y}) do
    case Map.get(grid, {x, y}) do
      :floor -> true
      _ -> false
    end
  end

  # Check if position is far enough from existing map links
  defp min_distance_from_existing_links?(_position, [], _min_distance), do: true

  defp min_distance_from_existing_links?({x, y}, existing_links, min_distance) do
    Enum.all?(existing_links, fn {ex, ey} ->
      # Manhattan distance
      distance = abs(x - ex) + abs(y - ey)
      distance >= min_distance
    end)
  end

  # Check if position is far enough from typical starting points
  defp min_distance_from_starting_points?({x, y}, min_distance) do
    # Common starting points to avoid
    starting_points = [
      # Common cavern/dungeon starting point
      {10, 12},
      # Common outdoor starting point
      {25, 25},
      # Another common point
      {15, 15},
      # Another common point
      {20, 20}
    ]

    Enum.all?(starting_points, fn {sx, sy} ->
      # Manhattan distance
      distance = abs(x - sx) + abs(y - sy)
      distance >= min_distance
    end)
  end
end
