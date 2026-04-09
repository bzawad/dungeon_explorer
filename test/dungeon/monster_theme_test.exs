defmodule Dungeon.MonsterThemeTest do
  use ExUnit.Case
  alias Dungeon.Monster

  # Test theme data
  @daylight_theme %{
    fog_type: "daylight",
    monsters: [
      {"Acolyte", :common},
      {"Guard", :common},
      {"Druid", :uncommon}
    ]
  }

  @dim_theme %{
    fog_type: "dim",
    monsters: [
      {"Rat", :common},
      {"Skeleton", :common},
      {"Orc", :uncommon}
    ]
  }

  @ancient_temple_theme %{
    fog_type: "dark",
    monsters: [
      {"Centipede Swarm", :common},
      {"Skeleton", :uncommon},
      {"Wailing Ghost", :rare},
      {"Silent Ghost", :rare},
      {"Mummy", :uncommon},
      {"Minotaur", :rare},
      {"Chimera", :rare},
      {"Deep Gnome", :uncommon},
      {"Efreeti", :rare},
      {"Gorgon", :rare},
      {"Iron Golem", :rare},
      {"Ghoul", :uncommon},
      {"Ghast", :rare},
      {"Cyclops", :rare}
    ]
  }

  describe "determine_theme_monster/3" do
    test "daylight themes use only theme and rarity (no level filtering)" do
      monster = Monster.determine_theme_monster(@daylight_theme, 5, 3)
      assert monster != nil
      # In daylight themes, level should not affect monster selection
      assert monster.name in ["Acolyte", "Guard", "Druid"]
    end

    test "dim themes use theme, rarity, and highest of player or map level" do
      monster = Monster.determine_theme_monster(@dim_theme, 3, 1)
      assert monster != nil
      assert monster.name in ["Rat", "Skeleton", "Orc"]

      # For dim themes, monster challenge_rating should be between (level-2) and level
      # Level should be max(3, 1) = 3, so challenge_rating should be between 1 and 3
      assert monster.challenge_rating >= 1
      assert monster.challenge_rating <= 3
    end

    test "ancient temple theme respects level constraints for level 1 character" do
      # Test multiple times to ensure consistency
      for _ <- 1..10 do
        monster = Monster.determine_theme_monster(@ancient_temple_theme, 1, 1)
        assert monster != nil

        # For level 1 character with new range logic, monster challenge_rating should be <= 2
        # The Ancient Temple theme has monsters with CR 2-7, but for level 1
        # we should only get monsters with CR <= 2 (level + 1), which means we'll get
        # appropriate level monsters from the global system
        assert monster.challenge_rating <= 2
      end
    end
  end

  describe "get_random_monster_for_theme_with_fog_type/3" do
    test "handles nil theme gracefully" do
      monster = Monster.get_random_monster_for_theme_with_fog_type(nil, 3, 5)
      assert monster != nil
    end

    test "handles theme with no monsters gracefully" do
      empty_theme = %{fog_type: "dark", monsters: []}
      monster = Monster.get_random_monster_for_theme_with_fog_type(empty_theme, 3, 5)
      assert monster != nil
    end
  end

  describe "rarity fallback logic" do
    test "get_next_lowest_rarity/1 works correctly" do
      assert Monster.get_next_lowest_rarity(:elite) == :rare
      assert Monster.get_next_lowest_rarity(:rare) == :uncommon
      assert Monster.get_next_lowest_rarity(:uncommon) == :common
      assert Monster.get_next_lowest_rarity(:common) == :common
    end
  end

  describe "fallback order for monster level selection" do
    setup do
      theme = %{
        fog_type: "dark",
        monsters: [
          # CR 1
          {"Goblin Scout", :common},
          # CR 2
          {"Skeleton", :uncommon},
          # CR 3
          {"Ghoul", :uncommon},
          # CR 5
          {"Minotaur", :rare}
        ]
      }

      {:ok, theme: theme}
    end

    test "prefers monsters in level-2 to level+1 range", %{theme: theme} do
      # For level 3, preferred range is 1-4, so should get from: Goblin Scout, Skeleton, Ghoul
      for _ <- 1..10 do
        monster = Dungeon.Monster.determine_theme_monster(theme, 3, 3)
        assert monster.name in ["Goblin Scout", "Skeleton", "Ghoul"]
        # Should not get Minotaur (CR 5) as it's outside the preferred range (1-4)
        assert monster.name != "Minotaur"
      end
    end

    test "falls back to monsters <= level if nothing in preferred range", %{theme: theme} do
      # For level 1, preferred range is -1 to 2, but CR can't be negative, so 1-2
      # Should get from: Goblin Scout, Skeleton
      for _ <- 1..10 do
        monster = Dungeon.Monster.determine_theme_monster(theme, 1, 1)
        assert monster.name in ["Goblin Scout", "Skeleton"]
        # Should not get Ghoul (CR 3) or Minotaur (CR 5) as they're above level
        assert monster.name not in ["Ghoul", "Minotaur"]
      end
    end

    test "handles edge case where no monsters are in preferred range", %{theme: theme} do
      # For level 0, preferred range is -2 to 1, but CR can't be negative, so 0-1
      # No monsters at CR 0, so should fallback to any <= 0, then global system
      for _ <- 1..10 do
        monster = Dungeon.Monster.determine_theme_monster(theme, 0, 0)
        assert monster != nil
        # Should not error, but may get any global monster
      end
    end

    test "provides level variety within appropriate range", %{theme: theme} do
      # For level 2, preferred range is 0-3, so should get from: Goblin Scout, Skeleton, Ghoul
      # This provides variety while staying within appropriate challenge
      for _ <- 1..10 do
        monster = Dungeon.Monster.determine_theme_monster(theme, 2, 2)
        assert monster.name in ["Goblin Scout", "Skeleton", "Ghoul"]
        # Should not get Minotaur (CR 5) as it's too strong for level 2
        assert monster.name != "Minotaur"
      end
    end

    test "avoids spawning much higher level monsters", %{theme: theme} do
      # For level 1, should never get Minotaur (CR 5) as it's way too strong
      for _ <- 1..10 do
        monster = Dungeon.Monster.determine_theme_monster(theme, 1, 1)
        assert monster.name != "Minotaur"
        # Should be within reasonable range for level 1
        assert monster.challenge_rating <= 2
      end
    end
  end

  describe "level calculation scenarios" do
    setup do
      theme = %{
        fog_type: "dark",
        monsters: [
          # CR 1
          {"Rat", :common},
          # CR 1
          {"Goblin Scout", :common},
          # CR 2
          {"Skeleton", :uncommon},
          # CR 3
          {"Ghoul", :uncommon},
          # CR 5
          {"Minotaur", :rare},
          # CR 5
          {"Gorgon", :rare}
        ]
      }

      {:ok, theme: theme}
    end

    test "high level player on low level map spawns higher level monsters", %{theme: theme} do
      # Player level 5, map level 1 -> should use max(5, 1) = 5
      # Preferred range: 3-6, so should get Minotaur or Gorgon (CR 5)
      for _ <- 1..10 do
        monster = Dungeon.Monster.determine_theme_monster(theme, 1, 5)
        assert monster != nil
        # Should get higher level monsters appropriate for level 5 player
        assert monster.challenge_rating >= 3
        assert monster.challenge_rating <= 6
        # Should not get weak monsters like Rat or Goblin Scout
        assert monster.name not in ["Rat", "Goblin Scout"]
      end
    end

    test "low level player on high level map spawns higher level monsters", %{theme: theme} do
      # Player level 1, map level 5 -> should use max(1, 5) = 5
      # Preferred range: 3-6, so should get Minotaur or Gorgon (CR 5)
      for _ <- 1..10 do
        monster = Dungeon.Monster.determine_theme_monster(theme, 5, 1)
        assert monster != nil
        # Should get higher level monsters appropriate for level 5 map
        assert monster.challenge_rating >= 3
        assert monster.challenge_rating <= 6
        # Should not get weak monsters like Rat or Goblin Scout
        assert monster.name not in ["Rat", "Goblin Scout"]
      end
    end

    test "both high level player and high level map spawns highest level monsters", %{
      theme: theme
    } do
      # Player level 6, map level 6 -> should use max(6, 6) = 6
      # Preferred range: 4-7, but our theme only has up to CR 5
      # Should fallback to highest available: Minotaur or Gorgon (CR 5)
      for _ <- 1..10 do
        monster = Dungeon.Monster.determine_theme_monster(theme, 6, 6)
        assert monster != nil
        # Should get the highest level monsters available
        assert monster.challenge_rating == 5
        assert monster.name in ["Minotaur", "Gorgon"]
      end
    end

    test "level calculation uses max of player and map level", %{theme: theme} do
      # Test various combinations to ensure max() is working
      test_cases = [
        # Both low
        {1, 1, 1},
        # Low player, high map
        {1, 5, 5},
        # High player, low map
        {5, 1, 5},
        # Different levels
        {3, 4, 4},
        # High player, low map
        {7, 2, 7}
      ]

      for {map_level, player_level, expected_level} <- test_cases do
        monster = Dungeon.Monster.determine_theme_monster(theme, map_level, player_level)
        assert monster != nil

        # The monster should be appropriate for the expected level
        # Preferred range would be (expected_level - 2) to (expected_level + 1)
        # CR can't be negative
        min_cr = max(1, expected_level - 2)
        max_cr = expected_level + 1

        # For our test theme, we only have CR 1-5, so adjust expectations
        actual_max_cr = min(max_cr, 5)

        assert monster.challenge_rating >= min_cr
        assert monster.challenge_rating <= actual_max_cr
      end
    end

    test "specific scenario: level 6 player on level 2 map in Goblin Lair theme" do
      # This test reproduces the scenario from the image
      # Player level 6, map level 2, Goblin Lair theme
      goblin_lair_theme = %{
        fog_type: "dim",
        monsters: [
          {"Rat", :common},
          {"Spider", :common},
          {"Goblin Scout", :common},
          {"Goblin Warrior", :common},
          {"Boar", :common},
          {"Goblin Shaman", :uncommon},
          {"Centipede Swarm", :uncommon},
          {"Giant Bat", :uncommon},
          {"Giant Dung Beetle", :uncommon},
          {"Cave Creeper", :uncommon},
          {"Cave Brute", :uncommon},
          {"Hobgoblin", :uncommon},
          {"Bugbear", :uncommon},
          {"Bat Swarm", :uncommon},
          {"Goblin Boss", :rare},
          {"Gelatinous Cube", :rare},
          {"Ogre", :rare}
        ]
      }

      # Level 6 player on level 2 map -> should use max(2, 6) = 6
      # Preferred range: 4-7, but Goblin Lair only has up to CR 5
      # Should get the highest level monsters available: Ogre (CR 5) or Gelatinous Cube (CR 4)
      for _ <- 1..10 do
        monster = Dungeon.Monster.determine_theme_monster(goblin_lair_theme, 2, 6)
        assert monster != nil

        # Should get higher level monsters appropriate for level 6 player
        # The theme has monsters up to CR 5, so should get CR 4-5 monsters
        assert monster.challenge_rating >= 4
        assert monster.challenge_rating <= 5

        # Should get the highest level monsters available in the theme
        assert monster.name in ["Ogre", "Gelatinous Cube", "Cave Brute"]

        # Should NOT get low level monsters like Goblin Warrior (CR 1)
        assert monster.name != "Goblin Warrior"
        assert monster.challenge_rating > 1
      end
    end
  end

  describe "ancient temple theme now has level 1 monsters for low level players" do
    test "ancient temple theme now has level 1 monsters for low level players" do
      # Test that Ancient Temple now works for level 1 players
      for _ <- 1..10 do
        monster = Monster.determine_theme_monster(@ancient_temple_theme, 1, 1)
        assert monster != nil
        # Should get monsters with CR 1-2 (level 1 + 1)
        assert monster.challenge_rating >= 1
        assert monster.challenge_rating <= 2
        # Should be able to get any CR 1 or CR 2 monster from the theme
        assert monster.name in ["Rat", "Centipede Swarm", "Skeleton", "Deep Gnome", "Berserker"]
      end
    end
  end
end
