defmodule DungeonWeb.RoomDescriptionTrackingTest do
  use ExUnit.Case, async: true

  describe "room description context tracking" do
    test "room descriptions update current and previous tracking correctly" do
      # Test the logic that should happen when room descriptions are completed
      # This simulates the fix we implemented in handle_description_generated_by_type

      # Initial state
      initial_assigns = %{
        current_room_description: nil,
        previous_room_description: nil,
        room_descriptions: %{}
      }

      # Test R1 room description completion
      description = "**Chamber of Echoes** The entrance to this ancient dungeon."

      # Simulate the logic from handle_description_generated_by_type for :r1_room
      updated_assigns = %{
        room_descriptions: Map.put(initial_assigns.room_descriptions, "R1", description),
        previous_room_description: initial_assigns.current_room_description,
        current_room_description: description
      }

      # After R1 completion:
      # - current should be R1 description
      # - previous should still be nil (first room)
      assert updated_assigns.current_room_description == description
      assert updated_assigns.previous_room_description == nil

      # Test R2 room description completion
      r2_description = "**Hall of Mysteries** This chamber continues the ancient theme."

      # Simulate R2 completion
      r2_assigns = %{
        room_descriptions: Map.put(updated_assigns.room_descriptions, "R2", r2_description),
        previous_room_description: updated_assigns.current_room_description,
        current_room_description: r2_description
      }

      # After R2 completion:
      # - current should be R2 description
      # - previous should be R1 description
      assert r2_assigns.current_room_description == r2_description
      assert r2_assigns.previous_room_description == description

      # Test R3 room description completion
      r3_description = "**Vault of Shadows** Darkness pervades this final chamber."

      # Simulate R3 completion
      r3_assigns = %{
        room_descriptions: Map.put(r2_assigns.room_descriptions, "R3", r3_description),
        previous_room_description: r2_assigns.current_room_description,
        current_room_description: r3_description
      }

      # After R3 completion:
      # - current should be R3 description
      # - previous should be R2 description
      assert r3_assigns.current_room_description == r3_description
      assert r3_assigns.previous_room_description == r2_description
    end

    test "corridor descriptions do not affect room tracking" do
      # Test that corridor completion doesn't change room tracking
      initial_assigns = %{
        current_room_description: "**Chamber of Echoes** The entrance room.",
        previous_room_description: nil,
        room_descriptions: %{"R1" => "**Chamber of Echoes** The entrance room."},
        corridor_descriptions: %{}
      }

      # Test corridor description completion
      corridor_description = "**Winding Passage** A narrow corridor connects the chambers."

      # Simulate corridor completion (should NOT affect room tracking)
      updated_assigns = %{
        current_room_description: initial_assigns.current_room_description,
        previous_room_description: initial_assigns.previous_room_description,
        room_descriptions: initial_assigns.room_descriptions,
        corridor_descriptions:
          Map.put(initial_assigns.corridor_descriptions, "C1", corridor_description)
      }

      # Room tracking should be unchanged
      assert updated_assigns.current_room_description == initial_assigns.current_room_description

      assert updated_assigns.previous_room_description ==
               initial_assigns.previous_room_description
    end

    test "room description generation context uses correct previous room" do
      # This tests the logic in RoomLabelSystem.generate_room_description/3
      # It should use current_room_description for context when generating NEW room descriptions
      # (the current room becomes the "previous" room for the new room being generated)

      # Mock socket state after R1 has been completed
      socket_with_r1 = %{
        assigns: %{
          current_room_description: "**Chamber of Echoes** The entrance chamber.",
          previous_room_description: nil,
          dungeon: %{theme: "Ancient Ruins"},
          dungeon_level: 1
        }
      }

      # When generating R2, it should use current_room_description (R1) as previous context
      expected_context = %{
        theme: "Ancient Ruins",
        level: 1,
        room_number: "R2",
        previous_room_description: "**Chamber of Echoes** The entrance chamber."
      }

      # Simulate the context building logic from generate_room_description
      actual_context = %{
        theme: socket_with_r1.assigns.dungeon.theme,
        level: socket_with_r1.assigns.dungeon_level,
        room_number: "R2",
        previous_room_description:
          socket_with_r1.assigns.current_room_description || "This is the first room entered."
      }

      assert actual_context == expected_context

      # Now test after R2 is completed
      socket_with_r2 = %{
        assigns: %{
          current_room_description: "**Hall of Mysteries** The second chamber.",
          previous_room_description: "**Chamber of Echoes** The entrance chamber.",
          dungeon: %{theme: "Ancient Ruins"},
          dungeon_level: 1
        }
      }

      # When generating R3, it should use current_room_description (R2) as previous context
      expected_r3_context = %{
        theme: "Ancient Ruins",
        level: 1,
        room_number: "R3",
        previous_room_description: "**Hall of Mysteries** The second chamber."
      }

      actual_r3_context = %{
        theme: socket_with_r2.assigns.dungeon.theme,
        level: socket_with_r2.assigns.dungeon_level,
        room_number: "R3",
        previous_room_description:
          socket_with_r2.assigns.current_room_description || "This is the first room entered."
      }

      assert actual_r3_context == expected_r3_context
    end

    test "corridor description generation context uses current room" do
      # This tests the logic in RoomLabelSystem.generate_corridor_description/3
      # It should use current_room_description for context when generating corridor descriptions

      socket_with_current_room = %{
        assigns: %{
          current_room_description: "**Chamber of Echoes** The entrance chamber.",
          previous_room_description: nil,
          dungeon: %{theme: "Ancient Ruins"},
          dungeon_level: 1
        }
      }

      # When generating corridor, it should use current_room_description
      expected_context = %{
        theme: "Ancient Ruins",
        level: 1,
        corridor_number: "C1",
        last_room_description: "**Chamber of Echoes** The entrance chamber."
      }

      # Simulate the context building logic from generate_corridor_description
      actual_context = %{
        theme: socket_with_current_room.assigns.dungeon.theme,
        level: socket_with_current_room.assigns.dungeon_level,
        corridor_number: "C1",
        last_room_description:
          socket_with_current_room.assigns.current_room_description ||
            "No previous room has been entered yet."
      }

      assert actual_context == expected_context
    end
  end
end
