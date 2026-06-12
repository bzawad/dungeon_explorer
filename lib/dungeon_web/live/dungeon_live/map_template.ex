defmodule DungeonWeb.DungeonLive.MapTemplate do
  @moduledoc """
  Template for rendering the dungeon map and UI components.
  Separated from the main DungeonLive module to improve code organization.
  """

  use Phoenix.Component

  import DungeonWeb.UISizing,
    only: [inline_image_classes: 1, inline_img_tag: 2, img_tag: 3, image_classes: 1]

  import Phoenix.HTML, only: [raw: 1]

  alias DungeonWeb.DungeonLive.{
    CombatSystem,
    FogOfWar,
    Renderer,
    SpecialFeatureSystem
  }

  alias Dungeon.Generator.Features
  alias DungeonWeb.Components.DialogComponent
  alias Phoenix.LiveView.JS

  @doc """
  Renders the main dungeon map template
  """
  def render(assigns) do
    render_original(assigns)
  end

  # Helper function to generate walkability grid for pathfinding
  defp get_walkability_grid(dungeon) do
    for y <- 0..(dungeon.height - 1) do
      for x <- 0..(dungeon.width - 1) do
        tile = Map.get(dungeon.grid, {x, y})
        walkable_tile?(tile)
      end
    end
  end

  # Determine if a tile is walkable for pathfinding
  # credo:disable-for-next-line Credo.Check.Refactor.CyclomaticComplexity
  defp walkable_tile?(tile) do
    case tile do
      :floor ->
        true

      :road ->
        true

      :corridor ->
        true

      {:door, _} ->
        true

      :door ->
        true

      :trapped_door ->
        true

      :stair_up ->
        true

      :stair_down ->
        true

      {:stair_up} ->
        true

      {:stair_down} ->
        true

      {:starting_stair, _} ->
        true

      {:waypoint, _} ->
        true

      {:starting_waypoint, _} ->
        true

      :room_trap ->
        true

      :treasure ->
        true

      :trapped_treasure ->
        true

      :torch ->
        true

      :bread ->
        true

      :cheese ->
        true

      :grapes ->
        true

      :healing_potion ->
        true

      :pile_of_bones ->
        true

      {:treasure, _} ->
        true

      {:food, _} ->
        true

      {:healing_potion, _} ->
        true

      {:torch, _} ->
        true

      {:quest_item, _} ->
        true

      {:room_label, _} ->
        true

      {:corridor_label, _} ->
        true

      {:area_label, _} ->
        true

      {:building_label, _} ->
        true

      {:cavern_entrance, _} ->
        true

      {:dungeon_entrance, _} ->
        true

      {:cavern_exit, _} ->
        true

      {:dungeon_exit, _} ->
        true

      {:special_feature, _, feature_name} ->
        # Pillars are not walkable - they act as blockers like walls
        extract_feature_name(feature_name) != "Pillar"

      {:encounter, _, _} ->
        true

      {:monster, _} ->
        true

      :wall ->
        false

      :shrub ->
        false

      :locked_door ->
        true

      :locked_trapped_door ->
        true

      :secret_door ->
        true

      _ ->
        false
    end
  end

  # Helper function to extract feature name from different formats
  defp extract_feature_name({feature_name, _rarity}) when is_binary(feature_name),
    do: feature_name

  defp extract_feature_name(feature_name) when is_binary(feature_name), do: feature_name
  defp extract_feature_name(_), do: "Unknown Feature"

  def render_original(assigns) do
    ~H"""
    <div
      id="dungeon-map"
      class="hero min-h-[80vh] bg-base-100 dark:bg-black"
      tabindex="0"
      phx-keydown="keydown"
      phx-mounted={JS.focus()}
      phx-hook="ScreenSizeDetector"
    >
      <!-- Audio Player Hook (invisible) -->
      <div id="audio-player" phx-hook="AudioPlayer" style="display: none;"></div>

      <!-- Image Preloader Hook (invisible) -->
      <div id="image-preloader" phx-hook="ImagePreloader" style="display: none;"></div>

      <!-- Hamburger Menu Button - Fixed Position Upper Left -->
      <div class="fixed top-4 left-4 z-50">
        <button
          class="btn btn-sm btn-ghost bg-gray-800 hover:bg-gray-700 text-white border-gray-600"
          phx-click="toggle_game_controls"
          title="Toggle Game Controls"
        >
          <div class="flex flex-col space-y-1">
            <div class="w-4 h-0.5 bg-white"></div>
            <div class="w-4 h-0.5 bg-white"></div>
            <div class="w-4 h-0.5 bg-white"></div>
          </div>
        </button>
      </div>

      <div class="hero-content text-center">
        <div class="flex flex-col lg:flex-row items-start justify-center gap-6">
          <!-- Left Sidebar (Controls + Character Dashboard) - Hidden on small screens -->
          <div class="hidden lg:block w-64 shrink-0 space-y-4">
            <!-- Desktop Title -->
            <div class="text-center mb-4">
              <div class="text-lg font-bold text-white">
                {@dungeon.theme} - Level {@dungeon_level}
              </div>
            </div>

            <!-- Desktop Game Controls - Hamburger Menu -->
            <%= if @show_game_controls do %>
              <div class="bg-gray-800 rounded-lg p-2 mb-2">
                <!-- Header with title and close button -->
                <div class="flex justify-between items-center mb-2">
                  <span class="text-sm font-medium text-gray-300">Game Menu</span>
                  <button
                    class="btn btn-xs btn-ghost text-gray-400 hover:text-white"
                    phx-click="toggle_game_controls"
                    title="Close Game Controls"
                  >
                    <img src="/images/cancel.png" alt="Close" class="w-4 h-4" />
                  </button>
                </div>
                <div class="grid grid-cols-4 gap-2">
                  <!-- New Button -->
                  <button
                    class="btn btn-primary h-12 flex items-center justify-center"
                    phx-click={JS.push("generate_new") |> JS.focus(to: "#dungeon-map")}
                    title="Generate New Dungeon"
                  >
                    <img src="/images/reset.png" alt="New" class="w-8 h-8 object-contain" />
                  </button>

                  <!-- Fog Button -->
                  <button
                    class="btn btn-secondary h-12 flex items-center justify-center"
                    phx-click={JS.push("toggle_fog") |> JS.focus(to: "#dungeon-map")}
                    title="Toggle Fog of War"
                  >
                    {if @fog_enabled,
                      do:
                        raw("<img src='/images/fog.png' alt='Fog' class='w-8 h-8 object-contain' />"),
                      else:
                        raw(
                          "<img src='/images/eye.png' alt='No Fog' class='w-8 h-8 object-contain' />"
                        )}
                  </button>

                  <!-- Print Button -->
                  <button
                    phx-click="open_print"
                    class="btn btn-info h-12 flex items-center justify-center"
                    title="Print Dungeon"
                  >
                    <img src="/images/printer.png" alt="Print" class="w-8 h-8 object-contain" />
                  </button>

                  <!-- Download PNG Button -->
                  <button
                    phx-click="open_download_png"
                    class="btn btn-success h-12 flex items-center justify-center"
                    title="Download as PNG"
                  >
                    <img src="/images/down_arrow.png" alt="PNG" class="w-8 h-8 object-contain" />
                  </button>
                </div>
              </div>
            <% end %>

            <!-- Desktop Character Dashboard - New Layout -->
            <div class="bg-gray-800 rounded-lg p-4 character-dashboard">
              <!-- Player Stats - New Layout -->
              <div>
                <div class="grid grid-cols-2 gap-2 mb-2">
                  <!-- Hit Points -->
                  <div class="p-2 bg-gray-700 rounded">
                    <div class="flex justify-between items-center">
                      <div class="flex items-center">
                        <img
                          src="/images/heart.png"
                          alt="Health"
                          class={inline_image_classes(:small_icon)}
                        />
                        <span class="text-sm text-gray-300 ml-1">HP</span>
                      </div>
                      <span class={[
                        "text-sm",
                        cond do
                          @player_hit_points > @max_hit_points * 0.6 -> "text-green-400"
                          @player_hit_points > @max_hit_points * 0.3 -> "text-yellow-400"
                          true -> "text-red-400"
                        end
                      ]}>
                        {@player_hit_points}/{@max_hit_points}
                      </span>
                    </div>
                    <div class="w-full bg-gray-600 rounded-full h-1 mt-1">
                      <div
                        class={[
                          "h-1 rounded-full transition-all duration-300",
                          cond do
                            @player_hit_points > @max_hit_points * 0.6 -> "bg-green-500"
                            @player_hit_points > @max_hit_points * 0.3 -> "bg-yellow-500"
                            true -> "bg-red-500"
                          end
                        ]}
                        style="width: {(@player_hit_points / @max_hit_points * 100)}%"
                      >
                      </div>
                    </div>
                  </div>

                  <!-- Torch (conditionally rendered) -->
                  <%= if @dungeon.fog_type != "daylight" do %>
                    <div class="p-2 bg-gray-700 rounded">
                      <div class="flex justify-between items-center">
                        <div class="flex items-center">
                          <img
                            src="/images/torch.png"
                            alt="Torch"
                            class={inline_image_classes(:small_icon)}
                          />
                          <span class="text-sm text-gray-300 ml-1">({@torch_count})</span>
                        </div>
                      </div>
                      <div class="w-full bg-gray-600 rounded-full h-1 mt-1">
                        <div
                          class="bg-amber-500 h-1 rounded-full transition-all duration-300"
                          style={"width: #{@torch_burn_time}%"}
                        >
                        </div>
                      </div>
                    </div>
                  <% end %>
                </div>

                <!-- Healing Potion -->
                <div class="p-2 bg-gray-700 rounded mb-2">
                  <div class="flex justify-between items-center">
                    <div class="flex items-center">
                      <img
                        src="/images/healing_potion.png"
                        alt="Healing Potion"
                        class={inline_image_classes(:small_icon)}
                      />
                      <span class="text-sm text-gray-300 ml-1">
                        Healing ({@healing_potion_count})
                      </span>
                    </div>
                    <button
                      class="btn btn-xs btn-success px-2 ml-2"
                      phx-click={JS.push("use_healing_potion") |> JS.focus(to: "#dungeon-map")}
                      disabled={@healing_potion_count == 0 or @player_hit_points >= @max_hit_points}
                    >
                      Drink
                    </button>
                  </div>
                </div>

                <!-- Level & XP (Combined) -->
                <div class="mb-2 p-2 bg-gray-700 rounded">
                  <div class="flex justify-between items-center mb-2">
                    <div class="flex items-center">
                      <img src="/images/xp.png" alt="Level" class={inline_image_classes(:small_icon)} />
                      <span class="text-sm text-gray-300 ml-1">
                        Level {@player_level}
                      </span>
                    </div>
                    <span class="text-sm text-purple-400">{@player_xp} XP</span>
                  </div>
                  <% next_level_xp = Dungeon.PlayerStats.xp_needed_for_next_level(@player_xp) %>
                  <% current_level_xp = Dungeon.PlayerStats.xp_required_for_level(@player_level) %>
                  <% xp_progress = @player_xp - current_level_xp %>
                  <% xp_for_this_level =
                    Dungeon.PlayerStats.xp_required_for_level(@player_level + 1) - current_level_xp %>
                  <div class="w-full bg-gray-600 rounded-full h-1">
                    <div
                      class="bg-purple-500 h-1 rounded-full transition-all duration-300"
                      style={"width: #{if xp_for_this_level > 0, do: (xp_progress / xp_for_this_level * 100), else: 0}%"}
                    >
                    </div>
                  </div>
                  <div class="text-xs text-gray-400 mt-1 text-center">
                    {next_level_xp} XP to next level
                  </div>
                </div>

                <!-- Armor Class | Attack Bonus -->
                <div class="grid grid-cols-2 gap-2 mb-2">
                  <!-- Armor Class -->
                  <div class="p-2 bg-gray-700 rounded">
                    <div class="flex justify-between items-center">
                      <div class="flex items-center">
                        <img
                          src="/images/shield.png"
                          alt="Armor Class"
                          class={inline_image_classes(:small_icon)}
                        />
                        <span class="text-sm text-gray-300 ml-1">AC</span>
                      </div>
                      <span class="text-sm text-blue-400">{@armor_class}</span>
                    </div>
                  </div>

                  <!-- Attack Bonus -->
                  <div class="p-2 bg-gray-700 rounded">
                    <div class="flex justify-between items-center">
                      <div class="flex items-center">
                        <img
                          src="/images/bullseye.png"
                          alt="Attack Bonus"
                          class={inline_image_classes(:small_icon)}
                        />
                        <span class="text-sm text-gray-300 ml-1">AB</span>
                      </div>
                      <span class="text-sm text-green-400">+{@attack_bonus}</span>
                    </div>
                  </div>
                </div>

                <!-- Weapon | Damage -->
                <div class="grid grid-cols-2 gap-2 mb-2">
                  <!-- Weapon -->
                  <div class="p-2 bg-gray-700 rounded">
                    <div class="flex justify-between items-center">
                      <img
                        src="/images/shortsword.png"
                        alt="Weapon"
                        class={inline_image_classes(:small_icon)}
                      />
                      <span class="text-sm text-white">{String.slice(@player_weapon, 0, 10)}</span>
                    </div>
                  </div>

                  <!-- Damage -->
                  <div class="p-2 bg-gray-700 rounded">
                    <div class="flex justify-between items-center">
                      <img
                        src="/images/damage.png"
                        alt="Damage"
                        class={inline_image_classes(:small_icon)}
                      />
                      <span class="text-sm text-red-400">{@weapon_damage_dice}</span>
                    </div>
                  </div>
                </div>

                <!-- Gold | Inventory -->
                <div class="grid grid-cols-2 gap-2 mb-2">
                  <!-- Gold -->
                  <div class="p-2 bg-gray-700 rounded">
                    <div class="flex justify-between items-center">
                      <img
                        src="/images/gold.png"
                        alt="Gold"
                        class={inline_image_classes(:small_icon)}
                      />
                      <span class="text-sm text-yellow-400">{@player_gold} gp</span>
                    </div>
                  </div>

                  <!-- Inventory -->
                  <%= if length(@special_items) > 0 do %>
                    <div
                      class="p-2 bg-gray-700 rounded hover:bg-gray-600 cursor-pointer transition-colors"
                      phx-click="show_special_items_list"
                      style="pointer-events: auto !important;"
                    >
                      <div class="flex justify-between items-center">
                        <img
                          src="/images/special_item.png"
                          alt="Items"
                          class={inline_image_classes(:small_icon)}
                        />
                        <span class="text-sm text-white">
                          {length(@special_items)}
                        </span>
                      </div>
                    </div>
                  <% else %>
                    <div class="p-2 bg-gray-700 rounded">
                      <div class="flex justify-between items-center">
                        <img
                          src="/images/special_item.png"
                          alt="Items"
                          class={inline_image_classes(:small_icon)}
                        />
                        <span class="text-sm text-gray-500">
                          {length(@special_items)}
                        </span>
                      </div>
                    </div>
                  <% end %>
                </div>

                <!-- Rumors | Achievements -->
                <div class="grid grid-cols-2 gap-2 mb-2">
                  <!-- Rumors -->
                  <%= if length(@rumors) > 0 do %>
                    <div
                      class="p-2 bg-gray-700 rounded hover:bg-gray-600 cursor-pointer transition-colors"
                      phx-click="show_rumors_list"
                      style="pointer-events: auto !important;"
                    >
                      <div class="flex justify-between items-center">
                        <img
                          src="/images/open_scroll.png"
                          alt="Rumors"
                          class={inline_image_classes(:small_icon)}
                        />
                        <span class="text-sm text-white">
                          {length(@rumors)}
                        </span>
                      </div>
                    </div>
                  <% else %>
                    <div class="p-2 bg-gray-700 rounded">
                      <div class="flex justify-between items-center">
                        <img
                          src="/images/open_scroll.png"
                          alt="Rumors"
                          class={inline_image_classes(:small_icon)}
                        />
                        <span class="text-sm text-gray-500">
                          {length(@rumors)}
                        </span>
                      </div>
                    </div>
                  <% end %>

                  <!-- Achievements -->
                  <%= if length(@achievements) > 0 do %>
                    <div
                      class="p-2 bg-gray-700 rounded hover:bg-gray-600 cursor-pointer transition-colors"
                      phx-click="show_achievements_list"
                      style="pointer-events: auto !important;"
                    >
                      <div class="flex justify-between items-center">
                        <img
                          src="/images/victory.png"
                          alt="Achievements"
                          class={inline_image_classes(:small_icon)}
                        />
                        <span class="text-sm text-white">
                          {length(@achievements)}
                        </span>
                      </div>
                    </div>
                  <% else %>
                    <div class="p-2 bg-gray-700 rounded">
                      <div class="flex justify-between items-center">
                        <img
                          src="/images/victory.png"
                          alt="Achievements"
                          class={inline_image_classes(:small_icon)}
                        />
                        <span class="text-sm text-gray-500">
                          {length(@achievements)}
                        </span>
                      </div>
                    </div>
                  <% end %>
                </div>

                <!-- Alignment -->
                <div class="p-2 bg-gray-700 rounded">
                  <div class="flex justify-between items-center">
                    <div class="flex items-center">
                      <img
                        src="/images/scale.png"
                        alt="Alignment"
                        class={inline_image_classes(:small_icon)}
                      />
                      <span class="text-sm text-gray-300 ml-1">Alignment</span>
                    </div>
                    <span class={"text-sm #{Dungeon.PlayerStats.get_alignment_color(@player_alignment)}"}>
                      {String.capitalize(
                        to_string(Dungeon.PlayerStats.get_alignment_description(@player_alignment))
                      )}
                    </span>
                  </div>
                  <div class="w-full bg-gray-600 rounded-full h-1 mt-1">
                    <div class={Dungeon.PlayerStats.get_alignment_gradient_class(@player_alignment) <> " h-1 rounded-full"}>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>

          <!-- Main Game Area -->
          <div class="flex-1">
            <!-- Title - Hidden on large screens (shown in sidebar), visible on small screens -->
            <div class="lg:hidden mb-4 text-center">
              <div class="text-lg font-bold text-white">
                {@dungeon.theme} - Level {@dungeon_level}
              </div>
            </div>

            <!-- Mobile Game Controls - Hamburger Menu -->
            <%= if @show_game_controls do %>
              <div class="lg:hidden mb-4">
                <div class="bg-gray-800 rounded-lg p-2">
                  <!-- Header with title and close button -->
                  <div class="flex justify-between items-center mb-2">
                    <span class="text-sm font-medium text-gray-300">Game Menu</span>
                    <button
                      class="btn btn-xs btn-ghost text-gray-400 hover:text-white"
                      phx-click="toggle_game_controls"
                      title="Close Game Controls"
                    >
                      <img src="/images/cancel.png" alt="Close" class="w-4 h-4" />
                    </button>
                  </div>
                  <div class="grid grid-cols-4 gap-2">
                    <!-- New Button -->
                    <button
                      class="btn btn-primary h-12 flex items-center justify-center"
                      phx-click={JS.push("generate_new") |> JS.focus(to: "#dungeon-map")}
                      title="Generate New Dungeon"
                    >
                      <img src="/images/reset.png" alt="New" class="w-8 h-8 object-contain" />
                    </button>

                    <!-- Fog Button -->
                    <button
                      class="btn btn-secondary h-12 flex items-center justify-center"
                      phx-click={JS.push("toggle_fog") |> JS.focus(to: "#dungeon-map")}
                      title="Toggle Fog of War"
                    >
                      {if @fog_enabled,
                        do:
                          raw(
                            "<img src='/images/fog.png' alt='Fog' class='w-8 h-8 object-contain' />"
                          ),
                        else:
                          raw(
                            "<img src='/images/eye.png' alt='No Fog' class='w-8 h-8 object-contain' />"
                          )}
                    </button>

                    <!-- Print Button -->
                    <button
                      phx-click="open_print"
                      class="btn btn-info h-12 flex items-center justify-center"
                      title="Print Dungeon"
                    >
                      <img src="/images/printer.png" alt="Print" class="w-8 h-8 object-contain" />
                    </button>

                    <!-- Download PNG Button -->
                    <button
                      phx-click="open_download_png"
                      class="btn btn-success h-12 flex items-center justify-center"
                      title="Download as PNG"
                    >
                      <img src="/images/down_arrow.png" alt="PNG" class="w-8 h-8 object-contain" />
                    </button>
                  </div>
                </div>
              </div>
            <% end %>

            <!-- Map Container - Conditionally shown on mobile -->
            <%= if @show_map_mobile or @screen_size != :mobile do %>
              <div
                id="dungeon-grid"
                class={
                  "dungeon-map inline-block p-1 lg:p-4 lg:rounded-lg " <>
                  if(@dungeon.generation_type == "city", do: "bg-amber-700 lg:bg-amber-800", else: "bg-black lg:bg-gray-900")
                }
                phx-hook="PathfindingHook"
                data-walkability={Jason.encode!(get_walkability_grid(@dungeon))}
                data-player-position={Jason.encode!(Tuple.to_list(@player_position))}
                data-grid-width={@dungeon.width}
                data-grid-height={@dungeon.height}
                data-viewport-x={@viewport_x}
                data-viewport-y={@viewport_y}
              >
                <% {y_range, x_range, row_height} = {
                  @viewport_y..min(@viewport_y + @viewport_height - 1, @dungeon.height - 1),
                  @viewport_x..min(@viewport_x + @viewport_width - 1, @dungeon.width - 1),
                  "h-[48px]"
                } %>
                <%= for y <- y_range do %>
                  <div class={"flex #{row_height}"}>
                    <%= for x <- x_range do %>
                      <% tile = Map.get(@dungeon.grid, {x, y}) %>
                      <% revealed = FogOfWar.square_revealed?(x, y, @revealed_squares, @fog_enabled) %>
                      <% show_trap = FogOfWar.show_door_trap?(x, y, @clicked_squares, @fog_enabled) %>
                      <% door_orientation = Renderer.get_door_orientation(@dungeon.grid, x, y, tile) %>
                      <div
                        class={
                          Renderer.tile_classes(
                            tile,
                            revealed,
                            {x, y},
                            @dungeon.rooms,
                            @dungeon.generation_type,
                            @dungeon.fog_type
                          )
                        }
                        data-x={x}
                        data-y={y}
                        phx-click={
                          Renderer.click_action(
                            x,
                            y,
                            @dungeon,
                            @revealed_squares,
                            @fog_enabled,
                            @player_position,
                            @unlocked_doors
                          )
                        }
                        phx-value-x={x}
                        phx-value-y={y}
                      >
                        <!-- Always render background for transparency -->
                        <%= unless revealed do %>
                          <!-- Simplified background for unrevealed tiles using tilesets -->
                          <div
                            class="absolute inset-0 tile-background"
                            style={Renderer.get_tile_background_style(tile, {x, y}, @dungeon)}
                          >
                          </div>

                          <!-- Fog overlay -->
                          <div class={
                          "absolute inset-0 z-10 " <>
                          Renderer.fog_opacity_class(@dungeon.fog_type)
                        }>
                          </div>
                        <% end %>

                        <%= if revealed do %>
                          <!-- Background tile texture layer using tilesets -->
                          <div
                            class="absolute inset-0 tile-background"
                            style={Renderer.get_tile_background_style(tile, {x, y}, @dungeon)}
                          >
                          </div>

                          <%= case tile do %>
                            <% {:room_label, room_number} -> %>
                              <%= if revealed do %>
                                <div class="absolute inset-0 flex items-center justify-center">
                                  <div class="bg-black bg-opacity-60 px-2 py-1 rounded text-[14px] font-bold text-white">
                                    {room_number}
                                  </div>
                                </div>
                              <% end %>
                            <% {:corridor_label, corridor_number} -> %>
                              <%= if revealed do %>
                                <div class="absolute inset-0 flex items-center justify-center">
                                  <div class="bg-black bg-opacity-60 px-2 py-1 rounded text-[14px] font-bold text-white">
                                    {corridor_number}
                                  </div>
                                </div>
                              <% end %>
                            <% {:area_label, area_number} -> %>
                              <%= if revealed do %>
                                <div class="absolute inset-0 flex items-center justify-center">
                                  <div class="bg-black bg-opacity-60 px-2 py-1 rounded text-[14px] font-bold text-white">
                                    {area_number}
                                  </div>
                                </div>
                              <% end %>
                            <% {:encounter, _encounter_label, monster} -> %>
                              <% monster_size_class = get_monster_image_size(monster) %>
                              <div class={get_monster_container_classes(monster)}>
                                <div
                                  class={"#{monster_size_class} flex-shrink-0"}
                                  style={
                                    Renderer.bg_image_style(
                                      "/images/monsters/" <> monster.image,
                                      x,
                                      y,
                                      @dungeon.grid,
                                      Renderer.bg_size_from_class(monster_size_class)
                                    )
                                  }
                                  role="img"
                                  aria-label={monster.name}
                                >
                                </div>
                                <!-- Quest glow effect for quest monsters and NPCs -->
                                <%= if monster.role == "quest_monster" or monster.role == "quest_npc" do %>
                                  <% quest_alignment =
                                    get_quest_alignment_for_monster(monster, @npc_quests) %>
                                  <%= if quest_alignment == :lawful do %>
                                    <div class="absolute inset-0 pointer-events-none quest-glow-lawful">
                                    </div>
                                  <% else %>
                                    <div class="absolute inset-0 pointer-events-none quest-glow-chaotic">
                                    </div>
                                  <% end %>
                                <% end %>
                              </div>
                            <% {:monster, monster_name} -> %>
                              <!-- Surprise monster from special feature -->
                              <%= case Dungeon.Monster.get_monster_by_name(monster_name) do %>
                                <% nil -> %>
                                  <!-- Monster not found, show generic monster icon -->
                                  <div class="absolute inset-0 flex items-center justify-center">
                                    <div
                                      class="w-[48px] h-[48px]"
                                      style={
                                        Renderer.bg_image_style_static(
                                          "/images/monsters/goblin_scout.png"
                                        )
                                      }
                                      role="img"
                                      aria-label="Unknown Monster"
                                    >
                                    </div>
                                  </div>
                                <% monster -> %>
                                  <% monster_size_class = get_monster_image_size(monster) %>
                                  <div class={get_monster_container_classes(monster)}>
                                    <div
                                      class={"#{monster_size_class} flex-shrink-0"}
                                      style={
                                        Renderer.bg_image_style(
                                          "/images/monsters/" <> monster.image,
                                          x,
                                          y,
                                          @dungeon.grid,
                                          Renderer.bg_size_from_class(monster_size_class)
                                        )
                                      }
                                      role="img"
                                      aria-label={monster.name}
                                    >
                                    </div>
                                  </div>
                              <% end %>
                            <% {:special_feature, _feature_label, feature_name} -> %>
                              <% actual_feature_name = extract_feature_name(feature_name) %>
                              <% feature_size_class = get_feature_image_size(actual_feature_name) %>
                              <div class={get_feature_container_classes(actual_feature_name)}>
                                <div
                                  class={"#{feature_size_class} flex-shrink-0"}
                                  style={
                                    Renderer.bg_image_style(
                                      SpecialFeatureSystem.get_feature_image_path(
                                        actual_feature_name
                                      ),
                                      x,
                                      y,
                                      @dungeon.grid,
                                      Renderer.bg_size_from_class(feature_size_class)
                                    )
                                  }
                                  role="img"
                                  aria-label={actual_feature_name}
                                >
                                </div>
                                <!-- Glow effect for light-creating special features -->
                                <%= if Dungeon.Generator.Features.special_feature_creates_light?(actual_feature_name) do %>
                                  <div
                                    class="absolute inset-0 pointer-events-none"
                                    style="animation: torch-flicker 0.8s ease-in-out infinite alternate; box-shadow: 0 0 12px 6px rgba(251,191,36,0.4), 0 0 24px 12px rgba(251,191,36,0.2);"
                                  >
                                  </div>
                                <% end %>
                              </div>
                            <% {:quest_item, _quest_item_data} -> %>
                              <div class="absolute inset-0 flex items-center justify-center z-20">
                                <div
                                  class="w-[48px] h-[48px]"
                                  style={
                                    Renderer.bg_image_style_static(
                                      "/images/special_item.png",
                                      "background-size: 48px 48px;"
                                    )
                                  }
                                  role="img"
                                  aria-label="Quest Item"
                                >
                                </div>
                                <!-- Magical glow effect for quest items -->
                                <div
                                  class="absolute inset-0 pointer-events-none"
                                  style="animation: quest-glow 2s ease-in-out infinite alternate; box-shadow: 0 0 16px 8px rgba(168,85,247,0.5), 0 0 32px 16px rgba(219,39,119,0.3);"
                                >
                                </div>
                              </div>
                            <% {:starting_stair, stair_label} -> %>
                              <!-- Stair background tile -->
                              <div
                                class="absolute inset-0 w-full h-full tile-background"
                                style={
                                  Renderer.bg_image_style_static(
                                    Renderer.random_stair_tile_image(
                                      {x, y},
                                      @dungeon.transition_theme
                                    ),
                                    "background-size: cover;"
                                  )
                                }
                                role="img"
                                aria-label="Stair Tile"
                              >
                              </div>
                              <span class="absolute inset-0 flex items-center justify-center text-[20px] font-bold text-green-600">
                                {stair_label}
                              </span>
                            <% {:starting_waypoint, waypoint_label} -> %>
                              <!-- Starting waypoint marker overlay -->
                              <span class="absolute inset-0 flex items-center justify-center">
                                <div
                                  class="w-[48px] h-[48px]"
                                  style={
                                    Renderer.bg_image_style(
                                      "/images/map_links/outdoor_waypoint1.png",
                                      x,
                                      y,
                                      @dungeon.grid,
                                      "background-size: 48px 48px;"
                                    )
                                  }
                                  role="img"
                                  aria-label="Starting Waypoint"
                                >
                                </div>
                              </span>
                              <!-- Waypoint label -->
                              <span class="absolute inset-0 flex items-center justify-center text-[20px] font-bold text-green-600">
                                {waypoint_label}
                              </span>
                            <% {:waypoint, waypoint_number} -> %>
                              <!-- Waypoint marker overlay -->
                              <span class="absolute inset-0 flex items-center justify-center">
                                <div
                                  class="w-[48px] h-[48px]"
                                  style={
                                    Renderer.bg_image_style(
                                      "/images/map_links/outdoor_waypoint#{waypoint_number}.png",
                                      x,
                                      y,
                                      @dungeon.grid,
                                      "background-size: 48px 48px;"
                                    )
                                  }
                                  role="img"
                                  aria-label="Waypoint"
                                >
                                </div>
                              </span>
                            <% {:cavern_entrance, entrance_number} -> %>
                              <!-- Cavern entrance overlay -->
                              <span class="absolute inset-0 flex items-center justify-center z-20 overflow-visible">
                                <div
                                  class="w-[96px] h-[96px] flex-shrink-0"
                                  style={
                                    Renderer.bg_image_style(
                                      "/images/map_links/cavern_entrance#{entrance_number}.png",
                                      x,
                                      y,
                                      @dungeon.grid,
                                      "background-size: 96px 96px;"
                                    )
                                  }
                                  role="img"
                                  aria-label="Cavern Entrance"
                                >
                                </div>
                              </span>
                            <% {:dungeon_entrance, entrance_number} -> %>
                              <!-- Dungeon entrance overlay -->
                              <span class="absolute inset-0 flex items-center justify-center z-20 overflow-visible">
                                <div
                                  class="w-[96px] h-[96px] flex-shrink-0"
                                  style={
                                    Renderer.bg_image_style(
                                      "/images/map_links/dungeon_entrance#{entrance_number}.png",
                                      x,
                                      y,
                                      @dungeon.grid,
                                      "background-size: 96px 96px;"
                                    )
                                  }
                                  role="img"
                                  aria-label="Dungeon Entrance"
                                >
                                </div>
                              </span>
                            <% {:cavern_exit, exit_number} -> %>
                              <!-- Cavern exit overlay -->
                              <span class="absolute inset-0 flex items-center justify-center z-20 overflow-visible">
                                <div
                                  class="w-[96px] h-[96px] flex-shrink-0"
                                  style={
                                    Renderer.bg_image_style(
                                      "/images/map_links/cavern_exit#{exit_number}.png",
                                      x,
                                      y,
                                      @dungeon.grid,
                                      "background-size: 96px 96px;"
                                    )
                                  }
                                  role="img"
                                  aria-label="Cavern Exit"
                                >
                                </div>
                              </span>
                            <% {:dungeon_exit, exit_number} -> %>
                              <!-- Dungeon exit overlay -->
                              <span class="absolute inset-0 flex items-center justify-center z-20 overflow-visible">
                                <div
                                  class="w-[96px] h-[96px] flex-shrink-0"
                                  style={
                                    Renderer.bg_image_style(
                                      "/images/map_links/dungeon_exit#{exit_number}.png",
                                      x,
                                      y,
                                      @dungeon.grid,
                                      "background-size: 96px 96px;"
                                    )
                                  }
                                  role="img"
                                  aria-label="Dungeon Exit"
                                >
                                </div>
                              </span>
                            <% :door -> %>
                              <div class="absolute inset-0">
                                <%= case door_orientation do %>
                                  <% :north -> %>
                                    <div class="absolute top-0 left-0 right-0 h-1/2 bg-black"></div>
                                  <% :south -> %>
                                    <div class="absolute bottom-0 left-0 right-0 h-1/2 bg-black">
                                    </div>
                                  <% :east -> %>
                                    <div class="absolute right-0 top-0 bottom-0 w-1/2 bg-black"></div>
                                  <% :west -> %>
                                    <div class="absolute left-0 top-0 bottom-0 w-1/2 bg-black"></div>
                                  <% _ -> %>
                                    <div class="absolute right-0 top-0 bottom-0 w-1/2 bg-black"></div>
                                <% end %>
                              </div>
                            <% :locked_door -> %>
                              <div class="absolute inset-0">
                                <%= case door_orientation do %>
                                  <% :north -> %>
                                    <div class="absolute top-0 left-0 right-0 h-1/2 bg-black"></div>
                                  <% :south -> %>
                                    <div class="absolute bottom-0 left-0 right-0 h-1/2 bg-black">
                                    </div>
                                  <% :east -> %>
                                    <div class="absolute right-0 top-0 bottom-0 w-1/2 bg-black"></div>
                                  <% :west -> %>
                                    <div class="absolute left-0 top-0 bottom-0 w-1/2 bg-black"></div>
                                  <% _ -> %>
                                    <div class="absolute right-0 top-0 bottom-0 w-1/2 bg-black"></div>
                                <% end %>
                                <%= unless MapSet.member?(@unlocked_doors, {x, y}) do %>
                                  <%= case door_orientation do %>
                                    <% :north -> %>
                                      <div class="absolute top-0 left-0 right-0 h-1/2 flex items-center justify-center">
                                        <div
                                          class="w-[18px] h-[18px]"
                                          style={
                                            Renderer.bg_image_style_static(
                                              "/images/lock.png",
                                              "background-size: 18px 18px;"
                                            )
                                          }
                                          role="img"
                                          aria-label="Lock"
                                        >
                                        </div>
                                      </div>
                                    <% :south -> %>
                                      <div class="absolute bottom-0 left-0 right-0 h-1/2 flex items-center justify-center">
                                        <div
                                          class="w-[18px] h-[18px]"
                                          style={
                                            Renderer.bg_image_style_static(
                                              "/images/lock.png",
                                              "background-size: 18px 18px;"
                                            )
                                          }
                                          role="img"
                                          aria-label="Lock"
                                        >
                                        </div>
                                      </div>
                                    <% :east -> %>
                                      <div class="absolute right-0 top-0 bottom-0 w-1/2 flex items-center justify-center">
                                        <div
                                          class="w-[18px] h-[18px]"
                                          style={
                                            Renderer.bg_image_style_static(
                                              "/images/lock.png",
                                              "background-size: 18px 18px;"
                                            )
                                          }
                                          role="img"
                                          aria-label="Lock"
                                        >
                                        </div>
                                      </div>
                                    <% _ -> %>
                                      <div class="absolute left-0 top-0 bottom-0 w-1/2 flex items-center justify-center">
                                        <div
                                          class="w-[18px] h-[18px]"
                                          style={
                                            Renderer.bg_image_style_static(
                                              "/images/lock.png",
                                              "background-size: 18px 18px;"
                                            )
                                          }
                                          role="img"
                                          aria-label="Lock"
                                        >
                                        </div>
                                      </div>
                                  <% end %>
                                <% end %>
                              </div>
                            <% :trapped_door -> %>
                              <div class="absolute inset-0">
                                <%= case door_orientation do %>
                                  <% :north -> %>
                                    <div class="absolute top-0 left-0 right-0 h-1/2 bg-black"></div>
                                  <% :south -> %>
                                    <div class="absolute bottom-0 left-0 right-0 h-1/2 bg-black">
                                    </div>
                                  <% :east -> %>
                                    <div class="absolute right-0 top-0 bottom-0 w-1/2 bg-black"></div>
                                  <% :west -> %>
                                    <div class="absolute left-0 top-0 bottom-0 w-1/2 bg-black"></div>
                                  <% _ -> %>
                                    <div class="absolute right-0 top-0 bottom-0 w-1/2 bg-black"></div>
                                <% end %>
                                <%= if show_trap do %>
                                  <%= case door_orientation do %>
                                    <% :north -> %>
                                      <div class="absolute top-0 left-0 right-0 h-1/2 flex items-center justify-center">
                                        <div
                                          class="w-[18px] h-[18px]"
                                          style={
                                            Renderer.bg_image_style_static(
                                              "/images/trap.png",
                                              "background-size: 18px 18px;"
                                            )
                                          }
                                          role="img"
                                          aria-label="Trap"
                                        >
                                        </div>
                                      </div>
                                    <% :south -> %>
                                      <div class="absolute bottom-0 left-0 right-0 h-1/2 flex items-center justify-center">
                                        <div
                                          class="w-[18px] h-[18px]"
                                          style={
                                            Renderer.bg_image_style_static(
                                              "/images/trap.png",
                                              "background-size: 18px 18px;"
                                            )
                                          }
                                          role="img"
                                          aria-label="Trap"
                                        >
                                        </div>
                                      </div>
                                    <% :east -> %>
                                      <div class="absolute right-0 top-0 bottom-0 w-1/2 flex items-center justify-center">
                                        <div
                                          class="w-[18px] h-[18px]"
                                          style={
                                            Renderer.bg_image_style_static(
                                              "/images/trap.png",
                                              "background-size: 18px 18px;"
                                            )
                                          }
                                          role="img"
                                          aria-label="Trap"
                                        >
                                        </div>
                                      </div>
                                    <% _ -> %>
                                      <div class="absolute left-0 top-0 bottom-0 w-1/2 flex items-center justify-center">
                                        <div
                                          class="w-[18px] h-[18px]"
                                          style={
                                            Renderer.bg_image_style_static(
                                              "/images/trap.png",
                                              "background-size: 18px 18px;"
                                            )
                                          }
                                          role="img"
                                          aria-label="Trap"
                                        >
                                        </div>
                                      </div>
                                  <% end %>
                                <% end %>
                              </div>
                            <% :secret_door -> %>
                              <%= if Renderer.show_secret_door?(tile, {x, y}, @revealed_secret_doors, @fog_enabled) do %>
                                <div class="absolute inset-0">
                                  <%= case door_orientation do %>
                                    <% :north -> %>
                                      <div class="absolute top-0 left-0 right-0 h-1/2 bg-black"></div>
                                    <% :south -> %>
                                      <div class="absolute bottom-0 left-0 right-0 h-1/2 bg-black">
                                      </div>
                                    <% :east -> %>
                                      <div class="absolute right-0 top-0 bottom-0 w-1/2 bg-black">
                                      </div>
                                    <% :west -> %>
                                      <div class="absolute left-0 top-0 bottom-0 w-1/2 bg-black">
                                      </div>
                                    <% _ -> %>
                                      <div class="absolute right-0 top-0 bottom-0 w-1/2 bg-black">
                                      </div>
                                  <% end %>
                                  <%= case door_orientation do %>
                                    <% :north -> %>
                                      <div class="absolute top-0 left-0 right-0 h-1/2 flex items-center justify-center">
                                        <div
                                          class="w-[18px] h-[18px]"
                                          style={
                                            Renderer.bg_image_style_static(
                                              "/images/secret.png",
                                              "background-size: 18px 18px;"
                                            )
                                          }
                                          role="img"
                                          aria-label="Secret Door"
                                        >
                                        </div>
                                      </div>
                                    <% :south -> %>
                                      <div class="absolute bottom-0 left-0 right-0 h-1/2 flex items-center justify-center">
                                        <div
                                          class="w-[18px] h-[18px]"
                                          style={
                                            Renderer.bg_image_style_static(
                                              "/images/secret.png",
                                              "background-size: 18px 18px;"
                                            )
                                          }
                                          role="img"
                                          aria-label="Secret Door"
                                        >
                                        </div>
                                      </div>
                                    <% :east -> %>
                                      <div class="absolute right-0 top-0 bottom-0 w-1/2 flex items-center justify-center">
                                        <div
                                          class="w-[18px] h-[18px]"
                                          style={
                                            Renderer.bg_image_style_static(
                                              "/images/secret.png",
                                              "background-size: 18px 18px;"
                                            )
                                          }
                                          role="img"
                                          aria-label="Secret Door"
                                        >
                                        </div>
                                      </div>
                                    <% _ -> %>
                                      <div class="absolute left-0 top-0 bottom-0 w-1/2 flex items-center justify-center">
                                        <div
                                          class="w-[18px] h-[18px]"
                                          style={
                                            Renderer.bg_image_style_static(
                                              "/images/secret.png",
                                              "background-size: 18px 18px;"
                                            )
                                          }
                                          role="img"
                                          aria-label="Secret Door"
                                        >
                                        </div>
                                      </div>
                                  <% end %>
                                </div>
                              <% end %>
                            <% :locked_trapped_door -> %>
                              <div class="absolute inset-0">
                                <%= case door_orientation do %>
                                  <% :north -> %>
                                    <div class="absolute top-0 left-0 right-0 h-1/2 bg-black"></div>
                                  <% :south -> %>
                                    <div class="absolute bottom-0 left-0 right-0 h-1/2 bg-black">
                                    </div>
                                  <% :east -> %>
                                    <div class="absolute right-0 top-0 bottom-0 w-1/2 bg-black"></div>
                                  <% :west -> %>
                                    <div class="absolute left-0 top-0 bottom-0 w-1/2 bg-black"></div>
                                  <% _ -> %>
                                    <div class="absolute right-0 top-0 bottom-0 w-1/2 bg-black"></div>
                                <% end %>
                                <%= cond do %>
                                  <% MapSet.member?(@unlocked_doors, {x, y}) and show_trap -> %>
                                    <%= case door_orientation do %>
                                      <% :north -> %>
                                        <div class="absolute top-0 left-0 right-0 h-1/2 flex items-center justify-center">
                                          <div
                                            class="w-[18px] h-[18px]"
                                            style={
                                              Renderer.bg_image_style_static(
                                                "/images/trap.png",
                                                "background-size: 18px 18px;"
                                              )
                                            }
                                            role="img"
                                            aria-label="Trap"
                                          >
                                          </div>
                                        </div>
                                      <% :south -> %>
                                        <div class="absolute bottom-0 left-0 right-0 h-1/2 flex items-center justify-center">
                                          <div
                                            class="w-[18px] h-[18px]"
                                            style={
                                              Renderer.bg_image_style_static(
                                                "/images/trap.png",
                                                "background-size: 18px 18px;"
                                              )
                                            }
                                            role="img"
                                            aria-label="Trap"
                                          >
                                          </div>
                                        </div>
                                      <% :east -> %>
                                        <div class="absolute right-0 top-0 bottom-0 w-1/2 flex items-center justify-center">
                                          <div
                                            class="w-[18px] h-[18px]"
                                            style={
                                              Renderer.bg_image_style_static(
                                                "/images/trap.png",
                                                "background-size: 18px 18px;"
                                              )
                                            }
                                            role="img"
                                            aria-label="Trap"
                                          >
                                          </div>
                                        </div>
                                      <% _ -> %>
                                        <div class="absolute left-0 top-0 bottom-0 w-1/2 flex items-center justify-center">
                                          <div
                                            class="w-[18px] h-[18px]"
                                            style={
                                              Renderer.bg_image_style_static(
                                                "/images/trap.png",
                                                "background-size: 18px 18px;"
                                              )
                                            }
                                            role="img"
                                            aria-label="Trap"
                                          >
                                          </div>
                                        </div>
                                    <% end %>
                                  <% not MapSet.member?(@unlocked_doors, {x, y}) and show_trap -> %>
                                    <%= case door_orientation do %>
                                      <% :north -> %>
                                        <div class="absolute top-0 left-0 right-0 h-1/2 flex items-center justify-start pl-1">
                                          <div
                                            class="w-[18px] h-[18px]"
                                            style={
                                              Renderer.bg_image_style_static(
                                                "/images/lock.png",
                                                "background-size: 18px 18px;"
                                              )
                                            }
                                            role="img"
                                            aria-label="Lock"
                                          >
                                          </div>
                                        </div>
                                        <div class="absolute top-0 left-0 right-0 h-1/2 flex items-center justify-end pr-1">
                                          <div
                                            class="w-[18px] h-[18px]"
                                            style={
                                              Renderer.bg_image_style_static(
                                                "/images/trap.png",
                                                "background-size: 18px 18px;"
                                              )
                                            }
                                            role="img"
                                            aria-label="Trap"
                                          >
                                          </div>
                                        </div>
                                      <% :south -> %>
                                        <div class="absolute bottom-0 left-0 right-0 h-1/2 flex items-center justify-start pl-1">
                                          <div
                                            class="w-[18px] h-[18px]"
                                            style={
                                              Renderer.bg_image_style_static(
                                                "/images/lock.png",
                                                "background-size: 18px 18px;"
                                              )
                                            }
                                            role="img"
                                            aria-label="Lock"
                                          >
                                          </div>
                                        </div>
                                        <div class="absolute bottom-0 left-0 right-0 h-1/2 flex items-center justify-end pr-1">
                                          <div
                                            class="w-[18px] h-[18px]"
                                            style={
                                              Renderer.bg_image_style_static(
                                                "/images/trap.png",
                                                "background-size: 18px 18px;"
                                              )
                                            }
                                            role="img"
                                            aria-label="Trap"
                                          >
                                          </div>
                                        </div>
                                      <% :east -> %>
                                        <div class="absolute right-0 top-0 bottom-0 w-1/2 flex items-start justify-center pt-1">
                                          <div
                                            class="w-[18px] h-[18px]"
                                            style={
                                              Renderer.bg_image_style_static(
                                                "/images/lock.png",
                                                "background-size: 18px 18px;"
                                              )
                                            }
                                            role="img"
                                            aria-label="Lock"
                                          >
                                          </div>
                                        </div>
                                        <div class="absolute right-0 top-0 bottom-0 w-1/2 flex items-end justify-center pb-1">
                                          <div
                                            class="w-[18px] h-[18px]"
                                            style={
                                              Renderer.bg_image_style_static(
                                                "/images/trap.png",
                                                "background-size: 18px 18px;"
                                              )
                                            }
                                            role="img"
                                            aria-label="Trap"
                                          >
                                          </div>
                                        </div>
                                      <% _ -> %>
                                        <div class="absolute left-0 top-0 bottom-0 w-1/2 flex items-start justify-center pt-1">
                                          <div
                                            class="w-[18px] h-[18px]"
                                            style={
                                              Renderer.bg_image_style_static(
                                                "/images/lock.png",
                                                "background-size: 18px 18px;"
                                              )
                                            }
                                            role="img"
                                            aria-label="Lock"
                                          >
                                          </div>
                                        </div>
                                        <div class="absolute left-0 top-0 bottom-0 w-1/2 flex items-end justify-center pb-1">
                                          <div
                                            class="w-[18px] h-[18px]"
                                            style={
                                              Renderer.bg_image_style_static(
                                                "/images/trap.png",
                                                "background-size: 18px 18px;"
                                              )
                                            }
                                            role="img"
                                            aria-label="Trap"
                                          >
                                          </div>
                                        </div>
                                    <% end %>
                                  <% not MapSet.member?(@unlocked_doors, {x, y}) -> %>
                                    <%= case door_orientation do %>
                                      <% :north -> %>
                                        <div class="absolute top-0 left-0 right-0 h-1/2 flex items-center justify-center">
                                          <div
                                            class="w-[18px] h-[18px]"
                                            style={
                                              Renderer.bg_image_style_static(
                                                "/images/lock.png",
                                                "background-size: 18px 18px;"
                                              )
                                            }
                                            role="img"
                                            aria-label="Lock"
                                          >
                                          </div>
                                        </div>
                                      <% :south -> %>
                                        <div class="absolute bottom-0 left-0 right-0 h-1/2 flex items-center justify-center">
                                          <div
                                            class="w-[18px] h-[18px]"
                                            style={
                                              Renderer.bg_image_style_static(
                                                "/images/lock.png",
                                                "background-size: 18px 18px;"
                                              )
                                            }
                                            role="img"
                                            aria-label="Lock"
                                          >
                                          </div>
                                        </div>
                                      <% :east -> %>
                                        <div class="absolute right-0 top-0 bottom-0 w-1/2 flex items-center justify-center">
                                          <div
                                            class="w-[18px] h-[18px]"
                                            style={
                                              Renderer.bg_image_style_static(
                                                "/images/lock.png",
                                                "background-size: 18px 18px;"
                                              )
                                            }
                                            role="img"
                                            aria-label="Lock"
                                          >
                                          </div>
                                        </div>
                                      <% _ -> %>
                                        <div class="absolute left-0 top-0 bottom-0 w-1/2 flex items-center justify-center">
                                          <div
                                            class="w-[18px] h-[18px]"
                                            style={
                                              Renderer.bg_image_style_static(
                                                "/images/lock.png",
                                                "background-size: 18px 18px;"
                                              )
                                            }
                                            role="img"
                                            aria-label="Lock"
                                          >
                                          </div>
                                        </div>
                                    <% end %>
                                  <% true -> %>
                                <% end %>
                              </div>
                            <% :room_trap -> %>
                              <div class={
                            "absolute inset-0 flex items-center justify-center" <>
                            if(MapSet.member?(@sprung_traps, {x, y}), do: " animate-bounce", else: "")
                          }>
                                <div
                                  class="w-[32px] h-[32px]"
                                  style={
                                    Renderer.bg_image_style_static(
                                      "/images/trap.png",
                                      "background-size: 32px 32px;"
                                    )
                                  }
                                  role="img"
                                  aria-label="Trap"
                                >
                                </div>
                              </div>
                            <% :treasure -> %>
                              <div class="absolute inset-0 flex items-center justify-center">
                                <div
                                  class="w-[32px] h-[32px]"
                                  style={
                                    Renderer.bg_image_style_static(
                                      "/images/chest.png",
                                      "background-size: 32px 32px;"
                                    )
                                  }
                                  role="img"
                                  aria-label="Treasure"
                                >
                                </div>
                              </div>
                            <% :trapped_treasure -> %>
                              <div class="absolute inset-0">
                                <!-- Always show full-size chest -->
                                <div class="absolute inset-0 flex items-center justify-center">
                                  <div
                                    class="w-[32px] h-[32px]"
                                    style={
                                      Renderer.bg_image_style_static(
                                        "/images/chest.png",
                                        "background-size: 32px 32px;"
                                      )
                                    }
                                    role="img"
                                    aria-label="Treasure"
                                  >
                                  </div>
                                </div>
                                <!-- Show skull overlay when trap is revealed (same size as door trap icons) -->
                                <%= if show_trap do %>
                                  <div class="absolute top-0 right-0 w-[18px] h-[18px] flex items-center justify-center">
                                    <div
                                      class="w-[18px] h-[18px]"
                                      style={
                                        Renderer.bg_image_style_static(
                                          "/images/trap.png",
                                          "background-size: 18px 18px;"
                                        )
                                      }
                                      role="img"
                                      aria-label="Trap"
                                    >
                                    </div>
                                  </div>
                                <% end %>
                              </div>
                            <% :torch -> %>
                              <div class="absolute inset-0 flex items-center justify-center z-20">
                                <div
                                  class="w-[32px] h-[32px]"
                                  style={
                                    Renderer.bg_image_style_static(
                                      "/images/torch.png",
                                      "background-size: 32px 32px;"
                                    )
                                  }
                                  role="img"
                                  aria-label="Torch"
                                >
                                </div>
                                <!-- Torch glow effect (similar to player but without the dot) -->
                                <div
                                  class="absolute inset-0 pointer-events-none"
                                  style="animation: torch-flicker 0.8s ease-in-out infinite alternate; box-shadow: 0 0 12px 6px rgba(251,191,36,0.4), 0 0 24px 12px rgba(251,191,36,0.2);"
                                >
                                </div>
                              </div>
                            <% :stair_up -> %>
                              <!-- Stair background tile -->
                              <div
                                class="absolute inset-0 w-full h-full tile-background"
                                style={
                                  Renderer.bg_image_style_static(
                                    Renderer.random_stair_tile_image(
                                      {x, y},
                                      @dungeon.transition_theme
                                    ),
                                    "background-size: cover;"
                                  )
                                }
                                role="img"
                                aria-label="Stair Tile"
                              >
                              </div>
                              <span class="absolute inset-0 flex items-center justify-center text-[20px] text-green-600 font-bold">
                                ↑
                              </span>
                            <% :stair_down -> %>
                              <!-- Stair background tile -->
                              <div
                                class="absolute inset-0 w-full h-full tile-background"
                                style={
                                  Renderer.bg_image_style_static(
                                    Renderer.random_stair_tile_image(
                                      {x, y},
                                      @dungeon.transition_theme
                                    ),
                                    "background-size: cover;"
                                  )
                                }
                                role="img"
                                aria-label="Stair Tile"
                              >
                              </div>
                              <span class="absolute inset-0 flex items-center justify-center text-[20px] text-green-600 font-bold">
                                ↓
                              </span>
                            <% :bread -> %>
                              <span class="absolute inset-0 flex items-center justify-center">
                                <div
                                  class="w-[32px] h-[32px]"
                                  style={
                                    Renderer.bg_image_style_static(
                                      "/images/bread.png",
                                      "background-size: 32px 32px;"
                                    )
                                  }
                                  role="img"
                                  aria-label="Bread"
                                >
                                </div>
                              </span>
                            <% :cheese -> %>
                              <span class="absolute inset-0 flex items-center justify-center">
                                <div
                                  class="w-[32px] h-[32px]"
                                  style={
                                    Renderer.bg_image_style_static(
                                      "/images/cheese.png",
                                      "background-size: 32px 32px;"
                                    )
                                  }
                                  role="img"
                                  aria-label="Cheese"
                                >
                                </div>
                              </span>
                            <% :grapes -> %>
                              <span class="absolute inset-0 flex items-center justify-center">
                                <div
                                  class="w-[32px] h-[32px]"
                                  style={
                                    Renderer.bg_image_style_static(
                                      "/images/grapes.png",
                                      "background-size: 32px 32px;"
                                    )
                                  }
                                  role="img"
                                  aria-label="Grapes"
                                >
                                </div>
                              </span>
                            <% :healing_potion -> %>
                              <span class="absolute inset-0 flex items-center justify-center">
                                <div
                                  class="w-[32px] h-[32px]"
                                  style={
                                    Renderer.bg_image_style_static(
                                      "/images/healing_potion.png",
                                      "background-size: 32px 32px;"
                                    )
                                  }
                                  role="img"
                                  aria-label="Healing Potion"
                                >
                                </div>
                              </span>
                            <% :pile_of_bones -> %>
                              <span class="absolute inset-0 flex items-center justify-center">
                                <div
                                  class="w-[32px] h-[32px]"
                                  style={
                                    Renderer.bg_image_style_static(
                                      "/images/pile_of_bones.png",
                                      "background-size: 32px 32px;"
                                    )
                                  }
                                  role="img"
                                  aria-label="Pile of Bones"
                                >
                                </div>
                              </span>
                            <% :road -> %>
                              <!-- Road tiles are handled by background texture only -->
                            <% :shrub -> %>
                              <!-- Shrub tiles are handled by background texture only -->
                            <% :wall -> %>
                              <!-- Wall tiles are handled by background texture only -->
                            <% :floor -> %>
                              <!-- Floor tiles are handled by background texture only -->
                            <% :corridor -> %>
                              <!-- Corridor tiles are handled by background texture only -->
                            <% {:building_label, building_number} -> %>
                              <%= if revealed do %>
                                <div class="absolute inset-0 flex items-center justify-center">
                                  <div class="bg-amber-900 bg-opacity-60 px-2 py-1 rounded text-[14px] font-bold text-white">
                                    {building_number}
                                  </div>
                                </div>
                              <% end %>
                            <% _ -> %>
                              <!-- Fallback for unhandled tile types - show a placeholder -->
                              <div class="absolute inset-0 flex items-center justify-center">
                                <div class="bg-red-600 bg-opacity-50 text-white text-xs p-1 rounded">
                                  ?
                                </div>
                              </div>
                          <% end %>
                        <% end %>

                        <!-- Player icon overlay -->
                        <%= if @player_position == {x, y} and revealed do %>
                          <div
                            class="absolute inset-0 z-30 player-token"
                            style={
                              get_player_transform_style(@player_visual_position, @player_position)
                            }
                          >
                            <div class="absolute inset-0 flex items-center justify-center">
                              <div
                                class="w-[48px] h-[48px]"
                                style={
                                  Renderer.bg_image_style_static(
                                    get_player_sprite_path(
                                      @player_facing,
                                      @torch_burn_time,
                                      @dungeon.fog_type
                                    ),
                                    "background-size: 48px 48px;"
                                  )
                                }
                                role="img"
                                aria-label="Player"
                              >
                              </div>
                              <!-- Torch glow effect (only when torch is lit and not daylight theme) -->
                              <%= if @torch_burn_time > 0 and @dungeon.fog_type != "daylight" do %>
                                <div
                                  class={get_torch_glow_position(@player_facing)}
                                  style="animation: torch-flicker 0.8s ease-in-out infinite alternate; box-shadow: 0 0 12px 6px rgba(251,191,36,0.4), 0 0 24px 12px rgba(251,191,36,0.2);"
                                >
                                </div>
                                <style>
                                  @keyframes torch-flicker {
                                    0% {
                                      opacity: 0.6;
                                      transform: scale(0.9);
                                      box-shadow: 0 0 10px 5px rgba(251,191,36,0.3), 0 0 20px 10px rgba(251,191,36,0.15);
                                    }
                                    25% {
                                      opacity: 0.9;
                                      transform: scale(1.1);
                                      box-shadow: 0 0 16px 8px rgba(251,191,36,0.5), 0 0 32px 16px rgba(251,191,36,0.25);
                                    }
                                    50% {
                                      opacity: 0.7;
                                      transform: scale(0.95);
                                      box-shadow: 0 0 12px 6px rgba(251,191,36,0.35), 0 0 24px 12px rgba(251,191,36,0.18);
                                    }
                                    75% {
                                      opacity: 0.95;
                                      transform: scale(1.05);
                                      box-shadow: 0 0 14px 7px rgba(251,191,36,0.45), 0 0 28px 14px rgba(251,191,36,0.22);
                                    }
                                    100% {
                                      opacity: 0.8;
                                      transform: scale(1.0);
                                      box-shadow: 0 0 12px 6px rgba(251,191,36,0.4), 0 0 24px 12px rgba(251,191,36,0.2);
                                    }
                                  }
                                </style>
                              <% end %>
                            </div>
                            <%= if @player_trapped do %>
                              <div class="absolute top-0 right-0 w-[16px] h-[16px] flex items-center justify-center animate-bounce">
                                <img
                                  src="/images/trap.png"
                                  alt="Trap"
                                  class="w-[18px] h-[18px] object-contain"
                                />
                              </div>
                            <% end %>
                            <%= if @show_encounter_dialog do %>
                              <span class="absolute top-0 left-0 text-[16px] text-yellow-500 animate-pulse">
                                <img
                                  src="/images/swords.png"
                                  alt="Combat"
                                  class={image_classes(:small_icon)}
                                />
                              </span>
                            <% end %>
                          </div>
                        <% end %>
                      </div>
                    <% end %>
                  </div>
                <% end %>
              </div>
            <% end %>

            <!-- Mobile Dashboard Stats - Hidden on large screens -->
            <div class="lg:hidden mt-4 character-dashboard">
              <div class="grid grid-cols-3 gap-2">
                <!-- Map Toggle -->
                <div class="p-2 bg-gray-700 rounded">
                  <button
                    class="w-full h-full flex flex-col items-center justify-center"
                    phx-click="toggle_map_mobile"
                    title="Toggle Map View"
                  >
                    <div class="flex items-center">
                      <span class="text-xs text-gray-300">Map</span>
                      <%= if @show_map_mobile do %>
                        <img src="/images/up_arrow.png" alt="Hide" class="w-6 h-6 ml-1" />
                      <% else %>
                        <img src="/images/down_arrow.png" alt="Show" class="w-6 h-6 ml-1" />
                      <% end %>
                    </div>
                  </button>
                </div>

                <!-- Torch -->
                <div class="p-2 bg-gray-700 rounded">
                  <div class="flex justify-between items-center">
                    <img
                      src="/images/torch.png"
                      alt="Torch"
                      class={inline_image_classes(:small_icon)}
                    />
                    <span class="text-sm text-amber-400">{@torch_burn_time}%</span>
                  </div>
                  <div class="w-full bg-gray-600 rounded-full h-1 mt-1">
                    <div
                      class="bg-amber-500 h-1 rounded-full transition-all duration-300"
                      style={"width: #{@torch_burn_time}%"}
                    >
                    </div>
                  </div>
                </div>

                <!-- Hit Points -->
                <div class="p-2 bg-gray-700 rounded">
                  <div class="flex justify-between items-center">
                    <div class="flex items-center">
                      <img
                        src="/images/heart.png"
                        alt="Health"
                        class={inline_image_classes(:small_icon)}
                      />
                      <span class="text-sm text-gray-300 ml-1">HP</span>
                    </div>
                    <span class={[
                      "text-sm",
                      cond do
                        @player_hit_points > @max_hit_points * 0.6 -> "text-green-400"
                        @player_hit_points > @max_hit_points * 0.3 -> "text-yellow-400"
                        true -> "text-red-400"
                      end
                    ]}>
                      {@player_hit_points}/{@max_hit_points}
                    </span>
                  </div>
                  <div class="w-full bg-gray-600 rounded-full h-1 mt-1">
                    <div
                      class={[
                        "h-1 rounded-full transition-all duration-300",
                        cond do
                          @player_hit_points > @max_hit_points * 0.6 -> "bg-green-500"
                          @player_hit_points > @max_hit_points * 0.3 -> "bg-yellow-500"
                          true -> "bg-red-500"
                        end
                      ]}
                      style={"width: #{(@player_hit_points / @max_hit_points * 100)}%"}
                    >
                    </div>
                  </div>
                </div>
              </div>

              <!-- Level & XP (Combined) -->
              <div class="mt-2 p-2 bg-gray-700 rounded">
                <div class="flex justify-between items-center mb-2">
                  <div class="flex items-center">
                    <img src="/images/xp.png" alt="Level" class={inline_image_classes(:small_icon)} />
                    <span class="text-sm text-gray-300 ml-1">
                      Level {@player_level}
                    </span>
                  </div>
                  <span class="text-sm text-purple-400">{@player_xp} XP</span>
                </div>
                <% next_level_xp = Dungeon.PlayerStats.xp_needed_for_next_level(@player_xp) %>
                <% current_level_xp = Dungeon.PlayerStats.xp_required_for_level(@player_level) %>
                <% xp_progress = @player_xp - current_level_xp %>
                <% xp_for_this_level =
                  Dungeon.PlayerStats.xp_required_for_level(@player_level + 1) - current_level_xp %>
                <div class="w-full bg-gray-600 rounded-full h-1">
                  <div
                    class="bg-purple-500 h-1 rounded-full transition-all duration-300"
                    style={"width: #{if xp_for_this_level > 0, do: (xp_progress / xp_for_this_level * 100), else: 0}%"}
                  >
                  </div>
                </div>
                <div class="text-xs text-gray-400 mt-1 text-center">
                  {next_level_xp} XP to next level
                </div>
              </div>

              <!-- Armor Class | Attack Bonus -->
              <div class="grid grid-cols-2 gap-2 mt-2">
                <!-- Armor Class -->
                <div class="p-2 bg-gray-700 rounded">
                  <div class="flex justify-between items-center">
                    <div class="flex items-center">
                      <img
                        src="/images/shield.png"
                        alt="Armor Class"
                        class={inline_image_classes(:small_icon)}
                      />
                      <span class="text-sm text-gray-300 ml-1">AC</span>
                    </div>
                    <span class="text-sm text-blue-400">{@armor_class}</span>
                  </div>
                </div>

                <!-- Attack Bonus -->
                <div class="p-2 bg-gray-700 rounded">
                  <div class="flex justify-between items-center">
                    <div class="flex items-center">
                      <img
                        src="/images/bullseye.png"
                        alt="Attack Bonus"
                        class={inline_image_classes(:small_icon)}
                      />
                      <span class="text-sm text-gray-300 ml-1">AB</span>
                    </div>
                    <span class="text-sm text-green-400">+{@attack_bonus}</span>
                  </div>
                </div>
              </div>

              <!-- Weapon | Damage -->
              <div class="grid grid-cols-2 gap-2 mt-2">
                <!-- Weapon -->
                <div class="p-2 bg-gray-700 rounded">
                  <div class="flex justify-between items-center">
                    <img
                      src="/images/shortsword.png"
                      alt="Weapon"
                      class={inline_image_classes(:small_icon)}
                    />
                    <span class="text-sm text-white">{String.slice(@player_weapon, 0, 10)}</span>
                  </div>
                </div>

                <!-- Damage -->
                <div class="p-2 bg-gray-700 rounded">
                  <div class="flex justify-between items-center">
                    <img
                      src="/images/damage.png"
                      alt="Damage"
                      class={inline_image_classes(:small_icon)}
                    />
                    <span class="text-sm text-red-400">{@weapon_damage_dice}</span>
                  </div>
                </div>
              </div>

              <!-- Gold | Inventory -->
              <div class="grid grid-cols-2 gap-2 mt-2">
                <!-- Gold -->
                <div class="p-2 bg-gray-700 rounded">
                  <div class="flex justify-between items-center">
                    <img src="/images/gold.png" alt="Gold" class={inline_image_classes(:small_icon)} />
                    <span class="text-sm text-yellow-400">{@player_gold} gp</span>
                  </div>
                </div>

                <!-- Inventory -->
                <%= if length(@special_items) > 0 do %>
                  <div
                    class="p-2 bg-gray-700 rounded hover:bg-gray-600 cursor-pointer transition-colors"
                    phx-click="show_special_items_list"
                    style="pointer-events: auto !important;"
                  >
                    <div class="flex justify-between items-center">
                      <img
                        src="/images/special_item.png"
                        alt="Items"
                        class={inline_image_classes(:small_icon)}
                      />
                      <span class="text-sm text-white">
                        {length(@special_items)}
                      </span>
                    </div>
                  </div>
                <% else %>
                  <div class="p-2 bg-gray-700 rounded">
                    <div class="flex justify-between items-center">
                      <img
                        src="/images/special_item.png"
                        alt="Items"
                        class={inline_image_classes(:small_icon)}
                      />
                      <span class="text-sm text-gray-500">
                        {length(@special_items)}
                      </span>
                    </div>
                  </div>
                <% end %>
              </div>

              <!-- Rumors | Achievements -->
              <div class="grid grid-cols-2 gap-2 mt-2">
                <!-- Rumors -->
                <%= if length(@rumors) > 0 do %>
                  <div
                    class="p-2 bg-gray-700 rounded hover:bg-gray-600 cursor-pointer transition-colors"
                    phx-click="show_rumors_list"
                    style="pointer-events: auto !important;"
                  >
                    <div class="flex justify-between items-center">
                      <img
                        src="/images/open_scroll.png"
                        alt="Rumors"
                        class={inline_image_classes(:small_icon)}
                      />
                      <span class="text-sm text-white">
                        {length(@rumors)}
                      </span>
                    </div>
                  </div>
                <% else %>
                  <div class="p-2 bg-gray-700 rounded">
                    <div class="flex justify-between items-center">
                      <img
                        src="/images/open_scroll.png"
                        alt="Rumors"
                        class={inline_image_classes(:small_icon)}
                      />
                      <span class="text-sm text-gray-500">
                        {length(@rumors)}
                      </span>
                    </div>
                  </div>
                <% end %>

                <!-- Achievements -->
                <%= if length(@achievements) > 0 do %>
                  <div
                    class="p-2 bg-gray-700 rounded hover:bg-gray-600 cursor-pointer transition-colors"
                    phx-click="show_achievements_list"
                    style="pointer-events: auto !important;"
                  >
                    <div class="flex justify-between items-center">
                      <img
                        src="/images/victory.png"
                        alt="Achievements"
                        class={inline_image_classes(:small_icon)}
                      />
                      <span class="text-sm text-white">
                        {length(@achievements)}
                      </span>
                    </div>
                  </div>
                <% else %>
                  <div class="p-2 bg-gray-700 rounded">
                    <div class="flex justify-between items-center">
                      <img
                        src="/images/victory.png"
                        alt="Achievements"
                        class={inline_image_classes(:small_icon)}
                      />
                      <span class="text-sm text-gray-500">
                        {length(@achievements)}
                      </span>
                    </div>
                  </div>
                <% end %>
              </div>

              <!-- Alignment -->
              <div class="mt-2 p-2 bg-gray-700 rounded">
                <div class="flex justify-between items-center">
                  <div class="flex items-center">
                    <img
                      src="/images/scale.png"
                      alt="Alignment"
                      class={inline_image_classes(:small_icon)}
                    />
                    <span class="text-sm text-gray-300 ml-1">Alignment</span>
                  </div>
                  <span class={"text-sm #{Dungeon.PlayerStats.get_alignment_color(@player_alignment)}"}>
                    {String.capitalize(
                      to_string(Dungeon.PlayerStats.get_alignment_description(@player_alignment))
                    )}
                  </span>
                </div>
                <div class="w-full bg-gray-600 rounded-full h-1 mt-1">
                  <div class={Dungeon.PlayerStats.get_alignment_gradient_class(@player_alignment) <> " h-1 rounded-full"}>
                  </div>
                </div>
              </div>

              <!-- Healing Potion button if available -->
              <%= if @healing_potion_count > 0 do %>
                <div class="mt-2 p-2 bg-gray-700 rounded">
                  <div class="flex justify-between items-center">
                    <img
                      src="/images/healing_potion.png"
                      alt="Potion"
                      class={inline_image_classes(:small_icon)}
                    />
                    <button
                      class="btn btn-xs btn-success px-2"
                      phx-click={JS.push("use_healing_potion") |> JS.focus(to: "#dungeon-map")}
                      disabled={@player_hit_points >= @max_hit_points}
                    >
                      {if @healing_potion_count > 1, do: "#{@healing_potion_count}", else: "1"}
                    </button>
                  </div>
                </div>
              <% end %>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Unlock Door Dialog -->
    <DialogComponent.dialog
      show={@show_unlock_dialog}
      title="Unlock Door"
      icon={
        raw(
          "#{img_tag(if(@selected_door, do: Renderer.random_door_image(@selected_door), else: "/images/doors/door01.png"), "Door", :medium_icon)}#{img_tag("/images/lock.png", "Lock", :medium_icon)}"
        )
      }
      color_scheme="gray"
      content={
        if @selected_door && MapSet.member?(@unpickable_doors, @selected_door) do
          "The lock mechanism is damaged and can no longer be picked. You might consider breaking down the door instead.\n\n" <>
            (assigns[:door_description] || "You found a locked door.")
        else
          assigns[:door_description] ||
            "You found a locked door. Would you like to attempt to unlock it?"
        end
      }
      buttons_disabled={
        String.contains?(assigns[:door_description] || "", "Generating description...")
      }
      buttons={
        if @selected_door && MapSet.member?(@unpickable_doors, @selected_door) do
          [
            %{
              text: raw("#{inline_img_tag("/images/break_door.png", "Break Door")} Break Door"),
              action: "break_door",
              variant: "primary"
            },
            %{
              text: raw("#{inline_img_tag("/images/cancel.png", "Cancel")} Cancel"),
              action: "cancel_unlock",
              variant: "secondary"
            }
          ]
        else
          [
            %{
              text: raw("#{inline_img_tag("/images/lockpicks.png", "Pick Lock")} Pick Lock"),
              action: "pick_lock",
              variant: "primary"
            },
            %{
              text: raw("#{inline_img_tag("/images/cancel.png", "Cancel")} Cancel"),
              action: "cancel_unlock",
              variant: "secondary"
            }
          ]
        end
      }
    />

    <!-- Lock Pick Result Dialog -->
    <DialogComponent.dialog
      show={@show_lock_pick_result_dialog}
      title={if @lock_pick_success, do: "Lock Picked Successfully!", else: "Lock Pick Failed"}
      icon={
        if @lock_pick_success,
          do: raw("#{img_tag("/images/open_lock.png", "Open Lock", :medium_icon)}"),
          else: raw("#{img_tag("/images/lock.png", "Lock", :medium_icon)}")
      }
      color_scheme={if @lock_pick_success, do: "green", else: "red"}
      content={
        if @lock_pick_success do
          "You successfully pick the lock!\n(Rolled #{@lock_pick_d20_roll} + #{@lock_pick_dex_bonus} dexterity = #{@lock_pick_roll} vs DC 12)\n\nThe door is now unlocked and you can enter."
        else
          "You fail to pick the lock.\n(Rolled #{@lock_pick_d20_roll} + #{@lock_pick_dex_bonus} dexterity = #{@lock_pick_roll} vs DC 12)\n\nThe lock mechanism is damaged and can no longer be picked. You might consider breaking down the door instead."
        end
      }
      buttons={[
        %{
          text: "Continue",
          action: "dismiss_lock_pick_result",
          variant: if(@lock_pick_success, do: "success", else: "error")
        }
      ]}
    />

    <!-- Break Door Result Dialog -->
    <DialogComponent.dialog
      show={@show_break_door_result_dialog}
      title={if @break_door_success, do: "Door Broken!", else: "Break Door Failed"}
      icon={
        if @break_door_success,
          do: raw("#{img_tag("/images/break_door.png", "Break Door", :medium_icon)}"),
          else: raw("#{img_tag("/images/lock.png", "Lock", :medium_icon)}")
      }
      color_scheme={if @break_door_success, do: "green", else: "red"}
      content={
        if @break_door_success do
          "You break down the door with force!\n(Rolled #{@break_door_roll} vs DC 13)\n\nThe loud CRASH echoes through the dungeon as splintered wood flies everywhere. The door is now unlocked and you can enter."
        else
          "You fail to break down the door.\n(Rolled #{@break_door_roll} vs DC 13)\n\nDespite the loud banging and crashing sounds, the door remains stubbornly locked."
        end
      }
      buttons={[
        %{
          text: "Continue",
          action: "dismiss_break_door_result",
          variant: if(@break_door_success, do: "success", else: "error")
        }
      ]}
    />

    <!-- Open Door Dialog -->
    <DialogComponent.dialog
      show={@show_open_door_dialog}
      title="Open Door"
      icon={
        raw(
          "#{img_tag(if(@selected_open_door, do: Renderer.random_door_image(@selected_open_door), else: "/images/doors/door01.png"), "Door", :medium_icon)}"
        )
      }
      color_scheme="green"
      content={
        assigns[:open_door_description] || "You stand before an open door. Would you like to enter?"
      }
      buttons_disabled={
        String.contains?(assigns[:open_door_description] || "", "Generating description...")
      }
      buttons={[
        %{
          text: raw("#{inline_img_tag("/images/doorway.png", "Enter")} Enter"),
          action: "enter_door",
          variant: "primary"
        },
        %{
          text: raw("#{inline_img_tag("/images/cancel.png", "Cancel")} Cancel"),
          action: "cancel_open_door",
          variant: "secondary"
        }
      ]}
    />

    <!-- Stair Dialog -->
    <DialogComponent.dialog
      show={@show_stair_dialog}
      title="Staircase"
      icon={raw("#{img_tag("/images/stairway.png", "Stairway", :medium_icon)}")}
      color_scheme="blue"
      content={
        assigns[:stair_description] ||
          "You stand before a staircase leading to the next level. Would you like to proceed?"
      }
      buttons_disabled={
        String.contains?(assigns[:stair_description] || "", "Generating description...")
      }
      buttons={[
        %{
          text:
            if(@dungeon.theme_direction == :up,
              do: raw("#{inline_img_tag("/images/up_arrow.png", "Up")} Go Up"),
              else: raw("#{inline_img_tag("/images/down_arrow.png", "Down")} Go Down")
            ),
          action: "use_stair",
          variant: "primary"
        },
        %{
          text: raw("#{inline_img_tag("/images/cancel.png", "Cancel")} Cancel"),
          action: "cancel_stair",
          variant: "secondary"
        }
      ]}
    />

    <!-- Waypoint Dialog -->
    <DialogComponent.dialog
      show={@show_waypoint_dialog}
      title="Waypoint Marker"
      icon={
        case @selected_waypoint do
          nil ->
            raw("#{img_tag("/images/map_links/outdoor_waypoint1.png", "Waypoint", :medium_icon)}")

          {x, y} ->
            case Map.get(@dungeon.grid, {x, y}) do
              {:waypoint, waypoint_number} ->
                raw(
                  "#{img_tag("/images/map_links/outdoor_waypoint#{waypoint_number}.png", "Waypoint", :medium_icon)}"
                )

              _ ->
                raw("#{img_tag("/images/map_links/outdoor_waypoint1.png", "Waypoint", :medium_icon)}")
            end
        end
      }
      color_scheme="green"
      content={
        assigns[:waypoint_description] ||
          "You stand before a waypoint marker pointing to a new area. Would you like to travel there?"
      }
      buttons_disabled={
        String.contains?(assigns[:waypoint_description] || "", "Generating description...")
      }
      buttons={[
        %{
          text: raw("#{inline_img_tag("/images/right_arrow.png", "Travel")} Travel"),
          action: "use_waypoint",
          variant: "primary"
        },
        %{
          text: raw("#{inline_img_tag("/images/cancel.png", "Cancel")} Cancel"),
          action: "cancel_waypoint",
          variant: "secondary"
        }
      ]}
    />

    <!-- Secret Door Dialog -->
    <DialogComponent.dialog
      show={@show_secret_door_dialog}
      title="Secret Door Discovered!"
      icon={raw("#{img_tag("/images/secret.png", "Secret Door", :medium_icon)}")}
      color_scheme="blue"
      content="You've discovered a hidden secret door! The wall conceals a passage that was cleverly disguised."
      buttons={[
        %{
          text: "Continue",
          action: "dismiss_secret_door",
          variant: "primary"
        }
      ]}
    />

    <!-- Map Link Dialog -->
    <DialogComponent.dialog
      show={@show_map_link_dialog}
      title="Passage Found"
      icon={
        case @selected_map_link do
          nil ->
            raw("#{img_tag("/images/map_links/dungeon_entrance1.png", "Passage", :medium_icon)}")

          {x, y} ->
            case Map.get(@dungeon.grid, {x, y}) do
              {:cavern_entrance, entrance_number} ->
                raw(
                  "#{img_tag("/images/map_links/cavern_entrance#{entrance_number}.png", "Cavern Entrance", :medium_icon)}"
                )

              {:dungeon_entrance, entrance_number} ->
                raw(
                  "#{img_tag("/images/map_links/dungeon_entrance#{entrance_number}.png", "Dungeon Entrance", :medium_icon)}"
                )

              {:cavern_exit, exit_number} ->
                raw(
                  "#{img_tag("/images/map_links/cavern_exit#{exit_number}.png", "Cavern Exit", :medium_icon)}"
                )

              {:dungeon_exit, exit_number} ->
                raw(
                  "#{img_tag("/images/map_links/dungeon_exit#{exit_number}.png", "Dungeon Exit", :medium_icon)}"
                )

              _ ->
                raw("#{img_tag("/images/map_links/dungeon_entrance1.png", "Passage", :medium_icon)}")
            end
        end
      }
      color_scheme="blue"
      content={
        assigns[:map_link_description] ||
          "You've discovered a passage to another area. Would you like to travel through it?"
      }
      buttons_disabled={
        String.contains?(assigns[:map_link_description] || "", "Generating description...")
      }
      buttons={[
        %{
          text: raw("#{inline_img_tag("/images/right_arrow.png", "Travel")} Enter"),
          action: "use_map_link",
          variant: "primary"
        },
        %{
          text: raw("#{inline_img_tag("/images/cancel.png", "Cancel")} Cancel"),
          action: "cancel_map_link",
          variant: "secondary"
        }
      ]}
    />

    <!-- Trap Dialog -->
    <DialogComponent.dialog
      show={@show_trap_dialog}
      title="Trap Triggered!"
      icon={@trap_icon}
      color_scheme="red"
      content={@trap_message}
      buttons_disabled={String.contains?(@trap_message || "", "Generating description...")}
      buttons={[
        %{
          text: raw("#{inline_img_tag("/images/swords.png", "Combat")} Continue"),
          action: "dismiss_trap",
          variant: "error"
        }
      ]}
    />

    <!-- Encounter Dialog -->
    <DialogComponent.dialog
      show={@show_encounter_dialog}
      title="You have an encounter!"
      icon={@encounter_icon}
      color_scheme="yellow"
      content={@encounter_message}
      scrollable={false}
      max_width={false}
      buttons={[
        %{
          text: raw("#{inline_img_tag("/images/swords.png", "Fight")} Fight!"),
          action: "fight_encounter",
          variant: "warning"
        },
        %{
          text: raw("#{inline_img_tag("/images/evade.png", "Evade")} Evade"),
          action: "evade_encounter",
          variant: "secondary"
        }
      ]}
    />

    <!-- Evade Dialog -->
    <DialogComponent.dialog
      show={@show_evade_dialog}
      title={if @evade_success, do: "Evade Successful!", else: "Evade Failed!"}
      icon={raw("#{img_tag("/images/evade.png", "Evade", :medium_icon)}")}
      color_scheme={if @evade_success, do: "green", else: "red"}
      content={@evade_message}
      buttons={[
        %{
          text:
            if(@evade_success,
              do: "Continue",
              else: raw("#{inline_img_tag("/images/swords.png", "Fight")} Fight!")
            ),
          action: "dismiss_evade",
          variant: if(@evade_success, do: "success", else: "warning")
        }
      ]}
    />

    <!-- Treasure Dialog -->
    <DialogComponent.dialog
      show={@show_treasure_dialog}
      title="Treasure Found!"
      icon={@treasure_icon}
      color_scheme="green"
      content={@treasure_message}
      buttons={[%{text: "Collect Treasure", action: "dismiss_treasure", variant: "success"}]}
    />

    <!-- Torch Dialog -->
    <DialogComponent.dialog
      show={@show_torch_dialog}
      title="Torch Found!"
      icon={@torch_icon}
      color_scheme="green"
      content={@torch_message}
      buttons={[%{text: "Take Torch", action: "dismiss_torch", variant: "success"}]}
    />

    <!-- Food Dialog -->
    <DialogComponent.dialog
      show={@show_food_dialog}
      title="Food Found!"
      icon={@food_icon}
      color_scheme="green"
      content={@food_message}
      buttons={[%{text: "Eat Food", action: "dismiss_food", variant: "success"}]}
    />

    <!-- Healing Potion Dialog -->
    <DialogComponent.dialog
      show={@show_healing_potion_dialog}
      title="Healing Potion Found!"
      icon={@healing_potion_icon}
      color_scheme="green"
      content={@healing_potion_message}
      buttons={[%{text: "Take Potion", action: "dismiss_healing_potion", variant: "success"}]}
    />

    <!-- Special Feature Dialog -->
    <DialogComponent.dialog
      show={@show_special_feature_dialog}
      title="Something Interesting!"
      icon={@special_feature_icon}
      color_scheme="blue"
      content={@special_feature_message}
      buttons_disabled={String.contains?(@special_feature_message || "", "Generating description...")}
      buttons={
        if @discovered_feature_position &&
             MapSet.member?(@investigated_features, @discovered_feature_position) do
          # Already investigated - just show close button
          [
            %{
              text: raw("#{inline_img_tag("/images/cancel.png", "Close")} Already Investigated"),
              action: "dismiss_special_feature",
              variant: "secondary"
            }
          ]
        else
          # Not yet investigated - show both investigate and skip options
          [
            %{
              text:
                raw("#{inline_img_tag("/images/magnifying_glass.png", "Investigate")} Investigate"),
              action: "investigate_feature",
              variant: "info"
            },
            %{
              text: raw("#{inline_img_tag("/images/cancel.png", "Skip")} Skip"),
              action: "dismiss_special_feature",
              variant: "secondary"
            }
          ]
        end
      }
    />

    <!-- Room/Corridor Label Dialog -->
    <DialogComponent.dialog
      show={@show_label_dialog}
      title="Location Info"
      icon={@label_icon}
      color_scheme="green"
      content={@label_message}
      buttons_disabled={String.contains?(@label_message || "", "Generating description...")}
      buttons={[%{text: "Continue", action: "dismiss_label", variant: "success"}]}
    />

    <!-- Rumors List Dialog -->
    <%= if @show_rumors_list_dialog do %>
      <div class="fixed inset-0 bg-black bg-opacity-25 flex items-center justify-center z-50">
        <div class="bg-black bg-opacity-25 backdrop-blur-sm p-6 rounded-lg shadow-xl border-2 border-gray-400 max-w-lg w-full mx-4">
          <div class="flex items-center mb-4">
            <img
              src="/images/open_scroll.png"
              alt="Rumors"
              class={image_classes(:large_icon) <> " mr-3"}
            />
            <h3 class="text-lg font-bold text-white">Learned Rumors</h3>
          </div>

          <div class="mb-6 max-h-64 overflow-y-auto">
            <%= if length(@rumors) == 0 do %>
              <div class="text-gray-200">
                No rumors have been discovered yet. Investigate special features to learn rumors!
              </div>
            <% else %>
              <div class="space-y-3">
                <p class="text-sm text-gray-300 mb-4">
                  Click on any rumor to view it in detail:
                </p>
                <%= for {rumor, index} <- Enum.with_index(@rumors) do %>
                  <div
                    class="p-3 bg-gray-800 rounded-lg cursor-pointer hover:bg-gray-700 transition-colors border border-gray-600"
                    phx-click="view_rumor"
                    phx-value-index={index}
                  >
                    <div class="flex items-start gap-2">
                      <span class="text-gray-400 font-mono text-sm shrink-0">#{index + 1}.</span>
                      <p class="text-sm text-gray-200">
                        {String.slice(rumor, 0, 120)}{if String.length(rumor) > 120, do: "..."}
                      </p>
                    </div>
                  </div>
                <% end %>
              </div>
            <% end %>
          </div>

          <div class="flex justify-center">
            <button
              class="btn btn-secondary"
              phx-click={JS.push("dismiss_rumors_list") |> JS.focus(to: "#dungeon-map")}
            >
              Close
            </button>
          </div>
        </div>
      </div>
    <% end %>

    <!-- Rumor Dialog -->
    <DialogComponent.dialog
      show={@show_rumor_dialog}
      title={
        if Map.get(assigns, :rumor_first_found, false),
          do: "Rumor Discovered!",
          else: "Rumor Detail"
      }
      icon={@rumor_icon}
      color_scheme="gray"
      content={@rumor_message}
      buttons={[
        if Map.get(assigns, :rumor_first_found, false) do
          %{text: "Note Rumor", action: "dismiss_rumor", variant: "info"}
        else
          %{text: "Close", action: "dismiss_rumor", variant: "secondary"}
        end
      ]}
    />

    <!-- Achievement Dialog -->
    <DialogComponent.dialog
      show={@show_achievement_dialog}
      title="Achievement Unlocked!"
      icon={@achievement_icon}
      color_scheme="yellow"
      content={@achievement_message}
      buttons={[%{text: "Continue", action: "dismiss_achievement", variant: "success"}]}
    />

    <!-- Level Up Dialog -->
    <DialogComponent.dialog
      show={@show_level_up_dialog}
      title="Level Up!"
      icon={raw("#{img_tag("/images/xp.png", "Level Up", :medium_icon)}")}
      color_scheme="yellow"
      content={"#{@level_up_message}\n\n#{@talent_gained}"}
      buttons={[%{text: "Continue", action: "dismiss_level_up", variant: "success"}]}
    />

    <!-- Achievements List Dialog -->
    <%= if @show_achievements_list_dialog do %>
      <div class="fixed inset-0 bg-black bg-opacity-25 flex items-center justify-center z-50">
        <div class="bg-black bg-opacity-25 backdrop-blur-sm p-6 rounded-lg shadow-xl border-2 border-gray-400 max-w-lg w-full mx-4">
          <div class="flex items-center mb-4">
            <img
              src="/images/victory.png"
              alt="Achievements"
              class={image_classes(:large_icon) <> " mr-3"}
            />
            <h3 class="text-lg font-bold text-white">Achievements</h3>
          </div>

          <div class="mb-6 max-h-64 overflow-y-auto">
            <%= if length(@achievements) == 0 do %>
              <div class="text-gray-200">
                No achievements unlocked yet. Complete quests and accomplish great deeds to earn achievements!
              </div>
            <% else %>
              <div class="space-y-3">
                <p class="text-sm text-gray-300 mb-4">
                  Click on any achievement to view it in detail:
                </p>
                <%= for {achievement, index} <- Enum.with_index(@achievements) do %>
                  <div
                    class="p-3 bg-gray-800 rounded-lg cursor-pointer hover:bg-gray-700 transition-colors border border-gray-600"
                    phx-click="view_achievement"
                    phx-value-index={index}
                  >
                    <div class="flex items-start gap-2">
                      <span class="text-gray-400 font-mono text-sm shrink-0">#{index + 1}.</span>
                      <p class="text-sm text-gray-200">
                        {String.slice(achievement, 0, 120)}{if String.length(achievement) > 120,
                          do: "..."}
                      </p>
                    </div>
                  </div>
                <% end %>
              </div>
            <% end %>
          </div>

          <div class="flex justify-center">
            <button
              class="btn btn-secondary"
              phx-click={JS.push("dismiss_achievements_list") |> JS.focus(to: "#dungeon-map")}
            >
              Close
            </button>
          </div>
        </div>
      </div>
    <% end %>

    <!-- Special Items List Dialog -->
    <%= if @show_special_items_list_dialog do %>
      <div class="fixed inset-0 bg-black bg-opacity-25 flex items-center justify-center z-50">
        <div class="bg-black bg-opacity-25 backdrop-blur-sm p-6 rounded-lg shadow-xl border-2 border-gray-400 max-w-lg w-full mx-4">
          <div class="flex items-center mb-4">
            <img
              src="/images/special_item.png"
              alt="Inventory"
              class={image_classes(:large_icon) <> " mr-3"}
            />
            <h3 class="text-lg font-bold text-white">Inventory</h3>
          </div>

          <div class="mb-6 max-h-64 overflow-y-auto">
            <%= if length(@special_items) == 0 do %>
              <div class="text-gray-200">
                Your inventory is empty. Investigate special features to find items!
              </div>
            <% else %>
              <div class="space-y-3">
                <p class="text-sm text-gray-300 mb-4">
                  Click on any item to view it in detail:
                </p>
                <% inventory_items = Dungeon.PlayerStats.get_inventory_status(@special_items) %>
                <%= for {item, index} <- Enum.with_index(inventory_items) do %>
                  <div
                    class="p-3 bg-gray-800 rounded-lg cursor-pointer hover:bg-gray-700 transition-colors border border-gray-600"
                    phx-click="view_special_item"
                    phx-value-index={index}
                  >
                    <div class="flex items-start gap-2">
                      <span class="text-gray-400 font-mono text-sm shrink-0">#{index + 1}.</span>
                      <div class="flex-1">
                        <div class="flex items-center justify-between">
                          <p class="text-sm text-gray-200">
                            <%= if item.wearable do %>
                              <span class="font-semibold text-blue-300">{item.name}</span>
                            <% else %>
                              <span class="text-gray-200">{item.name}</span>
                            <% end %>
                          </p>
                          <span class={
                            "text-xs px-2 py-1 rounded " <>
                              if item.status == "Worn" do
                                "bg-green-800 text-green-200 border border-green-600"
                              else
                                "bg-gray-700 text-gray-300 border border-gray-600"
                              end
                          }>
                            {item.status}
                          </span>
                        </div>
                        <p class="text-xs text-gray-400 mt-1">
                          <%= cond do %>
                            <% item.wearable_slot -> %>
                              {String.capitalize(item.wearable_slot)} • {String.slice(
                                item.description,
                                0,
                                80
                              )}{if String.length(item.description) > 80, do: "..."}
                            <% true -> %>
                              {String.slice(item.description, 0, 100)}{if String.length(
                                                                            item.description
                                                                          ) > 100,
                                                                          do: "..."}
                          <% end %>
                        </p>
                      </div>
                    </div>
                  </div>
                <% end %>
              </div>
            <% end %>
          </div>

          <div class="flex justify-center">
            <button
              class="btn btn-secondary"
              phx-click={JS.push("dismiss_special_items_list") |> JS.focus(to: "#dungeon-map")}
            >
              Close
            </button>
          </div>
        </div>
      </div>
    <% end %>

    <!-- Special Item Dialog -->
    <DialogComponent.dialog
      show={@show_special_item_dialog}
      title={
        if Map.get(assigns, :special_item_first_found, false),
          do: "Special Item Found!",
          else: "Special Item Detail"
      }
      icon={@special_item_icon}
      color_scheme="blue"
      content={@special_item_message}
      buttons={[
        if Map.get(assigns, :special_item_first_found, false) do
          %{text: "Take Item", action: "dismiss_special_item", variant: "primary"}
        else
          %{text: "Close", action: "dismiss_special_item", variant: "secondary"}
        end
      ]}
    />

    <!-- Trap Detection Dialog -->
    <DialogComponent.dialog
      show={@show_trap_detection_dialog}
      title={
        if @trap_detection_success == true do
          "Trap Disarmed!"
        else
          if @trap_detection_success == false do
            "Trap Triggered!"
          else
            "You've found a trap!"
          end
        end
      }
      icon={
        if @trap_detection_success == true do
          raw("#{img_tag("/images/green_checkmark.png", "Success", :medium_icon)}")
        else
          if @trap_detection_success == false do
            raw("#{img_tag("/images/explosion.png", "Explosion", :medium_icon)}")
          else
            raw("#{img_tag("/images/trap.png", "Trap", :medium_icon)}")
          end
        end
      }
      color_scheme={
        if @trap_detection_success == true do
          "green"
        else
          "red"
        end
      }
      content={@trap_detection_message}
      buttons={
        if @trap_detection_success != nil do
          [
            %{
              text: raw("#{inline_img_tag("/images/swords.png", "Combat")} Continue"),
              action: "dismiss_trap_detection",
              variant: "primary"
            }
          ]
        else
          [
            %{
              text: raw("#{inline_img_tag("/images/lockpicks.png", "Disarm")} Disarm"),
              action: "disarm_trap",
              variant: "primary"
            },
            %{
              text: raw("#{inline_img_tag("/images/cancel.png", "Skip")} Skip"),
              action: "skip_trap",
              variant: "secondary"
            }
          ]
        end
      }
    />

    <!-- Combat Dialog -->
    <DialogComponent.dialog
      show={@show_combat_dialog}
      title="Combat!"
      icon={raw("#{img_tag("/images/swords.png", "Combat", :medium_icon)}")}
      color_scheme="red"
      content={if @show_combat_dialog, do: CombatSystem.get_combat_content(assigns), else: ""}
      buttons={if @show_combat_dialog, do: CombatSystem.get_combat_buttons(assigns), else: []}
      max_width={false}
      scrollable={false}
    />

    <!-- Victory Dialog -->
    <DialogComponent.dialog
      show={@show_victory_dialog}
      title="Victory!"
      icon={raw("#{img_tag("/images/victory.png", "", :medium_icon)}")}
      color_scheme="green"
      content={
        if @victory_treasure_gold > 0 do
          "You have defeated the monster!\n\nYou find #{@victory_treasure_gold} gold pieces in the aftermath of the battle."
        else
          "You have defeated the monster!\n\nYou search the area but find no treasure."
        end
      }
      buttons={
        if @victory_treasure_gold > 0 do
          [
            %{
              text: raw("#{inline_img_tag("/images/gold.png", "Collect")} Collect Treasure"),
              action: "dismiss_victory",
              variant: "success"
            }
          ]
        else
          [
            %{
              text: "Continue",
              action: "dismiss_victory",
              variant: "success"
            }
          ]
        end
      }
    />

    <!-- Quest Completed Dialog -->
    <DialogComponent.dialog
      show={@show_quest_completed_dialog}
      title="Quest Completed!"
      icon={raw("#{img_tag("/images/victory.png", "Quest Complete", :medium_icon)}")}
      color_scheme="blue"
      content={
        if @completed_quest != nil do
          quest = @completed_quest
          xp_text = "You also received #{@quest_completion_xp} XP!"
          narrative = quest.completion_narrative || "Your quest is complete!"

          # Different content based on quest type
          case quest.type do
            :special_item ->
              magic_item_name =
                if quest.magic_item, do: quest.magic_item.name, else: "mysterious item"

              tldr = "You found #{magic_item_name} of #{quest.target_theme}! The rumor was true!"
              "#{tldr}\n\n#{xp_text}\n\n#{narrative}"

            :npc_kill ->
              tldr = "Quest Completed: #{quest.tldr_description}"
              "#{tldr}\n\n#{xp_text}\n\n#{narrative}"

            :monster_kill ->
              tldr = "Quest Completed: #{quest.tldr_description}"
              "#{tldr}\n\n#{xp_text}\n\n#{narrative}"

            _ ->
              "Your quest has been completed successfully!\n\n#{xp_text}\n\n#{narrative}"
          end
        else
          "Your quest has been completed successfully!"
        end
      }
      buttons={[
        %{
          text: raw("#{inline_img_tag("/images/green_checkmark.png", "Continue")} Continue"),
          action: "dismiss_quest_completed",
          variant: "success"
        }
      ]}
    />

    <!-- Death Dialog -->
    <DialogComponent.dialog
      show={@show_death_dialog}
      title="You Have Died"
      icon={raw("#{img_tag("/images/trap.png", "Death", :large_icon)}")}
      color_scheme="red"
      content={
        "Your Hit Points have reached 0<br/><br/>Your adventuring days have come to an end...<br/><br/><div class=\"flex items-center justify-center gap-2 p-3 bg-gray-800 rounded-lg mb-4\"><img src=\"/images/xp.png\" alt=\"XP\" class=\"w-6 h-6\"/> <span class=\"text-lg font-bold text-purple-400\">Final Score: #{@player_xp} XP</span></div>Choose how you wish to proceed:"
      }
      max_width={false}
      buttons={[
        %{
          text: "Continue",
          action: "death_continue",
          variant: "secondary"
        },
        %{
          text: raw("#{inline_img_tag("/images/reset.png", "New Game")} New Game"),
          action: "death_new_game",
          variant: "primary"
        }
      ]}
    />

    <!-- Revival Dialog -->
    <DialogComponent.dialog
      show={@show_revival_dialog}
      title="You're Alive!"
      icon={raw("#{img_tag("/images/empty_coin_purse.png", "Empty Coin Purse", :large_icon)}")}
      color_scheme="yellow"
      content="You're alive... somehow. You awaken dazed and bruised. Whoever brought you back wasn't generous-your gold is gone."
      buttons={[
        %{
          text: "Continue",
          action: "dismiss_revival",
          variant: "primary"
        }
      ]}
    />

    <!-- Wandering Monster Dialog -->
    <DialogComponent.dialog
      show={@show_wandering_monster_dialog}
      title="Wandering Monster!"
      icon={@wandering_monster_icon}
      color_scheme="red"
      content={@wandering_monster_message}
      buttons={[
        %{
          text: raw("#{inline_img_tag("/images/swords.png", "Fight")} Fight"),
          action: "fight_wandering_monster",
          variant: "primary"
        },
        %{
          text: raw("#{inline_img_tag("/images/evade.png", "Evade")} Evade"),
          action: "evade_wandering_monster",
          variant: "secondary"
        }
      ]}
    />

    <!-- Wandering Monster Evade Dialog -->
    <DialogComponent.dialog
      show={@show_wandering_evade_dialog}
      title={if @wandering_evade_success, do: "Evaded!", else: "Evade Failed!"}
      icon={
        if @wandering_evade_success,
          do: raw("#{img_tag("/images/evade.png", "Evade", :medium_icon)}"),
          else: raw("#{img_tag("/images/swords.png", "Combat", :medium_icon)}")
      }
      color_scheme={if @wandering_evade_success, do: "green", else: "red"}
      content={@wandering_evade_message}
      buttons={[
        %{
          text: "Continue",
          action: "dismiss_wandering_evade",
          variant: if(@wandering_evade_success, do: "success", else: "error")
        }
      ]}
    />

    <!-- NPC Dialog -->
    <DialogComponent.dialog
      show={@show_npc_dialog}
      title="NPC Dialog"
      icon={@npc_dialog_icon}
      color_scheme="blue"
      content={@npc_dialog_message}
      buttons={[
        %{
          text: raw("#{inline_img_tag("/images/chat.png", "Talk")} Talk"),
          action: "talk_to_npc",
          variant: "primary"
        },
        %{
          text: raw("#{inline_img_tag("/images/swords.png", "Fight")} Fight"),
          action: "fight_npc",
          variant: "warning"
        },
        %{text: "Leave", action: "dismiss_npc_dialog", variant: "secondary"}
      ]}
    />

    <!-- Quest Offer Dialog -->
    <DialogComponent.dialog
      show={@show_quest_offer_dialog}
      title="Quest Offer"
      icon={@quest_offer_icon}
      color_scheme="yellow"
      content={@quest_offer_message}
      buttons={
        if @offered_quest do
          [
            %{
              text: raw("#{inline_img_tag("/images/green_checkmark.png", "Accept")} Accept Quest"),
              action: "accept_quest",
              variant: "success"
            },
            %{
              text: raw("#{inline_img_tag("/images/cancel.png", "Decline")} Decline"),
              action: "decline_quest",
              variant: "secondary"
            }
          ]
        else
          [
            %{
              text: "Continue",
              action: "accept_quest",
              variant: "primary"
            }
          ]
        end
      }
    />
    """
  end

  # Helper functions used in the template will be moved here

  defp get_feature_container_classes(feature_name) do
    size = Features.get_special_feature_size(feature_name)

    if size >= 2 do
      # For features larger than the grid, use a container that can overflow but is properly centered
      "absolute inset-0 flex items-center justify-center z-20 overflow-visible"
    else
      # Size 1 and smaller features fit within the grid square
      "absolute inset-0 flex items-center justify-center z-20"
    end
  end

  defp get_monster_container_classes(monster) do
    size = monster.size || 1.0

    if size >= 2 do
      # For monsters larger than the grid, use a container that can overflow but is properly centered
      "absolute inset-0 flex items-center justify-center z-20 overflow-visible"
    else
      # Size 1 and smaller monsters fit within the grid square
      "absolute inset-0 flex items-center justify-center z-20"
    end
  end

  defp get_feature_image_size(feature_name) do
    size = Features.get_special_feature_size(feature_name)
    convert_size_to_css_classes(size)
  end

  defp get_monster_image_size(monster) do
    size = monster.size || 1.0
    convert_size_to_css_classes(size)
  end

  # Convert numeric size to CSS width/height classes
  defp convert_size_to_css_classes(size) when size <= 0.5, do: size_classes_small(size)
  defp convert_size_to_css_classes(size) when size <= 1.0, do: size_classes_medium(size)
  defp convert_size_to_css_classes(size) when size <= 2.0, do: size_classes_large(size)
  defp convert_size_to_css_classes(size) when size <= 3.0, do: size_classes_extra_large(size)
  defp convert_size_to_css_classes(_size), do: "w-[48px] h-[48px]"

  defp size_classes_small(0.25), do: "w-[12px] h-[12px]"
  defp size_classes_small(0.5), do: "w-[24px] h-[24px]"
  defp size_classes_small(_), do: "w-[24px] h-[24px]"

  defp size_classes_medium(0.75), do: "w-[36px] h-[36px]"
  defp size_classes_medium(1), do: "w-[48px] h-[48px]"
  defp size_classes_medium(_), do: "w-[48px] h-[48px]"

  defp size_classes_large(1.25), do: "w-[60px] h-[60px]"
  defp size_classes_large(1.5), do: "w-[72px] h-[72px]"
  defp size_classes_large(1.75), do: "w-[84px] h-[84px]"
  defp size_classes_large(2), do: "w-[96px] h-[96px]"
  defp size_classes_large(_), do: "w-[96px] h-[96px]"

  defp size_classes_extra_large(2.25), do: "w-[108px] h-[108px]"
  defp size_classes_extra_large(2.5), do: "w-[120px] h-[120px]"
  defp size_classes_extra_large(2.75), do: "w-[132px] h-[132px]"
  defp size_classes_extra_large(3), do: "w-[144px] h-[144px]"
  defp size_classes_extra_large(_), do: "w-[144px] h-[144px]"

  # Helper function to get player transform style for smooth movement
  defp get_player_transform_style(visual_position, logical_position) do
    {visual_x, visual_y} = visual_position
    {logical_x, logical_y} = logical_position

    # Calculate the offset to move FROM logical position TO visual position
    # This creates the effect of starting at visual position and animating to logical position
    offset_x = visual_x - logical_x
    offset_y = visual_y - logical_y

    if offset_x == 0 and offset_y == 0 do
      # When positions match, apply transition for smooth movement
      "transform: translate(0px, 0px); transition: transform 300ms ease-in-out;"
    else
      # When positions don't match, apply offset without transition (immediate positioning)
      # Use 48px (unified tile size) to match the actual grid
      pixel_offset_x = offset_x * 48
      pixel_offset_y = offset_y * 48

      "transform: translate(#{pixel_offset_x}px, #{pixel_offset_y}px);"
    end
  end

  # Helper function to get quest alignment for a monster or NPC
  defp get_quest_alignment_for_monster(monster, npc_quests) do
    # Find the quest that targets this monster or NPC
    quest =
      Enum.find(npc_quests, fn q ->
        q.target_monster == monster.name or q.target_npc == monster.name
      end)

    if quest, do: quest.quest_alignment, else: :neutral
  end

  # Helper function to get the correct player sprite path based on facing direction and torch status
  defp get_player_sprite_path(player_facing, torch_burn_time, fog_type) do
    # Determine sprite set based on torch status
    sprite_prefix =
      if fog_type == "daylight" do
        # Always use rogue2 (no torch) for daylight
        "rogue2"
      else
        if torch_burn_time > 0 do
          # with torch
          "rogue1"
        else
          # without torch
          "rogue2"
        end
      end

    # Map facing direction to sprite number
    # 0 = forward (south), 1 = back (north), 2 = left (west), 3 = right (east)
    sprite_number =
      case player_facing do
        # south
        :forward -> "0"
        # north
        :back -> "1"
        # west
        :left -> "2"
        # east
        :right -> "3"
        # default to forward
        _ -> "0"
      end

    "/images/characters/#{sprite_prefix}_#{sprite_number}.png"
  end

  # Helper function to get torch glow position based on player facing direction
  defp get_torch_glow_position(player_facing) do
    case player_facing do
      :forward ->
        # Forward (south)
        "absolute top-[8px] right-[7px] w-[1px] h-[5px] bg-yellow-400 rounded-full opacity-60"

      :back ->
        # Back (north)
        "absolute top-[8px] left-[7px] w-[1px] h-[5px] bg-yellow-400 rounded-full opacity-60"

      :left ->
        # Left (west)
        "absolute top-[8px] left-[7px] w-[1px] h-[5px] bg-yellow-400 rounded-full opacity-60"

      :right ->
        # Right (east)
        "absolute top-[8px] right-[7px] w-[1px] h-[5px] bg-yellow-400 rounded-full opacity-60"

      _ ->
        # Default to forward position
        "absolute top-[8px] right-[7px] w-[1px] h-[5px] bg-yellow-400 rounded-full opacity-60"
    end
  end
end
