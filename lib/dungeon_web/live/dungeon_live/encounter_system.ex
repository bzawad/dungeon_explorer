defmodule DungeonWeb.DungeonLive.EncounterSystem do
  @moduledoc """
  Encounter detection and dialog system
  """

  @doc """
  Check if a tile is an encounter
  """
  def encounter_tile?(tile) do
    match?({:encounter, _, _}, tile)
  end

  @doc """
  Process encounter when player steps on it
  """
  def process_encounter(socket, {x, y}) do
    dungeon = socket.assigns.dungeon
    tile = Map.get(dungeon.grid, {x, y})

    case tile do
      {:encounter, encounter_label, monster} ->
        process_encounter_tile(socket, {x, y}, encounter_label, monster)

      _ ->
        {false, "", "", nil}
    end
  end

  defp process_encounter_tile(socket, position, encounter_label, monster) do
    # Check if this encounter was already triggered
    if MapSet.member?(socket.assigns.triggered_encounters, position) do
      # Already triggered, no dialog
      {false, "", "", nil}
    else
      generate_encounter_dialog(encounter_label, monster)
    end
  end

  defp generate_encounter_dialog(encounter_label, monster) do
    # Check if this is an NPC
    if monster.role == "npc" do
      generate_npc_dialog(monster)
    else
      generate_monster_dialog(encounter_label, monster)
    end
  end

  @doc """
  Process encounter with guard system awareness
  """
  def process_encounter_with_guards(socket, {x, y}) do
    dungeon = socket.assigns.dungeon
    tile = Map.get(dungeon.grid, {x, y})

    case tile do
      {:encounter, encounter_label, monster} ->
        process_encounter_tile_with_guards(socket, {x, y}, encounter_label, monster)

      _ ->
        {false, "", "", nil}
    end
  end

  defp process_encounter_tile_with_guards(socket, position, encounter_label, monster) do
    # Check if this encounter was already triggered
    if MapSet.member?(socket.assigns.triggered_encounters, position) do
      # Already triggered, no dialog
      {false, "", "", nil}
    else
      generate_encounter_dialog_with_guards(socket, encounter_label, monster)
    end
  end

  defp generate_encounter_dialog_with_guards(socket, encounter_label, monster) do
    cond do
      # Check if this is a guard and whether guards are hostile
      monster.role == "guard" ->
        if socket.assigns.guards_hostile do
          # Guards are hostile - treat as regular monster
          generate_monster_dialog(encounter_label, monster)
        else
          # Guards are not hostile - treat as NPC
          generate_npc_dialog(monster)
        end

      # Check if this is an NPC
      monster.role == "npc" ->
        generate_npc_dialog(monster)

      # Regular monster
      true ->
        generate_monster_dialog(encounter_label, monster)
    end
  end

  defp generate_npc_dialog(monster) do
    # NPC dialog with chat icon
    npc_icon =
      DungeonWeb.UISizing.img_tag(
        "/images/chat.png",
        "Chat",
        :medium_icon
      )

    {true, npc_icon, "Can I help you?", monster}
  end

  defp generate_monster_dialog(encounter_label, monster) do
    # Regular encounter dialog
    encounter_message = generate_encounter_message(encounter_label, monster.name)

    monster_icon =
      DungeonWeb.UISizing.img_tag(
        "/images/monsters/#{monster.image}",
        monster.name,
        :medium_icon
      )

    {true, monster_icon, encounter_message, monster}
  end

  @doc """
  Process encounter click - always show dialog regardless of discovery status
  """
  def process_encounter_click(socket, {x, y}) do
    require Logger
    Logger.info("=== ENCOUNTER SYSTEM CLICK DEBUG ===")
    Logger.info("EncounterSystem.process_encounter_click called with position: {#{x}, #{y}}")

    dungeon = socket.assigns.dungeon
    tile = Map.get(dungeon.grid, {x, y})
    Logger.info("Tile at position: #{inspect(tile)}")

    case tile do
      {:encounter, encounter_label, monster} ->
        Logger.info("Found encounter - label: #{encounter_label}, monster: #{inspect(monster)}")
        Logger.info("Monster role: #{monster.role}")
        Logger.info("Guards hostile: #{socket.assigns.guards_hostile}")

        # Determine dialog type based on monster role, guard hostility state, and alignment compatibility
        player_alignment_desc =
          Dungeon.PlayerStats.get_alignment_description(socket.assigns.player_alignment)

        npc_hostile_to_player =
          (monster.alignment == :lawful and player_alignment_desc == :chaotic) or
            (monster.alignment == :chaotic and player_alignment_desc == :lawful)

        should_show_npc_dialog =
          cond do
            monster.role == "npc" and not npc_hostile_to_player ->
              true

            monster.role == "guard" && not socket.assigns.guards_hostile &&
                not npc_hostile_to_player ->
              true

            true ->
              false
          end

        Logger.info("Should show NPC dialog: #{should_show_npc_dialog}")

        if should_show_npc_dialog do
          Logger.info("Creating NPC dialog")
          # NPC dialog with chat icon
          npc_icon =
            DungeonWeb.UISizing.img_tag(
              "/images/chat.png",
              "Chat",
              :medium_icon
            )

          result = {true, npc_icon, "Can I help you?", monster}
          Logger.info("Returning NPC dialog result: #{inspect(result)}")
          result
        else
          Logger.info("Creating regular encounter dialog")
          # Regular encounter dialog
          encounter_message = generate_encounter_message(encounter_label, monster.name)

          monster_icon =
            DungeonWeb.UISizing.img_tag(
              "/images/monsters/#{monster.image}",
              monster.name,
              :medium_icon
            )

          result = {true, monster_icon, encounter_message, monster}
          Logger.info("Returning regular encounter result: #{inspect(result)}")
          result
        end

      _ ->
        Logger.info("No encounter found at position")
        {false, "", "", nil}
    end
  end

  @doc """
  Get encounter dismissal state changes
  """
  def get_dismiss_encounter_assigns do
    [
      show_encounter_dialog: false,
      encounter_icon: "",
      encounter_message: ""
    ]
  end

  # Private functions

  defp generate_encounter_message(encounter_label, monster_name) do
    "You have an encounter with a #{monster_name}! (#{encounter_label})"
  end
end
