defmodule DungeonWeb.DungeonLive.HealingPotionSystem do
  @moduledoc """
  Healing potion discovery, collection, and healing with 1d6 hit points
  """

  import Phoenix.Component, only: [assign: 3]
  alias Dungeon.Dice

  @doc """
  Check if a tile contains a healing potion
  """
  def healing_potion_tile?(tile) do
    tile == :healing_potion
  end

  @doc """
  Get healing potion icon and message with healing calculation
  """
  def get_healing_potion_message(socket, _position) do
    # Roll 1d6 for healing amount
    healing_amount = Dice.roll_dice_string("1d6")

    # Calculate actual healing (don't heal above max HP)
    current_hp = socket.assigns.player_hit_points
    max_hp = socket.assigns.max_hit_points
    actual_healing = min(healing_amount, max_hp - current_hp)

    # Generate healing potion description
    description =
      get_healing_potion_description(healing_amount, actual_healing, current_hp, max_hp)

    icon =
      DungeonWeb.UISizing.img_tag("/images/healing_potion.png", "Healing Potion", :medium_icon)

    {icon, description, actual_healing}
  end

  defp get_healing_potion_description(_healing_amount, _actual_healing, _current_hp, _max_hp) do
    "You found a healing potion! It has been added to your inventory. You can use it later when needed."
  end

  @doc """
  Process healing potion discovery when player steps on it
  """
  def process_healing_potion(socket, {x, y}) do
    dungeon = socket.assigns.dungeon
    tile = Map.get(dungeon.grid, {x, y})

    if healing_potion_tile?(tile) do
      {icon, message, healing_amount} = get_healing_potion_message(socket, {x, y})
      {true, icon, message, {x, y}, healing_amount}
    else
      {false, "", "", nil, 0}
    end
  end

  @doc """
  Dismiss healing potion dialog, apply healing, and remove the potion from the dungeon
  """
  def dismiss_healing_potion(socket) do
    # Play pickup sound when drinking healing potion
    socket = Phoenix.LiveView.push_event(socket, "play_audio", %{sound: "pickup"})

    position = socket.assigns.collected_healing_potion_position
    healing_amount = socket.assigns.collected_healing_potion_healing

    # Apply healing
    current_hp = socket.assigns.player_hit_points
    max_hp = socket.assigns.max_hit_points
    new_hp = min(current_hp + healing_amount, max_hp)

    # Remove healing potion from dungeon grid
    updated_grid =
      if position do
        # Determine if this position is in a room or corridor
        underlying_tile = determine_underlying_tile(position, socket.assigns.dungeon.rooms)
        Map.put(socket.assigns.dungeon.grid, position, underlying_tile)
      else
        socket.assigns.dungeon.grid
      end

    updated_dungeon = Map.put(socket.assigns.dungeon, :grid, updated_grid)

    socket
    |> assign(:dungeon, updated_dungeon)
    |> assign(:player_hit_points, new_hp)
    |> assign(:show_healing_potion_dialog, false)
    |> assign(:healing_potion_icon, "")
    |> assign(:healing_potion_message, "")
    |> assign(:collected_healing_potion_position, nil)
    |> assign(:collected_healing_potion_healing, 0)
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
end
