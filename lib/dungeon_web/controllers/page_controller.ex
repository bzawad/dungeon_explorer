defmodule DungeonWeb.PageController do
  use DungeonWeb, :controller

  def home(conn, _params) do
    # Get app version from the application spec
    version = Application.spec(:dungeon, :vsn) |> to_string()

    render(conn, :home, version: version)
  end
end
