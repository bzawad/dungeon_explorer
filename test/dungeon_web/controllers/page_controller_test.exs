defmodule DungeonWeb.PageControllerTest do
  use DungeonWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, ~p"/")
    response = html_response(conn, 200)
    assert response =~ "Dungeon"
    assert response =~ "Start Adventure"
    assert response =~ "/dungeon/live"
    assert response =~ "Version"
  end
end
