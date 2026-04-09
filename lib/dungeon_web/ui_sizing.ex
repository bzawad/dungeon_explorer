defmodule DungeonWeb.UISizing do
  @moduledoc """
  Centralized UI sizing configuration for the Dungeon app.

  This module defines all image sizes, UI dimensions, and responsive breakpoints
  in one location to make the app more maintainable and easier to test different
  sizing configurations.
  """

  # =============================================================================
  # IMAGE SIZES
  # =============================================================================

  @doc """
  Get Tailwind classes for different image size categories
  """
  def image_size(size_name) do
    case size_name do
      # 24x24px - Tiny tile symbols in print view (doubled from 12px)
      :tiny_icon -> "w-6 h-6"
      # 32x32px - UI controls, inline icons (doubled from 16px)
      :small_icon -> "w-8 h-8"
      # 48x48px - Game elements, food items (doubled from 24px)
      :medium_icon -> "w-12 h-12"
      # 128x128px - Main title/logo (doubled from 64px)
      :large_icon -> "w-32 h-32"
      # 32x32px - Loading indicators (doubled from 16px)
      :loading_icon -> "w-8 h-8"
      # Default fallback (doubled from 16px)
      _ -> "w-8 h-8"
    end
  end

  @doc """
  Get complete image classes including size and common styling
  """
  def image_classes(size_name, extra_classes \\ []) do
    base_classes = ["object-contain"]
    size_classes = [image_size(size_name)]
    all_classes = base_classes ++ size_classes ++ List.wrap(extra_classes)
    Enum.join(all_classes, " ")
  end

  @doc """
  Get inline image classes for text content
  """
  def inline_image_classes(size_name \\ :small_icon) do
    image_classes(size_name, ["inline"])
  end

  # =============================================================================
  # UI COMPONENT SIZES
  # =============================================================================

  @doc """
  Get Tailwind classes for UI component dimensions
  """
  def component_size(component_name) do
    cond do
      component_name in [:action_button, :control_button] ->
        button_size(component_name)

      component_name in [:sidebar_desktop, :modal_mobile, :dialog_content] ->
        container_size(component_name)

      component_name in [:progress_bar] ->
        form_element_size(component_name)

      component_name in [:dashboard_section, :control_spacing] ->
        spacing_size(component_name)

      true ->
        ""
    end
  end

  # Private sizing functions for different categories

  defp button_size(:action_button), do: "w-10 h-10"
  defp button_size(:control_button), do: "min-h-0 h-10"

  defp container_size(:sidebar_desktop), do: "w-64"
  defp container_size(:modal_mobile), do: "w-80 sm:w-96"
  defp container_size(:dialog_content), do: "max-h-64"

  defp form_element_size(:progress_bar), do: "h-2"

  defp spacing_size(:dashboard_section), do: "p-3"
  defp spacing_size(:control_spacing), do: "gap-2"

  # =============================================================================
  # MAP TILE SIZES
  # =============================================================================

  @doc """
  Get map tile dimensions for different screen sizes
  """
  def tile_size(screen_size) do
    case screen_size do
      :mobile -> "48px"
      # Can be adjusted as needed
      :desktop -> "48px"
      # Default
      _ -> "48px"
    end
  end

  @doc """
  Get CSS custom properties for map tiles
  """
  def tile_css_vars do
    %{
      "--tile-size-mobile" => tile_size(:mobile),
      "--tile-size-desktop" => tile_size(:desktop)
    }
  end

  # =============================================================================
  # RESPONSIVE BREAKPOINTS
  # =============================================================================

  @doc """
  Get responsive breakpoint values
  """
  def breakpoint(name) do
    case name do
      :mobile -> "768px"
      :tablet -> "1024px"
      :desktop -> "1280px"
      _ -> "768px"
    end
  end

  # =============================================================================
  # SIZING PRESETS
  # =============================================================================

  @doc """
  Get predefined sizing combinations for common UI patterns
  """
  def preset(preset_name) do
    case preset_name do
      :dashboard_icon ->
        %{
          size: :small_icon,
          classes: inline_image_classes(:small_icon)
        }

      :game_element_icon ->
        %{
          size: :medium_icon,
          classes: image_classes(:medium_icon)
        }

      :control_button_icon ->
        %{
          size: :small_icon,
          classes: inline_image_classes(:small_icon)
        }

      :loading_indicator ->
        %{
          size: :loading_icon,
          classes: inline_image_classes(:loading_icon)
        }

      _ ->
        %{size: :small_icon, classes: inline_image_classes(:small_icon)}
    end
  end

  # =============================================================================
  # UTILITY FUNCTIONS
  # =============================================================================

  @doc """
  Generate img tag with proper sizing
  """
  def img_tag(src, alt, size_name, extra_classes \\ []) do
    classes = image_classes(size_name, extra_classes)
    "<img src='#{src}' alt='#{alt}' class='#{classes}' />"
  end

  @doc """
  Generate inline img tag for text content
  """
  def inline_img_tag(src, alt, size_name \\ :small_icon) do
    classes = inline_image_classes(size_name)
    "<img src='#{src}' alt='#{alt}' class='#{classes}' />"
  end

  @doc """
  Get all available size options (useful for documentation/testing)
  """
  def available_sizes do
    [:tiny_icon, :small_icon, :medium_icon, :large_icon, :loading_icon]
  end

  @doc """
  Get size dimensions in pixels for reference
  """
  def size_in_pixels(size_name) do
    case size_name do
      :tiny_icon -> "24x24"
      :small_icon -> "32x32"
      :medium_icon -> "48x48"
      :large_icon -> "128x128"
      :loading_icon -> "32x32"
      _ -> "32x32"
    end
  end
end
