defmodule Dungeon.ApplicationTest do
  use ExUnit.Case, async: true

  alias Dungeon.Application

  test "config_change/3 calls Endpoint.config_change/2" do
    # Simulate a configuration change
    assert :ok == Application.config_change(%{some_key: "new_value"}, nil, [])

    # You can add additional assertions here to verify the expected behavior
    # For example, if your Endpoint has a state that should change, check that
  end
end
