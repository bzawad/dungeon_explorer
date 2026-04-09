defmodule DungeonWeb.UIComponents do
  @moduledoc """
  UI components using centralized sizing from UISizing module.

  This demonstrates the refactored patterns for consistent image and component sizing.
  """

  use DungeonWeb, :html

  @doc """
  Dashboard control button with icon
  """
  attr :phx_click, :string, required: true
  attr :icon_src, :string, required: true
  attr :icon_alt, :string, required: true
  attr :text, :string, required: true
  attr :class, :string, default: "btn btn-primary btn-sm"

  def control_button(assigns) do
    ~H"""
    <button class={@class} phx-click={@phx_click}>
      <img src={@icon_src} alt={@icon_alt} class={inline_image_classes(:small_icon)} />
      {@text}
    </button>
    """
  end

  @doc """
  Dashboard stat display with icon and progress bar
  """
  attr :icon_src, :string, required: true
  attr :icon_alt, :string, required: true
  attr :label, :string, required: true
  attr :current_value, :integer, required: true
  attr :max_value, :integer, default: nil
  attr :display_value, :string, default: nil
  attr :color_class, :string, default: "text-white"
  attr :progress_color, :string, default: "bg-blue-500"

  def dashboard_stat(assigns) do
    assigns =
      assigns
      |> assign_new(:show_progress, fn -> not is_nil(assigns[:max_value]) end)
      |> assign_new(:display_text, fn -> build_display_text(assigns) end)
      |> assign_new(:progress_percentage, fn -> calculate_progress_percentage(assigns) end)

    ~H"""
    <div class="mb-4 p-3 bg-gray-700 rounded">
      <div class="flex justify-between items-center mb-1">
        <span class="text-sm text-gray-300 flex items-center gap-1">
          <img src={@icon_src} alt={@icon_alt} class={inline_image_classes(:small_icon)} />
          {@label}
        </span>
        <span class={"text-sm #{@color_class}"}>
          {@display_text}
        </span>
      </div>
      <div
        :if={@show_progress}
        class={"w-full bg-gray-600 rounded-full #{component_size(:progress_bar)}"}
      >
        <div
          class={"#{component_size(:progress_bar)} rounded-full transition-all duration-300 #{@progress_color}"}
          style={"width: #{@progress_percentage}%"}
        >
        </div>
      </div>
    </div>
    """
  end

  @doc """
  Game element icon with consistent sizing
  """
  attr :src, :string, required: true
  attr :alt, :string, required: true
  attr :size, :atom, default: :medium_icon
  attr :extra_classes, :list, default: []

  def game_icon(assigns) do
    ~H"""
    <img src={@src} alt={@alt} class={image_classes(@size, @extra_classes)} />
    """
  end

  @doc """
  Loading indicator with consistent styling
  """
  attr :text, :string, default: "Loading..."

  def loading_indicator(assigns) do
    ~H"""
    <span>
      <img src="/images/hourglass.png" alt="Loading" class={inline_image_classes(:loading_icon)} />
      {@text}
    </span>
    """
  end

  @doc """
  Action button with icon for movement/game controls
  """
  attr :phx_click, :string, required: true
  attr :icon_src, :string, required: true
  attr :icon_alt, :string, required: true
  attr :class, :string, default: "btn btn-sm p-2"
  attr :button_size, :atom, default: :action_button

  def action_button(assigns) do
    assigns =
      assign_new(assigns, :full_class, fn ->
        "#{assigns.class} #{component_size(assigns.button_size)}"
      end)

    ~H"""
    <button class={@full_class} phx-click={@phx_click}>
      <.game_icon src={@icon_src} alt={@icon_alt} size={:medium_icon} />
    </button>
    """
  end

  # Private helper functions

  defp build_display_text(assigns) do
    if assigns[:display_value] do
      assigns.display_value
    else
      if assigns[:max_value] do
        "#{assigns.current_value}/#{assigns.max_value}"
      else
        to_string(assigns.current_value)
      end
    end
  end

  defp calculate_progress_percentage(assigns) do
    if assigns[:max_value] && assigns.max_value > 0 do
      assigns.current_value / assigns.max_value * 100
    else
      0
    end
  end
end
