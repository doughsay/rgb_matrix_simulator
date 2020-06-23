defmodule RGBMatrix.Effect.RandomKeypresses do
  @moduledoc """
  Changes every key pressed to a random color.
  """

  alias Chameleon.HSV
  alias RGBMatrix.Effect

  use Effect

  defmodule Config do
    use RGBMatrix.Effect.Config
  end

  defmodule State do
    defstruct [:led_colors]
  end

  @impl true
  def new(leds, _config) do
    {0,
     %State{
       led_colors: Enum.map(leds, fn led -> {led, random_color()} end)
     }}
  end

  defp random_color do
    HSV.new((:rand.uniform() * 360) |> trunc(), 100, 100)
  end

  @impl true
  def render(state, _config) do
    %{led_colors: led_colors} = state

    colors = Enum.map(led_colors, fn {_led, color} -> color end)

    {colors, :never, state}
  end

  @impl true
  def key_pressed(state, _config, led) do
    led_colors =
      Enum.map(state.led_colors, fn
        {^led, _color} -> {led, random_color()}
        {led, color} -> {led, color}
      end)

    {0, %{state | led_colors: led_colors}}
  end
end
