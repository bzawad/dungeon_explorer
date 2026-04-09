defmodule DungeonWeb.RouterTest do
  use DungeonWeb.ConnCase, async: true

  describe "Browser routes" do
    test "GET / returns 200" do
      conn = get(build_conn(), "/")
      assert conn.status == 200
    end

    test "GET /dungeon/print returns 200" do
      conn = get(build_conn(), "/dungeon/print")
      assert conn.status == 200
    end

    test "GET /invalid_route returns 404" do
      conn = get(build_conn(), "/invalid_route")
      assert conn.status == 404
    end
  end
end
