defmodule DungeonWeb.DungeonLive.NpcQuestSystem do
  @moduledoc """
  Handles NPC quest system functionality including quest offers, acceptance, and management.
  Returns data for the main LiveView to handle socket updates.
  """

  require Logger
  alias Dungeon.Services.DescriptionService

  # Public API functions that return data instead of updating socket assigns

  def get_quest_data_for_npc(socket) do
    Logger.info("=== NPC QUEST DATA DEBUG ===")
    Logger.info("get_quest_data_for_npc called")

    # Get the NPC from the current encounter
    encounter_position = socket.assigns.current_encounter_position
    Logger.info("Current encounter position: #{inspect(encounter_position)}")

    if encounter_position do
      dungeon = socket.assigns.dungeon
      tile = Map.get(dungeon.grid, encounter_position)
      Logger.info("Tile at encounter position: #{inspect(tile)}")

      case tile do
        {:encounter, _encounter_label, monster} ->
          Logger.info("Found encounter with monster: #{inspect(monster)}")
          Logger.info("Monster alignment: #{inspect(monster.alignment)}")

          # Check if this NPC can offer a quest
          if monster.alignment in [:lawful, :chaotic, :neutral] do
            Logger.info("Monster can offer quest, getting quest data")
            get_quest_data_for_monster(socket, monster)
          else
            Logger.info("Monster cannot offer quest")
            :close_dialog
          end

        _ ->
          Logger.info("No valid encounter found")
          :close_dialog
      end
    else
      Logger.info("No encounter position")
      :close_dialog
    end
  end

  def get_quest_acceptance_data(socket) do
    offered_quest = socket.assigns.offered_quest

    if offered_quest do
      # Return data for quest acceptance
      {:accept_quest,
       %{
         quest: offered_quest,
         updated_npc_quests: [offered_quest | socket.assigns.npc_quests],
         quest_rumor:
           "Quest from #{offered_quest.quest_giver}: #{offered_quest.tldr_description}",
         updated_rumors: [
           "Quest from #{offered_quest.quest_giver}: #{offered_quest.tldr_description}"
           | socket.assigns.rumors
         ]
       }}
    else
      {:no_quest, nil}
    end
  end

  def get_fight_npc_data(socket) do
    encounter_position = socket.assigns.current_encounter_position

    if encounter_position do
      dungeon = socket.assigns.dungeon
      tile = Map.get(dungeon.grid, encounter_position)

      case tile do
        {:encounter, _encounter_label, monster} ->
          {:fight_npc, %{monster: monster}}

        _ ->
          {:no_encounter, nil}
      end
    else
      {:no_encounter, nil}
    end
  end

  # Quest completion handling
  def handle_quest_completed(socket, quest, xp_reward, completion_narrative) do
    # Find and update the quest in the list
    updated_quests =
      Enum.map(socket.assigns.quests, fn q ->
        if q.id == quest.id do
          %{quest | completed: true, completion_narrative: completion_narrative}
        else
          q
        end
      end)

    # Return data for main LiveView to handle
    {:quest_completed,
     %{
       updated_quests: updated_quests,
       completed_quest: quest,
       xp_reward: xp_reward,
       completion_narrative: completion_narrative
     }}
  end

  def handle_quest_description_generated(socket, description, response_data) do
    %{quest_id: quest_id} = response_data

    # Find and update the quest with the generated narrative
    updated_quests =
      Enum.map(socket.assigns.quests, fn quest ->
        if quest.id == quest_id do
          %{quest | narrative_description: description}
        else
          quest
        end
      end)

    quest_tldr = get_quest_tldr(updated_quests, quest_id)

    {:quest_description_generated,
     %{
       updated_quests: updated_quests,
       rumor_message: "Quest Received: #{quest_tldr}\n\n#{description}"
     }}
  end

  def handle_generate_quest_narrative(socket, quest, position) do
    context = %{
      position: position,
      theme: socket.assigns.dungeon.theme,
      level: socket.assigns.dungeon_level,
      magic_item: quest.magic_item,
      target_theme: quest.target_theme,
      quest_id: quest.id
    }

    DescriptionService.generate_async(:quest, context, self(), %{
      type: :quest,
      quest_id: quest.id,
      context: context
    })

    {:noreply, socket}
  end

  # Helper functions that don't update socket assigns

  def spawn_quest_monsters_for_theme(socket, theme) do
    Logger.info("=== QUEST MONSTER THEME SPAWNING DEBUG ===")
    Logger.info("Attempting to spawn quest monsters for theme: #{theme}")
    Logger.info("Total NPC quests: #{length(socket.assigns.npc_quests)}")

    # Get active NPC quests that match the current theme
    active_quests =
      socket.assigns.npc_quests
      |> Enum.filter(fn quest ->
        quest.status == :active and quest.target_theme == theme
      end)

    Logger.info("Active quests for theme #{theme}: #{length(active_quests)}")

    Enum.each(active_quests, fn quest ->
      Logger.info("  - Quest #{quest.id}: #{quest.target_monster} (status: #{quest.status})")
    end)

    # Spawn quest monsters for each matching quest
    result_socket =
      Enum.reduce(active_quests, socket, fn quest, acc_socket ->
        Logger.info("Spawning quest monster for quest: #{quest.id}")
        Dungeon.Quest.spawn_quest_target(acc_socket, quest)
      end)

    Logger.info("Quest monster spawning completed for theme: #{theme}")
    result_socket
  end

  def get_monster_object_from_encounter_position(encounter_position, socket) do
    with {x, y} <- encounter_position,
         tile when tile != nil <- Map.get(socket.assigns.dungeon.grid, {x, y}) do
      case tile do
        {:encounter, _encounter_label, monster} ->
          monster

        {:monster, monster_name} ->
          # For old-style monster tiles, create a basic monster instance
          Dungeon.Monster.create_monster_instance(monster_name)

        _ ->
          # Fallback to a basic goblin
          Dungeon.Monster.create_monster_instance("Goblin Scout")
      end
    else
      _ -> Dungeon.Monster.create_monster_instance("Goblin Scout")
    end
  end

  def npc_dialog_encounter?(monster, guards_hostile, player_alignment) do
    player_alignment_desc = Dungeon.PlayerStats.get_alignment_description(player_alignment)

    npc_hostile_to_player =
      monster &&
        ((monster.alignment == :lawful and player_alignment_desc == :chaotic) or
           (monster.alignment == :chaotic and player_alignment_desc == :lawful))

    cond do
      monster && monster.role == "npc" && not npc_hostile_to_player ->
        true

      monster && monster.role == "guard" && not guards_hostile && not npc_hostile_to_player ->
        true

      true ->
        false
    end
  end

  # Initialize quest-related assigns
  def initialize_quest_assigns(socket) do
    %{
      socket
      | assigns:
          Map.merge(socket.assigns, %{
            npc_quests: [],
            active_quest_monsters: [],
            active_quest_npcs: [],
            killed_quest_monsters: [],
            killed_quest_npcs: [],
            show_quest_offer_dialog: false,
            quest_offer_icon: "",
            quest_offer_message: "",
            offered_quest: nil
          })
    }
  end

  # Private helper functions

  defp get_quest_data_for_monster(socket, monster) do
    Logger.info("=== GET QUEST DATA FOR MONSTER ===")
    Logger.info("get_quest_data_for_monster called with monster: #{monster.name}")

    # Check if player already has a quest from this NPC in this theme
    current_theme = socket.assigns.dungeon.theme
    Logger.info("Current theme: #{current_theme}")

    # Check for any active quest from this NPC
    existing_active_quest =
      Enum.find(socket.assigns.npc_quests, fn quest ->
        quest.quest_giver == monster.name and quest.status == :active
      end)

    Logger.info("Existing active quest: #{inspect(existing_active_quest)}")

    # Check if player has already had a quest from this NPC in this specific theme
    existing_quest_in_theme =
      Enum.find(socket.assigns.npc_quests, fn quest ->
        quest.quest_giver == monster.name and quest.quest_giver_theme == current_theme
      end)

    Logger.info("Existing quest in theme: #{inspect(existing_quest_in_theme)}")

    existing_quest = existing_active_quest || existing_quest_in_theme
    Logger.info("Final existing quest: #{inspect(existing_quest)}")

    if existing_quest do
      Logger.info("Player has existing quest, returning existing quest message")
      # Player already has a quest from this NPC or has already had one in this theme
      message =
        if existing_active_quest do
          "#{monster.name} says: \"You already have an active quest from me. Complete it first before I can offer you another!\""
        else
          "#{monster.name} says: \"I've already given you a quest here in the #{current_theme}. I don't have anything else for you in this area.\""
        end

      {:no_quest,
       %{
         icon: DungeonWeb.UISizing.img_tag("/images/chat.png", "Chat", :medium_icon),
         message: message
       }}
    else
      Logger.info("No existing quest, creating new quest")
      # Create a quest for this NPC
      quest =
        Dungeon.Quest.create_npc_quest(
          monster,
          socket.assigns.player_level,
          socket.assigns.dungeon.theme,
          Dungeon.PlayerStats.get_alignment_description(socket.assigns.player_alignment)
        )

      Logger.info("Created quest: #{inspect(quest)}")

      if quest do
        Logger.info("Quest created successfully, returning quest offer data")

        {:quest_offer,
         %{
           icon: DungeonWeb.UISizing.img_tag("/images/open_scroll.png", "Quest", :medium_icon),
           message: "#{monster.name} offers you a quest:\n\n#{quest.description}",
           quest: quest
         }}
      else
        Logger.info("Quest creation failed, returning neutral NPC message")

        {:no_quest,
         %{
           icon: DungeonWeb.UISizing.img_tag("/images/chat.png", "Chat", :medium_icon),
           message:
             "#{monster.name} says: \"I don't have anything for you right now. Safe travels!\""
         }}
      end
    end
  end

  defp get_quest_tldr(quests, quest_id) do
    quest = Enum.find(quests, fn q -> q.id == quest_id end)
    if quest, do: quest.tldr_description, else: "Unknown Quest"
  end

  # Legacy/deprecated functions - kept for compatibility but should not be used

  def handle_talk_to_npc(socket) do
    Logger.warning("handle_talk_to_npc is deprecated - use get_quest_data_for_npc instead")
    socket
  end

  def handle_accept_quest(socket) do
    Logger.warning("handle_accept_quest is deprecated - use get_quest_acceptance_data instead")
    socket
  end

  def handle_decline_quest(socket) do
    Logger.warning(
      "handle_decline_quest is deprecated - quest decline should be handled in main LiveView"
    )

    socket
  end

  def handle_fight_npc(socket) do
    Logger.warning("handle_fight_npc is deprecated - use get_fight_npc_data instead")
    socket
  end

  def handle_dismiss_npc_dialog(socket) do
    Logger.warning(
      "handle_dismiss_npc_dialog is deprecated - dialog dismissal should be handled in main LiveView"
    )

    socket
  end

  def show_npc_dialog(socket, _position, _icon, _message) do
    Logger.warning(
      "show_npc_dialog is deprecated - socket updates should be handled in main LiveView context"
    )

    socket
  end

  def show_encounter_dialog_for_npc_movement(socket, _position, _icon, _message) do
    Logger.warning(
      "show_encounter_dialog_for_npc_movement is deprecated - socket updates should be handled in main LiveView context"
    )

    socket
  end
end
