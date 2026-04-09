defmodule DungeonWeb.DungeonLive.TreasureSystem do
  @moduledoc """
  Treasure detection, messages, and dialog handling with gold tracking
  """

  alias Dungeon.Dice
  alias Dungeon.Services.DescriptionService

  @doc """
  Check if a tile contains treasure
  """
  def treasure_tile?(tile) do
    tile in [:treasure, :trapped_treasure]
  end

  @doc """
  Get treasure icon and message with gold calculation and LLM description
  """
  def get_treasure_message(socket, position) do
    # Roll 3d10 for gold amount
    gold_amount = Dice.roll_dice_string("3d10")

    # Get or generate treasure description
    description = get_or_generate_treasure_description(socket, position, gold_amount)

    {DungeonWeb.UISizing.img_tag("/images/gold.png", "Gold", :medium_icon), description,
     gold_amount}
  end

  # Get or generate treasure description from storage or trigger generation
  defp get_or_generate_treasure_description(socket, position, gold_amount) do
    # Get current or previous room description for context
    room_description =
      socket.assigns.current_room_description ||
        socket.assigns.previous_room_description ||
        "a mysterious chamber in the #{socket.assigns.dungeon.theme}"

    context = %{
      position: position,
      theme: socket.assigns.dungeon.theme,
      level: socket.assigns.dungeon_level,
      gold_amount: gold_amount,
      room_description: room_description
    }

    DescriptionService.get_or_generate(:treasure, socket, context)
  end

  @doc """
  Process treasure discovery when player steps on it
  """
  def process_treasure(socket, {x, y}) do
    dungeon = socket.assigns.dungeon
    tile = Map.get(dungeon.grid, {x, y})

    if treasure_tile?(tile) do
      {icon, message, gold_amount} = get_treasure_message(socket, {x, y})
      {true, icon, message, {x, y}, gold_amount}
    else
      {false, "", "", nil, 0}
    end
  end

  @doc """
  Dismiss treasure dialog, add gold to player total, and remove the treasure from the dungeon
  """
  def dismiss_treasure(socket) do
    # Play coins sound when collecting treasure
    socket = Phoenix.LiveView.push_event(socket, "play_audio", %{sound: "coins"})

    # Add collected gold to player's total if there's a gold amount stored
    socket =
      if socket.assigns[:collected_treasure_gold] do
        current_gold = socket.assigns.player_gold || 0
        new_gold = current_gold + socket.assigns.collected_treasure_gold
        assign(socket, :player_gold, new_gold)
      else
        socket
      end

    # Check if we need to remove the collected treasure
    socket =
      if socket.assigns.collected_treasure_position do
        remove_collected_treasure(socket, socket.assigns.collected_treasure_position)
      else
        socket
      end

    # Check for special item discovery (25% chance)
    socket = check_treasure_special_item(socket)

    socket
    |> assign(:show_treasure_dialog, false)
    |> assign(:treasure_icon, "")
    |> assign(:treasure_message, "")
    |> assign(:collected_treasure_position, nil)
    |> assign(:collected_treasure_gold, nil)
  end

  @doc """
  Remove collected treasure from the dungeon grid
  """
  def remove_collected_treasure(socket, {x, y}) do
    dungeon = socket.assigns.dungeon
    tile = Map.get(dungeon.grid, {x, y})

    new_tile =
      case tile do
        :treasure ->
          # Determine if this position is in a room or corridor
          determine_underlying_tile({x, y}, dungeon.rooms)

        # Should already be :treasure after trap removal, but handle both
        :trapped_treasure ->
          # Determine if this position is in a room or corridor
          determine_underlying_tile({x, y}, dungeon.rooms)

        # No change for other tiles
        _ ->
          tile
      end

    new_grid = Map.put(dungeon.grid, {x, y}, new_tile)
    new_dungeon = %{dungeon | grid: new_grid}

    assign(socket, :dungeon, new_dungeon)
  end

  # Check for special item discovery after treasure collection (25% chance)
  defp check_treasure_special_item(socket) do
    if socket.assigns[:collected_treasure_position] do
      position = socket.assigns.collected_treasure_position

      # Use the common special item system with 5% chance
      alias DungeonWeb.DungeonLive.SpecialItemSystem

      case SpecialItemSystem.check_special_item_discovery(
             socket,
             position,
             :treasure_chest,
             "treasure chest",
             5
           ) do
        nil ->
          # No special item found
          socket

        {:special_item, icon, message, updated_socket} ->
          # Special item found! Show special item dialog after treasure dialog closes
          updated_socket
          |> assign(:show_special_item_dialog, true)
          |> assign(:special_item_icon, icon)
          |> assign(:special_item_message, message)
      end
    else
      socket
    end
  end

  # Determine the underlying tile type based on position
  defp determine_underlying_tile({x, y}, rooms) do
    alias Dungeon.Generator.Grid

    if Grid.point_in_any_room?({x, y}, rooms) do
      :floor
    else
      :corridor
    end
  end

  # Private helper
  defp assign(socket, key, value) do
    Phoenix.Component.assign(socket, key, value)
  end
end
