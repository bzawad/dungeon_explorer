defmodule DungeonWeb.DungeonLive.SpecialFeatureSystem do
  @moduledoc """
  Special feature detection, messages, and dialog handling
  """

  alias Dungeon.Generator.Features

  @doc """
  Check if a tile contains a special feature
  """
  def special_feature_tile?(tile) do
    match?({:special_feature, _, _}, tile)
  end

  @doc """
  Get special feature icon and message (generates LLM description if needed)
  """
  def get_special_feature_message(socket, position, feature_data) do
    {feature_label, feature_name} = extract_feature_info(feature_data)

    feature_description =
      get_or_generate_feature_description(socket, position, feature_label, feature_name)

    # The feature description already includes the formatted feature name
    {DungeonWeb.UISizing.img_tag("/images/magnifying_glass.png", "Feature", :medium_icon),
     feature_description}
  end

  @doc """
  Get or generate feature description from storage or trigger generation
  """
  def get_or_generate_feature_description(socket, position, _feature_label, feature_name) do
    # Extract the actual feature name from tuple format if needed
    actual_feature_name = extract_feature_name_from_data(feature_name)

    # Build proper context with theme and room description
    # Try multiple sources for room description in order of preference
    room_description =
      socket.assigns.current_room_description ||
        socket.assigns.previous_room_description ||
        Map.get(socket.assigns.room_descriptions, "R1", nil) ||
        "a mysterious chamber in the #{socket.assigns.dungeon.theme}"

    context = %{
      theme: socket.assigns.dungeon.theme,
      room_description: room_description,
      position: position,
      # Use the specific feature name for LLM context
      feature_label: actual_feature_name
    }

    # Use the centralized description service
    alias Dungeon.Services.DescriptionService
    DescriptionService.get_or_generate(:feature, socket, context)
  end

  # Helper function to extract feature info from tuple format
  defp extract_feature_info({:special_feature, feature_label, feature_name}) do
    # Three-element format - separate display label and feature name
    {feature_label, feature_name}
  end

  # Backward compatibility for old 2-element format
  defp extract_feature_info({:special_feature, feature_name}) do
    # Two-element format - feature name serves as both label and name
    {feature_name, feature_name}
  end

  # Helper function to extract feature name from different formats
  defp extract_feature_name_from_data({feature_name, _rarity}) when is_binary(feature_name),
    do: feature_name

  defp extract_feature_name_from_data(feature_name) when is_binary(feature_name), do: feature_name
  defp extract_feature_name_from_data(_), do: "Unknown Feature"

  @doc """
  Process special feature discovery when player steps on it
  """
  def process_special_feature(socket, {x, y}) do
    dungeon = socket.assigns.dungeon
    tile = Map.get(dungeon.grid, {x, y})

    case tile do
      {:special_feature, _, _} ->
        # Check if this feature was already discovered
        if MapSet.member?(socket.assigns.discovered_features, {x, y}) do
          # Already discovered, no dialog
          {false, "", ""}
        else
          # New feature! Generate message
          {icon, message} = get_special_feature_message(socket, {x, y}, tile)
          {true, icon, message}
        end

      _ ->
        {false, "", ""}
    end
  end

  @doc """
  Process special feature click - show feature dialog with investigate option
  """
  def process_feature_click(socket, {x, y}) do
    dungeon = socket.assigns.dungeon
    tile = Map.get(dungeon.grid, {x, y})

    case tile do
      {:special_feature, _, _} ->
        # Always show feature dialog when clicked, regardless of discovery status
        {icon, message} = get_special_feature_message(socket, {x, y}, tile)
        {true, icon, message}

      _ ->
        {false, "", ""}
    end
  end

  @doc """
  Process feature investigation using attribute-based contents evaluation
  Contents are evaluated in order: treasure, special_item, rumor, trap, monster
  Only one result is returned, evaluation stops after first success
  """
  def process_feature_investigation(socket, {x, y}) do
    dungeon = socket.assigns.dungeon
    tile = Map.get(dungeon.grid, {x, y})

    if special_feature_tile?(tile) do
      {_feature_label, feature_name} = extract_feature_info(tile)
      evaluate_contents(socket, {x, y}, feature_name)
    else
      {false, "", ""}
    end
  end

  # Helper function to evaluate contents based on attributes
  defp evaluate_contents(socket, {x, y}, feature_name) do
    # Extract the actual feature name from tuple format if needed
    actual_feature_name = extract_feature_name_from_data(feature_name)
    config = Features.get_special_feature_contents_config(actual_feature_name)

    check_treasure(socket, {x, y}, actual_feature_name, config) ||
      check_special_item(socket, {x, y}, actual_feature_name, config) ||
      check_rumor(socket, {x, y}, actual_feature_name, config) ||
      check_trap(socket, {x, y}, actual_feature_name, config) ||
      check_monster(socket, {x, y}, actual_feature_name, config) ||
      generate_nothing_found(socket, {x, y}, actual_feature_name)
  end

  # Individual check functions for better readability and lower complexity
  defp check_treasure(socket, {x, y}, feature_name, config) do
    if config.treasure_chance > 0 and Dungeon.Dice.chance_succeeds?(config.treasure_chance) do
      generate_treasure_find(socket, {x, y}, feature_name)
    end
  end

  defp check_special_item(socket, {x, y}, feature_name, config) do
    if config.special_item_chance > 0 and
         Dungeon.Dice.chance_succeeds?(config.special_item_chance) do
      generate_special_item(socket, {x, y}, feature_name)
    end
  end

  defp check_rumor(socket, {x, y}, feature_name, config) do
    if config.rumor_chance > 0 and Dungeon.Dice.chance_succeeds?(config.rumor_chance) do
      generate_rumor(socket, {x, y}, feature_name)
    end
  end

  defp check_trap(socket, {x, y}, _feature_name, config) do
    if config.trap_chance > 0 and Dungeon.Dice.chance_succeeds?(config.trap_chance) do
      generate_room_trap(socket, {x, y})
    end
  end

  defp check_monster(socket, {x, y}, feature_name, config) do
    if config.monster_chance > 0 and Dungeon.Dice.chance_succeeds?(config.monster_chance) do
      spawn_monster_from_feature(socket, {x, y}, feature_name, config.monster_list)
    end
  end

  # Helper function to generate room trap
  defp generate_room_trap(socket, {x, y}) do
    alias DungeonWeb.DungeonLive.TrapSystem

    socket_with_trap =
      Map.put(
        socket,
        :assigns,
        Map.put(
          socket.assigns,
          :sprung_traps,
          MapSet.put(socket.assigns.sprung_traps, {x, y})
        )
      )

    message =
      TrapSystem.get_or_generate_room_trap_description(
        socket_with_trap,
        {x, y},
        :room_trap
      )

    icon = DungeonWeb.UISizing.img_tag("/images/trap.png", "Trap", :medium_icon)
    {:trap, icon, message}
  end

  defp generate_special_item(socket, position, feature_name) do
    # Use the common special item system
    alias DungeonWeb.DungeonLive.SpecialItemSystem

    SpecialItemSystem.generate_special_item_discovery(
      socket,
      position,
      :special_feature,
      feature_name
    )
  end

  defp generate_rumor(socket, position, feature_name) do
    # Send message to generate rumor asynchronously
    send(self(), {:generate_rumor, position, feature_name})

    # Return immediate result with placeholder
    {:rumor, DungeonWeb.UISizing.img_tag("/images/open_scroll.png", "Rumor", :medium_icon),
     "#{DungeonWeb.UISizing.inline_img_tag("/images/hourglass.png", "Loading", :loading_icon)} Generating rumor...",
     socket}
  end

  defp generate_treasure_find(_socket, {_x, _y}, feature_name) do
    # Use the existing treasure system patterns but simpler approach for features
    # Generate random gold amount (1d10 + 5)
    gold_amount = Dungeon.Dice.roll(1, 10) + 5

    {:treasure, DungeonWeb.UISizing.img_tag("/images/gold.png", "Treasure", :medium_icon),
     "You found #{gold_amount} gold pieces hidden in the #{feature_name}!"}
  end

  defp spawn_monster_from_feature(socket, {x, y}, feature_name, monster_list) do
    if Enum.empty?(monster_list) do
      # No monsters configured, fall back to nothing found
      generate_nothing_found(socket, {x, y}, feature_name)
    else
      # Select random monster from the list
      monster_name = Enum.random(monster_list)

      # Find adjacent floor space for monster
      case find_adjacent_floor_space(socket, {x, y}) do
        nil ->
          # No adjacent space found, fall back to nothing found
          generate_nothing_found(socket, {x, y}, feature_name)

        monster_position ->
          # Spawn monster and trigger combat
          spawn_surprise_monster(socket, monster_position, monster_name, feature_name)
      end
    end
  end

  defp generate_nothing_found(_socket, {_x, _y}, feature_name) do
    {:nothing,
     DungeonWeb.UISizing.img_tag("/images/magnifying_glass.png", "Search", :medium_icon),
     "You search the #{feature_name} thoroughly but find nothing of interest."}
  end

  # Helper function to find an adjacent floor space for monster spawning
  defp find_adjacent_floor_space(socket, {x, y}) do
    dungeon = socket.assigns.dungeon

    # Check all 8 adjacent positions
    adjacent_offsets = [
      {-1, -1},
      {0, -1},
      {1, -1},
      {-1, 0},
      {1, 0},
      {-1, 1},
      {0, 1},
      {1, 1}
    ]

    adjacent_positions =
      for {dx, dy} <- adjacent_offsets do
        {x + dx, y + dy}
      end

    # Filter for valid floor positions
    valid_positions =
      Enum.filter(adjacent_positions, fn {adj_x, adj_y} ->
        # Check bounds
        # Check if it's a floor tile
        adj_x >= 0 and adj_x < dungeon.width and
          adj_y >= 0 and adj_y < dungeon.height and
          Map.get(dungeon.grid, {adj_x, adj_y}) == :floor
      end)

    # Return first valid position or nil if none found
    List.first(valid_positions)
  end

  # Helper function to spawn a surprise monster and trigger combat
  defp spawn_surprise_monster(_socket, monster_position, monster_name, feature_name) do
    # Create monster data
    case Dungeon.Monster.create_monster_instance(monster_name) do
      nil ->
        # Monster not found, return nothing found message
        {:nothing,
         DungeonWeb.UISizing.img_tag("/images/magnifying_glass.png", "Search", :medium_icon),
         "You search the #{feature_name} thoroughly but find nothing of interest."}

      monster ->
        # Send message to LiveView to trigger surprise combat
        send(self(), {:surprise_monster_combat, monster_position, monster, feature_name})

        # Return immediate combat message
        {:monster, DungeonWeb.UISizing.img_tag("/images/swords.png", "Combat", :medium_icon),
         "A #{monster.name} jumps out of the #{feature_name} and attacks!"}
    end
  end

  @doc """
  Dismiss special feature dialog without marking as discovered (allows re-investigation)
  """
  def dismiss_special_feature(socket) do
    # Close dialog without marking as discovered - player can investigate again later
    socket
    |> assign(:show_special_feature_dialog, false)
    |> assign(:special_feature_icon, "")
    |> assign(:special_feature_message, "")
    |> assign(:discovered_feature_position, nil)
  end

  # Private helper
  defp assign(socket, key, value) do
    Phoenix.Component.assign(socket, key, value)
  end

  @doc """
  Get the appropriate image filename for a special feature name
  """
  def get_feature_image(feature_name) do
    case Features.get_special_feature_data(feature_name) do
      %{image: image} -> image
      nil -> "barrel.png"
    end
  end

  @doc """
  Get the full image path for a special feature, handling subdirectory organization
  """
  def get_feature_image_path(feature_name) do
    Features.get_special_feature_image_path(feature_name)
  end
end
