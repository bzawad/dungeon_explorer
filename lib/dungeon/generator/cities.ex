defmodule Dungeon.Generator.Cities do
  @moduledoc """
  City map generation using a grid-based urban layout algorithm:
  1. Fill entire map with shrubs (non-walkable)
  2. Divide map into uniform grid of rectangular building blocks
  3. Carve 2-tile wide roads between blocks
  4. Place buildings in 70% of blocks with doors connecting to roads
  """

  alias Dungeon.Generator.Grid

  # Building block parameters
  @block_width 12
  @block_height 10
  @road_width 2

  @doc """
  Generate city map
  Returns {grid, city_blocks} tuple where city_blocks represents areas for feature placement
  """
  def generate(theme_data \\ %{}) do
    # Initialize map filled with shrubs
    grid = initialize_with_shrubs(theme_data)

    # Calculate building blocks based on map dimensions
    blocks = calculate_building_blocks()

    # Carve roads between blocks
    grid = carve_roads(grid, blocks, theme_data)

    # Place buildings in blocks (70% chance each)
    {grid, placed_buildings} = place_buildings(grid, blocks, theme_data)

    # Add organic variation to shrub/road boundaries
    grid = add_shrub_road_variation(grid, theme_data)

    # Create city blocks for compatibility with feature system
    city_blocks = create_city_blocks(placed_buildings, blocks)

    {grid, city_blocks}
  end

  @doc """
  Get center coordinates of a city block
  """
  def center(block) do
    case block.type do
      :building -> calculate_building_center(block)
      :road_intersection -> {block.x + div(block.width, 2), block.y + div(block.height, 2)}
    end
  end

  defp calculate_building_center(block) do
    floor_cells = block.floor_cells || []

    if floor_cells != [] do
      {sum_x, sum_y} =
        Enum.reduce(floor_cells, {0, 0}, fn {x, y}, {acc_x, acc_y} ->
          {acc_x + x, acc_y + y}
        end)

      count = length(floor_cells)
      {div(sum_x, count), div(sum_y, count)}
    else
      {block.x + div(block.width, 2), block.y + div(block.height, 2)}
    end
  end

  @doc """
  Add city block labels to the grid
  """
  def add_labels(grid, city_blocks) do
    Enum.with_index(city_blocks, 1)
    |> Enum.reduce(grid, fn {block, index}, acc_grid ->
      {center_x, center_y} = center(block)

      case find_label_position(acc_grid, block, center_x, center_y) do
        {x, y} -> Map.put(acc_grid, {x, y}, create_label(block, index))
        nil -> acc_grid
      end
    end)
  end

  defp create_label(block, index) do
    case block.type do
      :building -> {:building_label, "B#{index}"}
      :road_intersection -> {:area_label, "R#{index}"}
    end
  end

  # Private helper functions

  defp initialize_with_shrubs(theme_data) do
    # Get shrub tile type from theme_data, default to :shrub for compatibility
    shrub_tile = get_shrub_tile(theme_data)

    # Start with empty grid and fill with shrubs
    for x <- 0..(Grid.map_width() - 1),
        y <- 0..(Grid.map_height() - 1),
        into: %{} do
      {{x, y}, shrub_tile}
    end
  end

  defp get_shrub_tile(theme_data) do
    case Map.get(theme_data, :shrub_theme) do
      # Default for backward compatibility
      nil -> :shrub
      # Keep as :shrub atom, theme used for rendering
      _theme -> :shrub
    end
  end

  defp get_road_tile(theme_data) do
    case Map.get(theme_data, :road_theme) do
      # Default for backward compatibility
      nil -> :road
      # Keep as :road atom, theme used for rendering
      _theme -> :road
    end
  end

  defp get_wall_tile(theme_data) do
    case Map.get(theme_data, :wall_theme) do
      # Default for backward compatibility
      nil -> :wall
      # Keep as :wall atom, theme used for rendering
      _theme -> :wall
    end
  end

  defp get_floor_tile(theme_data) do
    case Map.get(theme_data, :floor_theme) do
      # Default for backward compatibility
      nil -> :floor
      # Keep as :floor atom, theme used for rendering
      _theme -> :floor
    end
  end

  # City door type generation (no traps, same lock chance as regular doors)
  defp random_city_door_type do
    # 1 in 3 doors should be locked (same as regular doors)
    # No traps for city doors
    is_locked = Enum.random(1..3) == 1

    if is_locked do
      :locked_door
    else
      :door
    end
  end

  defp calculate_building_blocks do
    # Calculate how many blocks fit in each dimension
    map_width = Grid.map_width()
    map_height = Grid.map_height()

    # Account for roads between blocks
    blocks_x = div(map_width - @road_width, @block_width + @road_width)
    blocks_y = div(map_height - @road_width, @block_height + @road_width)

    # Generate block coordinates
    for block_x <- 0..(blocks_x - 1),
        block_y <- 0..(blocks_y - 1) do
      # Calculate actual pixel coordinates including road offsets
      x = block_x * (@block_width + @road_width) + @road_width
      y = block_y * (@block_height + @road_width) + @road_width

      %{
        x: x,
        y: y,
        width: @block_width,
        height: @block_height,
        block_x: block_x,
        block_y: block_y
      }
    end
  end

  defp carve_roads(grid, blocks, theme_data) do
    map_width = Grid.map_width()
    map_height = Grid.map_height()

    # Carve horizontal roads
    grid = carve_horizontal_roads(grid, blocks, map_width, map_height, theme_data)

    # Carve vertical roads
    grid = carve_vertical_roads(grid, blocks, map_height, theme_data)

    grid
  end

  defp carve_horizontal_roads(grid, blocks, map_width, map_height, theme_data) do
    # Get unique Y positions for horizontal roads
    road_y_positions =
      blocks
      |> Enum.map(fn block -> [block.y - @road_width, block.y + block.height] end)
      |> List.flatten()
      |> Enum.uniq()
      |> Enum.filter(fn y -> y >= 0 and y < map_height - @road_width + 1 end)

    # Add top border road
    road_y_positions = [0 | road_y_positions]

    Enum.reduce(road_y_positions, grid, fn y, acc_grid ->
      for road_y <- y..(y + @road_width - 1),
          x <- 0..(map_width - 1),
          reduce: acc_grid do
        acc ->
          if road_y >= 0 and road_y < map_height do
            road_tile = get_road_tile(theme_data)
            Map.put(acc, {x, road_y}, road_tile)
          else
            acc
          end
      end
    end)
  end

  defp carve_vertical_roads(grid, blocks, map_height, theme_data) do
    # Get unique X positions for vertical roads
    road_x_positions =
      blocks
      |> Enum.map(fn block -> [block.x - @road_width, block.x + block.width] end)
      |> List.flatten()
      |> Enum.uniq()
      |> Enum.filter(fn x -> x >= 0 and x < Grid.map_width() - @road_width + 1 end)

    # Add left border road
    road_x_positions = [0 | road_x_positions]

    Enum.reduce(road_x_positions, grid, fn x, acc_grid ->
      for road_x <- x..(x + @road_width - 1),
          y <- 0..(map_height - 1),
          reduce: acc_grid do
        acc ->
          if road_x >= 0 and road_x < Grid.map_width() do
            road_tile = get_road_tile(theme_data)
            Map.put(acc, {road_x, y}, road_tile)
          else
            acc
          end
      end
    end)
  end

  defp place_buildings(grid, blocks, theme_data) do
    Enum.reduce(blocks, {grid, []}, fn block, {acc_grid, placed_buildings} ->
      if :rand.uniform() <= 0.7 do
        # Place building (70% chance)
        {building_grid, building_info} = place_building_in_block(acc_grid, block, theme_data)
        {building_grid, [building_info | placed_buildings]}
      else
        # Skip this block (30% chance)
        {acc_grid, placed_buildings}
      end
    end)
  end

  defp place_building_in_block(grid, block, theme_data) do
    # Calculate building dimensions (leave space for walls and door access)
    min_building_width = 4
    min_building_height = 4
    # Leave 1 tile border on each side
    max_building_width = block.width - 2
    max_building_height = block.height - 2

    building_width =
      :rand.uniform(max_building_width - min_building_width + 1) + min_building_width - 1

    building_height =
      :rand.uniform(max_building_height - min_building_height + 1) + min_building_height - 1

    # Center the building in the block
    building_x = block.x + div(block.width - building_width, 2)
    building_y = block.y + div(block.height - building_height, 2)

    # Place floor tiles in the interior
    floor_cells =
      for x <- (building_x + 1)..(building_x + building_width - 2),
          y <- (building_y + 1)..(building_y + building_height - 2),
          do: {x, y}

    grid =
      Enum.reduce(floor_cells, grid, fn {x, y}, acc ->
        floor_tile = get_floor_tile(theme_data)
        Map.put(acc, {x, y}, floor_tile)
      end)

    # Place wall tiles around the perimeter
    wall_cells = []

    # Top and bottom walls
    wall_cells =
      (wall_cells ++
         for(
           x <- building_x..(building_x + building_width - 1),
           do: [{x, building_y}, {x, building_y + building_height - 1}]
         ))
      |> List.flatten()

    # Left and right walls
    wall_cells =
      (wall_cells ++
         for(
           y <- building_y..(building_y + building_height - 1),
           do: [{building_x, y}, {building_x + building_width - 1, y}]
         ))
      |> List.flatten()

    wall_cells = Enum.uniq(wall_cells)

    # Choose a random wall for the door and create connection to road
    {grid, door_position} =
      place_door_and_connection(
        grid,
        wall_cells,
        building_x,
        building_y,
        building_width,
        building_height,
        block,
        theme_data
      )

    # Place remaining walls
    grid =
      Enum.reduce(wall_cells, grid, fn {x, y}, acc ->
        if {x, y} != door_position do
          wall_tile = get_wall_tile(theme_data)
          Map.put(acc, {x, y}, wall_tile)
        else
          # Door position stays as road or floor
          acc
        end
      end)

    building_info = %{
      type: :building,
      x: building_x,
      y: building_y,
      width: building_width,
      height: building_height,
      floor_cells: floor_cells,
      wall_cells: wall_cells,
      door_position: door_position
    }

    {grid, building_info}
  end

  defp place_door_and_connection(
         grid,
         wall_cells,
         building_x,
         building_y,
         building_width,
         building_height,
         _block,
         theme_data
       ) do
    # Categorize walls by side, excluding corners
    top_walls =
      wall_cells
      |> Enum.filter(fn {x, y} ->
        y == building_y and x > building_x and x < building_x + building_width - 1
      end)

    bottom_walls =
      wall_cells
      |> Enum.filter(fn {x, y} ->
        y == building_y + building_height - 1 and x > building_x and
          x < building_x + building_width - 1
      end)

    left_walls =
      wall_cells
      |> Enum.filter(fn {x, y} ->
        x == building_x and y > building_y and y < building_y + building_height - 1
      end)

    right_walls =
      wall_cells
      |> Enum.filter(fn {x, y} ->
        x == building_x + building_width - 1 and y > building_y and
          y < building_y + building_height - 1
      end)

    # Choose a random side and position for the door
    wall_sides = [
      {:top, top_walls},
      {:bottom, bottom_walls},
      {:left, left_walls},
      {:right, right_walls}
    ]

    # Filter to non-empty sides
    available_sides = Enum.filter(wall_sides, fn {_side, walls} -> walls != [] end)

    {side, side_walls} = Enum.random(available_sides)
    door_position = Enum.random(side_walls)

    # Create 2-tile wide connection from door to nearest road
    grid = create_door_connection(grid, door_position, side, theme_data)

    # Make the door position an actual door
    door_type = random_city_door_type()
    grid = Map.put(grid, door_position, door_type)

    {grid, door_position}
  end

  defp create_door_connection(grid, {door_x, door_y}, side, theme_data) do
    case side do
      :top -> create_connection_up(grid, {door_x, door_y}, theme_data)
      :bottom -> create_connection_down(grid, {door_x, door_y}, theme_data)
      :left -> create_connection_left(grid, {door_x, door_y}, theme_data)
      :right -> create_connection_right(grid, {door_x, door_y}, theme_data)
    end
  end

  defp create_connection_up(grid, {door_x, door_y}, theme_data) do
    for y <- (door_y - 1)..0//-1,
        x <- (door_x - 1)..(door_x + 1),
        x >= 0 and x < Grid.map_width(),
        reduce: grid do
      acc -> carve_connection_tile(acc, {x, y}, theme_data)
    end
  end

  defp create_connection_down(grid, {door_x, door_y}, theme_data) do
    for y <- (door_y + 1)..(Grid.map_height() - 1),
        x <- (door_x - 1)..(door_x + 1),
        x >= 0 and x < Grid.map_width(),
        reduce: grid do
      acc -> carve_connection_tile(acc, {x, y}, theme_data)
    end
  end

  defp create_connection_left(grid, {door_x, door_y}, theme_data) do
    for x <- (door_x - 1)..0//-1,
        y <- (door_y - 1)..(door_y + 1),
        y >= 0 and y < Grid.map_height(),
        reduce: grid do
      acc -> carve_connection_tile(acc, {x, y}, theme_data)
    end
  end

  defp create_connection_right(grid, {door_x, door_y}, theme_data) do
    for x <- (door_x + 1)..(Grid.map_width() - 1),
        y <- (door_y - 1)..(door_y + 1),
        y >= 0 and y < Grid.map_height(),
        reduce: grid do
      acc -> carve_connection_tile(acc, {x, y}, theme_data)
    end
  end

  defp carve_connection_tile(grid, {x, y}, theme_data) do
    current_tile = Map.get(grid, {x, y})

    cond do
      current_tile == get_road_tile(theme_data) ->
        # Stop when we hit a road - connection complete
        grid

      current_tile in [get_wall_tile(theme_data), get_floor_tile(theme_data)] ->
        # Stop when we hit building structures - don't destroy them
        grid

      true ->
        # Only carve through shrubs or empty tiles
        Map.put(grid, {x, y}, get_road_tile(theme_data))
    end
  end

  defp create_city_blocks(placed_buildings, _all_blocks) do
    # Convert buildings to city blocks for feature placement
    building_blocks =
      Enum.map(placed_buildings, fn building ->
        Map.put(building, :cells, building.floor_cells)
      end)

    # Also create some road intersection areas for outdoor features
    road_intersections = create_road_intersections()

    # Combine all blocks and add numbers like traditional rooms
    all_blocks = building_blocks ++ road_intersections
    add_city_block_numbers(all_blocks)
  end

  defp add_city_block_numbers(blocks) do
    blocks
    |> Enum.with_index(1)
    |> Enum.map(fn {block, index} -> assign_block_number(block, index) end)
  end

  defp assign_block_number(block, index) do
    if index == 1 do
      Map.put(block, :number, "R1")
    else
      number = get_block_number_by_type(block.type, index)
      Map.put(block, :number, number)
    end
  end

  defp get_block_number_by_type(block_type, index) do
    case block_type do
      :building -> "B#{index}"
      :road_intersection -> "R#{index}"
      _ -> "A#{index}"
    end
  end

  defp create_road_intersections do
    # Create a few road intersection areas for outdoor feature placement
    map_width = Grid.map_width()
    map_height = Grid.map_height()

    intersection_positions = [
      {div(map_width, 4), div(map_height, 4)},
      {div(3 * map_width, 4), div(map_height, 4)},
      {div(map_width, 4), div(3 * map_height, 4)},
      {div(3 * map_width, 4), div(3 * map_height, 4)},
      {div(map_width, 2), div(map_height, 2)}
    ]

    Enum.map(intersection_positions, fn {x, y} ->
      # Create small area around intersection for feature placement
      cells = for ix <- (x - 2)..(x + 2), iy <- (y - 2)..(y + 2), do: {ix, iy}

      %{
        type: :road_intersection,
        x: x - 2,
        y: y - 2,
        width: 5,
        height: 5,
        cells: cells
      }
    end)
  end

  defp find_label_position(grid, block, center_x, center_y) do
    # Try positions around the center, preferring appropriate tile types
    potential_positions = [
      {center_x, center_y},
      {center_x - 1, center_y},
      {center_x + 1, center_y},
      {center_x, center_y - 1},
      {center_x, center_y + 1}
    ]

    target_tile =
      case block.type do
        :building -> get_floor_tile(%{})
        :road_intersection -> get_road_tile(%{})
      end

    Enum.find(potential_positions, fn {x, y} ->
      Map.get(grid, {x, y}) == target_tile
    end)
  end

  # Add organic variation to shrub/road boundaries to make them less square and more natural
  defp add_shrub_road_variation(grid, theme_data) do
    map_width = Grid.map_width()
    map_height = Grid.map_height()

    # Get tiles for theme
    road_tile = get_road_tile(theme_data)

    # Collect all shrub positions before making any changes
    shrub_positions =
      for x <- 0..(map_width - 1),
          y <- 0..(map_height - 1),
          Map.get(grid, {x, y}) == :shrub,
          do: {x, y}

    # For each shrub, check if adjacent to a road and randomly convert some
    Enum.reduce(shrub_positions, grid, fn {x, y}, acc_grid ->
      # Check neighbors for roads
      neighbors = [
        # up
        {x, y - 1},
        # down
        {x, y + 1},
        # left
        {x - 1, y},
        # right
        {x + 1, y}
      ]

      is_adjacent_to_road =
        Enum.any?(neighbors, fn {nx, ny} ->
          nx >= 0 and nx < map_width and
            ny >= 0 and ny < map_height and
            Map.get(acc_grid, {nx, ny}) == :road
        end)

      # 20% chance to convert shrub to road if adjacent to a road
      if is_adjacent_to_road and Enum.random(1..5) == 1 do
        Map.put(acc_grid, {x, y}, road_tile)
      else
        acc_grid
      end
    end)
  end
end
