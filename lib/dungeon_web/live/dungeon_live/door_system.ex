defmodule DungeonWeb.DungeonLive.DoorSystem do
  @moduledoc """
  Handles door interactions including clicking, unlocking, breaking, and opening doors.
  """

  import Phoenix.Component, only: [assign: 3]
  alias Dungeon.{Dice, Services.DescriptionService}
  alias DungeonWeb.DungeonLive.{FogOfWar, Movement, WanderingMonsterSystem}
  alias Phoenix.LiveView
  require Logger

  @doc """
  Handles door clicks - determines if player can interact and what type of interaction.
  """
  def handle_door_click(socket, x_str, y_str) do
    x = String.to_integer(x_str)
    y = String.to_integer(y_str)
    position = {x, y}

    case can_interact_with_door?(socket, position) do
      true -> process_door_click(socket, position)
      false -> {:noreply, socket}
    end
  end

  @doc """
  Handles picking locks on doors.
  """
  def pick_lock(socket) do
    case socket.assigns.selected_door do
      {x, y} ->
        # Play click sound when attempting to pick lock
        socket = LiveView.push_event(socket, "play_audio", %{sound: "click"})

        # Roll d20 + dexterity_bonus vs DC 12
        d20_roll = Dice.roll(1, 20)
        dex_bonus = socket.assigns.dexterity_bonus
        lock_pick_roll = d20_roll + dex_bonus

        if lock_pick_roll >= 12 do
          # Success! Unlock the door
          new_unlocked_doors = MapSet.put(socket.assigns.unlocked_doors, {x, y})

          socket =
            socket
            |> assign(:unlocked_doors, new_unlocked_doors)
            |> assign(:show_unlock_dialog, false)
            |> assign(:selected_door, nil)
            |> assign(:door_description, nil)
            |> assign(:show_lock_pick_result_dialog, true)
            |> assign(:lock_pick_success, true)
            |> assign(:lock_pick_roll, lock_pick_roll)
            |> assign(:lock_pick_d20_roll, d20_roll)
            |> assign(:lock_pick_dex_bonus, dex_bonus)
            |> award_xp(5, "lock picked")

          {:noreply, socket}
        else
          # Failure! Lock remains locked and becomes unpickable
          new_unpickable_doors = MapSet.put(socket.assigns.unpickable_doors, {x, y})

          socket =
            socket
            |> assign(:unpickable_doors, new_unpickable_doors)
            |> assign(:show_unlock_dialog, false)
            |> assign(:selected_door, nil)
            |> assign(:door_description, nil)
            |> assign(:show_lock_pick_result_dialog, true)
            |> assign(:lock_pick_success, false)
            |> assign(:lock_pick_roll, lock_pick_roll)
            |> assign(:lock_pick_d20_roll, d20_roll)
            |> assign(:lock_pick_dex_bonus, dex_bonus)

          {:noreply, socket}
        end

      nil ->
        {:noreply, socket}
    end
  end

  @doc """
  Handles canceling unlock dialog.
  """
  def cancel_unlock(socket) do
    socket =
      socket
      |> assign(:show_unlock_dialog, false)
      |> assign(:selected_door, nil)
      |> assign(:door_description, nil)
      |> assign(:show_open_door_dialog, false)
      |> assign(:selected_open_door, nil)
      |> assign(:open_door_description, nil)

    {:noreply, socket}
  end

  @doc """
  Handles dismissing lock pick result dialog.
  """
  def dismiss_lock_pick_result(socket) do
    socket =
      socket
      |> assign(:show_lock_pick_result_dialog, false)
      |> assign(:lock_pick_success, false)
      |> assign(:lock_pick_roll, 0)
      |> assign(:lock_pick_d20_roll, 0)
      |> assign(:lock_pick_dex_bonus, 0)

    {:noreply, socket}
  end

  @doc """
  Handles breaking doors.
  """
  def break_door(socket) do
    case socket.assigns.selected_door do
      {x, y} -> process_break_door_attempt(socket, {x, y})
      nil -> {:noreply, socket}
    end
  end

  @doc """
  Handles dismissing break door result dialog.
  """
  def dismiss_break_door_result(socket) do
    socket =
      socket
      |> assign(:show_break_door_result_dialog, false)
      |> assign(:break_door_success, false)
      |> assign(:break_door_roll, 0)

    # Do wandering monster check on dismissal (1 in 6 chance)
    wandering_monster_check = WanderingMonsterSystem.check_wandering_monster()

    if wandering_monster_check do
      case WanderingMonsterSystem.spawn_wandering_monster(socket) do
        {:wandering_monster, updated_socket} -> {:noreply, updated_socket}
        {:no_monster, updated_socket} -> {:noreply, updated_socket}
      end
    else
      {:noreply, socket}
    end
  end

  @doc """
  Handles entering through doors.
  """
  def enter_door(socket) do
    case socket.assigns.selected_open_door do
      {x, y} ->
        # Play door opening sound
        socket = LiveView.push_event(socket, "play_audio", %{sound: "door_open"})

        # Close the dialog first
        socket =
          socket
          |> assign(:show_open_door_dialog, false)
          |> assign(:selected_open_door, nil)
          |> assign(:open_door_description, nil)

        # Move player through the door using confirmed movement
        Movement.move_player_to_position_confirmed(socket, {x, y})

      nil ->
        {:noreply, socket}
    end
  end

  @doc """
  Handles canceling open door dialog.
  """
  def cancel_open_door(socket) do
    socket =
      socket
      |> assign(:show_open_door_dialog, false)
      |> assign(:selected_open_door, nil)
      |> assign(:open_door_description, nil)

    {:noreply, socket}
  end

  @doc """
  Handles dismissing secret door dialog.
  """
  def dismiss_secret_door(socket) do
    socket =
      socket
      |> assign(:show_secret_door_dialog, false)
      |> assign(:selected_secret_door, nil)

    {:noreply, socket}
  end

  @doc """
  Shows open door dialog for movement when player tries to move into a door.
  """
  def show_open_door_dialog_for_movement(socket, position, tile) do
    door_description = get_or_generate_door_description(socket, position, tile)

    socket =
      socket
      |> assign(:show_open_door_dialog, true)
      |> assign(:selected_open_door, position)
      |> assign(:open_door_description, door_description)

    {:noreply, socket}
  end

  @doc """
  Shows unlock dialog for movement when player tries to move into a locked door.
  """
  def show_unlock_dialog_for_movement(socket, position, tile) do
    door_description = get_or_generate_door_description(socket, position, tile)

    socket =
      socket
      |> assign(:show_unlock_dialog, true)
      |> assign(:selected_door, position)
      |> assign(:door_description, door_description)

    {:noreply, socket}
  end

  @doc """
  Shows secret door dialog when a secret door is discovered.
  """
  def show_secret_door_dialog(socket, position) do
    socket =
      socket
      |> assign(:show_secret_door_dialog, true)
      |> assign(:selected_secret_door, position)

    {:noreply, socket}
  end

  # Private helper functions

  defp can_interact_with_door?(socket, {x, y}) do
    FogOfWar.square_revealed?(
      x,
      y,
      socket.assigns.revealed_squares,
      socket.assigns.fog_enabled
    ) and Movement.adjacent_to_player?({x, y}, socket.assigns.player_position)
  end

  defp process_door_click(socket, {_x, _y} = position) do
    dungeon = socket.assigns.dungeon
    tile = Map.get(dungeon.grid, position)

    cond do
      # Check for trapped doors - these MUST be dealt with before door can be used
      tile in [:trapped_door, :locked_trapped_door] ->
        attempt_trap_detection(socket, position, :door_trap, {:open_door, position})

      locked_door?(tile, socket, position) ->
        show_unlock_dialog(socket, position, tile)

      open_door?(tile, socket, position) ->
        show_open_door_dialog(socket, position, tile)

      true ->
        {:noreply, socket}
    end
  end

  defp locked_door?(tile, socket, position) do
    tile in [:locked_door, :locked_trapped_door] and
      not MapSet.member?(socket.assigns.unlocked_doors, position)
  end

  defp open_door?(tile, socket, position) do
    tile in [:door, :trapped_door] or
      (tile in [:locked_door, :locked_trapped_door] and
         MapSet.member?(socket.assigns.unlocked_doors, position))
  end

  defp show_unlock_dialog(socket, position, tile) do
    door_description = get_or_generate_door_description(socket, position, tile)

    socket =
      socket
      |> assign(:show_unlock_dialog, true)
      |> assign(:selected_door, position)
      |> assign(:door_description, door_description)

    {:noreply, socket}
  end

  defp show_open_door_dialog(socket, position, tile) do
    door_description = get_or_generate_door_description(socket, position, tile)

    socket =
      socket
      |> assign(:show_open_door_dialog, true)
      |> assign(:selected_open_door, position)
      |> assign(:open_door_description, door_description)

    {:noreply, socket}
  end

  defp get_or_generate_door_description(socket, {_x, _y} = position, tile) do
    # Check if this door has failed lock picking attempts
    is_unpickable = MapSet.member?(socket.assigns.unpickable_doors, position)

    # Use current room description for context
    room_description =
      socket.assigns.current_room_description ||
        "a mysterious chamber in the #{socket.assigns.dungeon.theme}"

    context = %{
      position: position,
      theme: socket.assigns.dungeon.theme,
      level: socket.assigns.dungeon_level,
      room_description: room_description,
      door_status:
        cond do
          is_unpickable -> "unpickable (lock mechanism is broken from failed picking attempts)"
          tile in [:locked_door, :locked_trapped_door] -> "locked"
          true -> "unlocked"
        end
    }

    DescriptionService.get_or_generate(:door, socket, context)
  end

  defp attempt_trap_detection(socket, position, trap_type, success_action) do
    send(self(), {:attempt_trap_detection, position, trap_type, success_action})
    {:noreply, socket}
  end

  defp process_break_door_attempt(socket, {x, y}) do
    # Play banging sound when attempting to break door
    socket = LiveView.push_event(socket, "play_audio", %{sound: "banging"})

    # Roll d20 vs DC 13
    break_roll = Dice.roll(1, 20)
    break_success = break_roll >= 13

    socket =
      if break_success do
        handle_successful_door_break(socket, {x, y}, break_roll)
      else
        handle_failed_door_break(socket, break_roll)
      end

    {:noreply, socket}
  end

  defp handle_successful_door_break(socket, {x, y}, break_roll) do
    # Success! Unlock the door (remove from unpickable doors and add to unlocked doors)
    new_unpickable_doors = MapSet.delete(socket.assigns.unpickable_doors, {x, y})
    new_unlocked_doors = MapSet.put(socket.assigns.unlocked_doors, {x, y})

    # Track door breaking for guard system
    new_doors_broken_count = socket.assigns.doors_broken_count + 1

    # Check if we should make guards hostile (first door break triggers it)
    socket =
      if new_doors_broken_count == 1 and not socket.assigns.guards_hostile do
        trigger_guard_hostility(socket, "door breaking")
      else
        socket
      end

    socket
    |> assign(:unpickable_doors, new_unpickable_doors)
    |> assign(:unlocked_doors, new_unlocked_doors)
    |> assign(:doors_broken_count, new_doors_broken_count)
    |> assign(:show_unlock_dialog, false)
    |> assign(:selected_door, nil)
    |> assign(:door_description, nil)
    |> assign(:show_break_door_result_dialog, true)
    |> assign(:break_door_success, true)
    |> assign(:break_door_roll, break_roll)
    |> award_xp(10, "door broken")
  end

  defp handle_failed_door_break(socket, break_roll) do
    # Failure! Door remains locked
    socket
    |> assign(:show_unlock_dialog, false)
    |> assign(:selected_door, nil)
    |> assign(:door_description, nil)
    |> assign(:show_break_door_result_dialog, true)
    |> assign(:break_door_success, false)
    |> assign(:break_door_roll, break_roll)
  end

  defp trigger_guard_hostility(socket, reason) do
    # Make all guards on the current map hostile
    socket = assign(socket, :guards_hostile, true)

    # Log the event for debugging
    Logger.info("Guards have become hostile due to: #{reason}")

    socket
  end

  defp award_xp(socket, amount, _reason) do
    current_xp = socket.assigns.player_xp
    new_xp = current_xp + amount
    socket = assign(socket, :player_xp, new_xp)

    # Check for level up using the PlayerStats module
    if Dungeon.PlayerStats.leveled_up?(current_xp, new_xp) do
      do_level_up(socket, new_xp)
    else
      socket
    end
  end

  # Level up function - simplified version that just awards XP
  # The main module will handle the full level up logic
  defp do_level_up(socket, _new_xp) do
    # For now, just return the socket - the main module will handle level up checks
    socket
  end
end
