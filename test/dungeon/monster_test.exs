defmodule Dungeon.MonsterTest do
  use ExUnit.Case, async: true

  alias Dungeon.Monster

  describe "get_monster_by_name/1" do
    test "finds monster by name" do
      monster = Monster.get_monster_by_name("Goblin Scout")

      assert monster.name == "Goblin Scout"
      assert monster.image == "goblin_scout.png"
      assert monster.armor_class == 11
      assert monster.hit_points == 5
      assert monster.attack_bonus == 0
      assert monster.damage_dice == "1d4"
      assert monster.weapon == "Dagger"
    end

    test "finds weak monster" do
      monster = Monster.get_monster_by_name("Rat")

      assert monster.name == "Rat"
      assert monster.image == "rat.png"
      assert monster.armor_class == 10
      assert monster.hit_points == 1
      assert monster.attack_bonus == 0
      assert monster.damage_dice == "1d1"
      assert monster.weapon == "Bite"
    end

    test "finds powerful boss monster" do
      monster = Monster.get_monster_by_name("God Of All Multiverses")

      assert monster.name == "God Of All Multiverses"
      assert monster.image == "god_of_all_multiverses.png"
      assert monster.armor_class == 18
      assert monster.hit_points == 20
      assert monster.attack_bonus == 5
      assert monster.damage_dice == "2d12"
      assert monster.weapon == "Reality Warp"
    end

    test "returns nil for unknown monster" do
      monster = Monster.get_monster_by_name("Unknown Monster")

      assert is_nil(monster)
    end
  end

  describe "get_monster_by_image/1" do
    test "finds monster by image filename" do
      monster = Monster.get_monster_by_image("orc.png")

      assert monster.name == "Orc"
      assert monster.image == "orc.png"
      assert monster.armor_class == 15
      assert monster.hit_points == 6
      assert monster.damage_dice == "1d8"
      assert monster.weapon == "Greataxe"
    end

    test "returns nil for unknown image" do
      monster = Monster.get_monster_by_image("unknown.png")

      assert is_nil(monster)
    end
  end

  describe "all_monsters/0" do
    test "returns all available monsters" do
      monsters = Monster.all_monsters()

      assert length(monsters) == 110
      assert Enum.any?(monsters, &(&1.name == "Goblin Scout"))
      assert Enum.any?(monsters, &(&1.name == "Orc"))
      assert Enum.any?(monsters, &(&1.name == "God Of All Multiverses"))
      assert Enum.any?(monsters, &(&1.name == "Ant"))
      assert Enum.any?(monsters, &(&1.name == "Blob Fish"))
      assert Enum.any?(monsters, &(&1.name == "Evil Piggy"))
      assert Enum.any?(monsters, &(&1.name == "Scary Face"))
      assert Enum.any?(monsters, &(&1.name == "Zombie Piggy"))

      # Verify all monsters have required attributes
      Enum.each(monsters, fn monster ->
        assert is_binary(monster.name)
        assert is_binary(monster.image)
        assert is_integer(monster.armor_class)
        assert is_integer(monster.hit_points)
        assert is_integer(monster.attack_bonus)
        assert is_binary(monster.damage_dice)
        assert is_binary(monster.weapon)
        assert is_float(monster.size)
      end)
    end
  end

  describe "get_random_monster/0" do
    test "returns a random monster" do
      monster = Monster.get_random_monster()

      assert %Monster{} = monster
      assert is_binary(monster.name)
      assert is_binary(monster.image)
    end
  end

  describe "create_monster_instance/1" do
    test "creates instance from name" do
      instance = Monster.create_monster_instance("Goblin Scout")

      assert instance.name == "Goblin Scout"
      assert instance.current_hit_points == 5
      assert instance.max_hit_points == 5
    end

    test "creates instance from monster struct" do
      monster = Monster.get_monster_by_name("Rat")
      instance = Monster.create_monster_instance(monster)

      assert instance.name == "Rat"
      assert instance.current_hit_points == 1
      assert instance.max_hit_points == 1
    end

    test "returns nil for unknown monster name" do
      instance = Monster.create_monster_instance("Unknown Monster")

      assert is_nil(instance)
    end
  end

  describe "get_hit_points/1" do
    test "gets fixed hit points for monster" do
      monster = Monster.get_monster_by_name("Goblin Scout")
      hp = Monster.get_hit_points(monster)

      # Goblin has fixed 5 hit points
      assert hp == 5
    end
  end
end
