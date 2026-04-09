defmodule DungeonWeb.DungeonLive.FoodSystem do
  @moduledoc """
  Food discovery, collection, and healing with three specific food types: bread, cheese, and grapes
  """

  import Phoenix.Component, only: [assign: 3]
  alias Dungeon.Dice

  # Food data mappings
  @food_data %{
    "bread" => %{
      name: "a chunk of fresh bread",
      icon: DungeonWeb.UISizing.img_tag("/images/bread.png", "Bread", :medium_icon)
    },
    "cheese" => %{
      name: "a wedge of aged cheese",
      icon: DungeonWeb.UISizing.img_tag("/images/cheese.png", "Cheese", :medium_icon)
    },
    "grapes" => %{
      name: "a cluster of grapes",
      icon: DungeonWeb.UISizing.img_tag("/images/grapes.png", "Grapes", :medium_icon)
    }
  }

  @doc """
  Check if a tile contains food
  """
  def food_tile?(tile) do
    tile in [:bread, :cheese, :grapes]
  end

  @doc """
  Get food icon and message with healing calculation based on actual food type
  """
  def get_food_message(socket, position) do
    # Get the specific food type from the tile
    dungeon = socket.assigns.dungeon
    tile = Map.get(dungeon.grid, position)

    # Convert tile atom to string for lookup
    food_type = Atom.to_string(tile)
    food_info = Map.get(@food_data, food_type)

    # Roll 1d2 for healing amount
    healing_amount = Dice.roll_dice_string("1d2")

    # Calculate actual healing (don't heal above max HP)
    current_hp = socket.assigns.player_hit_points
    max_hp = socket.assigns.max_hit_points
    actual_healing = min(healing_amount, max_hp - current_hp)

    # Generate food description
    description =
      get_food_description(food_info.name, healing_amount, actual_healing, current_hp, max_hp)

    {food_info.icon, description, actual_healing}
  end

  defp get_food_description(food_name, _healing_amount, actual_healing, current_hp, max_hp) do
    base_message = "You found #{food_name}! "

    cond do
      current_hp >= max_hp ->
        base_message <> "You're already at full health, but the food still tastes lawful."

      actual_healing > 0 ->
        base_message <>
          "It restores #{actual_healing} hit point#{if actual_healing == 1, do: "", else: "s"}. (#{current_hp + actual_healing}/#{max_hp} HP)"

      true ->
        base_message <> "You're too healthy to benefit from it right now."
    end
  end

  @doc """
  Process food discovery when player steps on it
  """
  def process_food(socket, {x, y}) do
    dungeon = socket.assigns.dungeon
    tile = Map.get(dungeon.grid, {x, y})

    if food_tile?(tile) do
      {icon, message, healing_amount} = get_food_message(socket, {x, y})
      {true, icon, message, {x, y}, healing_amount}
    else
      {false, "", "", nil, 0}
    end
  end

  @doc """
  Dismiss food dialog, apply healing, and remove the food from the dungeon
  """
  def dismiss_food(socket) do
    # Play pickup sound when eating food
    socket = Phoenix.LiveView.push_event(socket, "play_audio", %{sound: "pickup"})

    position = socket.assigns.collected_food_position
    healing_amount = socket.assigns.collected_food_healing

    # Apply healing
    current_hp = socket.assigns.player_hit_points
    max_hp = socket.assigns.max_hit_points
    new_hp = min(current_hp + healing_amount, max_hp)

    # Remove food from dungeon grid
    updated_grid =
      if position do
        Map.put(socket.assigns.dungeon.grid, position, :floor)
      else
        socket.assigns.dungeon.grid
      end

    updated_dungeon = Map.put(socket.assigns.dungeon, :grid, updated_grid)

    socket
    |> assign(:dungeon, updated_dungeon)
    |> assign(:player_hit_points, new_hp)
    |> assign(:show_food_dialog, false)
    |> assign(:food_icon, "")
    |> assign(:food_message, "")
    |> assign(:collected_food_position, nil)
    |> assign(:collected_food_healing, 0)
  end
end
