defmodule RGBMatrix.Effect.SolidColor do
  @moduledoc """
  All LEDs are a solid color.
  """

  alias Chameleon.HSV
  alias RGBMatrix.Effect

  use Effect

  defmodule State do
    defstruct [:color, :led_count]
  end

  @impl true
  def new(leds) do
    # TODO: configurable base color
    color = HSV.new(120, 100, 100)
    {0, %State{color: color, led_count: length(leds)}}
  end

  @impl true
  def render(state) do
    %{color: color, led_count: led_count} = state

    colors = Enum.map(1..led_count, fn _ -> color end)

    {colors, :never, state}
  end

  @impl true
  def key_pressed(state, _led) do
    {:ignore, state}
  end
end
