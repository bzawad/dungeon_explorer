defmodule DungeonWeb.DungeonHTML do
  @moduledoc """
  HTML helpers for dungeon controller
  """

  use DungeonWeb, :html

  alias Dungeon.Generator.Features
  alias DungeonWeb.UISizing

  embed_templates "dungeon_html/*"

  @doc """
  Get image classes for print view buttons using centralized sizing
  """
  def ui_image_classes(size_name), do: UISizing.image_classes(size_name)

  @doc """
  Get inline image classes for print view using centralized sizing
  """
  def ui_inline_image_classes(size_name), do: UISizing.inline_image_classes(size_name)

  @doc """
  Get inline image tag for print view using centralized sizing
  """
  def ui_inline_img_tag(src, alt, size_name \\ :small_icon),
    do: UISizing.inline_img_tag(src, alt, size_name)

  # Get inline image tag for tiny tile symbols in print view
  defp tile_img_tag(src, alt), do: UISizing.inline_img_tag(src, alt, :tiny_icon)

  @doc """
  Get CSS class for tile type in print view
  """
  def get_tile_class(tile) do
    cond do
      basic_tile?(tile) -> get_basic_tile_class(tile)
      door_tile?(tile) -> get_door_tile_class(tile)
      special_tile?(tile) -> get_special_tile_class(tile)
      labeled_tile?(tile) -> get_labeled_tile_class(tile)
      true -> "floor"
    end
  end

  # Basic structural tiles
  defp basic_tile?(tile), do: tile in [:wall, :floor, :corridor, :pillar, :road, :shrub]

  defp get_basic_tile_class(:wall), do: "wall"
  defp get_basic_tile_class(:floor), do: "floor"
  defp get_basic_tile_class(:corridor), do: "corridor"
  defp get_basic_tile_class(:road), do: "road"
  defp get_basic_tile_class(:shrub), do: "shrub"

  # Door variants
  defp door_tile?(tile),
    do: tile in [:door, :locked_door, :trapped_door, :locked_trapped_door, :secret_door]

  defp get_door_tile_class(:door), do: "door"
  defp get_door_tile_class(:locked_door), do: "locked-door"
  defp get_door_tile_class(:trapped_door), do: "trapped-door"
  defp get_door_tile_class(:locked_trapped_door), do: "locked-trapped-door"
  defp get_door_tile_class(:secret_door), do: "secret-door"

  # Special interactive tiles
  defp special_tile?(tile),
    do:
      tile in [
        :room_trap,
        :treasure,
        :trapped_treasure,
        :torch,
        :bread,
        :cheese,
        :grapes,
        :healing_potion,
        :stair_up,
        :stair_down,
        :pile_of_bones
      ]

  defp get_special_tile_class(:room_trap), do: "room-trap"
  defp get_special_tile_class(:treasure), do: "treasure"
  defp get_special_tile_class(:trapped_treasure), do: "trapped-treasure"
  defp get_special_tile_class(:torch), do: "torch"
  defp get_special_tile_class(:bread), do: "bread"
  defp get_special_tile_class(:cheese), do: "cheese"
  defp get_special_tile_class(:grapes), do: "grapes"
  defp get_special_tile_class(:healing_potion), do: "healing-potion"
  defp get_special_tile_class(:stair_up), do: "stair-up"
  defp get_special_tile_class(:stair_down), do: "stair-down"
  defp get_special_tile_class(:pile_of_bones), do: "pile-of-bones"

  # Labeled tiles (tuples)
  defp labeled_tile?({:encounter, _, _}), do: true
  defp labeled_tile?({:special_feature, _, _}), do: true
  defp labeled_tile?({:room_label, _}), do: true
  defp labeled_tile?({:corridor_label, _}), do: true
  defp labeled_tile?({:area_label, _}), do: true
  defp labeled_tile?({:building_label, _}), do: true
  defp labeled_tile?({:starting_stair, _}), do: true
  defp labeled_tile?(_), do: false

  defp get_labeled_tile_class({:encounter, _, _}), do: "encounter"
  defp get_labeled_tile_class({:special_feature, _, _}), do: "special-feature"
  defp get_labeled_tile_class({:room_label, _}), do: "room-label"
  defp get_labeled_tile_class({:corridor_label, _}), do: "corridor-label"
  defp get_labeled_tile_class({:area_label, _}), do: "area-label"
  defp get_labeled_tile_class({:building_label, _}), do: "building-label"
  defp get_labeled_tile_class({:starting_stair, _}), do: "starting-stair"

  @doc """
  Get symbol for tile type in print view
  """
  def get_tile_symbol(tile) do
    cond do
      basic_tile?(tile) -> get_basic_tile_symbol(tile)
      door_tile?(tile) -> get_door_tile_symbol(tile)
      special_tile?(tile) -> get_special_tile_symbol(tile)
      labeled_tile?(tile) -> get_labeled_tile_symbol(tile)
      true -> ""
    end
  end

  # Basic tile symbols (mostly empty)
  defp get_basic_tile_symbol(tile)
       when tile in [:wall, :floor, :corridor, :pillar, :road, :shrub],
       do: ""

  # Door symbols
  defp get_door_tile_symbol(:door), do: "▒"
  defp get_door_tile_symbol(:locked_door), do: "🔒"
  defp get_door_tile_symbol(:trapped_door), do: "⚠"
  defp get_door_tile_symbol(:locked_trapped_door), do: "🔐"
  defp get_door_tile_symbol(:secret_door), do: "🔍"

  # Special tile symbols
  defp get_special_tile_symbol(:room_trap), do: tile_img_tag("/images/trap.png", "Trap")
  defp get_special_tile_symbol(:treasure), do: tile_img_tag("/images/chest.png", "Treasure")

  defp get_special_tile_symbol(:trapped_treasure),
    do: tile_img_tag("/images/chest.png", "Treasure")

  defp get_special_tile_symbol(:torch), do: tile_img_tag("/images/torch.png", "Torch")
  defp get_special_tile_symbol(:bread), do: tile_img_tag("/images/bread.png", "Bread")
  defp get_special_tile_symbol(:cheese), do: tile_img_tag("/images/cheese.png", "Cheese")
  defp get_special_tile_symbol(:grapes), do: tile_img_tag("/images/grapes.png", "Grapes")

  defp get_special_tile_symbol(:healing_potion),
    do: tile_img_tag("/images/healing_potion.png", "Healing Potion")

  defp get_special_tile_symbol(:stair_up), do: "↑"
  defp get_special_tile_symbol(:stair_down), do: "↓"

  defp get_special_tile_symbol(:pile_of_bones),
    do: tile_img_tag("/images/pile_of_bones.png", "Pile of Bones")

  # Labeled tile symbols (extract from tuple)
  defp get_labeled_tile_symbol({:encounter, _label, monster}) do
    tile_img_tag("/images/monsters/#{monster.image}", monster.name)
  end

  defp get_labeled_tile_symbol({:special_feature, _label, feature_name}) do
    # Extract the actual feature name from tuple format {name, rarity} or use as-is if already a string
    actual_feature_name = extract_feature_name(feature_name)
    feature_image_path = Features.get_special_feature_image_path(actual_feature_name)
    tile_img_tag(feature_image_path, actual_feature_name)
  end

  defp get_labeled_tile_symbol({:room_label, room_number}), do: to_string(room_number)
  defp get_labeled_tile_symbol({:corridor_label, corridor_number}), do: to_string(corridor_number)
  defp get_labeled_tile_symbol({:area_label, area_number}), do: to_string(area_number)
  defp get_labeled_tile_symbol({:building_label, building_number}), do: to_string(building_number)
  defp get_labeled_tile_symbol({:starting_stair, stair_label}), do: to_string(stair_label)

  # Helper function to extract feature name from different formats
  def extract_feature_name({feature_name, _rarity}) when is_binary(feature_name),
    do: feature_name

  def extract_feature_name(feature_name) when is_binary(feature_name), do: feature_name
  def extract_feature_name(_), do: "Unknown Feature"

  @doc """
  Get random floor texture class for static view based on position
  """
  def get_floor_texture_class(x, y, generation_type \\ "dungeon") do
    if generation_type == "cavern" do
      "bg-gray-300"
    else
      get_static_dungeon_floor_texture(x, y)
    end
  end

  # Helper function for traditional dungeon floor textures in static view
  defp get_static_dungeon_floor_texture(x, y) do
    # Use position to seed random variation for consistent results
    hash = rem(x * 31 + y * 17, 6)

    case hash do
      0 -> "bg-gray-300"
      1 -> "bg-gray-200"
      2 -> "bg-stone-200"
      3 -> "bg-stone-300"
      4 -> "bg-slate-200"
      _ -> "bg-slate-300"
    end
  end

  @doc """
  Get random floor tileset style for static view based on position and theme
  """
  def get_floor_tileset_style(x, y, theme \\ "light_cracked_stone.png") do
    tileset_path = "/images/tilesets/#{theme}"
    background_position = get_random_tile_position_static(x, y, 41, 29)

    "background-image: url('#{tileset_path}'); background-position: #{background_position}; background-size: 60px 60px; background-repeat: no-repeat;"
  end

  @doc """
  Get random floor tileset style for PNG downloads based on position and theme
  """
  def get_floor_tileset_style_for_png(x, y, theme \\ "light_cracked_stone.png") do
    tileset_path = "/images/tilesets/#{theme}"
    background_position = get_random_tile_position_png(x, y, 41, 29)

    "background-image: url('#{tileset_path}'); background-position: #{background_position}; background-size: 560px 560px; background-repeat: no-repeat;"
  end

  @doc """
  Get random wall tileset style for static view based on position and theme
  """
  def get_wall_tileset_style(x, y, theme \\ "dark_stone_with_vines.png") do
    tileset_path = "/images/tilesets/#{theme}"
    background_position = get_random_tile_position_static(x, y, 47, 19)

    "background-image: url('#{tileset_path}'); background-position: #{background_position}; background-size: 60px 60px; background-repeat: no-repeat;"
  end

  @doc """
  Get random wall tileset style for PNG downloads based on position and theme
  """
  def get_wall_tileset_style_for_png(x, y, theme \\ "dark_stone_with_vines.png") do
    tileset_path = "/images/tilesets/#{theme}"
    background_position = get_random_tile_position_png(x, y, 47, 19)

    "background-image: url('#{tileset_path}'); background-position: #{background_position}; background-size: 560px 560px; background-repeat: no-repeat;"
  end

  @doc """
  Get random corridor tileset style for static view based on position and theme
  """
  def get_corridor_tileset_style(
        x,
        y,
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
    background_position = get_random_tile_position_static(x, y, 43, 31)

    "background-image: url('#{tileset_path}'); background-position: #{background_position}; background-size: 60px 60px; background-repeat: no-repeat;"
  end

  @doc """
  Get random corridor tileset style for PNG downloads based on position and theme
  """
  def get_corridor_tileset_style_for_png(
        x,
        y,
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
    background_position = get_random_tile_position_png(x, y, 43, 31)

    "background-image: url('#{tileset_path}'); background-position: #{background_position}; background-size: 560px 560px; background-repeat: no-repeat;"
  end

  @doc """
  Get random shrub tileset style for static view based on position and theme
  """
  def get_shrub_tileset_style(x, y, shrub_theme \\ "green_shrubs.png") do
    tileset_path = "/images/tilesets/#{shrub_theme}"
    background_position = get_random_tile_position_static(x, y, 83, 107)

    "background-image: url('#{tileset_path}'); background-position: #{background_position}; background-size: 60px 60px; background-repeat: no-repeat;"
  end

  @doc """
  Get random shrub tileset style for PNG downloads based on position and theme
  """
  def get_shrub_tileset_style_for_png(x, y, shrub_theme \\ "green_shrubs.png") do
    tileset_path = "/images/tilesets/#{shrub_theme}"
    background_position = get_random_tile_position_png(x, y, 83, 107)

    "background-image: url('#{tileset_path}'); background-position: #{background_position}; background-size: 560px 560px; background-repeat: no-repeat;"
  end

  @doc """
  Get random road tileset style for static view based on position and theme
  """
  def get_road_tileset_style(x, y, road_theme \\ "dirt_and_grass.png") do
    tileset_path = "/images/tilesets/#{road_theme}"
    background_position = get_random_tile_position_static(x, y, 79, 101)

    "background-image: url('#{tileset_path}'); background-position: #{background_position}; background-size: 60px 60px; background-repeat: no-repeat;"
  end

  @doc """
  Get random road tileset style for PNG downloads based on position and theme
  """
  def get_road_tileset_style_for_png(x, y, road_theme \\ "dirt_and_grass.png") do
    tileset_path = "/images/tilesets/#{road_theme}"
    background_position = get_random_tile_position_png(x, y, 79, 101)

    "background-image: url('#{tileset_path}'); background-position: #{background_position}; background-size: 560px 560px; background-repeat: no-repeat;"
  end

  # Helper function to calculate random tile position within a 4x4 grid for static view
  defp get_random_tile_position_static(x, y, seed_x, seed_y) do
    # Use position to seed random variation for consistent results
    # Create a simple hash from coordinates for tile selection (0-15 for 4x4 grid)
    hash = rem(x * seed_x + y * seed_y, 16)

    # Convert hash to grid position (0-3 for both x and y)
    grid_x = rem(hash, 4)
    grid_y = div(hash, 4)

    # Convert grid position to background-position in pixels
    # Each tile is 15px in the scaled 60px background, so positions are 0px, -15px, -30px, -45px
    pos_x = grid_x * -15
    pos_y = grid_y * -15

    "#{pos_x}px #{pos_y}px"
  end

  # Helper function to calculate random tile position within a 4x4 grid for PNG downloads
  defp get_random_tile_position_png(x, y, seed_x, seed_y) do
    # Use position to seed random variation for consistent results
    # Create a simple hash from coordinates for tile selection (0-15 for 4x4 grid)
    hash = rem(x * seed_x + y * seed_y, 16)

    # Convert hash to grid position (0-3 for both x and y)
    grid_x = rem(hash, 4)
    grid_y = div(hash, 4)

    # Convert grid position to background-position in pixels
    # Each tile is 140px in the scaled 560px background (560/4 = 140px), so positions are 0px, -140px, -280px, -420px
    pos_x = grid_x * -140
    pos_y = grid_y * -140

    "#{pos_x}px #{pos_y}px"
  end

  @doc """
  Get random corridor texture class for static view based on position
  """
  def get_corridor_texture_class(x, y, generation_type \\ "dungeon") do
    if generation_type == "cavern" do
      "bg-gray-300"
    else
      get_static_dungeon_corridor_texture(x, y)
    end
  end

  # Helper function for traditional dungeon corridor textures in static view
  defp get_static_dungeon_corridor_texture(x, y) do
    # Use position to seed random variation for consistent results
    # Create a simple hash from coordinates (offset from floor hash)
    hash = rem(x * 37 + y * 23, 6)

    case hash do
      0 -> "bg-gray-400"
      1 -> "bg-gray-300"
      2 -> "bg-stone-300"
      3 -> "bg-stone-400"
      4 -> "bg-slate-300"
      _ -> "bg-slate-400"
    end
  end

  @doc """
  Get random stair tile image for static view based on position and transition theme
  """
  def get_stair_tile_image(x, y, transition_theme \\ "dungeon_stairs") do
    # Use position to seed random variation for consistent results
    # Create a simple hash from coordinates for stair tile selection (1-4)
    hash = rem(x * 53 + y * 67, 4) + 1
    "/images/map_links/#{transition_theme}#{hash}.png"
  end

  @doc """
  Get random door image for static view based on position
  """
  def get_door_image(x, y) do
    # Use position to seed random variation for consistent results
    # Create a simple hash from coordinates for door selection (1-16)
    hash = rem(x * 73 + y * 97, 16) + 1
    door_number = String.pad_leading(to_string(hash), 2, "0")
    "/images/doors/door#{door_number}.png"
  end

  @doc """
  Get border class for static view based on generation type
  """
  def get_tile_border_class(_generation_type) do
    # No borders for any generation type in static view
    "border-0"
  end

  @doc """
  Check if a position should use floor texture (vs road texture) for city maps in PNG downloads
  """
  def should_use_floor_texture_for_png?(x, y, dungeon) do
    case dungeon.generation_type do
      "city" ->
        point_in_city_building?({x, y}, dungeon.rooms)

      _ ->
        true
    end
  end

  @doc """
  Check if a position should use road texture for city maps in PNG downloads
  """
  def should_use_road_texture_for_png?(tile, x, y, dungeon) do
    case dungeon.generation_type do
      "city" ->
        # Use road background for road tiles and items placed on roads (not in buildings)
        corridor_tile?(tile) or not point_in_city_building?({x, y}, dungeon.rooms)

      _ ->
        false
    end
  end

  # Helper function to check if a position is within a city building (not road intersection)
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

  # Helper function to check if tile is a corridor tile
  defp corridor_tile?(tile) do
    tile in [:corridor, :road] or match?({:corridor_label, _}, tile)
  end

  @doc """
  Get CSS sizing classes for special features in PNG downloads
  """
  def get_feature_image_size_for_png(feature_name) do
    size = Features.get_special_feature_size(feature_name)
    convert_size_to_css_style(size)
  end

  @doc """
  Get CSS container classes for special features in PNG downloads
  """
  def get_feature_container_style_for_png(feature_name) do
    size = Features.get_special_feature_size(feature_name)

    if size >= 2 do
      # For features larger than the grid, allow overflow and center
      "position: absolute; top: 0; left: 0; right: 0; bottom: 0; display: flex; align-items: center; justify-content: center; z-index: 20; overflow: visible;"
    else
      # Size 1 and smaller features fit within the grid square
      "position: absolute; top: 0; left: 0; right: 0; bottom: 0; display: flex; align-items: center; justify-content: center; z-index: 20;"
    end
  end

  @doc """
  Get CSS sizing classes for monsters in PNG downloads
  """
  def get_monster_image_size_for_png(monster) do
    size = monster.size || 1.0
    convert_size_to_css_style(size)
  end

  @doc """
  Get CSS container classes for monsters in PNG downloads
  """
  def get_monster_container_style_for_png(monster) do
    size = monster.size || 1.0

    if size >= 2 do
      # For monsters larger than the grid, allow overflow and center
      "position: absolute; top: 0; left: 0; right: 0; bottom: 0; display: flex; align-items: center; justify-content: center; z-index: 20; overflow: visible;"
    else
      # Size 1 and smaller monsters fit within the grid square
      "position: absolute; top: 0; left: 0; right: 0; bottom: 0; display: flex; align-items: center; justify-content: center; z-index: 20;"
    end
  end

  @doc """
  Get CSS container style for map links (always size 2 with overflow)
  """
  def get_map_link_container_style_for_png do
    "position: absolute; top: 0; left: 0; right: 0; bottom: 0; display: flex; align-items: center; justify-content: center; z-index: 20; overflow: visible;"
  end

  # Convert numeric size to CSS width/height inline styles for PNG downloads
  # PNG template uses 140px grid cells vs 48px in live view, so scale by ~2.92x
  defp convert_size_to_css_style(size) when size <= 0.5, do: png_size_style_small(size)
  defp convert_size_to_css_style(size) when size <= 1.0, do: png_size_style_medium(size)
  defp convert_size_to_css_style(size) when size <= 2.0, do: png_size_style_large(size)
  defp convert_size_to_css_style(size) when size <= 3.0, do: png_size_style_extra_large(size)
  defp convert_size_to_css_style(_size), do: "width: 140px; height: 140px;"

  # PNG template sizing functions (scaled up from 48px base to 140px base = 2.92x)
  defp png_size_style_small(0.25), do: "width: 35px; height: 35px;"
  defp png_size_style_small(0.5), do: "width: 70px; height: 70px;"
  defp png_size_style_small(_), do: "width: 70px; height: 70px;"

  defp png_size_style_medium(0.75), do: "width: 105px; height: 105px;"
  defp png_size_style_medium(1), do: "width: 140px; height: 140px;"
  defp png_size_style_medium(_), do: "width: 140px; height: 140px;"

  defp png_size_style_large(1.25), do: "width: 175px; height: 175px;"
  defp png_size_style_large(1.5), do: "width: 210px; height: 210px;"
  defp png_size_style_large(1.75), do: "width: 245px; height: 245px;"
  defp png_size_style_large(2), do: "width: 280px; height: 280px;"
  defp png_size_style_large(_), do: "width: 280px; height: 280px;"

  defp png_size_style_extra_large(2.25), do: "width: 315px; height: 315px;"
  defp png_size_style_extra_large(2.5), do: "width: 350px; height: 350px;"
  defp png_size_style_extra_large(2.75), do: "width: 385px; height: 385px;"
  defp png_size_style_extra_large(3), do: "width: 420px; height: 420px;"
  defp png_size_style_extra_large(_), do: "width: 420px; height: 420px;"

  @doc """
  Check if an image should be horizontally flipped based on adjacent walls/shrubs for PNG downloads
  Returns true if there's a wall/shrub on the right (so image should face left)
  """
  def should_flip_image_for_png?(x, y, dungeon_grid) do
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
  Get CSS transform style for image flipping based on adjacent walls/shrubs for PNG downloads
  """
  def get_image_flip_style_for_png(x, y, dungeon_grid) do
    if should_flip_image_for_png?(x, y, dungeon_grid) do
      " transform: scaleX(-1);"
    else
      ""
    end
  end

  # Helper function to check if a tile is a wall or shrub
  defp wall_or_shrub_tile?(tile) do
    tile == :wall or tile == :shrub
  end

  @doc """
  Get door orientation for static view (copied from live view renderer)
  """
  def get_door_orientation(grid, x, y, tile) do
    if door_tile?(tile) do
      determine_door_orientation(grid, x, y)
    else
      nil
    end
  end

  # Extract door orientation logic to reduce complexity
  defp determine_door_orientation(grid, x, y) do
    adjacent_tiles = %{
      north: Map.get(grid, {x, y - 1}),
      south: Map.get(grid, {x, y + 1}),
      east: Map.get(grid, {x + 1, y}),
      west: Map.get(grid, {x - 1, y})
    }

    Enum.find([:north, :south, :east, :west], :north, fn direction ->
      room_tile?(adjacent_tiles[direction])
    end)
  end

  # Check if a tile is a room tile type
  defp room_tile?(tile) do
    basic_room_tile?(tile) or special_room_tile?(tile)
  end

  defp basic_room_tile?(tile) do
    tile in [
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
  end

  defp special_room_tile?(tile) do
    match?({:room_label, _}, tile) or match?({:encounter, _, _}, tile) or
      match?({:starting_stair, _}, tile) or match?({:starting_waypoint, _}, tile) or
      match?({:special_feature, _, _}, tile) or match?({:waypoint, _}, tile)
  end
end
