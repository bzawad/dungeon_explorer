defmodule DungeonWeb.DungeonController do
  use DungeonWeb, :controller

  def print(conn, params) do
    dungeon =
      case params["session_key"] do
        nil ->
          # No session key provided, generate a new dungeon or use seed
          case params["seed"] do
            nil ->
              Dungeon.Generator.generate()

            seed ->
              # Set random seed for reproducible dungeons
              :rand.seed(:exsplus, {String.to_integer(seed), 1, 1})
              Dungeon.Generator.generate()
          end

        session_key ->
          # Session key provided, retrieve from temporary storage
          case retrieve_dungeon_data(session_key) do
            {:ok, dungeon_data} -> dungeon_data
            # Fallback if data not found/expired
            :error -> Dungeon.Generator.generate()
          end
      end

    render(conn, :print, dungeon: dungeon, layout: false)
  end

  def download_image(conn, params) do
    dungeon =
      case params["session_key"] do
        nil ->
          # No session key provided, generate a new dungeon or use seed
          case params["seed"] do
            nil ->
              Dungeon.Generator.generate()

            seed ->
              # Set random seed for reproducible dungeons
              :rand.seed(:exsplus, {String.to_integer(seed), 1, 1})
              Dungeon.Generator.generate()
          end

        session_key ->
          # Session key provided, retrieve from temporary storage
          case retrieve_dungeon_data(session_key) do
            {:ok, dungeon_data} ->
              require Logger
              Logger.info("=== PNG CONTROLLER DEBUG ===")
              Logger.info("Retrieved dungeon data for PNG")
              Logger.info("Session key: #{session_key}")
              Logger.info("Dungeon theme: #{dungeon_data.theme}")
              Logger.info("Grid size: #{map_size(dungeon_data.grid)}")

              # Check for quest monsters in the retrieved grid
              quest_monsters_in_retrieved_grid =
                dungeon_data.grid
                |> Enum.filter(fn {_pos, tile} ->
                  case tile do
                    {:encounter, _label, monster} -> monster.role == "quest_monster"
                    _ -> false
                  end
                end)
                |> Enum.map(fn {pos, {:encounter, _label, monster}} ->
                  {pos, monster.name}
                end)

              Logger.info(
                "Quest monsters found in retrieved grid: #{inspect(quest_monsters_in_retrieved_grid)}"
              )

              dungeon_data

            # Fallback if data not found/expired
            :error ->
              Dungeon.Generator.generate()
          end
      end

    render(conn, :download_image, dungeon: dungeon, layout: false)
  end

  defp retrieve_dungeon_data(session_key) do
    # Check if ETS table exists
    case :ets.whereis(:dungeon_temp_storage) do
      :undefined ->
        :error

      _table ->
        do_retrieve_dungeon_data(session_key)
    end
  end

  defp do_retrieve_dungeon_data(session_key) do
    case :ets.lookup(:dungeon_temp_storage, session_key) do
      [{^session_key, dungeon_data, expire_time}] ->
        current_time = System.system_time(:second)

        if current_time < expire_time do
          :ets.delete(:dungeon_temp_storage, session_key)
          {:ok, dungeon_data}
        else
          :ets.delete(:dungeon_temp_storage, session_key)
          :error
        end

      [] ->
        :error
    end
  end
end
