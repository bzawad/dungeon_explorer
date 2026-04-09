defmodule Dungeon.Generator.Outdoor do
  @moduledoc """
  Outdoor area generation using hybrid approach:
  1. Generate traditional dungeon foundation (same as caverns)
  2. Transform rooms to organic outdoor areas
  3. Widen corridors to natural paths
  4. Apply organic growth for natural appearance
  5. Use waypoints instead of stairs for level transitions
  """

  alias Dungeon.Generator.{Corridors, Grid, Rooms}

  @doc """
  Generate natural outdoor area
  """
  def generate do
    # Use hybrid approach for reliable connectivity (same as caverns)
    foundation = generate_traditional_foundation()
    {grid, areas} = transform_rooms_to_outdoor_areas(foundation)
    grid = transform_corridors_to_paths(grid, foundation.corridors)
    grid = apply_organic_growth(grid, areas)

    # Return tuple format expected by main generator
    {grid, areas}
  end

  @doc """
  Get center coordinates of an outdoor area
  """
  def center(area) do
    if area.cells != [] do
      # Calculate centroid of all cells
      {sum_x, sum_y} =
        Enum.reduce(area.cells, {0, 0}, fn {x, y}, {acc_x, acc_y} ->
          {acc_x + x, acc_y + y}
        end)

      count = length(area.cells)
      {div(sum_x, count), div(sum_y, count)}
    else
      # Fallback to map center
      {32, 24}
    end
  end

  @doc """
  Add outdoor area labels to the grid
  """
  def add_labels(grid, areas) do
    Enum.reduce(areas, grid, fn area, acc_grid ->
      {center_x, center_y} = center(area)

      # Find a suitable position near the center for the label
      case find_label_position(acc_grid, area, center_x, center_y) do
        {x, y} -> Map.put(acc_grid, {x, y}, {:area_label, area.number})
        nil -> acc_grid
      end
    end)
  end

  # Private helper functions

  defp grow_area_organically(grid, area) do
    # Apply organic blob growth around area cells (same pattern as caverns)
    seed_count = min(3, div(length(area.cells), 8))
    seeds = Enum.take_random(area.cells, seed_count)

    # Grow blobs from seed points
    Enum.reduce(1..2, grid, fn _iteration, acc_grid ->
      grow_blobs_iteration(acc_grid, seeds)
    end)
  end

  defp grow_blobs_iteration(grid, seeds) do
    Enum.reduce(seeds, grid, fn {seed_x, seed_y}, acc_grid ->
      directions = [{-1, -1}, {-1, 0}, {-1, 1}, {0, -1}, {0, 1}, {1, -1}, {1, 0}, {1, 1}]
      random_directions = Enum.take_random(directions, 4)

      Enum.reduce(random_directions, acc_grid, fn {dx, dy}, inner_grid ->
        grow_blob_in_direction(inner_grid, seed_x, seed_y, dx, dy)
      end)
    end)
  end

  defp grow_blob_in_direction(grid, seed_x, seed_y, dx, dy) do
    new_x = seed_x + dx
    new_y = seed_y + dy

    if new_x > 0 and new_x < Grid.map_width() - 1 and
         new_y > 0 and new_y < Grid.map_height() - 1 and
         :rand.uniform() < 0.6 do
      Map.put(grid, {new_x, new_y}, :floor)
    else
      grid
    end
  end

  defp find_label_position(grid, area, center_x, center_y) do
    # Try positions around the center, preferring floor cells within the area
    potential_positions = [
      {center_x, center_y},
      {center_x - 1, center_y},
      {center_x + 1, center_y},
      {center_x, center_y - 1},
      {center_x, center_y + 1},
      {center_x - 1, center_y - 1},
      {center_x + 1, center_y - 1},
      {center_x - 1, center_y + 1},
      {center_x + 1, center_y + 1}
    ]

    Enum.find(potential_positions, fn {x, y} ->
      {x, y} in area.cells and Map.get(grid, {x, y}) == :floor
    end)
  end

  # Hybrid approach functions

  defp generate_traditional_foundation do
    # Generate a traditional dungeon as our foundation (same as caverns)
    grid = Grid.initialize()
    rooms = Rooms.generate()
    grid = Rooms.place_on_grid(grid, rooms)
    {grid, corridors} = Corridors.connect_rooms(grid, rooms)

    %{grid: grid, rooms: rooms, corridors: corridors}
  end

  defp transform_rooms_to_outdoor_areas(traditional_dungeon) do
    # Convert traditional rectangular rooms into organic outdoor areas
    areas =
      traditional_dungeon.rooms
      |> Enum.with_index(1)
      |> Enum.map(fn {room, index} ->
        # Generate organic shape around the room area
        cells = generate_organic_area(room)

        %{cells: cells, number: "A#{index}"}
      end)

    # Start with traditional grid and enhance with organic growth
    grid = enhance_grid_with_organic_shapes(traditional_dungeon.grid, areas)

    {grid, areas}
  end

  defp transform_corridors_to_paths(grid, corridors) do
    # Convert straight corridors into wider, more natural paths
    Enum.reduce(corridors, grid, fn corridor, acc_grid ->
      widen_corridor_to_path(acc_grid, corridor.path)
    end)
  end

  defp apply_organic_growth(grid, areas) do
    # Apply organic blob growth around the foundation areas
    Enum.reduce(areas, grid, fn area, acc_grid ->
      grow_area_organically(acc_grid, area)
    end)
  end

  defp generate_organic_area(room) do
    # Generate organic area cells based on traditional room bounds
    base_cells =
      for x <- room.x..(room.x + room.width - 1),
          y <- room.y..(room.y + room.height - 1),
          do: {x, y}

    # Add some organic expansion around the room
    expanded_cells =
      Enum.reduce(base_cells, base_cells, fn {x, y}, acc ->
        # Randomly add adjacent cells for organic shape
        adjacent = [{x - 1, y}, {x + 1, y}, {x, y - 1}, {x, y + 1}]
        new_cells = Enum.filter(adjacent, fn _ -> :rand.uniform() < 0.4 end)
        acc ++ new_cells
      end)

    Enum.uniq(expanded_cells)
  end

  defp enhance_grid_with_organic_shapes(grid, areas) do
    # Ensure all area cells are floor
    Enum.reduce(areas, grid, fn area, acc_grid ->
      Enum.reduce(area.cells, acc_grid, fn {x, y}, inner_grid ->
        Map.put(inner_grid, {x, y}, :floor)
      end)
    end)
  end

  defp widen_corridor_to_path(grid, corridor_path) do
    # Convert corridor to wider path (same as caverns but conceptually paths)
    Enum.reduce(corridor_path, grid, fn {x, y}, acc_grid ->
      # Place floor at corridor position
      acc_grid = Map.put(acc_grid, {x, y}, :floor)

      # Add adjacent cells for width
      adjacent = [{x - 1, y}, {x + 1, y}, {x, y - 1}, {x, y + 1}]
      widen_corridor_cell(acc_grid, adjacent)
    end)
  end

  defp widen_corridor_cell(grid, adjacent_positions) do
    Enum.reduce(adjacent_positions, grid, fn {adj_x, adj_y}, inner_grid ->
      if adj_x > 0 and adj_x < Grid.map_width() - 1 and
           adj_y > 0 and adj_y < Grid.map_height() - 1 and
           :rand.uniform() < 0.5 do
        Map.put(inner_grid, {adj_x, adj_y}, :floor)
      else
        inner_grid
      end
    end)
  end
end
