defmodule DungeonWeb.TelemetryTest do
  use ExUnit.Case, async: true

  alias DungeonWeb.Telemetry

  test "metrics returns expected values" do
    metrics = Telemetry.metrics()
    # Assuming metrics returns a list
    assert is_list(metrics)
    # Ensure there are metrics defined
    assert match?([_ | _], metrics)
    # Add more assertions based on what metrics should contain
  end
end
