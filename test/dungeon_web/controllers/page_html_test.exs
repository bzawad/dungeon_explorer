defmodule DungeonWeb.PageHTMLTest do
  use DungeonWeb.ConnCase, async: true

  alias Phoenix.HTML.Safe

  test "renders home.html" do
    html = Safe.to_iodata(DungeonWeb.PageHTML.home(%{version: "0.1.0"})) |> IO.iodata_to_binary()
    assert html =~ "Dungeon"
    assert html =~ "Generate and explore dungeons"
    assert html =~ "Start Adventure"
    assert html =~ "Print Last Dungeon"
  end
end
