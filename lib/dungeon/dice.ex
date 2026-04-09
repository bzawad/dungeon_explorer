defmodule Dungeon.Dice do
  @moduledoc """
  Dice rolling utilities for the dungeon game
  """

  @doc """
  Roll a specified number of dice with a specified number of sides
  """
  def roll(num_dice, num_sides) do
    Enum.sum(for _ <- 1..num_dice, do: Enum.random(1..num_sides))
  end

  @doc """
  Parse and roll dice from a string like "1d6", "2d8", "4d12"
  Returns the sum of all dice rolled
  """
  def roll_dice_string(dice_string) do
    case parse_dice_string(dice_string) do
      {num_dice, num_sides} -> roll(num_dice, num_sides)
      # Default to 1 if parsing fails
      :error -> 1
    end
  end

  @doc """
  Parse a dice string like "1d6" into {num_dice, num_sides}
  Returns :error if the string cannot be parsed
  """
  def parse_dice_string(dice_string) do
    case String.split(String.downcase(dice_string), "d") do
      [num_dice_str, num_sides_str] ->
        with {num_dice, ""} <- Integer.parse(num_dice_str),
             {num_sides, ""} <- Integer.parse(num_sides_str),
             true <- num_dice > 0 and num_sides > 0 do
          {num_dice, num_sides}
        else
          _ -> :error
        end

      _ ->
        :error
    end
  end

  @doc """
  Roll damage dice with a bonus
  Used for monster attacks: dice + bonus
  """
  def roll_damage(dice_string, bonus \\ 0) do
    damage = roll_dice_string(dice_string)
    # Minimum 1 damage
    max(1, damage + bonus)
  end

  @doc """
  Roll an attack with a d20 + bonus
  Returns the attack roll result
  """
  def roll_attack(bonus \\ 0) do
    roll_dice_string("1d20") + bonus
  end

  @doc """
  Roll a percentage dice (1d100)
  Returns a value from 1 to 100
  """
  def roll_percent do
    roll(1, 100)
  end

  @doc """
  Check if a percentage chance succeeds
  Returns true if the roll is <= the chance percentage

  Examples:
    - chance_succeeds?(25) with roll of 20 -> true
    - chance_succeeds?(25) with roll of 30 -> false
    - chance_succeeds?(0) -> always false
    - chance_succeeds?(100) -> always true (unless roll is exactly 100, then it's true)
  """
  def chance_succeeds?(chance_percent) when chance_percent <= 0, do: false
  def chance_succeeds?(chance_percent) when chance_percent >= 100, do: true

  def chance_succeeds?(chance_percent) do
    roll_percent() <= chance_percent
  end
end
