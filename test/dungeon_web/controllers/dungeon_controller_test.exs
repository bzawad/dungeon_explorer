defmodule DungeonWeb.DungeonControllerTest do
  use DungeonWeb.ConnCase, async: true

  test "GET /dungeon/print renders print layout" do
    conn = get(build_conn(), "/dungeon/print")
    response = html_response(conn, 200)
    assert response =~ "Dungeon Map"
  end
end
