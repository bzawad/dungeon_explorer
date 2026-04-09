defmodule DungeonWeb.DungeonLive.TrapSystem do
  @moduledoc """
  Trap detection, messages, and dialog handling with damage calculation
  """

  alias Dungeon.Dice
  alias DungeonWeb.DungeonLive.TreasureSystem

  @doc """
  Check if a tile is trapped
  """
  def trapped_tile?(tile) do
    tile in [:room_trap, :trapped_treasure, :trapped_door, :locked_trapped_door]
  end

  @doc """
  Calculate trap damage based on trap type
  """
  def calculate_trap_damage(tile) do
    case tile do
      :room_trap ->
        # Room (skull) traps deal 1d6 damage
        Dice.roll_dice_string("1d4")

      :trapped_treasure ->
        # Treasure traps deal 1d2 damage
        Dice.roll_dice_string("1d2")

      :trapped_door ->
        # Door traps deal 1d2 damage
        Dice.roll_dice_string("1d2")

      :locked_trapped_door ->
        # Locked door traps deal 1d2 damage
        Dice.roll_dice_string("1d2")

      _ ->
        0
    end
  end

  @doc """
  Apply damage to player hit points and check for death
  """
  def apply_damage(socket, damage) do
    # Play monster_hit sound when trap causes damage
    socket =
      if damage > 0 do
        Phoenix.LiveView.push_event(socket, "play_audio", %{sound: "monster_hit"})
      else
        socket
      end

    current_hp = socket.assigns.player_hit_points
    new_hp = max(0, current_hp - damage)

    socket = socket |> assign(:player_hit_points, new_hp)

    # Check if player has died
    if new_hp <= 0 do
      # Schedule delayed death dialog after 1 second (like combat death)
      Process.send_after(self(), :show_death_dialog, 1000)

      socket
      |> assign(:player_dead, true)
    else
      socket
    end
  end

  @doc """
  Get trap icon and message for different trap types with damage
  """
  def get_trap_message(tile) do
    damage = calculate_trap_damage(tile)

    case tile do
      :room_trap ->
        {DungeonWeb.UISizing.img_tag("/images/trap.png", "Trap", :medium_icon),
         "#{DungeonWeb.UISizing.inline_img_tag("/images/hourglass.png", "Loading", :loading_icon)} Generating description...",
         damage}

      :trapped_treasure ->
        {DungeonWeb.UISizing.img_tag("/images/chest.png", "Treasure", :medium_icon),
         "#{DungeonWeb.UISizing.inline_img_tag("/images/hourglass.png", "Loading", :loading_icon)} Generating description...",
         damage}

      :trapped_door ->
        {DungeonWeb.UISizing.img_tag("/images/door.png", "Door", :medium_icon),
         "#{DungeonWeb.UISizing.inline_img_tag("/images/hourglass.png", "Loading", :loading_icon)} Generating description...",
         damage}

      :locked_trapped_door ->
        {DungeonWeb.UISizing.img_tag("/images/door.png", "Door", :medium_icon),
         "#{DungeonWeb.UISizing.inline_img_tag("/images/hourglass.png", "Loading", :loading_icon)} Generating description...",
         damage}

      _ ->
        {DungeonWeb.UISizing.img_tag("/images/trap.png", "Trap", :medium_icon),
         "You triggered a trap!", damage}
    end
  end

  @doc """
  Get or generate door trap description using LLM
  """
  def get_or_generate_door_trap_description(socket, position, tile) do
    if tile in [:trapped_door, :locked_trapped_door] do
      context = %{
        position: position,
        theme: socket.assigns.dungeon.theme,
        room_description:
          Map.get(socket.assigns.room_descriptions, "R1", "No description available.")
      }

      alias Dungeon.Services.DescriptionService
      DescriptionService.get_or_generate(:door_trap, socket, context)
    else
      # Not a door trap, return default message
      {_icon, message, _damage} = get_trap_message(tile)
      message
    end
  end

  @doc """
  Get or generate room trap description using LLM
  """
  def get_or_generate_room_trap_description(socket, position, tile) do
    if tile == :room_trap do
      context = %{
        position: position,
        theme: socket.assigns.dungeon.theme,
        room_description:
          Map.get(socket.assigns.room_descriptions, "R1", "No description available.")
      }

      alias Dungeon.Services.DescriptionService
      DescriptionService.get_or_generate(:room_trap, socket, context)
    else
      # Not a room trap, return default message
      {_icon, message, _damage} = get_trap_message(tile)
      message
    end
  end

  @doc """
  Get or generate treasure trap description using LLM
  """
  def get_or_generate_treasure_trap_description(socket, position, tile) do
    if tile == :trapped_treasure do
      # Use current room description for context
      room_description =
        socket.assigns.current_room_description ||
          socket.assigns.previous_room_description ||
          "a mysterious chamber in the #{socket.assigns.dungeon.theme}"

      context = %{
        position: position,
        theme: socket.assigns.dungeon.theme,
        room_description: room_description
      }

      alias Dungeon.Services.DescriptionService
      DescriptionService.get_or_generate(:treasure_trap, socket, context)
    else
      # Not a treasure trap, return default message
      {_icon, message, _damage} = get_trap_message(tile)
      message
    end
  end

  @doc """
  Process trap triggered from clicking on a square
  """
  def process_click_trap(socket, x, y) do
    dungeon = socket.assigns.dungeon
    tile = Map.get(dungeon.grid, {x, y})
    clicked_trap = tile in [:trapped_treasure, :trapped_door, :locked_trapped_door]

    if clicked_trap do
      position = {x, y}

      # Calculate damage for this trap
      damage = calculate_trap_damage(tile)

      # Generate appropriate description based on trap type
      message =
        case tile do
          :trapped_treasure ->
            get_or_generate_treasure_trap_description(socket, position, tile)

          :trapped_door ->
            get_or_generate_door_trap_description(socket, position, tile)

          :locked_trapped_door ->
            get_or_generate_door_trap_description(socket, position, tile)

          _ ->
            {_icon, msg, _damage} = get_trap_message(tile)
            msg
        end

      {icon, _, _} = get_trap_message(tile)
      {true, icon, message, damage}
    else
      {false, "", "", 0}
    end
  end

  @doc """
  Dismiss trap dialog, apply damage, and remove the triggered trap from the dungeon
  """
  def dismiss_trap(socket) do
    socket
    |> apply_trap_damage()
    |> handle_trap_removal_and_treasure()
    |> clear_trap_dialog()
  end

  defp apply_trap_damage(socket) do
    if socket.assigns.triggered_trap_position do
      {x, y} = socket.assigns.triggered_trap_position
      dungeon = socket.assigns.dungeon
      tile = Map.get(dungeon.grid, {x, y})

      damage = calculate_trap_damage_for_tile(socket, tile)
      apply_damage(socket, damage)
    else
      socket
    end
  end

  defp calculate_trap_damage_for_tile(socket, tile) do
    case tile do
      {:special_feature, _, _} ->
        # For feature traps, use stored trap damage or default to 1d6 room trap damage
        socket.assigns[:trap_damage] || Dice.roll_dice_string("1d6")

      _ ->
        # For regular traps, calculate damage based on tile type
        calculate_trap_damage(tile)
    end
  end

  defp handle_trap_removal_and_treasure(socket) do
    if socket.assigns.triggered_trap_position do
      {socket, show_treasure} = remove_trap_and_check_treasure(socket)
      maybe_show_treasure_dialog(socket, show_treasure)
    else
      socket
    end
  end

  defp remove_trap_and_check_treasure(socket) do
    {x, y} = socket.assigns.triggered_trap_position
    dungeon = socket.assigns.dungeon
    tile = Map.get(dungeon.grid, {x, y})

    # Only remove trap if it's actually a trap tile (not a special feature)
    socket =
      case tile do
        {:special_feature, _, _} ->
          # Don't remove special features from the grid
          socket

        _ ->
          # Remove actual trap tiles
          remove_triggered_trap(socket, socket.assigns.triggered_trap_position)
      end

    # Check if it was a trapped treasure - if so, show treasure dialog next
    show_treasure = tile == :trapped_treasure

    {socket, show_treasure}
  end

  defp maybe_show_treasure_dialog(socket, show_treasure) do
    if show_treasure and socket.assigns.player_hit_points > 0 do
      {x, y} = socket.assigns.triggered_trap_position

      {treasure_icon, treasure_message, gold_amount} =
        TreasureSystem.get_treasure_message(socket, {x, y})

      socket
      |> assign(:show_treasure_dialog, true)
      |> assign(:treasure_icon, treasure_icon)
      |> assign(:treasure_message, treasure_message)
      |> assign(:collected_treasure_position, {x, y})
      |> assign(:collected_treasure_gold, gold_amount)
    else
      socket
    end
  end

  defp clear_trap_dialog(socket) do
    socket
    |> assign(:show_trap_dialog, false)
    |> assign(:trap_icon, "")
    |> assign(:trap_message, "")
    |> assign(:triggered_trap_position, nil)
    |> assign(:trap_damage, 0)
  end

  @doc """
  Remove a triggered trap from the dungeon grid
  """
  def remove_triggered_trap(socket, {x, y}) do
    dungeon = socket.assigns.dungeon
    tile = Map.get(dungeon.grid, {x, y})

    new_tile =
      case tile do
        :room_trap -> :floor
        # Remove trap, keep treasure
        :trapped_treasure -> :treasure
        # Remove trap, keep door
        :trapped_door -> :door
        # Remove trap, keep locked door
        :locked_trapped_door -> :locked_door
        # No change for other tiles
        _ -> tile
      end

    new_grid = Map.put(dungeon.grid, {x, y}, new_tile)
    new_dungeon = %{dungeon | grid: new_grid}

    assign(socket, :dungeon, new_dungeon)
  end

  # Private helper
  defp assign(socket, key, value) do
    Phoenix.Component.assign(socket, key, value)
  end
end
