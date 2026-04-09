defmodule Dungeon.Generator.Grid do
  @moduledoc """
  Grid utilities and tile management for dungeon generation
  """

  # Map dimensions
  @map_width 64
  @map_height 48

  def map_width, do: @map_width
  def map_height, do: @map_height

  @doc """
  Initialize empty grid filled with walls
  """
  def initialize do
    for x <- 0..(@map_width - 1),
        y <- 0..(@map_height - 1),
        into: %{},
        do: {{x, y}, :wall}
  end

  @doc """
  Check if a point is within any room boundaries
  """
  def point_in_any_room?({x, y}, rooms) do
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

  @doc """
  Check if a position is available for placing treasure
  """
  def position_available_for_treasure?(grid, {x, y}) do
    case Map.get(grid, {x, y}) do
      :floor -> true
      :corridor -> true
      _ -> false
    end
  end

  @doc """
  Check if a room tile is nearby (used for corridor path planning)
  """
  def room_nearby?(grid, {x, y}) do
    case Map.get(grid, {x, y}) do
      :floor -> true
      _ -> false
    end
  end

  @doc """
  List of room tile types
  """
  def room_tiles do
    [
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
      :healing_potion
    ]
  end

  @doc """
  Check if a tile is a room tile
  """
  def room_tile?(tile) do
    tile in room_tiles() or match?({:room_label, _}, tile) or
      match?({:encounter, _}, tile) or match?({:starting_stair, _}, tile) or
      match?({:starting_waypoint, _}, tile) or
      match?({:special_feature, _, _}, tile) or match?({:waypoint, _}, tile)
  end
end
