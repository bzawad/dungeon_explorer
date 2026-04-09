defmodule DungeonWeb.DungeonLive.RoomLabelSystem do
  @moduledoc """
  Room and corridor label detection and dialog handling
  """

  @doc """
  Check if a tile contains a room, corridor, area, or building label
  """
  def label_tile?(tile) do
    match?({:room_label, _}, tile) or match?({:corridor_label, _}, tile) or
      match?({:area_label, _}, tile) or match?({:building_label, _}, tile)
  end

  @doc """
  Get label icon and message
  """
  def get_label_message(
        tile,
        room_descriptions \\ %{},
        corridor_descriptions \\ %{},
        area_descriptions \\ %{},
        building_descriptions \\ %{}
      ) do
    case tile do
      {:room_label, room_number} ->
        # For any room, use generated description if available
        description = Map.get(room_descriptions, room_number, "Room #{room_number}")
        {DungeonWeb.UISizing.img_tag("/images/room.png", "Room", :medium_icon), description}

      {:corridor_label, corridor_number} ->
        # For any corridor, use generated description if available
        description =
          Map.get(corridor_descriptions, corridor_number, "Corridor #{corridor_number}")

        {DungeonWeb.UISizing.img_tag("/images/corridor.png", "Corridor", :medium_icon),
         description}

      {:area_label, area_number} ->
        # For any area, use generated description if available
        description =
          Map.get(area_descriptions, area_number, "Area #{area_number}")

        {DungeonWeb.UISizing.img_tag("/images/magnifying_glass.png", "Area", :medium_icon),
         description}

      {:building_label, building_number} ->
        # For any building, use generated description if available
        description =
          Map.get(building_descriptions, building_number, "Building #{building_number}")

        {DungeonWeb.UISizing.img_tag("/images/castle.png", "Building", :medium_icon), description}

      _ ->
        {"", "Location"}
    end
  end

  @doc """
  Process label discovery when player steps on it
  """
  def process_label(socket, {x, y}) do
    dungeon = socket.assigns.dungeon
    tile = Map.get(dungeon.grid, {x, y})

    cond do
      not label_tile?(tile) ->
        {false, "", ""}

      MapSet.member?(socket.assigns.discovered_labels, {x, y}) ->
        handle_discovered_label(socket, tile)

      true ->
        handle_new_label(socket, tile)
    end
  end

  defp handle_discovered_label(socket, tile) do
    case tile do
      {:room_label, room_number} -> handle_room_access(socket, tile, room_number)
      {:corridor_label, corridor_number} -> handle_corridor_access(socket, tile, corridor_number)
      {:area_label, area_number} -> handle_area_access(socket, tile, area_number)
      _ -> {false, "", ""}
    end
  end

  defp handle_new_label(socket, tile) do
    case tile do
      {:room_label, room_number} ->
        handle_room_access(socket, tile, room_number)

      {:corridor_label, corridor_number} ->
        handle_corridor_access(socket, tile, corridor_number)

      {:area_label, area_number} ->
        handle_area_access(socket, tile, area_number)

      _ ->
        room_descriptions = Map.get(socket.assigns, :room_descriptions, %{})
        corridor_descriptions = Map.get(socket.assigns, :corridor_descriptions, %{})
        area_descriptions = Map.get(socket.assigns, :area_descriptions, %{})

        {icon, message} =
          get_label_message(tile, room_descriptions, corridor_descriptions, area_descriptions)

        {true, icon, message}
    end
  end

  @doc """
  Handle room access - generate LLM description if not already generated
  """
  def handle_room_access(socket, tile, room_number) do
    room_descriptions = Map.get(socket.assigns, :room_descriptions, %{})

    case Map.get(room_descriptions, room_number) do
      nil ->
        # Generate description for this room
        if room_number == "R1" do
          generate_r1_description(socket, tile)
        else
          generate_room_description(socket, tile, room_number)
        end

      existing_description ->
        # Use existing description
        {icon, _} = get_label_message(tile, room_descriptions)
        {true, icon, existing_description}
    end
  end

  @doc """
  Generate LLM description for general rooms (non-R1)
  """
  def generate_room_description(socket, tile, room_number) do
    # Use centralized DescriptionService with streaming support
    context = %{
      theme: socket.assigns.dungeon.theme,
      level: socket.assigns.dungeon_level,
      previous_room_description:
        socket.assigns.current_room_description || "This is the first room entered."
    }

    # Generate description using centralized service (supports streaming)
    alias Dungeon.Services.DescriptionService

    DescriptionService.generate_async(:room, context, self(), %{
      tile: tile,
      room_number: room_number
    })

    {icon, _} = get_label_message(tile)

    {true, icon,
     "#{DungeonWeb.UISizing.inline_img_tag("/images/hourglass.png", "Loading", :loading_icon)} Generating description..."}
  end

  @doc """
  Handle corridor access - generate LLM description if not already generated
  """
  def handle_corridor_access(socket, tile, corridor_number) do
    corridor_descriptions = Map.get(socket.assigns, :corridor_descriptions, %{})

    case Map.get(corridor_descriptions, corridor_number) do
      nil ->
        # Generate description for this corridor
        generate_corridor_description(socket, tile, corridor_number)

      existing_description ->
        # Use existing description
        corridor_descriptions_for_msg = Map.get(socket.assigns, :corridor_descriptions, %{})
        {icon, _} = get_label_message(tile, %{}, corridor_descriptions_for_msg)
        {true, icon, existing_description}
    end
  end

  @doc """
  Generate LLM description for corridors
  """
  def generate_corridor_description(socket, tile, corridor_number) do
    # Use centralized DescriptionService with streaming support
    context = %{
      theme: socket.assigns.dungeon.theme,
      level: socket.assigns.dungeon_level,
      last_room_description:
        socket.assigns.current_room_description || "No previous room has been entered yet."
    }

    # Generate description using centralized service (supports streaming)
    alias Dungeon.Services.DescriptionService

    DescriptionService.generate_async(:corridor, context, self(), %{
      tile: tile,
      corridor_number: corridor_number
    })

    {icon, _} = get_label_message(tile)

    {true, icon,
     "#{DungeonWeb.UISizing.inline_img_tag("/images/hourglass.png", "Loading", :loading_icon)} Generating description..."}
  end

  @doc """
  Handle area access - generate LLM description if not already generated
  """
  def handle_area_access(socket, tile, area_number) do
    area_descriptions = Map.get(socket.assigns, :area_descriptions, %{})

    case Map.get(area_descriptions, area_number) do
      nil ->
        # Generate description for this area
        generate_area_description(socket, tile, area_number)

      existing_description ->
        # Use existing description
        area_descriptions_for_msg = Map.get(socket.assigns, :area_descriptions, %{})
        {icon, _} = get_label_message(tile, %{}, %{}, area_descriptions_for_msg)
        {true, icon, existing_description}
    end
  end

  @doc """
  Generate LLM description for areas
  """
  def generate_area_description(socket, tile, area_number) do
    # Use centralized DescriptionService with streaming support
    context = %{
      theme: socket.assigns.dungeon.theme,
      level: socket.assigns.dungeon_level,
      previous_area_description:
        Map.get(socket.assigns, :current_area_description, "This is the first area entered.")
    }

    # Generate description using centralized service (supports streaming)
    alias Dungeon.Services.DescriptionService

    DescriptionService.generate_async(:area, context, self(), %{
      tile: tile,
      area_number: area_number
    })

    {icon, _} = get_label_message(tile)

    {true, icon,
     "#{DungeonWeb.UISizing.inline_img_tag("/images/hourglass.png", "Loading", :loading_icon)} Generating description..."}
  end

  @doc """
  Handle building access - generate LLM description if not already generated
  """
  def handle_building_access(socket, tile, building_number) do
    building_descriptions = Map.get(socket.assigns, :building_descriptions, %{})

    case Map.get(building_descriptions, building_number) do
      nil ->
        # Generate description for this building
        generate_building_description(socket, tile, building_number)

      existing_description ->
        # Use existing description
        building_descriptions_for_msg = Map.get(socket.assigns, :building_descriptions, %{})
        {icon, _} = get_label_message(tile, %{}, %{}, %{}, building_descriptions_for_msg)
        {true, icon, existing_description}
    end
  end

  @doc """
  Generate LLM description for buildings
  """
  def generate_building_description(socket, tile, building_number) do
    # Use centralized DescriptionService with streaming support
    context = %{
      theme: socket.assigns.dungeon.theme,
      level: socket.assigns.dungeon_level,
      building_type: "merchant building",
      previous_building_description:
        Map.get(
          socket.assigns,
          :current_building_description,
          "This is the first building entered."
        )
    }

    # Generate description using centralized service (supports streaming)
    alias Dungeon.Services.DescriptionService

    DescriptionService.generate_async(:building, context, self(), %{
      tile: tile,
      building_number: building_number
    })

    {icon, _} = get_label_message(tile)

    {true, icon,
     "#{DungeonWeb.UISizing.inline_img_tag("/images/hourglass.png", "Loading", :loading_icon)} Generating description..."}
  end

  @doc """
  Process label click - always show dialog regardless of discovery status
  """
  def process_label_click(socket, {x, y}) do
    dungeon = socket.assigns.dungeon
    tile = Map.get(dungeon.grid, {x, y})

    if label_tile?(tile) do
      case tile do
        {:room_label, room_number} ->
          handle_room_access(socket, tile, room_number)

        {:corridor_label, corridor_number} ->
          handle_corridor_access(socket, tile, corridor_number)

        {:area_label, area_number} ->
          handle_area_access(socket, tile, area_number)

        {:building_label, building_number} ->
          handle_building_access(socket, tile, building_number)

        _ ->
          # Other labels, use standard message
          room_descriptions = Map.get(socket.assigns, :room_descriptions, %{})
          corridor_descriptions = Map.get(socket.assigns, :corridor_descriptions, %{})
          area_descriptions = Map.get(socket.assigns, :area_descriptions, %{})
          building_descriptions = Map.get(socket.assigns, :building_descriptions, %{})

          {icon, message} =
            get_label_message(
              tile,
              room_descriptions,
              corridor_descriptions,
              area_descriptions,
              building_descriptions
            )

          {true, icon, message}
      end
    else
      {false, "", ""}
    end
  end

  @doc """
  Handle R1 access - generate LLM description if not already generated
  """
  def handle_r1_access(socket, tile) do
    room_descriptions = Map.get(socket.assigns, :room_descriptions, %{})

    case Map.get(room_descriptions, "R1") do
      nil ->
        # Generate description for R1
        generate_r1_description(socket, tile)

      existing_description ->
        # Use existing description
        {icon, _} = get_label_message(tile, room_descriptions)
        {true, icon, existing_description}
    end
  end

  @doc """
  Generate LLM description for R1
  """
  def generate_r1_description(socket, tile) do
    # Use centralized DescriptionService with streaming support
    context = %{
      theme: socket.assigns.dungeon.theme,
      level: socket.assigns.dungeon_level
    }

    # Generate description using centralized service (supports streaming)
    alias Dungeon.Services.DescriptionService
    DescriptionService.generate_async(:r1_room, context, self(), %{tile: tile})

    {icon, _} = get_label_message(tile)

    {true, icon,
     "#{DungeonWeb.UISizing.inline_img_tag("/images/hourglass.png", "Loading", :loading_icon)} Generating description..."}
  end

  @doc """
  Dismiss label dialog and mark as discovered
  """
  def dismiss_label(socket) do
    # Mark label as discovered if we have a position and award XP for first-time discovery
    socket = maybe_award_discovery_xp(socket)

    socket
    |> assign(:show_label_dialog, false)
    |> assign(:label_icon, "")
    |> assign(:label_message, "")
    |> assign(:discovered_label_position, nil)
  end

  # Helper function to handle discovery XP logic
  defp maybe_award_discovery_xp(socket) do
    if socket.assigns.discovered_label_position do
      position = socket.assigns.discovered_label_position
      is_first_discovery = not MapSet.member?(socket.assigns.discovered_labels, position)

      if is_first_discovery do
        socket
        |> award_discovery_xp_by_tile_type(position)
        |> mark_label_as_discovered(position)
      else
        socket
      end
    else
      socket
    end
  end

  # Helper function to award XP based on tile type
  defp award_discovery_xp_by_tile_type(socket, position) do
    tile = Map.get(socket.assigns.dungeon.grid, position)

    case tile do
      {:room_label, "R1"} ->
        # R1 doesn't get discovery XP
        socket

      {:room_label, _room_number} ->
        # Award 50 XP for discovering a new room (not R1)
        send(self(), {:award_discovery_xp, 50, "room"})
        socket

      {:corridor_label, _corridor_number} ->
        # Award 25 XP for discovering a new corridor
        send(self(), {:award_discovery_xp, 25, "corridor"})
        socket

      {:area_label, _area_number} ->
        # Award 35 XP for discovering a new area
        send(self(), {:award_discovery_xp, 35, "area"})
        socket

      _ ->
        # Other label types don't get discovery XP
        socket
    end
  end

  # Helper function to mark label as discovered
  defp mark_label_as_discovered(socket, position) do
    new_discovered = MapSet.put(socket.assigns.discovered_labels, position)
    assign(socket, :discovered_labels, new_discovered)
  end

  # Private helper
  defp assign(socket, key, value) do
    Phoenix.Component.assign(socket, key, value)
  end
end
