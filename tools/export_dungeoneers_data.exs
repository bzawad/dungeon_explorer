# Usage (from dungeon_explorer/):
#   mix run --no-start tools/export_dungeoneers_data.exs registry /path/to/special_feature_registry.json
#   mix run --no-start tools/export_dungeoneers_data.exs themes /path/to/themes.json
#
# Requires Jason (see mix.exs).

alias Dungeon.Generator.Features
alias Dungeon.Themes

defmodule ExportDungeoneersData do
  @moduledoc false

  def run(["registry", out_path | _]) do
    rows = Features.dungeoneers_special_feature_registry_rows()
    File.write!(out_path, Jason.encode!(rows, pretty: true) <> "\n")
  end

  def run(["themes", out_path | _]) do
    data =
      Themes.get_themes()
      |> Enum.map(&theme_to_json_safe/1)

    File.write!(out_path, Jason.encode!(data, pretty: true) <> "\n")
  end

  def run(_) do
    IO.puts(:stderr, "usage: export_dungeoneers_data.exs registry|themes OUT_PATH")
    System.halt(2)
  end

  defp theme_to_json_safe(%{} = m) do
    m
    |> Enum.map(fn {k, v} ->
      key = if is_atom(k), do: Atom.to_string(k), else: to_string(k)
      {key, value_to_json(v)}
    end)
    |> Map.new()
  end

  defp value_to_json(list) when is_list(list), do: Enum.map(list, &value_to_json/1)

  defp value_to_json({a, b}) when is_binary(a) and is_atom(b) do
    %{"name" => a, "rarity" => Atom.to_string(b)}
  end

  defp value_to_json(a) when is_atom(a), do: Atom.to_string(a)
  defp value_to_json(x), do: x
end

argv = System.argv()
ExportDungeoneersData.run(argv)
