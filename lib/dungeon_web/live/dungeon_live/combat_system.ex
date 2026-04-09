defmodule DungeonWeb.DungeonLive.CombatSystem do
  @moduledoc """
  Combat system for turn-based fighting between player and monsters
  """

  import Phoenix.Component, only: [assign: 3]
  alias Dungeon.{Dice, Monster}
  alias DungeonWeb.UISizing
  require Logger

  @doc """
  Initialize combat when player clicks Fight on encounter dialog
  """
  def start_combat(socket, monster_name_or_object) do
    # Create monster instance with current HP - handle both string names and monster objects
    monster =
      case monster_name_or_object do
        monster when is_map(monster) ->
          # Monster object passed directly - preserve it but ensure it has current_hit_points
          %{monster | current_hit_points: monster.hit_points, max_hit_points: monster.hit_points}

        monster_name when is_binary(monster_name) ->
          # Monster name passed - create instance from definition
          Monster.create_monster_instance(monster_name)
      end

    if monster do
      # Roll for surprise (1-2 on d6 means player surprises monster)
      surprise_roll = Dice.roll(1, 6)
      player_surprises = surprise_roll <= 2

      # Create surprise log entry
      surprise_log =
        if player_surprises do
          "Surprise! You catch the #{monster.name} off guard! (Rolled #{surprise_roll} on d6)"
        else
          "No surprise. The #{monster.name} notices your approach. (Rolled #{surprise_roll} on d6)"
        end

      socket =
        socket
        |> assign(:show_encounter_dialog, false)
        |> assign(:show_combat_dialog, true)
        |> assign(:combat_monster, monster)
        # Always start with fresh log containing only surprise roll
        |> assign(:combat_log, [surprise_log])
        |> assign(:combat_current_event, surprise_log)
        |> assign(:combat_player_attacking, false)
        |> assign(:combat_monster_attacking, false)
        |> assign(:combat_player_taking_damage, false)
        |> assign(:combat_monster_taking_damage, false)
        |> assign(:player_surprises, player_surprises)
        |> Phoenix.LiveView.push_event("play_combat_music", %{})

      if player_surprises do
        # Player gets a free backstab attack with advantage
        socket
        |> assign(:combat_round, 0)
        |> assign(:combat_current_turn, :player)
        |> assign(:combat_awaiting_player_action, true)
        |> assign(:combat_player_has_acted, false)
        |> assign(:combat_monster_has_acted, false)
        |> assign(:surprise_attack_available, true)
      else
        # No surprise, proceed with normal initiative
        start_normal_combat(socket, monster)
      end
    else
      # Monster not found, just close encounter dialog
      socket
      |> assign(:show_encounter_dialog, false)
    end
  end

  @doc """
  Start normal combat with initiative rolls
  """
  def start_normal_combat(socket, _monster) do
    # Roll initiative for both player and monster (1d6 each, player wins ties)
    player_initiative = Dice.roll(1, 6)
    monster_initiative = Dice.roll(1, 6)

    player_goes_first = player_initiative >= monster_initiative

    # Determine current turn
    current_turn = if player_goes_first, do: :player, else: :monster

    # Create combat log entry for initiative
    initiative_log =
      create_initiative_log(player_initiative, monster_initiative, player_goes_first)

    socket =
      socket
      |> assign(:combat_current_turn, current_turn)
      |> assign(:combat_round, 1)
      |> assign(:combat_log, [initiative_log | socket.assigns.combat_log])
      |> assign(:combat_current_event, initiative_log)
      |> assign(:combat_player_initiative, player_initiative)
      |> assign(:combat_monster_initiative, monster_initiative)
      |> assign(:combat_awaiting_player_action, current_turn == :player)
      |> assign(:combat_player_has_acted, false)
      |> assign(:combat_monster_has_acted, false)
      |> assign(:surprise_attack_available, false)

    # If monster goes first, process its turn with delay
    if current_turn == :monster do
      Process.send_after(self(), :process_monster_turn, 1000)
      socket
    else
      socket
    end
  end

  @doc """
  Player chooses to attack - roll d20 + attack bonus vs monster AC
  For surprise attacks, roll with advantage and double damage on hit
  """
  def player_attack(socket) do
    monster = socket.assigns.combat_monster
    attack_bonus = socket.assigns.attack_bonus
    is_surprise_attack = Map.get(socket.assigns, :surprise_attack_available, false)

    # Set player attacking animation
    socket = assign(socket, :combat_player_attacking, true)
    # Clear animation after 600ms - send message to main LiveView
    Process.send_after(self(), :clear_player_attack_animation, 600)

    if is_surprise_attack do
      # Surprise attack with advantage - roll d20 twice, take highest
      attack_roll_1 = Dice.roll(1, 20)
      attack_roll_2 = Dice.roll(1, 20)
      attack_roll = max(attack_roll_1, attack_roll_2)
      total_attack = attack_roll + attack_bonus

      advantage_text =
        "Backstab with advantage! Rolled #{attack_roll_1} and #{attack_roll_2}, taking #{attack_roll}"

      if total_attack >= monster.armor_class do
        # Hit! Roll backstab damage (double weapon damage)
        damage_1 = Dice.roll_dice_string(socket.assigns.weapon_damage_dice)
        damage_2 = Dice.roll_dice_string(socket.assigns.weapon_damage_dice)
        total_damage = damage_1 + damage_2

        new_monster_hp = max(0, monster.current_hit_points - total_damage)
        updated_monster = Map.put(monster, :current_hit_points, new_monster_hp)

        # Create log entry for backstab
        hit_log =
          "BACKSTAB! #{advantage_text} + #{attack_bonus} = #{total_attack} vs AC #{monster.armor_class}. HIT for #{total_damage} damage! (#{damage_1} + #{damage_2})"

        socket =
          socket
          |> assign(:combat_monster, updated_monster)
          |> assign(:combat_log, [hit_log | socket.assigns.combat_log])
          |> assign(:combat_current_event, hit_log)
          |> assign(:combat_monster_taking_damage, true)
          |> assign(:surprise_attack_available, false)
          |> trigger_combat_audio("player_hit")

        # Clear damage overlay after 800ms - send message to main LiveView
        Process.send_after(self(), :clear_monster_damage_animation, 800)

        # Check if monster is dead from backstab
        if new_monster_hp <= 0 do
          handle_monster_defeated(socket, monster)
        else
          # Monster survived backstab, transition to normal combat
          handle_surprise_attack_complete(socket, monster)
        end
      else
        # Miss even with advantage
        miss_log =
          "BACKSTAB ATTEMPT! #{advantage_text} + #{attack_bonus} = #{total_attack} vs AC #{monster.armor_class}. MISS!"

        socket =
          socket
          |> assign(:combat_log, [miss_log | socket.assigns.combat_log])
          |> assign(:combat_current_event, miss_log)
          |> assign(:surprise_attack_available, false)
          |> trigger_combat_audio("player_miss")

        # Transition to normal combat after missed backstab
        handle_surprise_attack_complete(socket, monster)
      end
    else
      # Normal attack without advantage
      attack_roll = Dice.roll(1, 20)
      total_attack = attack_roll + attack_bonus

      if total_attack >= monster.armor_class do
        # Hit! Roll normal damage
        damage = Dice.roll_dice_string(socket.assigns.weapon_damage_dice)
        new_monster_hp = max(0, monster.current_hit_points - damage)
        updated_monster = Map.put(monster, :current_hit_points, new_monster_hp)

        # Create log entry
        hit_log =
          "Player attacks with #{socket.assigns.player_weapon}! Rolled #{attack_roll} + #{attack_bonus} = #{total_attack} vs AC #{monster.armor_class}. HIT for #{damage} damage!"

        socket =
          socket
          |> assign(:combat_monster, updated_monster)
          |> assign(:combat_log, [hit_log | socket.assigns.combat_log])
          |> assign(:combat_current_event, hit_log)
          |> assign(:combat_monster_taking_damage, true)
          |> trigger_combat_audio("player_hit")

        # Clear damage overlay after 800ms - send message to main LiveView
        Process.send_after(self(), :clear_monster_damage_animation, 800)

        # Check if monster is dead
        if new_monster_hp <= 0 do
          handle_monster_defeated(socket, monster)
        else
          handle_monster_alive_after_attack(socket)
        end
      else
        handle_player_attack_miss(socket, monster, attack_roll, attack_bonus, total_attack)
      end
    end
  end

  @doc """
  Process monster's turn - automatic attack
  """
  def process_monster_turn(socket) do
    # Only process monster turn if it's actually the monster's turn
    if socket.assigns.combat_current_turn == :monster do
      monster = socket.assigns.combat_monster
      player_ac = socket.assigns.armor_class

      # Set monster attacking animation
      socket = assign(socket, :combat_monster_attacking, true)
      # Clear animation after 600ms - send message to main LiveView
      Process.send_after(self(), :clear_monster_attack_animation, 600)

      # Roll d20 + monster attack bonus
      attack_roll = Dice.roll(1, 20)
      total_attack = attack_roll + monster.attack_bonus

      if total_attack >= player_ac do
        handle_monster_hit(socket, monster, attack_roll, total_attack, player_ac)
      else
        handle_monster_miss(socket, monster, attack_roll, total_attack, player_ac)
      end
    else
      # Not the monster's turn, do nothing
      socket
    end
  end

  defp handle_monster_hit(socket, monster, attack_roll, total_attack, player_ac) do
    # Hit! Roll damage
    damage = Dice.roll_dice_string(monster.damage_dice)
    new_player_hp = max(0, socket.assigns.player_hit_points - damage)

    # Create log entry
    hit_log =
      "#{monster.name} attacks with #{monster.weapon}! Rolled #{attack_roll} + #{monster.attack_bonus} = #{total_attack} vs AC #{player_ac}. HIT for #{damage} damage!"

    socket =
      socket
      |> assign(:player_hit_points, new_player_hp)
      |> assign(:combat_log, [hit_log | socket.assigns.combat_log])
      |> assign(:combat_current_event, hit_log)
      |> assign(:combat_player_taking_damage, true)
      |> trigger_combat_audio("monster_hit")

    # Clear damage overlay after 800ms - send message to main LiveView
    Process.send_after(self(), :clear_player_damage_animation, 800)

    # Check if player is dead
    if new_player_hp <= 0 do
      death_log = "You have been defeated!"

      socket
      |> assign(:combat_log, [death_log | socket.assigns.combat_log])
      |> end_combat_death()
    else
      handle_monster_action_complete(socket)
    end
  end

  defp handle_monster_miss(socket, monster, attack_roll, total_attack, player_ac) do
    # Miss!
    miss_log =
      "#{monster.name} attacks with #{monster.weapon}! Rolled #{attack_roll} + #{monster.attack_bonus} = #{total_attack} vs AC #{player_ac}. MISS!"

    socket =
      socket
      |> assign(:combat_log, [miss_log | socket.assigns.combat_log])
      |> assign(:combat_current_event, miss_log)
      |> trigger_combat_audio("monster_miss")

    handle_monster_action_complete(socket)
  end

  defp handle_monster_action_complete(socket) do
    socket = assign(socket, :combat_monster_has_acted, true)

    # Send delayed message to maybe start next round or switch to player turn
    if socket.assigns.combat_player_has_acted do
      Process.send_after(self(), :maybe_start_next_round, 1000)
      socket
    else
      # Monster acted, now player's turn
      socket
      |> assign(:combat_current_turn, :player)
      |> assign(:combat_awaiting_player_action, true)
    end
  end

  @doc """
  Check if both combatants have acted, and if so start next round
  """
  def maybe_start_next_round(socket) do
    if socket.assigns.combat_player_has_acted and socket.assigns.combat_monster_has_acted do
      start_next_round(socket)
    else
      # Switch to the other combatant's turn
      if socket.assigns.combat_player_has_acted do
        # Player acted, now monster's turn (but this shouldn't happen as monster processes immediately)
        socket
        |> assign(:combat_current_turn, :monster)
        |> assign(:combat_awaiting_player_action, false)
        |> process_monster_turn()
      else
        # Monster acted, now player's turn
        socket
        |> assign(:combat_current_turn, :player)
        |> assign(:combat_awaiting_player_action, true)
      end
    end
  end

  @doc """
  Start the next combat round
  """
  def start_next_round(socket) do
    new_round = socket.assigns.combat_round + 1

    # Roll initiative for new round
    player_initiative = Dice.roll(1, 6)
    monster_initiative = Dice.roll(1, 6)

    player_goes_first = player_initiative >= monster_initiative
    current_turn = if player_goes_first, do: :player, else: :monster

    socket =
      socket
      |> assign(:combat_round, new_round)
      |> assign(:combat_current_turn, current_turn)
      |> assign(:combat_awaiting_player_action, current_turn == :player)
      |> assign(:combat_player_initiative, player_initiative)
      |> assign(:combat_monster_initiative, monster_initiative)
      |> assign(:combat_player_has_acted, false)
      |> assign(:combat_monster_has_acted, false)

    # If monster goes first this round, process its turn with delay
    if current_turn == :monster do
      Process.send_after(self(), :process_monster_turn, 1000)
      socket
    else
      socket
    end
  end

  @doc """
  End combat with player victory
  """
  def end_combat_victory(socket) do
    # Use monster's treasure attribute or default to 0 if nil
    monster = socket.assigns.combat_monster

    treasure_gold =
      case monster.treasure do
        nil -> 0
        dice_string when is_binary(dice_string) -> Dice.roll_dice_string(dice_string)
        _ -> 0
      end

    # Keep combat dialog open to show victory message, then show victory dialog after 1 second
    # Schedule delayed victory dialog transition after 1 second
    Process.send_after(self(), :show_victory_dialog, 1000)

    socket
    |> assign(:victory_treasure_gold, treasure_gold)
  end

  @doc """
  End combat with player death
  """
  def end_combat_death(socket) do
    # Remove the monster from the grid since it defeated the player
    socket = remove_defeated_player_monster(socket)

    # Keep combat dialog open to show death message, then close after 1 second
    # Schedule delayed death dialog transition after 1 second
    Process.send_after(self(), :show_death_dialog, 1000)

    socket
    |> assign(:player_dead, true)
  end

  @doc """
  Show victory dialog after combat ends
  """
  def show_victory_dialog(socket) do
    socket
    |> assign(:show_combat_dialog, false)
    |> assign(:show_victory_dialog, true)
  end

  @doc """
  Show death dialog after combat ends
  """
  def show_death_dialog(socket) do
    socket
    |> Phoenix.LiveView.push_event("play_audio", %{sound: "death"})
    |> Phoenix.LiveView.push_event("play_death_music", %{})
    |> assign(:show_combat_dialog, false)
    |> assign(:show_death_dialog, true)
  end

  @doc """
  Start surprise combat when monster is encountered during feature investigation
  """
  def start_surprise_combat(socket, monster_position, monster) do
    # Place the monster on the dungeon grid temporarily for combat
    updated_grid =
      Map.put(socket.assigns.dungeon.grid, monster_position, {:monster, monster.name})

    updated_dungeon = Map.put(socket.assigns.dungeon, :grid, updated_grid)

    # Set up combat state with the monster attacking first
    socket
    |> assign(:dungeon, updated_dungeon)
    |> assign(:current_encounter_position, monster_position)
    |> assign(:show_encounter_dialog, false)
    |> start_combat(monster)
  end

  @doc """
  Enhanced dismiss_victory that handles XP calculation and treasure collection
  """
  def dismiss_victory_with_xp(socket) do
    # Award XP before clearing combat data
    monster = socket.assigns.combat_monster
    treasure_gold = socket.assigns.victory_treasure_gold

    # Award XP for monster HP (1 XP per HP) - this needs to be handled by the calling module
    # since award_xp is defined in dungeon_live.ex
    xp_awards = []

    xp_awards =
      if monster do
        [{monster.max_hit_points, "monster defeat"} | xp_awards]
      else
        xp_awards
      end

    # Award XP for gold (1 XP per gold)
    xp_awards =
      if treasure_gold > 0 do
        [{treasure_gold, "treasure gold"} | xp_awards]
      else
        xp_awards
      end

    # Only play coins sound if there is treasure
    socket =
      if treasure_gold > 0 do
        Phoenix.LiveView.push_event(socket, "play_audio", %{sound: "coins"})
      else
        socket
      end

    # Resume background music after combat victory
    socket = Phoenix.LiveView.push_event(socket, "resume_background_music", %{})

    # Call the original dismiss_victory function
    socket = dismiss_victory(socket)

    # Return socket and XP awards for the calling module to process
    {socket, xp_awards}
  end

  @doc """
  Get combat dialog content for display
  """
  def get_combat_content(assigns) do
    monster = assigns.combat_monster
    round = assigns.combat_round
    combat_log = assigns[:combat_log] || []
    is_surprise_round = round == 0 and Map.get(assigns, :surprise_attack_available, false)

    events_html = format_combat_events(combat_log, monster)
    player_section = render_player_section(assigns)
    monster_section = render_monster_section(assigns, monster)

    # Show different title for surprise round vs normal combat
    title =
      if is_surprise_round do
        "Surprise Attack!"
      else
        "Combat Round #{round}"
      end

    # Show monster status
    monster_status =
      if is_surprise_round do
        "<div class=\"text-center text-red-400 font-bold\">#{monster.name} is SURPRISED!</div>"
      else
        ""
      end

    """
    <div class="space-y-1">
      <div class="text-center">
        <h3 class="text-lg font-bold">#{title}</h3>
        #{monster_status}
      </div>
      <div class="flex justify-center items-center gap-4">
        #{player_section}
        <div class="text-lg font-bold text-red-400">VS</div>
        #{monster_section}
      </div>
      #{events_html}
    </div>
    """
  end

  @doc """
  Get combat dialog buttons based on current state
  """
  def get_combat_buttons(assigns) do
    if assigns.combat_awaiting_player_action do
      is_surprise_attack = Map.get(assigns, :surprise_attack_available, false)

      attack_text =
        if is_surprise_attack do
          UISizing.inline_img_tag("/images/d20.png", "Backstab") <> " Backstab"
        else
          UISizing.inline_img_tag("/images/d20.png", "Attack") <> " Attack"
        end

      [
        %{
          text: attack_text,
          action: "combat_attack",
          variant: "primary"
        },
        %{
          text: UISizing.inline_img_tag("/images/evade.png", "Flee") <> " Flee",
          action: "combat_flee",
          variant: "secondary"
        }
      ]
    else
      # No buttons during monster turn or processing
      []
    end
  end

  @doc """
  Handle player fleeing from combat - monster gets free attack first
  """
  def flee_combat(socket) do
    monster = socket.assigns.combat_monster
    player_ac = socket.assigns.armor_class

    # Monster gets a free attack when player flees
    attack_roll = Dice.roll(1, 20)
    total_attack = attack_roll + monster.attack_bonus

    if total_attack >= player_ac do
      # Monster hits during flee attempt
      damage = Dice.roll_dice_string(monster.damage_dice)
      new_player_hp = max(0, socket.assigns.player_hit_points - damage)

      # Create log entry for the free attack
      flee_attack_log =
        "You attempt to flee! #{monster.name} gets a free attack with #{monster.weapon}! Rolled #{attack_roll} + #{monster.attack_bonus} = #{total_attack} vs AC #{player_ac}. HIT for #{damage} damage!"

      socket =
        socket
        |> assign(:player_hit_points, new_player_hp)
        |> assign(:combat_log, [flee_attack_log | socket.assigns.combat_log])
        |> assign(:combat_current_event, flee_attack_log)
        |> assign(:combat_awaiting_player_action, false)
        |> assign(:combat_player_taking_damage, true)
        |> trigger_combat_audio("monster_hit")

      # Clear damage overlay after 800ms - send message to main LiveView
      Process.send_after(self(), :clear_player_damage_animation, 800)

      # Check if player died from the free attack
      if new_player_hp <= 0 do
        death_log = "You have been defeated while trying to flee!"

        socket
        |> assign(:combat_log, [death_log | socket.assigns.combat_log])
        |> end_combat_death()
      else
        # Player survived, schedule evade attempt after delay
        Process.send_after(self(), :attempt_combat_flee_evade, 1000)
        socket
      end
    else
      # Monster misses during flee attempt
      flee_attack_log =
        "You attempt to flee! #{monster.name} gets a free attack with #{monster.weapon}! Rolled #{attack_roll} + #{monster.attack_bonus} = #{total_attack} vs AC #{player_ac}. MISS!"

      socket =
        socket
        |> assign(:combat_log, [flee_attack_log | socket.assigns.combat_log])
        |> assign(:combat_current_event, flee_attack_log)
        |> assign(:combat_awaiting_player_action, false)
        |> trigger_combat_audio("monster_miss")

      # Schedule evade attempt after delay
      Process.send_after(self(), :attempt_combat_flee_evade, 1000)
      socket
    end
  end

  @doc """
  Process the evade attempt after monster's free attack during flee
  """
  def process_flee_evade(socket) do
    # Roll d20 + dexterity bonus for evade attempt (DC 12)
    evade_roll = Dice.roll(1, 20)
    dex_bonus = socket.assigns.dexterity_bonus
    total_roll = evade_roll + dex_bonus
    evade_success = total_roll >= 12

    # Generate evade message based on success/failure
    evade_message =
      if evade_success do
        "Success! You manage to escape from combat.\n\n(Rolled #{evade_roll} + #{dex_bonus} dexterity = #{total_roll} vs DC 12)"
      else
        "Failed! You cannot escape the encounter and must fight.\n\n(Rolled #{evade_roll} + #{dex_bonus} dexterity = #{total_roll} vs DC 12)"
      end

    # Close combat dialog and show evade result dialog
    socket =
      socket
      |> assign(:show_combat_dialog, false)
      |> assign(:show_evade_dialog, true)
      |> assign(:evade_success, evade_success)
      |> assign(:evade_roll, total_roll)
      |> assign(:evade_message, evade_message)

    socket
  end

  @doc """
  Dismiss victory dialog and collect treasure
  """
  def dismiss_victory(socket) do
    # Play coins sound when collecting treasure
    socket = Phoenix.LiveView.push_event(socket, "play_audio", %{sound: "coins"})

    treasure_gold = socket.assigns.victory_treasure_gold
    current_gold = socket.assigns.player_gold
    new_gold = current_gold + treasure_gold

    # XP will be awarded in the main live view dismiss_victory handler

    # Replace encounter tiles with pile of bones in the dungeon grid
    # Include both triggered encounters and current encounter position
    all_encounter_positions =
      socket.assigns.triggered_encounters
      |> MapSet.to_list()
      |> then(fn positions ->
        case socket.assigns.current_encounter_position do
          nil -> positions
          pos -> [pos | positions]
        end
      end)
      |> Enum.uniq()

    updated_grid =
      Enum.reduce(all_encounter_positions, socket.assigns.dungeon.grid, fn {x, y}, grid ->
        tile = Map.get(grid, {x, y})

        case tile do
          {:encounter, _, _} ->
            # Replace encounter with pile of bones
            Map.put(grid, {x, y}, :pile_of_bones)

          {:monster, _} ->
            # Replace monster with pile of bones
            Map.put(grid, {x, y}, :pile_of_bones)

          _ ->
            # Keep other tiles unchanged
            grid
        end
      end)

    updated_dungeon = Map.put(socket.assigns.dungeon, :grid, updated_grid)

    socket
    |> assign(:dungeon, updated_dungeon)
    |> assign(:show_victory_dialog, false)
    |> assign(:player_gold, new_gold)
    |> assign(:combat_monster, nil)
    |> assign(:combat_log, [])
    |> assign(:combat_current_event, "")
    |> assign(:combat_awaiting_player_action, false)
    |> assign(:combat_player_has_acted, false)
    |> assign(:combat_monster_has_acted, false)
    |> assign(:triggered_encounters, MapSet.new())
    |> assign(:current_encounter_position, nil)
  end

  # Helper function to trigger audio events
  defp trigger_combat_audio(socket, sound) do
    Phoenix.LiveView.push_event(socket, "play_audio", %{sound: sound})
  end

  # Helper functions for combat content rendering

  defp format_combat_events(combat_log, monster) do
    # Get the last 4 entries from the combat log (most recent events)
    recent_events = combat_log |> Enum.take(4) |> Enum.reverse()

    # Create HTML for recent events
    Enum.map_join(recent_events, "", fn event ->
      bg_color = get_event_color(event, monster.name)

      "<div class=\"#{bg_color} p-2 rounded text-center\"><div class=\"text-sm text-gray-200\">#{event}</div></div>"
    end)
  end

  defp get_event_color(event, monster_name) do
    cond do
      String.contains?(event, "Player attacks") -> "bg-blue-800"
      String.contains?(event, "#{monster_name} attacks") -> "bg-red-800"
      String.contains?(event, "Initiative:") -> "bg-gray-700"
      true -> "bg-gray-800"
    end
  end

  defp render_player_section(assigns) do
    damage_overlay = render_damage_overlay(assigns[:combat_player_taking_damage])
    attack_animation = get_attack_animation(assigns[:combat_player_attacking])
    player_sprite_path = get_player_combat_sprite_path(assigns)

    """
    <div class="text-center">
      <div class="relative inline-block">
        <div class="w-12 h-12 mx-auto #{attack_animation}" style="background-image: url('#{player_sprite_path}'); background-size: contain; background-position: center; background-repeat: no-repeat;" role="img" aria-label="Player"></div>
        #{damage_overlay}
      </div>
      <div class="text-sm font-bold">You</div>
      <div class="text-xs text-green-400">#{assigns.player_hit_points}/#{assigns.max_hit_points} HP</div>
      <div class="text-xs text-orange-400">#{assigns.player_weapon}</div>
      <div class="text-xs text-purple-400">#{assigns.weapon_damage_dice}</div>
    </div>
    """
  end

  defp render_monster_section(assigns, monster) do
    damage_overlay = render_damage_overlay(assigns[:combat_monster_taking_damage])
    attack_animation = get_attack_animation(assigns[:combat_monster_attacking])

    """
    <div class="text-center">
      <div class="relative inline-block">
        <div class="w-12 h-12 mx-auto #{attack_animation} scale-x-[-1]" style="background-image: url('/images/monsters/#{monster.image}'); background-size: contain; background-position: center; background-repeat: no-repeat;" role="img" aria-label="#{monster.name}"></div>
        #{damage_overlay}
      </div>
      <div class="text-sm font-bold">#{monster.name}</div>
      <div class="text-xs text-red-400">#{monster.current_hit_points}/#{monster.max_hit_points} HP</div>
      <div class="text-xs text-orange-400">#{monster.weapon}</div>
      <div class="text-xs text-purple-400">#{monster.damage_dice}</div>
    </div>
    """
  end

  defp render_damage_overlay(is_taking_damage) do
    if is_taking_damage do
      """
      <div class="absolute inset-0 flex items-center justify-center animate-damage-overlay">
        <div class="w-8 h-8" style="background-image: url('/images/damage.png'); background-size: contain; background-position: center; background-repeat: no-repeat;" role="img" aria-label="Damage"></div>
      </div>
      """
    else
      ""
    end
  end

  defp get_attack_animation(is_attacking) do
    if is_attacking, do: "animate-attack-bounce", else: ""
  end

  # Helper function to get the correct player sprite for combat (always forward-facing)
  defp get_player_combat_sprite_path(assigns) do
    # Determine sprite set based on torch status
    sprite_prefix =
      if assigns.dungeon.fog_type == "daylight" do
        # Always use rogue2 (no torch) for daylight
        "rogue2"
      else
        if assigns.torch_burn_time > 0 do
          # with torch
          "rogue1"
        else
          # without torch
          "rogue2"
        end
      end

    # Always use forward-facing sprite (0) in combat
    "/images/characters/#{sprite_prefix}_0.png"
  end

  # Private helper functions

  defp create_initiative_log(player_roll, monster_roll, player_goes_first) do
    if player_goes_first do
      "Initiative: You rolled #{player_roll}, monster rolled #{monster_roll}. You go first!"
    else
      "Initiative: You rolled #{player_roll}, monster rolled #{monster_roll}. Monster goes first!"
    end
  end

  # Remove monster from grid when player dies - the monster disappears after defeating the player
  defp remove_defeated_player_monster(socket) do
    case socket.assigns.current_encounter_position do
      nil ->
        # No current encounter position tracked
        socket

      {x, y} ->
        # Remove the monster from the grid at the current encounter position
        dungeon = socket.assigns.dungeon
        tile = Map.get(dungeon.grid, {x, y})

        new_tile =
          case tile do
            {:monster, _} ->
              # Replace monster with underlying tile (floor or corridor)
              determine_underlying_tile({x, y}, dungeon.rooms)

            {:encounter, _, _} ->
              # Replace encounter with underlying tile
              determine_underlying_tile({x, y}, dungeon.rooms)

            _ ->
              # Keep other tiles unchanged
              tile
          end

        updated_grid = Map.put(dungeon.grid, {x, y}, new_tile)
        new_dungeon = %{dungeon | grid: updated_grid}

        socket
        |> assign(:dungeon, new_dungeon)
    end
  end

  # Helper to determine the underlying tile type based on position
  defp determine_underlying_tile({x, y}, rooms) do
    alias Dungeon.Generator.Grid

    if Grid.point_in_any_room?({x, y}, rooms) do
      :floor
    else
      :corridor
    end
  end

  # Helper for when monster is defeated

  defp handle_monster_defeated(socket, monster) do
    victory_log = "#{monster.name} is defeated!"
    socket = handle_npc_or_guard_kill(socket, monster)

    # Check if this was a quest monster
    socket = handle_quest_monster_defeat(socket, monster)

    socket
    |> assign(:combat_log, [victory_log | socket.assigns.combat_log])
    |> end_combat_victory()
  end

  # Helper for quest monster defeat
  defp handle_quest_monster_defeat(socket, monster) do
    # Debug logging
    Logger.info("=== QUEST MONSTER DEFEAT DEBUG ===")
    Logger.info("Monster defeated: #{monster.name}")
    Logger.info("Monster role: #{monster.role}")
    Logger.info("Monster alignment: #{monster.alignment}")
    Logger.info("Total NPC quests: #{length(socket.assigns.npc_quests)}")

    # Log all active quests
    Enum.each(socket.assigns.npc_quests, fn q ->
      Logger.info(
        "Quest #{q.id}: target_monster=#{q.target_monster}, target_npc=#{q.target_npc}, status=#{q.status}"
      )
    end)

    if monster.role == "quest_monster" or monster.role == "quest_npc" do
      Logger.info("Monster has quest role - looking for matching quest...")

      # Find the quest that targets this monster or NPC
      quest =
        Enum.find(socket.assigns.npc_quests, fn q ->
          q.target_monster == monster.name or q.target_npc == monster.name
        end)

      Logger.info("Found quest: #{if quest, do: "YES - #{quest.id}", else: "NO"}")

      if quest do
        Logger.info("Processing quest completion for quest #{quest.id}")

        # Complete the quest - mark as completed instead of removing
        completed_quest = %{quest | status: :completed}

        updated_quests =
          Enum.map(socket.assigns.npc_quests, fn q ->
            if q.id == quest.id, do: completed_quest, else: q
          end)

        # Remove quest from rumors list as well
        quest_rumor = "Quest from #{quest.quest_giver}: #{quest.tldr_description}"
        updated_rumors = Enum.reject(socket.assigns.rumors, fn rumor -> rumor == quest_rumor end)

        # Award gold and adjust alignment
        gold_reward = quest.reward_gold

        alignment_change =
          if quest.quest_alignment == :lawful, do: gold_reward, else: -gold_reward

        Logger.info("Awarding #{gold_reward} gold and #{alignment_change} alignment change")

        # Generate completion narrative based on quest type
        completion_narrative =
          case quest.type do
            :monster_kill ->
              generate_monster_quest_completion_narrative(
                monster,
                quest,
                socket.assigns.dungeon.theme
              )

            :npc_kill ->
              generate_npc_quest_completion_narrative(
                monster,
                quest,
                socket.assigns.dungeon.theme
              )

            _ ->
              "Your quest has been completed successfully!"
          end

        socket
        |> Phoenix.Component.assign(:npc_quests, updated_quests)
        |> Phoenix.Component.assign(:rumors, updated_rumors)
        |> Phoenix.Component.assign(:player_gold, socket.assigns.player_gold + gold_reward)
        |> Phoenix.Component.assign(
          :player_alignment,
          socket.assigns.player_alignment + alignment_change
        )
        |> Phoenix.Component.assign(:completed_quest, %{
          completed_quest
          | completion_narrative: completion_narrative
        })
        |> Phoenix.Component.assign(:quest_completion_xp, gold_reward)
        |> Phoenix.Component.assign(:show_quest_completed_dialog, true)
        |> Phoenix.LiveView.push_event("play_audio", %{sound: "orch_hit"})
        |> then(fn socket ->
          send(self(), {:award_xp, gold_reward, "quest completion"})
          socket
        end)
      else
        Logger.warning("No matching quest found for monster #{monster.name}")
        socket
      end
    else
      Logger.info("Monster does not have quest role - skipping quest completion check")
      socket
    end
  end

  # Generate completion narrative for monster kill quests
  defp generate_monster_quest_completion_narrative(monster, quest, current_theme) do
    "You have successfully defeated the #{monster.name} that was terrorizing the #{current_theme}! " <>
      "#{quest.quest_giver} will be grateful for your heroic deed. The threat has been eliminated, " <>
      "and the area is now safe for travelers once again."
  end

  # Generate completion narrative for NPC kill quests
  defp generate_npc_quest_completion_narrative(monster, quest, current_theme) do
    "You have successfully eliminated the #{monster.name} in the #{current_theme}! " <>
      "#{quest.quest_giver} will be pleased that their rival has been dealt with. Your reputation " <>
      "among the chaotic forces grows stronger with this deed."
  end

  # Helper for when monster is still alive after attack

  defp handle_monster_alive_after_attack(socket) do
    socket =
      socket
      |> assign(:combat_current_turn, :monster)
      |> assign(:combat_awaiting_player_action, false)
      |> assign(:combat_player_has_acted, true)

    Process.send_after(self(), :process_monster_turn, 1000)
    socket
  end

  # Helper for when player misses

  defp handle_player_attack_miss(socket, monster, attack_roll, attack_bonus, total_attack) do
    miss_log =
      "Player attacks with #{socket.assigns.player_weapon}! Rolled #{attack_roll} + #{attack_bonus} = #{total_attack} vs AC #{monster.armor_class}. MISS!"

    socket =
      socket
      |> assign(:combat_log, [miss_log | socket.assigns.combat_log])
      |> assign(:combat_current_event, miss_log)
      |> assign(:combat_current_turn, :monster)
      |> assign(:combat_awaiting_player_action, false)
      |> assign(:combat_player_has_acted, true)
      |> trigger_combat_audio("player_miss")

    Process.send_after(self(), :process_monster_turn, 1000)
    socket
  end

  # Helper for NPC/guard kill logic

  defp handle_npc_or_guard_kill(socket, monster) do
    cond do
      monster.role == "npc" and not socket.assigns.guards_hostile ->
        new_npcs_killed = socket.assigns.npcs_killed_count + 1
        socket = assign(socket, :npcs_killed_count, new_npcs_killed)

        # Shift alignment toward chaotic when killing lawful or neutral NPCs
        alignment_shift = if monster.alignment in [:lawful, :neutral], do: -5, else: 0

        socket =
          assign(socket, :player_alignment, socket.assigns.player_alignment + alignment_shift)

        send(self(), {:trigger_guard_hostility, "killing NPCs"})
        socket

      monster.role == "guard" and not socket.assigns.guards_hostile ->
        new_npcs_killed = socket.assigns.npcs_killed_count + 1
        socket = assign(socket, :npcs_killed_count, new_npcs_killed)

        # Shift alignment toward chaotic when killing lawful or neutral guards
        alignment_shift = if monster.alignment in [:lawful, :neutral], do: -5, else: 0

        socket =
          assign(socket, :player_alignment, socket.assigns.player_alignment + alignment_shift)

        send(self(), {:trigger_guard_hostility, "killing peaceful guards"})
        socket

      true ->
        socket
    end
  end

  @doc """
  Handle completion of surprise attack - roll initiative and start normal combat
  """
  def handle_surprise_attack_complete(socket, _monster) do
    # Add transition message
    transition_log = "The element of surprise is lost! Rolling for initiative..."

    # Roll initiative for both player and monster (1d6 each, player wins ties)
    player_initiative = Dice.roll(1, 6)
    monster_initiative = Dice.roll(1, 6)

    player_goes_first = player_initiative >= monster_initiative

    # Determine current turn
    current_turn = if player_goes_first, do: :player, else: :monster

    # Create combat log entry for initiative
    initiative_log =
      create_initiative_log(player_initiative, monster_initiative, player_goes_first)

    socket =
      socket
      |> assign(:combat_log, [initiative_log, transition_log | socket.assigns.combat_log])
      |> assign(:combat_current_event, initiative_log)
      |> assign(:combat_awaiting_player_action, current_turn == :player)
      |> assign(:combat_current_turn, current_turn)
      |> assign(:combat_round, 1)
      |> assign(:combat_player_initiative, player_initiative)
      |> assign(:combat_monster_initiative, monster_initiative)
      |> assign(:combat_player_has_acted, false)
      |> assign(:combat_monster_has_acted, false)
      |> assign(:surprise_attack_available, false)

    # If monster goes first, process its turn with delay
    if current_turn == :monster do
      Process.send_after(self(), :process_monster_turn, 1000)
      socket
    else
      socket
    end
  end
end
