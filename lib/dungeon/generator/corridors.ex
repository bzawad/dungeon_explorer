defmodule Dungeon.Generator.Corridors do
  @moduledoc """
  Corridor creation and pathfinding for dungeon generation
  """

  alias Dungeon.Generator.{Grid, Rooms}

  @doc """
  Connect rooms with corridors and track corridor info
  """
  def connect_rooms(grid, []), do: {grid, []}
  def connect_rooms(grid, [_single_room]), do: {grid, []}

  def connect_rooms(grid, rooms) do
    # Connect each room to the next one and track corridors
    room_pairs = Enum.zip(rooms, tl(rooms) ++ [hd(rooms)])

    {final_grid, corridors} =
      Enum.reduce(room_pairs, {grid, []}, fn {room1, room2}, {acc_grid, acc_corridors} ->
        corridor_number = "C#{length(acc_corridors) + 1}"

        {new_grid, corridor_path} =
          create_corridor_with_tracking(acc_grid, Rooms.center(room1), Rooms.center(room2))

        corridor = %{number: corridor_number, path: corridor_path}
        {new_grid, [corridor | acc_corridors]}
      end)

    {final_grid, Enum.reverse(corridors)}
  end

  @doc """
  Add corridor labels to the grid
  """
  def add_labels(grid, corridors, rooms) do
    Enum.reduce(corridors, grid, fn corridor, acc_grid ->
      # Find corridor segments that are NOT in rooms
      pure_corridor_path =
        Enum.filter(corridor.path, fn {x, y} ->
          Map.get(acc_grid, {x, y}) == :corridor and not Grid.point_in_any_room?({x, y}, rooms)
        end)

      # Place corridor label at the middle of pure corridor segments
      if length(pure_corridor_path) > 2 do
        middle_index = div(length(pure_corridor_path), 2)
        {label_x, label_y} = Enum.at(pure_corridor_path, middle_index)

        Map.put(acc_grid, {label_x, label_y}, {:corridor_label, corridor.number})
      else
        acc_grid
      end
    end)
  end

  # Private functions

  defp create_corridor_with_tracking(grid, {x1, y1}, {x2, y2}) do
    # Create L-shaped corridor avoiding room adjacency
    # Adjust paths to avoid running parallel to rooms
    {safe_y1, safe_x2} = find_safe_corridor_route(grid, {x1, y1}, {x2, y2})

    # First, move horizontally (possibly with offset)
    {grid, h_path} = create_horizontal_tunnel_with_tracking(grid, x1, safe_x2, safe_y1)
    # Then, move vertically
    {grid, v_path} = create_vertical_tunnel_with_tracking(grid, safe_y1, y2, safe_x2)

    {grid, h_path ++ v_path}
  end

  defp find_safe_corridor_route(grid, {x1, y1}, {x2, y2}) do
    # Try to find a route that doesn't run parallel to rooms
    # Check if the direct L-path would run adjacent to rooms
    if path_too_close_to_rooms?(grid, {x1, y1}, {x2, y2}) do
      # Offset the path to avoid room adjacency
      offset_y = if y1 < y2, do: y1 + 2, else: y1 - 2
      offset_x = if x1 < x2, do: x2 - 2, else: x2 + 2
      {offset_y, offset_x}
    else
      {y1, x2}
    end
  end

  defp path_too_close_to_rooms?(grid, {x1, y1}, {x2, y2}) do
    # Check if horizontal path from x1 to x2 at y1 would be too close to rooms
    min_x = min(x1, x2)
    max_x = max(x1, x2)

    # Check positions above and below the horizontal path
    # Check if vertical path from y1 to y2 at x2 would be too close to rooms
    Enum.any?(min_x..max_x, fn x ->
      Grid.room_nearby?(grid, {x, y1 - 1}) or Grid.room_nearby?(grid, {x, y1 + 1})
    end) or
      Enum.any?(min(y1, y2)..max(y1, y2), fn y ->
        Grid.room_nearby?(grid, {x2 - 1, y}) or Grid.room_nearby?(grid, {x2 + 1, y})
      end)
  end

  defp create_horizontal_tunnel_with_tracking(grid, x1, x2, y) do
    min_x = min(x1, x2)
    max_x = max(x1, x2)

    path = for x <- min_x..max_x, do: {x, y}

    grid =
      for x <- min_x..max_x, reduce: grid do
        acc ->
          # Only place corridor if it's not already a room floor and if it's safe
          case Map.get(acc, {x, y}) do
            # Don't overwrite room floors
            :floor ->
              acc

            _ ->
              Map.put(acc, {x, y}, :corridor)
          end
      end

    {grid, path}
  end

  defp create_vertical_tunnel_with_tracking(grid, y1, y2, x) do
    min_y = min(y1, y2)
    max_y = max(y1, y2)

    path = for y <- min_y..max_y, do: {x, y}

    grid =
      for y <- min_y..max_y, reduce: grid do
        acc ->
          # Only place corridor if it's not already a room floor and if it's safe
          case Map.get(acc, {x, y}) do
            # Don't overwrite room floors
            :floor ->
              acc

            _ ->
              Map.put(acc, {x, y}, :corridor)
          end
      end

    {grid, path}
  end
end
