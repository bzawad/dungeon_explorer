defmodule Dungeon.Generator do
  @moduledoc """
  Generates interesting dungeon maps using room-and-corridor algorithm
  """

  alias Dungeon.Generator.{Caverns, Cities, Corridors, Features, Grid, Outdoor, Rooms}
  alias Dungeon.{MapLinkSystem, Themes}

  @doc """
  Returns the list of all available themes.
  """
  def get_themes, do: Themes.get_themes()

  @doc """
  Returns themes filtered by generation type.
  """
  def get_themes_by_type(generation_type) do
    Themes.get_themes_by_type(generation_type)
  end

  # Exit validation functions to ensure at least 2 exits per map

  @doc """
  Count exits in a grid (staircases and waypoints)
  """
  def count_exits(grid) do
    grid
    |> Map.values()
    |> Enum.count(fn tile ->
      case tile do
        :stair_up -> true
        :stair_down -> true
        {:starting_stair, _} -> true
        {:starting_waypoint, _} -> true
        {:waypoint, _} -> true
        _ -> false
      end
    end)
  end

  @doc """
  Ensure minimum exits for traditional dungeons (at least 2 staircases)
  """
  def ensure_minimum_exits_dungeon(grid, rooms, theme_direction, minimum \\ 2) do
    current_exits = count_exits(grid)

    if current_exits >= minimum do
      grid
    else
      needed_exits = minimum - current_exits
      add_additional_staircases(grid, rooms, theme_direction, needed_exits)
    end
  end

  @doc """
  Ensure minimum exits for caverns (at least 2 staircases)
  """
  def ensure_minimum_exits_caverns(grid, caverns, theme_direction, minimum \\ 2) do
    current_exits = count_exits(grid)

    if current_exits >= minimum do
      grid
    else
      needed_exits = minimum - current_exits
      add_additional_staircases_to_caverns(grid, caverns, theme_direction, needed_exits)
    end
  end

  @doc """
  Ensure minimum exits for outdoor areas (at least 2 waypoints)
  """
  def ensure_minimum_exits_outdoor(grid, areas, minimum \\ 2) do
    current_exits = count_exits(grid)

    if current_exits >= minimum do
      grid
    else
      needed_exits = minimum - current_exits
      add_additional_waypoints(grid, areas, needed_exits)
    end
  end

  # Helper functions to add additional exits when needed

  defp add_additional_staircases(grid, rooms, theme_direction, count) do
    # Filter out the first room (which already has the starting staircase)
    [_first_room | available_rooms] = rooms
    available_rooms = Enum.shuffle(available_rooms)

    add_staircases_to_rooms(grid, available_rooms, theme_direction, count)
  end

  defp add_additional_staircases_to_caverns(grid, caverns, theme_direction, count) do
    # Filter out the first cavern (which already has the starting staircase)
    [_first_cavern | available_caverns] = caverns
    available_caverns = Enum.shuffle(available_caverns)

    add_staircases_to_caverns_list(grid, available_caverns, theme_direction, count)
  end

  defp add_additional_waypoints(grid, areas, count) do
    # Filter out the first area (which already has the starting waypoint)
    [_first_area | available_areas] = areas
    available_areas = Enum.shuffle(available_areas)

    add_waypoints_to_areas_list(grid, available_areas, count)
  end

  defp add_staircases_to_rooms(grid, _rooms, _theme_direction, 0), do: grid
  defp add_staircases_to_rooms(grid, [], _theme_direction, _count), do: grid

  defp add_staircases_to_rooms(grid, [room | remaining_rooms], theme_direction, count) do
    case Features.find_staircase_position(grid, room) do
      nil ->
        # Couldn't place staircase in this room, try next
        add_staircases_to_rooms(grid, remaining_rooms, theme_direction, count)

      {x, y} ->
        # Choose stair type based on theme direction
        stair_type = if theme_direction == :up, do: :stair_up, else: :stair_down
        updated_grid = Map.put(grid, {x, y}, stair_type)
        add_staircases_to_rooms(updated_grid, remaining_rooms, theme_direction, count - 1)
    end
  end

  defp add_staircases_to_caverns_list(grid, _caverns, _theme_direction, 0), do: grid
  defp add_staircases_to_caverns_list(grid, [], _theme_direction, _count), do: grid

  defp add_staircases_to_caverns_list(grid, [cavern | remaining_caverns], theme_direction, count) do
    case Features.find_cavern_position(grid, cavern) do
      nil ->
        # Couldn't place staircase in this cavern, try next
        add_staircases_to_caverns_list(grid, remaining_caverns, theme_direction, count)

      {x, y} ->
        stair_type = if theme_direction == :up, do: :stair_up, else: :stair_down
        updated_grid = Map.put(grid, {x, y}, stair_type)

        add_staircases_to_caverns_list(
          updated_grid,
          remaining_caverns,
          theme_direction,
          count - 1
        )
    end
  end

  defp add_waypoints_to_areas_list(grid, _areas, 0), do: grid
  defp add_waypoints_to_areas_list(grid, [], _count), do: grid

  defp add_waypoints_to_areas_list(grid, [area | remaining_areas], count) do
    case Features.find_waypoint_position(grid, area) do
      nil ->
        # Couldn't place waypoint in this area, try next
        add_waypoints_to_areas_list(grid, remaining_areas, count)

      {x, y} ->
        # Choose random waypoint image (1-4)
        waypoint_number = Enum.random(1..4)
        waypoint_type = {:waypoint, waypoint_number}
        updated_grid = Map.put(grid, {x, y}, waypoint_type)
        add_waypoints_to_areas_list(updated_grid, remaining_areas, count - 1)
    end
  end

  def generate do
    # Check for forced theme via environment variable
    case System.get_env("THEME") do
      nil ->
        # Select random theme
        theme_data = Themes.get_random_theme()
        generate_with_theme_data(theme_data)

      theme_name when is_binary(theme_name) ->
        # Use forced theme from environment variable
        generate_with_theme(theme_name)
    end
  end

  def generate_with_player_level(player_level, dungeon_level \\ 1) do
    # Check for forced theme via environment variable
    case System.get_env("THEME") do
      nil ->
        # Select random theme
        theme_data = Themes.get_random_theme()
        generate_with_theme_data_and_levels(theme_data, player_level, dungeon_level)

      theme_name when is_binary(theme_name) ->
        # Use forced theme from environment variable
        generate_with_theme_and_levels(theme_name, player_level, dungeon_level)
    end
  end

  def generate_with_theme(theme_name) do
    # Find theme data by name
    theme_data = Themes.find_theme_by_name(theme_name)

    if theme_data do
      generate_with_theme_data(theme_data)
    else
      # Fallback to random theme if not found
      generate()
    end
  end

  def generate_with_theme_and_levels(theme_name, player_level, dungeon_level) do
    # Find theme data by name
    theme_data = Themes.find_theme_by_name(theme_name)

    if theme_data do
      generate_with_theme_data_and_levels(theme_data, player_level, dungeon_level)
    else
      # Fallback to random theme if not found
      generate_with_player_level(player_level, dungeon_level)
    end
  end

  def generate_with_theme_and_level(theme_name, level) do
    # Find theme data by name
    theme_data = Themes.find_theme_by_name(theme_name)

    if theme_data do
      generate_with_theme_data_and_level(theme_data, level)
    else
      # Fallback to random theme if not found
      generate()
    end
  end

  def generate_with_theme_type(generation_type) do
    # Get a random theme of the specified type
    themes = get_themes_by_type(generation_type)

    case themes do
      [] ->
        # No themes of this type, fallback to random
        generate()

      themes ->
        theme_data = Enum.random(themes)
        generate_with_theme_data(theme_data)
    end
  end

  def generate_with_theme_type_and_levels(generation_type, player_level, dungeon_level) do
    # Get a random theme of the specified type
    themes = get_themes_by_type(generation_type)

    case themes do
      [] ->
        # No themes of this type, fallback to random
        generate_with_player_level(player_level, dungeon_level)

      themes ->
        theme_data = Enum.random(themes)
        generate_with_theme_data_and_levels(theme_data, player_level, dungeon_level)
    end
  end

  defp generate_with_theme_data(theme_data) do
    case theme_data.generation_type do
      "cavern" ->
        generate_cavern_dungeon(theme_data)

      "outdoor" ->
        generate_outdoor_area(theme_data)

      "city" ->
        generate_city(theme_data)

      _ ->
        generate_traditional_dungeon(theme_data)
    end
  end

  defp generate_traditional_dungeon(theme_data) do
    # Initialize empty grid (all walls)
    grid = Grid.initialize()

    # Generate rooms
    rooms = Rooms.generate()

    # Place rooms on grid
    grid = Rooms.place_on_grid(grid, rooms)

    # Connect rooms with corridors and get corridor info
    {grid, corridors} = Corridors.connect_rooms(grid, rooms)

    # Add some interesting features (but not doors yet)
    grid = Features.add_pillars(grid, rooms)

    # Add room labels
    grid = Rooms.add_labels(grid, rooms)

    # Add corridor labels (only in pure corridor areas)
    grid = Corridors.add_labels(grid, corridors, rooms)

    # Add doors at corridor-room intersections
    grid = Features.add_doors(grid, corridors, rooms)

    # Add map links early for priority placement (before other features)
    grid = MapLinkSystem.add_map_links(grid, rooms, theme_data)

    # Add random staircases
    grid = Features.add_staircases(grid, rooms, theme_data.direction)

    # Ensure minimum exits (at least 2 staircases)
    grid = ensure_minimum_exits_dungeon(grid, rooms, theme_data.direction)

    # Add room traps
    grid = Features.add_room_traps(grid, rooms)

    # Add encounters (theme-aware)
    player_level = Map.get(theme_data, :player_level, 1)
    dungeon_level = Map.get(theme_data, :dungeon_level, 1)
    max_level = max(player_level, dungeon_level)
    grid = Features.add_encounters(grid, rooms, corridors, theme_data, max_level)

    # Add treasures
    grid = Features.add_treasures(grid, rooms, corridors)

    # Add food
    grid = Features.add_food(grid, rooms)

    # Add healing potions
    grid = Features.add_healing_potions(grid, rooms, corridors)

    # Add torches (before special features to ensure placement)
    grid =
      if Map.get(theme_data, :fog_type) == "daylight" do
        # Skip torch spawning for daylight themes
        grid
      else
        Features.add_torches(grid, rooms)
      end

    # Add special features (theme-aware)
    grid = Features.add_special_features(grid, rooms, theme_data)

    %{
      width: Grid.map_width(),
      height: Grid.map_height(),
      grid: grid,
      rooms: rooms,
      corridors: corridors,
      theme: theme_data.name,
      theme_data: theme_data,
      theme_direction: theme_data.direction,
      wall_theme: theme_data.wall_theme,
      floor_theme: theme_data.floor_theme,
      transition_theme: theme_data.transition_theme,
      generation_type: theme_data.generation_type,
      fog_type: Map.get(theme_data, :fog_type, "dark")
    }
  end

  defp generate_cavern_dungeon(theme_data) do
    # Generate natural cavern system
    {grid, caverns} = Caverns.generate()

    # Add cavern labels
    grid = Caverns.add_labels(grid, caverns)

    # Add random staircases to caverns
    grid = Features.add_staircases_to_caverns(grid, caverns, theme_data.direction)

    # Ensure minimum exits (at least 2 staircases)
    grid = ensure_minimum_exits_caverns(grid, caverns, theme_data.direction)

    # Add map links early for priority placement (before other features)
    grid = MapLinkSystem.add_map_links(grid, caverns, theme_data)

    # Add encounters to caverns (theme-aware)
    grid = Features.add_encounters_to_caverns(grid, caverns, theme_data)

    # Add treasures to caverns
    grid = Features.add_treasures_to_caverns(grid, caverns)

    # Add food to caverns
    grid = Features.add_food_to_caverns(grid, caverns)

    # Add healing potions to caverns
    grid = Features.add_healing_potions_to_caverns(grid, caverns)

    # Add torches to caverns
    grid =
      if Map.get(theme_data, :fog_type) == "daylight" do
        # Skip torch spawning for daylight themes
        grid
      else
        Features.add_torches_to_caverns(grid, caverns)
      end

    # Add special features to caverns (theme-aware)
    grid = Features.add_special_features_to_caverns(grid, caverns, theme_data)

    %{
      width: Grid.map_width(),
      height: Grid.map_height(),
      grid: grid,
      # Use caverns as rooms for compatibility
      rooms: caverns,
      # No traditional corridors in cavern system
      corridors: [],
      theme: theme_data.name,
      theme_data: theme_data,
      theme_direction: theme_data.direction,
      wall_theme: theme_data.wall_theme,
      floor_theme: theme_data.floor_theme,
      transition_theme: theme_data.transition_theme,
      generation_type: theme_data.generation_type,
      fog_type: Map.get(theme_data, :fog_type, "dark")
    }
  end

  defp generate_outdoor_area(theme_data) do
    # Generate natural outdoor area system
    {grid, areas} = Outdoor.generate()

    # Add area labels
    grid = Outdoor.add_labels(grid, areas)

    # Add random waypoints to areas (instead of staircases)
    grid = Features.add_waypoints_to_areas(grid, areas)

    # Add waypoints that link to city themes
    grid = Features.add_city_linking_waypoints(grid, areas)

    # Ensure minimum exits (at least 2 waypoints)
    grid = ensure_minimum_exits_outdoor(grid, areas)

    # Add map links early for priority placement (before other features)
    grid = MapLinkSystem.add_map_links(grid, areas, theme_data)

    # Add encounters to areas (theme-aware)
    grid = Features.add_encounters_to_caverns(grid, areas, theme_data)

    # Add treasures to areas
    grid = Features.add_treasures_to_caverns(grid, areas)

    # Add food to areas
    grid = Features.add_food_to_caverns(grid, areas)

    # Add healing potions to areas
    grid = Features.add_healing_potions_to_caverns(grid, areas)

    # Add torches to areas
    grid =
      if Map.get(theme_data, :fog_type) == "daylight" do
        # Skip torch spawning for daylight themes
        grid
      else
        Features.add_torches_to_caverns(grid, areas)
      end

    # Add special features to areas (theme-aware)
    grid = Features.add_special_features_to_caverns(grid, areas, theme_data)

    %{
      width: Grid.map_width(),
      height: Grid.map_height(),
      grid: grid,
      # Use areas as rooms for compatibility
      rooms: areas,
      # No traditional corridors in outdoor system
      corridors: [],
      theme: theme_data.name,
      theme_data: theme_data,
      theme_direction: theme_data.direction,
      wall_theme: theme_data.wall_theme,
      floor_theme: theme_data.floor_theme,
      generation_type: theme_data.generation_type,
      fog_type: Map.get(theme_data, :fog_type, "dark")
    }
  end

  defp generate_city(theme_data) do
    # Generate city layout
    {grid, city_blocks} = Cities.generate(theme_data)

    # Add city block labels
    grid = Cities.add_labels(grid, city_blocks)

    # Add city-specific waypoints to roads near edges (like arriving/leaving town)
    grid = Features.add_waypoints_to_city_areas(grid, city_blocks, theme_data.generation_type)

    # Ensure minimum exits (at least 2 waypoints)
    grid = ensure_minimum_exits_outdoor(grid, city_blocks)

    # Add map links early for priority placement (before other features)
    grid = MapLinkSystem.add_map_links(grid, city_blocks, theme_data)

    # Add encounters to city areas (theme-aware)
    grid = Features.add_encounters_to_city_areas(grid, city_blocks, theme_data)

    # Add treasures to city areas
    grid = Features.add_treasures_to_caverns(grid, city_blocks)

    # Add food to city areas
    grid = Features.add_food_to_caverns(grid, city_blocks)

    # Add healing potions to city areas
    grid = Features.add_healing_potions_to_caverns(grid, city_blocks)

    # Skip torches for daylight city themes
    grid =
      if Map.get(theme_data, :fog_type) == "daylight" do
        # Skip torch spawning for daylight themes
        grid
      else
        Features.add_torches_to_caverns(grid, city_blocks)
      end

    # Add special features to city areas (theme-aware with indoor/outdoor distinction)
    grid = add_city_special_features(grid, city_blocks, theme_data)

    %{
      width: Grid.map_width(),
      height: Grid.map_height(),
      grid: grid,
      # Use city_blocks as rooms for compatibility
      rooms: city_blocks,
      # No traditional corridors in city system
      corridors: [],
      theme: theme_data.name,
      theme_data: theme_data,
      theme_direction: theme_data.direction,
      wall_theme: theme_data.wall_theme,
      floor_theme: theme_data.floor_theme,
      road_theme: Map.get(theme_data, :road_theme),
      shrub_theme: Map.get(theme_data, :shrub_theme),
      generation_type: theme_data.generation_type,
      fog_type: Map.get(theme_data, :fog_type, "dark")
    }
  end

  defp add_city_special_features(grid, city_blocks, theme_data) do
    # Add special features to city areas, using outdoor features for road intersections
    # and indoor features for buildings
    Enum.reduce(city_blocks, grid, fn block, acc_grid ->
      process_block_features(acc_grid, block, theme_data)
    end)
  end

  defp process_block_features(grid, block, theme_data) do
    case block.type do
      :building -> process_building_features(grid, block, theme_data)
      :road_intersection -> process_road_intersection_features(grid, block, theme_data)
      _ -> grid
    end
  end

  defp process_building_features(grid, block, theme_data) do
    indoor_features = Map.get(theme_data, :indoor_features, [])

    if indoor_features != [] and :rand.uniform() < 0.3 do
      add_feature_to_city_block(grid, block, indoor_features)
    else
      grid
    end
  end

  defp process_road_intersection_features(grid, block, theme_data) do
    outdoor_features = Map.get(theme_data, :outdoor_features, [])

    if outdoor_features != [] and :rand.uniform() < 0.4 do
      add_feature_to_city_block(grid, block, outdoor_features)
    else
      grid
    end
  end

  defp add_feature_to_city_block(grid, block, features) do
    # Find a suitable position in the block for the feature
    case find_feature_position_in_block(grid, block) do
      nil ->
        grid

      {x, y} ->
        feature_name = Enum.random(features)
        # Use proper 3-element format like traditional dungeons
        Map.put(grid, {x, y}, {:special_feature, feature_name, feature_name})
    end
  end

  defp find_feature_position_in_block(grid, block) do
    # Try to find a suitable position within the block's cells
    suitable_cells =
      case block.type do
        :building ->
          # For buildings, use floor cells
          Enum.filter(block.floor_cells || [], fn {x, y} ->
            Map.get(grid, {x, y}) == :floor
          end)

        :road_intersection ->
          # For road intersections, use road cells
          Enum.filter(block.cells || [], fn {x, y} ->
            Map.get(grid, {x, y}) == :road
          end)

        _ ->
          []
      end

    if suitable_cells != [] do
      Enum.random(suitable_cells)
    else
      nil
    end
  end

  defp generate_with_theme_data_and_level(theme_data, level) do
    case theme_data.generation_type do
      "cavern" ->
        generate_cavern_dungeon_with_level(theme_data, level)

      "outdoor" ->
        generate_outdoor_area_with_level(theme_data, level)

      "city" ->
        generate_city_with_level(theme_data, level)

      _ ->
        generate_traditional_dungeon_with_level(theme_data, level)
    end
  end

  defp generate_with_theme_data_and_levels(theme_data, player_level, dungeon_level) do
    # Add player and dungeon levels to theme data
    theme_data_with_levels =
      Map.merge(theme_data, %{
        player_level: player_level,
        dungeon_level: dungeon_level
      })

    case theme_data.generation_type do
      "cavern" ->
        generate_cavern_dungeon_with_levels(theme_data_with_levels, player_level, dungeon_level)

      "outdoor" ->
        generate_outdoor_area_with_levels(theme_data_with_levels, player_level, dungeon_level)

      "city" ->
        generate_city_with_levels(theme_data_with_levels, player_level, dungeon_level)

      _ ->
        generate_traditional_dungeon_with_levels(
          theme_data_with_levels,
          player_level,
          dungeon_level
        )
    end
  end

  defp generate_traditional_dungeon_with_level(theme_data, level) do
    # Initialize empty grid (all walls)
    grid = Grid.initialize()

    # Generate rooms
    rooms = Rooms.generate()

    # Place rooms on grid
    grid = Rooms.place_on_grid(grid, rooms)

    # Connect rooms with corridors and get corridor info
    {grid, corridors} = Corridors.connect_rooms(grid, rooms)

    # Add some interesting features (but not doors yet)
    grid = Features.add_pillars(grid, rooms)

    # Add room labels
    grid = Rooms.add_labels(grid, rooms)

    # Add corridor labels (only in pure corridor areas)
    grid = Corridors.add_labels(grid, corridors, rooms)

    # Add doors at corridor-room intersections
    grid = Features.add_doors(grid, corridors, rooms)

    # Add map links early for priority placement (before other features)
    grid = MapLinkSystem.add_map_links(grid, rooms, theme_data)

    # Add random staircases
    grid = Features.add_staircases(grid, rooms, theme_data.direction)

    # Ensure minimum exits (at least 2 staircases)
    grid = ensure_minimum_exits_dungeon(grid, rooms, theme_data.direction)

    # Add room traps
    grid = Features.add_room_traps(grid, rooms)

    # Add encounters (theme-aware)
    player_level = Map.get(theme_data, :player_level, 1)
    dungeon_level = Map.get(theme_data, :dungeon_level, 1)
    max_level = max(player_level, dungeon_level)
    grid = Features.add_encounters(grid, rooms, corridors, theme_data, max_level)

    # Add treasures
    grid = Features.add_treasures(grid, rooms, corridors)

    # Add food
    grid = Features.add_food(grid, rooms)

    # Add healing potions
    grid = Features.add_healing_potions(grid, rooms, corridors)

    # Add torches (with level-aware placement)
    grid =
      if Map.get(theme_data, :fog_type) == "daylight" do
        # Skip torch spawning for daylight themes
        grid
      else
        Features.add_torches_with_level(grid, rooms, level)
      end

    # Add special features (theme-aware)
    grid = Features.add_special_features(grid, rooms, theme_data)

    %{
      width: Grid.map_width(),
      height: Grid.map_height(),
      grid: grid,
      rooms: rooms,
      corridors: corridors,
      theme: theme_data.name,
      theme_data: theme_data,
      theme_direction: theme_data.direction,
      wall_theme: theme_data.wall_theme,
      floor_theme: theme_data.floor_theme,
      transition_theme: theme_data.transition_theme,
      generation_type: theme_data.generation_type,
      fog_type: Map.get(theme_data, :fog_type, "dark")
    }
  end

  defp generate_traditional_dungeon_with_levels(theme_data, player_level, dungeon_level) do
    # Initialize empty grid (all walls)
    grid = Grid.initialize()

    # Generate rooms
    rooms = Rooms.generate()

    # Place rooms on grid
    grid = Rooms.place_on_grid(grid, rooms)

    # Connect rooms with corridors and get corridor info
    {grid, corridors} = Corridors.connect_rooms(grid, rooms)

    # Add some interesting features (but not doors yet)
    grid = Features.add_pillars(grid, rooms)

    # Add room labels
    grid = Rooms.add_labels(grid, rooms)

    # Add corridor labels (only in pure corridor areas)
    grid = Corridors.add_labels(grid, corridors, rooms)

    # Add doors at corridor-room intersections
    grid = Features.add_doors(grid, corridors, rooms)

    # Add map links early for priority placement (before other features)
    grid = MapLinkSystem.add_map_links(grid, rooms, theme_data)

    # Add random staircases
    grid = Features.add_staircases(grid, rooms, theme_data.direction)

    # Ensure minimum exits (at least 2 staircases)
    grid = ensure_minimum_exits_dungeon(grid, rooms, theme_data.direction)

    # Add room traps
    grid = Features.add_room_traps(grid, rooms)

    # Add encounters (theme-aware with proper level filtering)
    max_level = max(player_level, dungeon_level)
    grid = Features.add_encounters(grid, rooms, corridors, theme_data, max_level)

    # Add treasures
    grid = Features.add_treasures(grid, rooms, corridors)

    # Add food
    grid = Features.add_food(grid, rooms)

    # Add healing potions
    grid = Features.add_healing_potions(grid, rooms, corridors)

    # Add torches (with level-aware placement)
    grid =
      if Map.get(theme_data, :fog_type) == "daylight" do
        # Skip torch spawning for daylight themes
        grid
      else
        Features.add_torches_with_level(grid, rooms, dungeon_level)
      end

    # Add special features (theme-aware)
    grid = Features.add_special_features(grid, rooms, theme_data)

    %{
      width: Grid.map_width(),
      height: Grid.map_height(),
      grid: grid,
      rooms: rooms,
      corridors: corridors,
      theme: theme_data.name,
      theme_data: theme_data,
      theme_direction: theme_data.direction,
      wall_theme: theme_data.wall_theme,
      floor_theme: theme_data.floor_theme,
      transition_theme: theme_data.transition_theme,
      generation_type: theme_data.generation_type,
      fog_type: Map.get(theme_data, :fog_type, "dark")
    }
  end

  defp generate_cavern_dungeon_with_level(theme_data, level) do
    # Generate natural cavern system
    {grid, caverns} = Caverns.generate()

    # Add cavern labels
    grid = Caverns.add_labels(grid, caverns)

    # Add random staircases to caverns
    grid = Features.add_staircases_to_caverns(grid, caverns, theme_data.direction)

    # Ensure minimum exits (at least 2 staircases)
    grid = ensure_minimum_exits_caverns(grid, caverns, theme_data.direction)

    # Add map links early for priority placement (before other features)
    grid = MapLinkSystem.add_map_links(grid, caverns, theme_data)

    # Add encounters to caverns (theme-aware)
    grid = Features.add_encounters_to_caverns(grid, caverns, theme_data)

    # Add treasures to caverns
    grid = Features.add_treasures_to_caverns(grid, caverns)

    # Add food to caverns
    grid = Features.add_food_to_caverns(grid, caverns)

    # Add healing potions to caverns
    grid = Features.add_healing_potions_to_caverns(grid, caverns)

    # Add torches to caverns (with level-aware placement)
    grid =
      if Map.get(theme_data, :fog_type) == "daylight" do
        # Skip torch spawning for daylight themes
        grid
      else
        Features.add_torches_to_caverns_with_level(grid, caverns, level)
      end

    # Add special features to caverns (theme-aware)
    grid = Features.add_special_features_to_caverns(grid, caverns, theme_data)

    %{
      width: Grid.map_width(),
      height: Grid.map_height(),
      grid: grid,
      # Use caverns as rooms for compatibility
      rooms: caverns,
      # No traditional corridors in cavern system
      corridors: [],
      theme: theme_data.name,
      theme_data: theme_data,
      theme_direction: theme_data.direction,
      wall_theme: theme_data.wall_theme,
      floor_theme: theme_data.floor_theme,
      transition_theme: theme_data.transition_theme,
      generation_type: theme_data.generation_type,
      fog_type: Map.get(theme_data, :fog_type, "dark")
    }
  end

  defp generate_cavern_dungeon_with_levels(theme_data, player_level, dungeon_level) do
    # Generate natural cavern system
    {grid, caverns} = Caverns.generate()

    # Add cavern labels
    grid = Caverns.add_labels(grid, caverns)

    # Add random staircases to caverns
    grid = Features.add_staircases_to_caverns(grid, caverns, theme_data.direction)

    # Ensure minimum exits (at least 2 staircases)
    grid = ensure_minimum_exits_caverns(grid, caverns, theme_data.direction)

    # Add map links early for priority placement (before other features)
    grid = MapLinkSystem.add_map_links(grid, caverns, theme_data)

    # Add encounters to caverns (theme-aware with proper level filtering)
    max_level = max(player_level, dungeon_level)
    grid = Features.add_encounters_to_caverns(grid, caverns, theme_data, max_level)

    # Add treasures to caverns
    grid = Features.add_treasures_to_caverns(grid, caverns)

    # Add food to caverns
    grid = Features.add_food_to_caverns(grid, caverns)

    # Add healing potions to caverns
    grid = Features.add_healing_potions_to_caverns(grid, caverns)

    # Add torches to caverns (with level-aware placement)
    grid =
      if Map.get(theme_data, :fog_type) == "daylight" do
        # Skip torch spawning for daylight themes
        grid
      else
        Features.add_torches_to_caverns_with_level(grid, caverns, dungeon_level)
      end

    # Add special features to caverns (theme-aware)
    grid = Features.add_special_features_to_caverns(grid, caverns, theme_data)

    %{
      width: Grid.map_width(),
      height: Grid.map_height(),
      grid: grid,
      # Use caverns as rooms for compatibility
      rooms: caverns,
      # No traditional corridors in cavern system
      corridors: [],
      theme: theme_data.name,
      theme_data: theme_data,
      theme_direction: theme_data.direction,
      wall_theme: theme_data.wall_theme,
      floor_theme: theme_data.floor_theme,
      transition_theme: theme_data.transition_theme,
      generation_type: theme_data.generation_type,
      fog_type: Map.get(theme_data, :fog_type, "dark")
    }
  end

  defp generate_city_with_level(theme_data, _level) do
    # Cities don't have level-specific behavior, so just call regular generate_city
    generate_city(theme_data)
  end

  defp generate_city_with_levels(theme_data, _player_level, _dungeon_level) do
    # Cities don't have level-specific behavior, so just call regular generate_city
    generate_city(theme_data)
  end

  defp generate_outdoor_area_with_level(theme_data, level) do
    # Generate natural outdoor area system
    {grid, areas} = Outdoor.generate()

    # Add area labels
    grid = Outdoor.add_labels(grid, areas)

    # Add random waypoints to areas (instead of staircases)
    grid = Features.add_waypoints_to_areas(grid, areas)

    # Add waypoints that link to city themes
    grid = Features.add_city_linking_waypoints(grid, areas)

    # Ensure minimum exits (at least 2 waypoints)
    grid = ensure_minimum_exits_outdoor(grid, areas)

    # Add map links early for priority placement (before other features)
    grid = MapLinkSystem.add_map_links(grid, areas, theme_data)

    # Add encounters to areas (theme-aware)
    grid = Features.add_encounters_to_caverns(grid, areas, theme_data)

    # Add treasures to areas
    grid = Features.add_treasures_to_caverns(grid, areas)

    # Add food to areas
    grid = Features.add_food_to_caverns(grid, areas)

    # Add healing potions to areas
    grid = Features.add_healing_potions_to_caverns(grid, areas)

    # Add torches to areas (with level-aware placement)
    grid =
      if Map.get(theme_data, :fog_type) == "daylight" do
        # Skip torch spawning for daylight themes
        grid
      else
        Features.add_torches_to_caverns_with_level(grid, areas, level)
      end

    # Add special features to areas (theme-aware)
    grid = Features.add_special_features_to_caverns(grid, areas, theme_data)

    %{
      width: Grid.map_width(),
      height: Grid.map_height(),
      grid: grid,
      # Use areas as rooms for compatibility
      rooms: areas,
      # No traditional corridors in outdoor system
      corridors: [],
      theme: theme_data.name,
      theme_data: theme_data,
      theme_direction: theme_data.direction,
      wall_theme: theme_data.wall_theme,
      floor_theme: theme_data.floor_theme,
      generation_type: theme_data.generation_type,
      fog_type: Map.get(theme_data, :fog_type, "dark")
    }
  end

  defp generate_outdoor_area_with_levels(theme_data, player_level, dungeon_level) do
    # Generate natural outdoor area system
    {grid, areas} = Outdoor.generate()

    # Add area labels
    grid = Outdoor.add_labels(grid, areas)

    # Add random waypoints to areas (instead of staircases)
    grid = Features.add_waypoints_to_areas(grid, areas)

    # Add waypoints that link to city themes
    grid = Features.add_city_linking_waypoints(grid, areas)

    # Ensure minimum exits (at least 2 waypoints)
    grid = ensure_minimum_exits_outdoor(grid, areas)

    # Add map links early for priority placement (before other features)
    grid = MapLinkSystem.add_map_links(grid, areas, theme_data)

    # Add encounters to areas (theme-aware with proper level filtering)
    max_level = max(player_level, dungeon_level)
    grid = Features.add_encounters_to_caverns(grid, areas, theme_data, max_level)

    # Add treasures to areas
    grid = Features.add_treasures_to_caverns(grid, areas)

    # Add food to areas
    grid = Features.add_food_to_caverns(grid, areas)

    # Add healing potions to areas
    grid = Features.add_healing_potions_to_caverns(grid, areas)

    # Add torches to areas (with level-aware placement)
    grid =
      if Map.get(theme_data, :fog_type) == "daylight" do
        # Skip torch spawning for daylight themes
        grid
      else
        Features.add_torches_to_caverns_with_level(grid, areas, dungeon_level)
      end

    # Add special features to areas (theme-aware)
    grid = Features.add_special_features_to_caverns(grid, areas, theme_data)

    %{
      width: Grid.map_width(),
      height: Grid.map_height(),
      grid: grid,
      # Use areas as rooms for compatibility
      rooms: areas,
      # No traditional corridors in outdoor system
      corridors: [],
      theme: theme_data.name,
      theme_data: theme_data,
      theme_direction: theme_data.direction,
      wall_theme: theme_data.wall_theme,
      floor_theme: theme_data.floor_theme,
      generation_type: theme_data.generation_type,
      fog_type: Map.get(theme_data, :fog_type, "dark")
    }
  end
end
