defmodule DungeonWeb.DungeonLive.WanderingMonsterSystem do
  @moduledoc """
  Wandering monster system for noise-triggered encounters
  """

  alias Dungeon.{Dice, Monster}
  alias DungeonWeb.DungeonLive.CombatSystem

  @doc """
  Check for wandering monster (1 in 6 chance)
  """
  def check_wandering_monster do
    Dice.roll(1, 6) == 1
  end

  @doc """
  Spawn a wandering monster encounter
  """
  def spawn_wandering_monster(socket) do
    # Get theme monsters or use default
    dungeon = socket.assigns.dungeon

    # Check if this is a city and doors have been broken
    monster =
      if dungeon.generation_type == "city" and socket.assigns.doors_broken_count > 0 do
        # In cities with broken doors, preferentially spawn guards
        guard_monster = Monster.get_monster_by_name("Guard")
        if guard_monster, do: %{guard_monster | role: nil}, else: get_theme_monster(socket)
      else
        get_theme_monster(socket)
      end

    if monster do
      monster_icon =
        DungeonWeb.UISizing.img_tag(
          "/images/monsters/#{monster.image}",
          monster.name,
          :medium_icon
        )

      encounter_message = "The noise attracts a wandering #{monster.name}!"

      socket =
        socket
        |> Phoenix.Component.assign(:show_wandering_monster_dialog, true)
        |> Phoenix.Component.assign(:wandering_monster, monster)
        |> Phoenix.Component.assign(:wandering_monster_icon, monster_icon)
        |> Phoenix.Component.assign(:wandering_monster_message, encounter_message)

      {:wandering_monster, socket}
    else
      {:no_monster, socket}
    end
  end

  # Helper function to get theme-appropriate monster
  defp get_theme_monster(socket) do
    dungeon = socket.assigns.dungeon
    player_level = socket.assigns[:player_level] || 1
    map_level = socket.assigns[:dungeon_level] || 1

    case dungeon.theme_data do
      theme when is_map(theme) ->
        Monster.get_random_monster_for_theme_with_fog_type(theme, map_level, player_level)

      _ ->
        # Fallback when theme_data is missing or not a map
        Monster.get_random_monster_for_theme(nil, player_level)
    end
  end

  @doc """
  Start combat with wandering monster (normal initiative, not surprise)
  """
  def start_wandering_monster_combat(socket) do
    monster = socket.assigns.wandering_monster

    if monster do
      # Close wandering monster dialog and start combat
      socket =
        socket
        |> Phoenix.Component.assign(:show_wandering_monster_dialog, false)
        |> Phoenix.Component.assign(:wandering_monster, nil)
        |> Phoenix.Component.assign(:wandering_monster_icon, "")
        |> Phoenix.Component.assign(:wandering_monster_message, "")

      # Start combat with normal initiative (not surprise)
      socket = CombatSystem.start_combat(socket, monster.name)
      {:noreply, socket}
    else
      {:noreply, socket}
    end
  end

  @doc """
  Handle successful evasion of wandering monster
  """
  def evade_wandering_monster(socket) do
    # Roll d20 + dexterity bonus for evade attempt (DC 12)
    evade_roll = Dice.roll(1, 20)
    dex_bonus = socket.assigns.dexterity_bonus
    total_roll = evade_roll + dex_bonus
    evade_success = total_roll >= 12

    # Generate evade message based on success/failure
    evade_message =
      if evade_success do
        "Success! You quietly slip away before the wandering monster notices you.\n\n(Rolled #{evade_roll} + #{dex_bonus} dexterity = #{total_roll} vs DC 12)"
      else
        "Failed! The wandering monster spots you and attacks!\n\n(Rolled #{evade_roll} + #{dex_bonus} dexterity = #{total_roll} vs DC 12)"
      end

    # Close wandering monster dialog and show evade result
    socket =
      socket
      |> Phoenix.Component.assign(:show_wandering_monster_dialog, false)
      |> Phoenix.Component.assign(:show_wandering_evade_dialog, true)
      |> Phoenix.Component.assign(:wandering_evade_success, evade_success)
      |> Phoenix.Component.assign(:wandering_evade_roll, total_roll)
      |> Phoenix.Component.assign(:wandering_evade_message, evade_message)

    {:noreply, socket}
  end

  @doc """
  Handle dismissal of wandering monster evade dialog
  """
  def dismiss_wandering_evade(socket) do
    if socket.assigns.wandering_evade_success do
      # Successful evade - monster disappears, award XP
      socket = award_xp(socket, 5, "wandering monster evaded")

      socket =
        socket
        |> Phoenix.Component.assign(:show_wandering_evade_dialog, false)
        |> Phoenix.Component.assign(:wandering_monster, nil)
        |> Phoenix.Component.assign(:wandering_monster_icon, "")
        |> Phoenix.Component.assign(:wandering_monster_message, "")
        |> Phoenix.Component.assign(:wandering_evade_success, false)
        |> Phoenix.Component.assign(:wandering_evade_roll, 0)
        |> Phoenix.Component.assign(:wandering_evade_message, "")

      {:noreply, socket}
    else
      # Failed evade - start combat
      monster = socket.assigns.wandering_monster

      socket =
        socket
        |> Phoenix.Component.assign(:show_wandering_evade_dialog, false)
        |> Phoenix.Component.assign(:wandering_evade_success, false)
        |> Phoenix.Component.assign(:wandering_evade_roll, 0)
        |> Phoenix.Component.assign(:wandering_evade_message, "")

      if monster do
        # Play fight sound and start combat
        socket = Phoenix.LiveView.push_event(socket, "play_audio", %{sound: "fight"})
        socket = CombatSystem.start_combat(socket, monster.name)
        {:noreply, socket}
      else
        {:noreply, socket}
      end
    end
  end

  # Helper function to award XP and check for level ups (private)
  defp award_xp(socket, amount, _reason) do
    current_xp = socket.assigns.player_xp
    new_xp = current_xp + amount

    socket = Phoenix.Component.assign(socket, :player_xp, new_xp)

    # Check for level up and update stats if needed
    if Dungeon.PlayerStats.leveled_up?(current_xp, new_xp) do
      apply_level_up(socket, current_xp, new_xp)
    else
      socket
    end
  end

  # Apply level up changes (send message to main live view)
  defp apply_level_up(socket, old_xp, new_xp) do
    # Send level up message to the main live view process for handling
    send(self(), {:level_up_occurred, old_xp, new_xp})
    socket
  end
end
