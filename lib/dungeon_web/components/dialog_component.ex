defmodule DungeonWeb.Components.DialogComponent do
  @moduledoc """
  Reusable dialog component for all dungeon dialogs
  """
  use Phoenix.Component
  import Phoenix.HTML, only: [raw: 1]
  alias Phoenix.LiveView.JS

  @doc """
  Renders a modal dialog with customizable styling and content
  """
  attr :show, :boolean, required: true
  attr :title, :string, required: true
  attr :icon, :string, required: true
  attr :color_scheme, :string, default: "blue", values: ~w(blue green red yellow gray)
  attr :content, :string, required: true
  attr :scrollable, :boolean, default: true
  attr :buttons, :list, default: []
  attr :max_width, :boolean, default: true
  attr :buttons_disabled, :boolean, default: false

  def dialog(assigns) do
    ~H"""
    <%= if @show do %>
      <div class="fixed inset-0 bg-black bg-opacity-25 flex items-center justify-center z-50">
        <div class={[
          "bg-black bg-opacity-25 backdrop-blur-sm p-4 rounded-lg shadow-xl border-2",
          border_color(@color_scheme),
          if(@max_width, do: "max-w-lg w-full mx-4", else: "mx-4")
        ]}>
          <div class="flex items-center mb-3">
            <span class="text-3xl mr-3">{raw(@icon)}</span>
            <h3 class={["text-lg font-bold", title_color(@color_scheme)]}>{raw(@title)}</h3>
          </div>

          <%= if @scrollable do %>
            <div class="mb-4 max-h-64 overflow-y-auto">
              <div class={["whitespace-pre-wrap", content_color(@color_scheme)]}>
                {raw(@content)}
              </div>
            </div>
          <% else %>
            <div class={["mb-4", content_color(@color_scheme)]}>
              {raw(@content)}
            </div>
          <% end %>

          <%= if length(@buttons) > 0 do %>
            <div class="flex space-x-4 justify-center">
              <%= for button <- @buttons do %>
                <button
                  class={[
                    "btn",
                    button_class(button[:variant] || "primary"),
                    @buttons_disabled && "btn-disabled opacity-50 cursor-not-allowed"
                  ]}
                  phx-click={
                    unless @buttons_disabled,
                      do: JS.push(button[:action]) |> JS.focus(to: "#dungeon-map")
                  }
                  disabled={@buttons_disabled}
                >
                  {raw(button[:text])}
                </button>
              <% end %>
            </div>
          <% end %>
        </div>
      </div>
    <% end %>
    """
  end

  # Color scheme helpers
  defp border_color("blue"), do: "border-blue-400"
  defp border_color("green"), do: "border-green-400"
  defp border_color("red"), do: "border-red-400"
  defp border_color("yellow"), do: "border-yellow-400"
  defp border_color("gray"), do: "border-gray-400"

  defp title_color("blue"), do: "text-blue-100"
  defp title_color("green"), do: "text-green-100"
  defp title_color("red"), do: "text-red-100"
  defp title_color("yellow"), do: "text-yellow-100"
  defp title_color("gray"), do: "text-white"

  defp content_color("blue"), do: "text-blue-200"
  defp content_color("green"), do: "text-green-200"
  defp content_color("red"), do: "text-red-200"
  defp content_color("yellow"), do: "text-yellow-200"
  defp content_color("gray"), do: "text-gray-200"

  defp button_class("primary"), do: "btn-primary"
  defp button_class("secondary"), do: "btn-secondary"
  defp button_class("success"), do: "btn-success text-white"
  defp button_class("warning"), do: "btn-warning text-black"
  defp button_class("error"), do: "btn-error text-white"
  defp button_class("info"), do: "btn-info text-white"
end
