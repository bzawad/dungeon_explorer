defmodule Dungeon.Services.DescriptionService do
  @moduledoc """
  Centralized service for generating LLM descriptions for dungeon elements
  """
  require Logger
  alias Dungeon.Services.OllamaClient

  @doc """
  Generate description asynchronously and send result to LiveView
  """
  def generate_async(type, context, live_view_pid, response_data) do
    # Check if Ollama is disabled via environment variable
    if System.get_env("OLLAMA_MODEL", "none") == "none" do
      # Send fallback description immediately
      fallback_description = get_fallback_description(type, context)

      send(
        live_view_pid,
        {{:description_stream, type, response_data}, :complete, fallback_description}
      )
    else
      # Always use streaming for new LLM generation - provides better UX
      # Cached descriptions are returned instantly anyway in get_or_generate
      generate_async_streaming(type, context, live_view_pid, response_data)
    end
  end

  @doc """
  Generate description asynchronously with streaming support for typewriter effect
  """
  def generate_async_streaming(type, context, live_view_pid, response_data) do
    # Check if Ollama is disabled via environment variable
    if System.get_env("OLLAMA_MODEL", "none") == "none" do
      # Send fallback description immediately
      fallback_description = get_fallback_description(type, context)

      send(
        live_view_pid,
        {{:description_stream, type, response_data}, :complete, fallback_description}
      )
    else
      prompt = build_prompt(type, context)

      # Log the prompt
      icon = get_log_icon(type)

      Logger.info(
        "#{icon} #{String.upcase(to_string(type))} STREAMING DESCRIPTION PROMPT:\n#{prompt}"
      )

      # Use streaming API with custom message tag
      message_tag = {:description_stream, type, response_data}
      OllamaClient.generate_streaming(prompt, live_view_pid, message_tag)
    end
  end

  # Template builders for different description types
  defp build_discoveries_context(context) do
    rumors = Map.get(context, :recent_rumors, [])
    special_items = Map.get(context, :recent_special_items, [])

    rumors_section =
      if rumors != [] do
        rumors_list =
          rumors
          |> Enum.with_index(1)
          |> Enum.map_join("\n\n", fn {rumor, index} -> "#{index}) #{rumor}" end)

        "\n\nRecent rumors learned for context:\n#{rumors_list}"
      else
        ""
      end

    items_section =
      if special_items != [] do
        items_list =
          special_items
          |> Enum.with_index(1)
          |> Enum.map_join("\n\n", fn {item, index} ->
            formatted_item = format_context_item_entry(item)
            "#{index}) #{formatted_item}"
          end)

        "\n\nRecent special items found for context:\n#{items_list}"
      else
        ""
      end

    rumors_section <> items_section
  end

  defp build_prompt(
         :door,
         %{
           theme: theme,
           level: level,
           room_description: room_desc,
           door_status: status
         } = context
       ) do
    discoveries_context = build_discoveries_context(context)

    """
    You are the Dungeon Master. The party is standing before a #{status} door in level #{level} of a #{theme}.
    In 1–2 interesting sentences, describe only the appearance and mood of the door.
    Focus on concise, vivid detail, no mention of what's beyond or behind the door.
    Do not explain your description or include any extra commentary.

    Use the chamber's description for narrative consistency:
    #{room_desc}
    #{discoveries_context}
    """
  end

  defp build_prompt(
         :room,
         %{
           theme: theme,
           level: level,
           previous_room_description: prev_desc
         } = context
       ) do
    discoveries_context = build_discoveries_context(context)

    """
    You are the Dungeon Master. The party has just entered a chamber on level #{level} of a #{theme}.
    This chamber has a distinctive sub-theme appropriate to the setting.
    Begin your response with a creative, evocative chamber title.
    Then, in 1 or 2 interesting sentences, set the mood.
    Describe the atmosphere, air, light, age, condition, and sensory details as the party enters, all tailored to the chamber's unique sub-theme.
    Do not describe any monsters, treasure, doors, stairways, corridors, or exits; those will be shown on the map.
    Do not explain your description or include any extra commentary.

    Use the chamber's description for narrative consistency:
    #{prev_desc}
    #{discoveries_context}
    """
  end

  defp build_prompt(:r1_room, %{theme: theme, level: level} = context) do
    discoveries_context = build_discoveries_context(context)

    """
    You are the Dungeon Master. The party has just entered the first chamber on level #{level} of a #{theme}.
    This is the starting area where their adventure begins.
    Set an atmospheric tone that establishes the mood and setting for their entire exploration.
    Begin your response with a creative, evocative chamber title.
    Then, in a single descriptive paragraph, describe the initial atmosphere, air, light, age, condition, and sensory details as the party steps into this mysterious place.
    Do not describe any monsters, treasure, doors, stairways, corridors, or exits; those will be shown on the map.
    Do not explain your description or include any extra commentary.

    #{discoveries_context}
    """
  end

  defp build_prompt(
         :corridor,
         %{theme: theme, level: level, last_room_description: room_desc} = context
       ) do
    discoveries_context = build_discoveries_context(context)

    """
    You are the Dungeon Master. The party has just entered a passage on level #{level} of a #{theme}.

    This passage has a distinctive sub-theme appropriate to the setting.
    In 1 or 2 sentences, set the mood: describe the atmosphere, air currents, lighting, geological features, and sensory details.
    Do not describe any monsters, treasure, passages, or exits; those will be shown on the map.
    Do not explain your description or include any extra commentary.

    Use the chamber's description for narrative consistency:
    #{room_desc}
    #{discoveries_context}
    """
  end

  defp build_prompt(
         :area,
         %{theme: theme, level: level, previous_area_description: prev_desc} = context
       ) do
    discoveries_context = build_discoveries_context(context)

    """
    You are the Dungeon Master. The party has just entered a open area on level #{level} of a #{theme}.

    Begin your response with a creative, evocative area title.
    Then, in 1 or 2 sentences, set the mood: describe the atmosphere, air currents, lighting, geological features, and sensory details. Do not describe any monsters, treasure, passages, or exits; those will be shown on the map.
    Do not reference connections to other spaces.
    Do not explain your description or include any extra commentary.

    Use the chamber's description for narrative consistency:
    #{prev_desc}
    #{discoveries_context}
    """
  end

  defp build_prompt(
         :feature,
         %{theme: theme, room_description: room_desc, feature_label: feature_name} = context
       ) do
    discoveries_context = build_discoveries_context(context)

    """
    You are the Dungeon Master. The setting is #{theme}.
    The party has discovered a #{feature_name} in this chamber.
    Begin with an evocative title that incorporates the #{feature_name}.
    Then, in 1–2 vivid sentences, describe this specific #{feature_name} so it feels like a natural part of the setting.
    Focus on how this #{feature_name} looks, its condition, age, and how it enhances the setting.
    Do not describe any monsters, treasure, areas, passages, or exits; those will be shown on the map.
    Do not explain your description or include any extra commentary.

    Use the chamber's description for narrative consistency:
    #{room_desc}
    #{discoveries_context}
    """
  end

  defp build_prompt(:door_trap, %{theme: theme, room_description: room_desc}) do
    """
    You are the Dungeon Master. The setting is #{theme}.
    The party has just triggered a trap on a door in this setting.
    Begin with an evocative trap title.
    Then, in 1–2 vivid sentences, describe what happens as the trap is triggered—what the party sees, hears, feels, or smells in the immediate aftermath.
    Do not explain how to avoid or disarm the trap; focus only on the sensory experience and dramatic effect.
    Do not describe any monsters, treasure, areas, passages, or exits; those will be shown on the map.
    Do not explain your description or include any extra commentary.

    Use the chamber's description for narrative consistency:
    #{room_desc}
    """
  end

  defp build_prompt(:room_trap, %{theme: theme, room_description: room_desc}) do
    """
    You are the Dungeon Master. The setting is #{theme}.
    The party has just triggered a trap or hazard within a chamber.
    Begin with an evocative trap or hazard title.
    Then, in 1–2 vivid sentences, describe what happens as the trap or hazard is triggered—focus on what the party sees, hears, feels, or smells in the immediate aftermath.
    Do not explain how the trap works or how to disarm it; focus only on the sensory impact and dramatic effect.
    Do not describe any monsters, treasure, areas, passages, or exits; those will be shown on the map.
    Do not explain your description or include any extra commentary.

    Use the chamber's description for narrative consistency:
    #{room_desc}
    """
  end

  defp build_prompt(:rumor, %{
         theme: theme,
         level: level,
         feature_description: feature_desc,
         room_description: room_desc,
         existing_rumors: existing_rumors,
         feature_label: feature_name,
         magic_item: magic_item,
         target_theme: target_theme
       }) do
    rumors_context =
      if existing_rumors != [] do
        rumors_list =
          existing_rumors
          |> Enum.with_index(1)
          |> Enum.map_join("\n\n", fn {rumor, index} -> "#{index}) #{rumor}" end)

        "\n\nUse other previously learned rumors for context:\n#{rumors_list}"
      else
        ""
      end

    """
    You are the Dungeon Master. The party is investigating a #{feature_name} in a chamber in level #{level} of a #{theme}.

    The party has discovered a rumor about a legendary #{magic_item.name} hidden somewhere in the #{target_theme}.

    Begin your response with a creative rumor title that incorporates the #{magic_item.name}.
    Then start with a clear quest summary: "Find #{magic_item.name} of #{target_theme}"
    Follow this with 2-3 vivid sentences that describe the legend or tale behind this #{magic_item.name}—why it was lost, who once possessed it, and what makes it so valuable.
    Create compelling atmospheric storytelling that makes the party want to seek out this treasure.
    Do not explain your description or include any extra commentary.

    The #{magic_item.name} is described as: #{magic_item.description}
    Use the feature's description for narrative consistency:
    #{feature_desc}

    Use the chamber's description for narrative consistency:
    #{room_desc}#{rumors_context}
    """
  end

  defp build_prompt(:quest, %{
         theme: theme,
         level: level,
         magic_item: magic_item,
         target_theme: target_theme,
         quest_id: _quest_id
       }) do
    """
    You are the Dungeon Master. The party has discovered a rumor on level #{level} of a #{theme}.
    The rumor speaks of a legendary #{magic_item.name} hidden somewhere in the #{target_theme}.

    Begin your response with a creative quest title that incorporates both the #{magic_item.name} and the #{target_theme}.
    Then, in 2-3 vivid sentences, describe the legend or tale behind this #{magic_item.name}—why it was lost, who once possessed it, and what makes it so valuable that adventurers still seek it today.
    Create a compelling narrative that makes the party want to seek out this treasure.
    Do not explain your description or include any extra commentary.

    The #{magic_item.name} is described as: #{magic_item.description}
    Focus on weaving this into an exciting quest narrative that feels like discovering ancient lore.
    """
  end

  defp build_prompt(:special_item, %{
         theme: theme,
         level: level,
         feature_description: feature_desc,
         room_description: room_desc,
         existing_special_items: existing_special_items,
         feature_label: feature_name
       }) do
    items_context = build_items_context(existing_special_items)

    """
    You are the Dungeon Master. The party is investigating a #{feature_name} in a chamber in level #{level} of a #{theme}.
    Begin your response with a creative special item title that relates to this #{feature_name}.
    Then, in 1-2 vivid sentences, describe the unique and magical special item that the party has discovered hidden within or near this #{feature_name}.
    Do not explain your description or include any extra commentary.

    Use the feature's description for narrative consistency:
    #{feature_desc}

    Use the chamber's description for narrative consistency:
    #{room_desc}#{items_context}
    """
  end

  # New format for selected special item (from common special item system)
  defp build_prompt(:selected_special_item, %{
         theme: theme,
         level: level,
         room_description: room_desc,
         existing_special_items: existing_special_items,
         selected_item: selected_item,
         source_description: source_desc
       }) do
    items_context = build_items_context(existing_special_items)

    """
    You are the Dungeon Master. The party is exploring level #{level} of a #{theme}.
    They have discovered a #{selected_item.name} #{source_desc}.

    Provide a vivid, unique description in 1-2 sentences that explains how this specific #{selected_item.name} appears in this context.
    The #{selected_item.name} is described as: #{selected_item.description}
    Do not explain your description or include any extra commentary.

    Use the chamber's description for narrative consistency:
    #{room_desc}#{items_context}

    Focus on making this specific #{selected_item.name} feel unique to this location while maintaining its core identity.
    """
  end

  # Legacy format for selected special item (for backwards compatibility)
  defp build_prompt(:selected_special_item, %{
         theme: theme,
         level: level,
         feature_description: feature_desc,
         room_description: room_desc,
         existing_special_items: existing_special_items,
         feature_label: feature_name,
         selected_item: selected_item
       }) do
    items_context = build_items_context(existing_special_items)

    """
    You are the Dungeon Master. The party is investigating a #{feature_name} in a chamber in level #{level} of a #{theme}.
    They have discovered a #{selected_item.name} hidden within or near this #{feature_name}.

    Provide a vivid, unique description in 1-2 sentences that explains how this specific #{selected_item.name} appears in this context.
    The #{selected_item.name} is described as: #{selected_item.description}
    Do not explain your description or include any extra commentary.

    Use the feature's description for narrative consistency:
    #{feature_desc}

    Use the chamber's description for narrative consistency:
    #{room_desc}#{items_context}

    Focus on making this specific #{selected_item.name} feel unique to this location while maintaining its core identity.
    """
  end

  defp build_prompt(:treasure, %{
         theme: theme,
         level: level,
         gold_amount: gold_amount,
         room_description: room_desc
       }) do
    """
    You are the Dungeon Master. The party is exploring in level #{level} of a #{theme}.
    Then, in a single descriptive sentence, describe a small treasure the party has found worth #{gold_amount} gold.
    Do not explain your description or include any extra commentary.

    Use the chamber's description for narrative consistency:
    #{room_desc}
    """
  end

  defp build_prompt(:treasure_trap, %{theme: theme, room_description: room_desc}) do
    """
    You are the Dungeon Master. The setting is #{theme}. The party has just triggered a trap on a treasure chest or hoard in this setting.
    Begin with an evocative trap title.
    Then, in 1-2 vivid sentences, describe what happens as the trap is triggered—what the party sees, hears, feels, or smells in the immediate aftermath.
    Do not explain how to avoid or disarm the trap; focus only on the sensory experience and dramatic effect.
    Do not explain your description or include any extra commentary.

    Use the chamber's description for narrative consistency:
    #{room_desc}
    """
  end

  defp build_prompt(:stair, %{
         theme: theme,
         level: level,
         room_description: room_desc,
         stair_direction: direction,
         theme_direction: _theme_direction
       }) do
    """
    You are the Dungeon Master. The setting is #{theme} on level #{level}. The party stands before a staircase leading #{direction}.
    Begin with an evocative title for the staircase.
    Then, in 1-2 vivid sentences, describe the staircase and what lies beyond—the atmosphere, sounds, air currents, or hints of what awaits on the next level.
    Do not explain your description or include any extra commentary.

    Use the chamber's description for narrative consistency:
    #{room_desc}
    """
  end

  defp build_prompt(:waypoint, %{
         theme: theme,
         level: level,
         room_description: room_desc,
         waypoint_number: waypoint_number
       }) do
    """
    You are the Dungeon Master. The setting is #{theme} on level #{level}. The party stands before a waypoint marker (waypoint #{waypoint_number}) that hints of what awaits in the next area.
    Create anticipation for traveling to this new outdoor location within the #{theme}.

    Use the area description for context:
    #{room_desc}
    """
  end

  # Helper function to build items context for prompts
  defp build_items_context(existing_special_items) do
    if existing_special_items != [] do
      items_list = format_existing_items_list(existing_special_items)
      "\n\nUse other previously found special items for context:\n#{items_list}"
    else
      ""
    end
  end

  defp format_existing_items_list(existing_special_items) do
    existing_special_items
    |> Enum.with_index(1)
    |> Enum.map_join("\n\n", &format_item_entry/1)
  end

  defp format_item_entry({item_data, index}) do
    case item_data do
      %{item_name: name, description: desc} -> "#{index}) #{name} - #{desc}"
      description when is_binary(description) -> "#{index}) #{description}"
      _ -> "#{index}) Unknown item"
    end
  end

  # Helper function for formatting special items in context (without index)
  defp format_context_item_entry(item_data) do
    case item_data do
      %{item_name: name, description: desc} -> "#{name} - #{desc}"
      description when is_binary(description) -> description
      _ -> "Unknown item"
    end
  end

  # Helper to get storage key for different description types
  def get_storage_key(:door, %{position: {x, y}}), do: "#{x}_#{y}"
  def get_storage_key(:room, %{context: %{}, tile: _tile, room_number: room_num}), do: room_num
  def get_storage_key(:room, %{room_number: room_num}), do: room_num
  def get_storage_key(:r1_room, _), do: "R1"

  def get_storage_key(:corridor, %{context: %{}, tile: _tile, corridor_number: corr_num}),
    do: corr_num

  def get_storage_key(:corridor, %{corridor_number: corr_num}), do: corr_num

  def get_storage_key(:area, %{context: %{}, tile: _tile, area_number: area_num}),
    do: area_num

  def get_storage_key(:area, %{area_number: area_num}), do: area_num

  def get_storage_key(:feature, %{position: {x, y}, feature_label: label}),
    do: "#{x}_#{y}_#{label}"

  def get_storage_key(:door_trap, %{position: {x, y}}), do: "#{x}_#{y}"
  def get_storage_key(:room_trap, %{position: {x, y}}), do: "#{x}_#{y}"

  def get_storage_key(:treasure, %{position: {x, y}}), do: "#{x}_#{y}"
  def get_storage_key(:treasure_trap, %{position: {x, y}}), do: "#{x}_#{y}"
  def get_storage_key(:stair, %{position: {x, y}}), do: "#{x}_#{y}"
  def get_storage_key(:waypoint, %{position: {x, y}}), do: "#{x}_#{y}"

  def get_storage_key(:special_item, %{position: {x, y}, feature_label: label}),
    do: "#{x}_#{y}_#{label}"

  def get_storage_key(:special_item, %{position: {x, y}, source_name: name}),
    do: "#{x}_#{y}_#{name}"

  def get_storage_key(:selected_special_item, %{position: {x, y}, feature_label: label}),
    do: "#{x}_#{y}_#{label}"

  def get_storage_key(:selected_special_item, %{position: {x, y}, source_name: name}),
    do: "#{x}_#{y}_#{name}"

  # Helper to get socket assign key for different description types
  def get_assign_key(:door), do: :door_descriptions
  def get_assign_key(:room), do: :room_descriptions
  def get_assign_key(:r1_room), do: :room_descriptions
  def get_assign_key(:corridor), do: :corridor_descriptions
  def get_assign_key(:feature), do: :feature_descriptions
  def get_assign_key(:door_trap), do: :door_trap_descriptions
  def get_assign_key(:room_trap), do: :room_trap_descriptions
  def get_assign_key(:treasure), do: :treasure_descriptions
  def get_assign_key(:treasure_trap), do: :treasure_trap_descriptions
  def get_assign_key(:stair), do: :stair_descriptions
  def get_assign_key(:waypoint), do: :waypoint_descriptions
  def get_assign_key(:special_item), do: :special_item_descriptions
  def get_assign_key(:selected_special_item), do: :special_item_descriptions
  def get_assign_key(:area), do: :area_descriptions

  # Helper to get log icon for different types
  defp get_log_icon(:door),
    do: DungeonWeb.UISizing.inline_img_tag("/images/door.png", "Door")

  defp get_log_icon(:room), do: "🏠"
  defp get_log_icon(:r1_room), do: "🏠"

  defp get_log_icon(:corridor),
    do: DungeonWeb.UISizing.inline_img_tag("/images/door.png", "Door")

  defp get_log_icon(:feature),
    do: DungeonWeb.UISizing.inline_img_tag("/images/magnifying_glass.png", "Feature")

  defp get_log_icon(:door_trap),
    do: DungeonWeb.UISizing.inline_img_tag("/images/explosion.png", "Explosion")

  defp get_log_icon(:room_trap),
    do: DungeonWeb.UISizing.inline_img_tag("/images/trap.png", "Trap")

  defp get_log_icon(:rumor),
    do: DungeonWeb.UISizing.inline_img_tag("/images/open_scroll.png", "Rumor")

  defp get_log_icon(:quest),
    do: DungeonWeb.UISizing.inline_img_tag("/images/open_scroll.png", "Quest")

  defp get_log_icon(:treasure),
    do: DungeonWeb.UISizing.inline_img_tag("/images/chest.png", "Treasure")

  defp get_log_icon(:treasure_trap),
    do: DungeonWeb.UISizing.inline_img_tag("/images/explosion.png", "Explosion")

  defp get_log_icon(:stair),
    do: DungeonWeb.UISizing.inline_img_tag("/images/stairway.png", "Stairway")

  defp get_log_icon(:waypoint),
    do: DungeonWeb.UISizing.inline_img_tag("/images/map_links/outdoor_waypoint1.png", "Waypoint")

  defp get_log_icon(:special_item),
    do: DungeonWeb.UISizing.inline_img_tag("/images/special_item.png", "Special Item")

  defp get_log_icon(:selected_special_item),
    do: DungeonWeb.UISizing.inline_img_tag("/images/special_item.png", "Special Item")

  defp get_log_icon(:area), do: "🗻"

  @doc """
  Get fallback description when LLM generation fails
  """
  def get_fallback_description(type, context) do
    cond do
      type in [:door_trap, :room_trap, :treasure_trap] ->
        get_trap_fallback(type, context)

      type in [:door, :room, :r1_room, :corridor, :area, :stair, :waypoint] ->
        get_location_fallback(type, context)

      type in [:feature, :treasure] ->
        get_discovery_fallback(type, context)

      type in [:rumor, :special_item, :selected_special_item] ->
        get_investigation_fallback(type, context)

      type == :quest ->
        get_quest_fallback(context)

      true ->
        get_generic_fallback()
    end
  end

  # Trap-related fallback descriptions
  defp get_trap_fallback(:door_trap, context) do
    theme = Map.get(context, :theme, "dungeon")

    "**Trap Triggered!** You triggered a dangerous trap on this door in the #{theme}. Sharp spikes spring from hidden mechanisms!"
  end

  defp get_trap_fallback(:room_trap, context) do
    theme = Map.get(context, :theme, "dungeon")

    "**Hidden Trap!** You stumbled into a concealed trap in this part of the #{theme}. The floor gives way beneath you!"
  end

  defp get_trap_fallback(:treasure_trap, context) do
    theme = Map.get(context, :theme, "dungeon")

    "**Treasure Trap!** As you reach for the treasure, a hidden mechanism springs to life in this #{theme}. Poisoned darts whistle through the air!"
  end

  # Location-related fallback descriptions
  defp get_location_fallback(:door, context) do
    status = Map.get(context, :door_status, "closed")
    theme = Map.get(context, :theme, "dungeon")

    case status do
      "unpickable" ->
        "A sturdy locked door made from weathered wood and iron, fitting for this #{theme} setting. The lock mechanism appears damaged from a failed picking attempt and can no longer be picked."

      _ ->
        "A sturdy #{status} door made from weathered wood and iron, fitting for this #{theme} setting."
    end
  end

  defp get_location_fallback(:room, context) do
    theme = Map.get(context, :theme, "dungeon")

    "A chamber within this #{theme}, filled with shadows and the echo of ancient secrets."
  end

  defp get_location_fallback(:r1_room, context) do
    theme = Map.get(context, :theme, "dungeon")

    "The entrance chamber of this #{theme}. The walls stretch upward into darkness, and the air carries the weight of untold mysteries."
  end

  defp get_location_fallback(:corridor, context) do
    theme = Map.get(context, :theme, "dungeon")

    "A passage winding through this #{theme}, where every shadow might hide danger or treasure."
  end

  defp get_location_fallback(:area, context) do
    theme = Map.get(context, :theme, "dungeon")

    "An open area within this #{theme}."
  end

  defp get_location_fallback(:stair, context) do
    direction = Map.get(context, :stair_direction, "unknown")
    theme = Map.get(context, :theme, "dungeon")

    "A #{direction}ward staircase in this #{theme}. Stone steps disappear into shadows, beckoning you to venture #{direction}ward to the next level."
  end

  defp get_location_fallback(:waypoint, context) do
    waypoint_number = Map.get(context, :waypoint_number, 1)
    theme = Map.get(context, :theme, "outdoor area")

    "**Waypoint Discovered**\n\nYou've found a weathered waypoint marker (#{waypoint_number}) standing sentinel in this #{theme}. The ancient stone points deeper into the wilderness, indicating a path to unexplored territory. Do you wish to follow the direction it indicates and venture forth to the next area?"
  end

  # Discovery-related fallback descriptions
  defp get_discovery_fallback(:feature, context) do
    feature_label = Map.get(context, :feature_label, "mysterious feature")
    theme = Map.get(context, :theme, "dungeon")

    "**#{feature_label}**\n\nAn intriguing #{String.downcase(feature_label)} in this #{theme}. Something about this #{String.downcase(feature_label)} catches your eye and seems worth investigating further."
  end

  defp get_discovery_fallback(:treasure, context) do
    gold_amount = Map.get(context, :gold_amount, 0)
    theme = Map.get(context, :theme, "dungeon")

    "A collection of valuable coins and trinkets worth #{gold_amount} gold, gleaming in the dim light of this #{theme}."
  end

  # Investigation-related fallback descriptions
  defp get_investigation_fallback(:rumor, context) do
    # Check if quest details are available in context
    magic_item = Map.get(context, :magic_item)
    target_theme = Map.get(context, :target_theme)

    if magic_item && target_theme do
      # Handle both string and map formats for magic_item
      {magic_item_name, magic_item_category} =
        case magic_item do
          %{name: name} = item -> {name, Map.get(item, :category, "artifact")}
          name when is_binary(name) -> {name, "artifact"}
          _ -> {"mysterious artifact", "artifact"}
        end

      # Create quest-based rumor with TLDR and description
      tldr = "Find #{magic_item_name} of #{target_theme}"

      description =
        "Legend speaks of a powerful #{magic_item_name} hidden somewhere in the #{target_theme}. Ancient texts suggest that this #{magic_item_category} possesses remarkable properties and would be invaluable to any adventurer brave enough to seek it out. The tales are vague on its exact location, but they all agree: the #{magic_item_name} awaits discovery by a worthy explorer."

      "**Quest Discovered: #{tldr}**\n\n#{description}"
    else
      # Fallback to generic message if quest details are missing
      "You overhear whispered tales of ancient secrets, hidden passages, and forgotten treasures that might lie deeper within these halls."
    end
  end

  defp get_investigation_fallback(:special_item, context) do
    feature_label = Map.get(context, :feature_label, "the feature")

    "**Mysterious Item**\n\nAmong the debris near the #{String.downcase(feature_label)}, you discover a unique item that might prove useful in your adventures ahead."
  end

  defp get_investigation_fallback(:selected_special_item, context) do
    # Support both old format (feature_label) and new format (source_name/source_description)
    source_description =
      Map.get(context, :source_description) ||
        "near the #{String.downcase(Map.get(context, :feature_label, "feature"))}"

    "**Mysterious Item**\n\nAmong the debris #{source_description}, you discover a unique item that might prove useful in your adventures ahead."
  end

  defp get_quest_fallback(context) do
    magic_item = Map.get(context, :magic_item, %{name: "mysterious artifact"})
    target_theme = Map.get(context, :target_theme, "distant lands")

    "Legend speaks of a powerful #{magic_item.name} hidden somewhere in the #{target_theme}. Ancient texts suggest that this #{magic_item.category || "artifact"} possesses remarkable properties and would be invaluable to any adventurer brave enough to seek it out. The tales are vague on its exact location, but they all agree: the #{magic_item.name} awaits discovery by a worthy explorer."
  end

  # Generic fallback for unknown types
  defp get_generic_fallback do
    "An interesting discovery that adds to the mystery and atmosphere of your dungeon exploration."
  end

  @doc """
  Append consistent damage information to trap descriptions
  """
  def append_trap_damage(description, trap_type) do
    damage_text = get_trap_damage_text(trap_type)
    "#{String.trim(description)}\n\n#{damage_text}"
  end

  # Get consistent damage text for different trap types
  defp get_trap_damage_text(:door_trap), do: "**Damage:** The trap deals 1d4 damage."
  defp get_trap_damage_text(:room_trap), do: "**Damage:** The trap deals 1d6 damage."
  defp get_trap_damage_text(:treasure_trap), do: "**Damage:** The trap deals 1d4 damage."
  defp get_trap_damage_text(_), do: "**Damage:** The trap deals 1d4 damage."

  @doc """
  Get or generate description with consistent pattern
  """
  def get_or_generate(type, socket, context) do
    # Check if Ollama is disabled via environment variable
    if System.get_env("OLLAMA_MODEL", "none") == "none" do
      get_fallback_description(type, context)
    else
      get_or_generate_with_llm(type, socket, context)
    end
  end

  # Handle LLM-based description generation
  defp get_or_generate_with_llm(type, socket, context) do
    assign_key = get_assign_key(type)
    storage_key = get_storage_key(type, context)
    descriptions = Map.get(socket.assigns, assign_key, %{})

    case Map.get(descriptions, storage_key) do
      nil -> generate_new_description(type, context, socket)
      existing_description -> existing_description
    end
  end

  # Generate a new description using LLM
  defp generate_new_description(type, context, socket) do
    enhanced_context = enhance_context_if_needed(type, context, socket)
    response_data = build_response_data(type, enhanced_context)
    generate_async(type, enhanced_context, self(), response_data)

    "#{DungeonWeb.UISizing.inline_img_tag("/images/hourglass.png", "Loading")} Generating description..."
  end

  # Add recent discoveries context for relevant types
  defp enhance_context_if_needed(type, context, socket) do
    if type in [:door, :room, :r1_room, :corridor, :area, :feature] do
      Map.merge(context, get_recent_discoveries(socket))
    else
      context
    end
  end

  @doc """
  Get recent rumors and special items for context
  """
  def get_recent_discoveries(socket) do
    rumors = Map.get(socket.assigns, :rumors, [])
    special_items = Map.get(socket.assigns, :special_items, [])

    # Take most recent 2 of each
    recent_rumors = rumors |> Enum.reverse() |> Enum.take(2) |> Enum.reverse()
    recent_special_items = special_items |> Enum.reverse() |> Enum.take(2) |> Enum.reverse()

    %{
      recent_rumors: recent_rumors,
      recent_special_items: recent_special_items
    }
  end

  # Helper to build appropriate response_data for different types
  defp build_response_data(:feature, %{position: position, feature_label: feature_label}),
    do: %{position: position, feature_label: feature_label}

  defp build_response_data(:selected_special_item, %{
         position: position,
         source_type: source_type,
         source_name: source_name,
         selected_item: selected_item
       }),
       do: %{
         position: position,
         source_type: source_type,
         source_name: source_name,
         selected_item: selected_item
       }

  defp build_response_data(type, context),
    do: %{type: type, context: context}
end
