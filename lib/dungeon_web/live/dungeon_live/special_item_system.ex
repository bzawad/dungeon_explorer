defmodule DungeonWeb.DungeonLive.SpecialItemSystem do
  @moduledoc """
  Common special item discovery system used across treasure chests, special features, and other sources
  """

  @doc """
  Generate a special item discovery with async description generation

  Returns a tuple with discovery type, icon, message, and socket for immediate display,
  while triggering async description generation in the background.

  Args:
  - socket: LiveView socket
  - position: {x, y} position where item was found
  - source_type: :treasure_chest, :special_feature, :monster_drop, etc.
  - source_name: Name of the source (e.g. "ornate chest", "ancient altar")
  """
  def generate_special_item_discovery(socket, position, source_type, source_name) do
    # Select a random special item using rarity-based system
    selected_item = Dungeon.SpecialItem.random_by_rarity_system()

    # Send message to generate custom description for this specific item
    send(self(), {:generate_special_item, position, source_type, source_name, selected_item})

    # Return immediate result with placeholder
    {:special_item,
     DungeonWeb.UISizing.img_tag("/images/special_item.png", "Special Item", :medium_icon),
     "#{DungeonWeb.UISizing.inline_img_tag("/images/hourglass.png", "Loading", :loading_icon)} Generating special item...",
     socket}
  end

  @doc """
  Check for special item discovery with given probability

  Returns either the special item discovery result or nil if check fails.
  """
  def check_special_item_discovery(socket, position, source_type, source_name, chance_percent) do
    if Dungeon.Dice.chance_succeeds?(chance_percent) do
      generate_special_item_discovery(socket, position, source_type, source_name)
    else
      nil
    end
  end

  @doc """
  Generate context for special item description based on source type
  """
  def build_special_item_context(socket, position, source_type, source_name, selected_item) do
    # Get current or previous room description for context
    room_description =
      socket.assigns.current_room_description ||
        socket.assigns.previous_room_description ||
        "a mysterious chamber in the #{socket.assigns.dungeon.theme}"

    base_context = %{
      position: position,
      theme: socket.assigns.dungeon.theme,
      level: socket.assigns.dungeon_level,
      room_description: room_description,
      selected_item: selected_item
    }

    # Add source-specific context
    case source_type do
      :treasure_chest ->
        Map.put(base_context, :source_description, "discovered in a #{source_name}")

      :special_feature ->
        Map.put(base_context, :source_description, "found within the #{source_name}")

      :monster_drop ->
        Map.put(base_context, :source_description, "dropped by the #{source_name}")

      _ ->
        Map.put(base_context, :source_description, "found near the #{source_name}")
    end
  end
end
