defmodule Dungeon.Generator.Rooms do
  @moduledoc """
  Room generation and placement for dungeon generation
  """

  alias Dungeon.Generator.Grid

  # Room generation parameters
  @min_room_size 4
  @max_room_size 12
  @max_rooms 12
  @max_attempts 50

  @doc """
  Generate all rooms for the dungeon
  """
  def generate do
    generate_recursive([], 0)
    |> add_room_numbers()
  end

  @doc """
  Place rooms on the grid
  """
  def place_on_grid(grid, rooms) do
    Enum.reduce(rooms, grid, fn room, acc_grid ->
      # Carve out room interior
      for x <- room.x..(room.x + room.width - 1),
          y <- room.y..(room.y + room.height - 1),
          reduce: acc_grid do
        acc -> Map.put(acc, {x, y}, :floor)
      end
    end)
  end

  @doc """
  Add room labels to the grid
  """
  def add_labels(grid, rooms) do
    Enum.reduce(rooms, grid, fn room, acc_grid ->
      # Place room label in center of room
      center_x = room.x + div(room.width, 2)
      center_y = room.y + div(room.height, 2)

      # Only place label if the center is floor (not pillar)
      case Map.get(acc_grid, {center_x, center_y}) do
        :floor ->
          Map.put(acc_grid, {center_x, center_y}, {:room_label, room.number})

        _ ->
          # If center is occupied, try adjacent positions
          find_label_position(acc_grid, room, center_x, center_y)
      end
    end)
  end

  @doc """
  Get the center coordinates of a room
  """
  def center(room) do
    {room.x + div(room.width, 2), room.y + div(room.height, 2)}
  end

  # Private functions

  defp generate_recursive(rooms, attempts)
       when attempts >= @max_attempts or length(rooms) >= @max_rooms do
    rooms
  end

  defp generate_recursive(rooms, attempts) do
    # Generate random room
    width = Enum.random(@min_room_size..@max_room_size)
    height = Enum.random(@min_room_size..@max_room_size)
    x = Enum.random(1..(Grid.map_width() - width - 1))
    y = Enum.random(1..(Grid.map_height() - height - 1))

    new_room = %{x: x, y: y, width: width, height: height}

    # Check if room overlaps with existing rooms
    if room_overlaps?(new_room, rooms) do
      generate_recursive(rooms, attempts + 1)
    else
      generate_recursive([new_room | rooms], attempts + 1)
    end
  end

  defp room_overlaps?(new_room, existing_rooms) do
    Enum.any?(existing_rooms, fn room ->
      # Add 1 cell buffer between rooms
      !(new_room.x + new_room.width + 1 < room.x or
          new_room.x > room.x + room.width + 1 or
          new_room.y + new_room.height + 1 < room.y or
          new_room.y > room.y + room.height + 1)
    end)
  end

  defp add_room_numbers(rooms) do
    rooms
    |> Enum.with_index(1)
    |> Enum.map(fn {room, index} ->
      Map.put(room, :number, "R#{index}")
    end)
  end

  defp find_label_position(grid, room, center_x, center_y) do
    # Try positions around the center
    potential_positions = [
      {center_x - 1, center_y},
      {center_x + 1, center_y},
      {center_x, center_y - 1},
      {center_x, center_y + 1},
      {center_x - 1, center_y - 1},
      {center_x + 1, center_y - 1},
      {center_x - 1, center_y + 1},
      {center_x + 1, center_y + 1}
    ]

    # Find first available floor position
    case Enum.find(potential_positions, fn {x, y} ->
           x >= room.x and x < room.x + room.width and
             y >= room.y and y < room.y + room.height and
             Map.get(grid, {x, y}) == :floor
         end) do
      {x, y} ->
        Map.put(grid, {x, y}, {:room_label, room.number})

      nil ->
        # If no position found, don't place label
        grid
    end
  end
end
