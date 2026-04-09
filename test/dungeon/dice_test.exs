defmodule Dungeon.DiceTest do
  use ExUnit.Case, async: true

  alias Dungeon.Dice

  describe "parse_dice_string/1" do
    test "parses valid dice strings" do
      assert Dice.parse_dice_string("1d6") == {1, 6}
      assert Dice.parse_dice_string("2d8") == {2, 8}
      assert Dice.parse_dice_string("4d12") == {4, 12}
      assert Dice.parse_dice_string("10d10") == {10, 10}
    end

    test "handles uppercase D" do
      assert Dice.parse_dice_string("1D6") == {1, 6}
      assert Dice.parse_dice_string("2D8") == {2, 8}
    end

    test "returns error for invalid strings" do
      assert Dice.parse_dice_string("invalid") == :error
      assert Dice.parse_dice_string("1d") == :error
      assert Dice.parse_dice_string("d6") == :error
      assert Dice.parse_dice_string("0d6") == :error
      assert Dice.parse_dice_string("1d0") == :error
      assert Dice.parse_dice_string("") == :error
    end
  end

  describe "roll_dice_string/1" do
    test "rolls dice and returns valid results" do
      # Test multiple times to ensure results are in valid range
      for _ <- 1..20 do
        result = Dice.roll_dice_string("1d6")
        assert result >= 1 and result <= 6
      end

      for _ <- 1..20 do
        result = Dice.roll_dice_string("2d8")
        assert result >= 2 and result <= 16
      end
    end

    test "returns 1 for invalid dice strings" do
      assert Dice.roll_dice_string("invalid") == 1
      assert Dice.roll_dice_string("") == 1
    end
  end

  describe "roll_damage/2" do
    test "rolls damage with bonus" do
      # Without bonus
      for _ <- 1..20 do
        damage = Dice.roll_damage("1d4")
        assert damage >= 1 and damage <= 4
      end

      # With positive bonus
      for _ <- 1..20 do
        damage = Dice.roll_damage("1d4", 2)
        assert damage >= 3 and damage <= 6
      end
    end

    test "ensures minimum 1 damage even with negative bonus" do
      # Even with large negative bonus, damage should be at least 1
      damage = Dice.roll_damage("1d4", -10)
      assert damage >= 1
    end
  end

  describe "roll_attack/1" do
    test "rolls attack with bonus" do
      # Without bonus
      for _ <- 1..20 do
        attack = Dice.roll_attack()
        assert attack >= 1 and attack <= 20
      end

      # With bonus
      for _ <- 1..20 do
        attack = Dice.roll_attack(5)
        assert attack >= 6 and attack <= 25
      end
    end
  end
end
