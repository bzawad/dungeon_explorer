defmodule Dungeon.PlayerStatsTest do
  use ExUnit.Case
  alias Dungeon.PlayerStats

  describe "basic stats constants" do
    test "player_hit_points returns correct value" do
      assert PlayerStats.player_hit_points() == 4
    end

    test "max_hit_points returns correct base value" do
      assert PlayerStats.max_hit_points() == 4
    end

    test "max_hit_points with bonuses" do
      assert PlayerStats.max_hit_points(3) == 7
    end

    test "max_hit_points_with_levels returns correct value" do
      assert PlayerStats.max_hit_points_with_levels() == 4
      assert PlayerStats.max_hit_points_with_levels(2, 3) == 9
      assert PlayerStats.max_hit_points_with_levels(0, 5) == 9
    end

    test "roll_hit_points_for_level returns valid d4 roll" do
      roll = PlayerStats.roll_hit_points_for_level()
      assert roll in 1..4
    end

    test "player_weapon returns correct value" do
      assert PlayerStats.player_weapon() == "Dagger"
    end

    test "weapon_damage_dice returns correct value" do
      assert PlayerStats.weapon_damage_dice() == "1d4"
    end

    test "attack_bonus returns correct base value" do
      assert PlayerStats.attack_bonus() == 1
    end

    test "attack_bonus with bonuses" do
      assert PlayerStats.attack_bonus(2) == 3
    end

    test "dexterity_bonus returns correct base value" do
      assert PlayerStats.dexterity_bonus() == 1
    end

    test "dexterity_bonus with bonuses" do
      assert PlayerStats.dexterity_bonus(2) == 3
    end

    test "armor_bonus returns correct value" do
      assert PlayerStats.armor_bonus() == 1
    end

    test "armor_class calculates correctly" do
      # base (10) + armor (1) + dex (1) = 12
      assert PlayerStats.armor_class() == 12
    end

    test "armor_class with dexterity bonuses" do
      # base (10) + armor (1) + dex (1 + 2) = 14
      assert PlayerStats.armor_class(2) == 14
    end

    test "torch_burn_time returns correct value" do
      assert PlayerStats.torch_burn_time() == 100
    end

    test "player_gold returns correct value" do
      assert PlayerStats.player_gold() == 0
    end

    test "starting_level returns correct value" do
      assert PlayerStats.starting_level() == 1
    end
  end

  describe "level progression" do
    test "xp_required_for_level calculates correctly" do
      assert PlayerStats.xp_required_for_level(1) == 0
      assert PlayerStats.xp_required_for_level(2) == 500
      assert PlayerStats.xp_required_for_level(3) == 1500
      assert PlayerStats.xp_required_for_level(4) == 3000
    end

    test "calculate_level works correctly" do
      assert PlayerStats.calculate_level(0) == 1
      assert PlayerStats.calculate_level(499) == 1
      assert PlayerStats.calculate_level(500) == 2
      assert PlayerStats.calculate_level(1499) == 2
      assert PlayerStats.calculate_level(1500) == 3
    end

    test "xp_needed_for_next_level calculates correctly" do
      assert PlayerStats.xp_needed_for_next_level(0) == 500
      assert PlayerStats.xp_needed_for_next_level(250) == 250
      assert PlayerStats.xp_needed_for_next_level(500) == 1000
    end

    test "leveled_up? detects level changes" do
      assert PlayerStats.leveled_up?(0, 500) == true
      assert PlayerStats.leveled_up?(250, 499) == false
      assert PlayerStats.leveled_up?(499, 500) == true
      assert PlayerStats.leveled_up?(1000, 1500) == true
    end
  end

  describe "talent system" do
    test "generate_random_talent returns valid talents" do
      {type, bonus, message} = PlayerStats.generate_random_talent()

      assert type in [:hit_points, :attack, :dexterity]

      case type do
        :hit_points ->
          assert bonus in 1..4
          assert String.contains?(message, "Maximum Hit Points")

        :attack ->
          assert bonus == 1
          assert String.contains?(message, "Attack Bonus")

        :dexterity ->
          assert bonus == 1
          assert String.contains?(message, "Dexterity Bonus")
      end
    end

    test "apply_talent_bonus updates bonuses correctly" do
      talents = PlayerStats.default_talents()

      # Test hit points bonus
      updated = PlayerStats.apply_talent_bonus(talents, {:hit_points, 3, "msg"})
      assert updated.hit_points == 3

      # Test attack bonus
      updated = PlayerStats.apply_talent_bonus(talents, {:attack, 1, "msg"})
      assert updated.attack == 1

      # Test dexterity bonus
      updated = PlayerStats.apply_talent_bonus(talents, {:dexterity, 1, "msg"})
      assert updated.dexterity == 1
    end

    test "default_talents returns correct structure" do
      talents = PlayerStats.default_talents()
      assert talents.hit_points == 0
      assert talents.attack == 0
      assert talents.dexterity == 0
    end
  end

  describe "special item system" do
    test "weapon damage is updated when weapon item is equipped" do
      # Create a weapon special item
      weapon_item = %{
        item: %{
          name: "Dagger of the Silent Step",
          wearable: true,
          wearable_slot: "weapon",
          damage_bonus: "1d6",
          weapon_bonus: 1,
          dexterity_bonus: 1
        },
        item_name: "Dagger of the Silent Step",
        description: "A magical dagger"
      }

      special_items = [weapon_item]
      talent_bonuses = PlayerStats.default_talents()

      # Test that weapon damage is updated
      assert PlayerStats.weapon_damage_dice(special_items, talent_bonuses) == "1d6"

      assert PlayerStats.player_weapon(special_items, talent_bonuses) ==
               "Dagger of the Silent Step"
    end

    test "dexterity bonus is applied from special items" do
      # Create a dexterity bonus item
      dex_item = %{
        item: %{
          name: "Ring of Evasion",
          wearable: true,
          wearable_slot: "finger",
          dexterity_bonus: 1
        },
        item_name: "Ring of Evasion",
        description: "A ring that enhances agility"
      }

      special_items = [dex_item]
      talent_bonuses = PlayerStats.default_talents()

      # Test that dexterity bonus is applied
      total_stats = PlayerStats.calculate_total_stats(special_items, talent_bonuses)
      # base 1 + item 1
      assert total_stats.dexterity_bonus == 2
    end

    test "level hit points are included in total stats calculation" do
      special_items = []
      talent_bonuses = PlayerStats.default_talents()
      level_hit_points = 6

      total_stats =
        PlayerStats.calculate_total_stats(special_items, talent_bonuses, level_hit_points)

      # base 4 + level 6 = 10
      assert total_stats.max_hit_points == 10
    end

    test "level hit points and talent bonuses are combined correctly" do
      special_items = []
      talent_bonuses = %{hit_points: 2, attack: 0, dexterity: 0}
      level_hit_points = 8

      total_stats =
        PlayerStats.calculate_total_stats(special_items, talent_bonuses, level_hit_points)

      # base 4 + talent 2 + level 8 = 14
      assert total_stats.max_hit_points == 14
    end

    test "armor class calculation includes level hit points parameter" do
      special_items = []
      talent_bonuses = PlayerStats.default_talents()
      level_hit_points = 5

      armor_class =
        PlayerStats.calculate_total_armor_class(special_items, talent_bonuses, level_hit_points)

      # base (10) + armor (1) + dex (1) = 12 (level hit points don't affect armor class)
      assert armor_class == 12
    end

    test "legacy functions work with level hit points parameter" do
      special_items = []
      talent_bonuses = PlayerStats.default_talents()
      level_hit_points = 3

      # Test that legacy functions accept the new parameter
      weapon = PlayerStats.player_weapon(special_items, talent_bonuses, level_hit_points)

      damage_dice =
        PlayerStats.weapon_damage_dice(special_items, talent_bonuses, level_hit_points)

      armor_bonus = PlayerStats.armor_bonus(special_items, talent_bonuses, level_hit_points)

      assert weapon == "Dagger"
      assert damage_dice == "1d4"
      assert armor_bonus == 1
    end

    test "multiple items in same slot use highest XP value" do
      # Create two items for the same slot with different XP values
      low_xp_item = %{
        item: %{
          name: "Basic Ring",
          wearable: true,
          wearable_slot: "finger",
          dexterity_bonus: 1,
          xp_value: 5
        },
        item_name: "Basic Ring",
        description: "A basic ring"
      }

      high_xp_item = %{
        item: %{
          name: "Ring of Evasion",
          wearable: true,
          wearable_slot: "finger",
          dexterity_bonus: 2,
          xp_value: 14
        },
        item_name: "Ring of Evasion",
        description: "A better ring"
      }

      special_items = [low_xp_item, high_xp_item]
      talent_bonuses = PlayerStats.default_talents()

      # Test that the higher XP item is equipped (higher dexterity bonus)
      total_stats = PlayerStats.calculate_total_stats(special_items, talent_bonuses)
      # base 1 + high_xp_item 2
      assert total_stats.dexterity_bonus == 3
    end
  end
end
