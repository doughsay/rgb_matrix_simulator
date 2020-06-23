defmodule RGBMatrix.Effect.Breathing do
  @moduledoc """
  Single hue brightness cycling.
  """

  alias Chameleon.HSV
  alias RGBMatrix.Effect

  use Effect

  defmodule Config do
    use RGBMatrix.Effect.Config
  end

  defmodule State do
    defstruct [:color, :tick, :speed, :led_count]
  end

  @delay_ms 17

  @impl true
  def new(leds, _config) do
    # TODO: configurable base color
    color = HSV.new(40, 100, 100)
    {0, %State{color: color, tick: 0, speed: 100, led_count: length(leds)}}
  end

  @impl true
  def render(state, _config) do
    %{color: base_color, tick: tick, speed: speed, led_count: led_count} = state

    value = trunc(abs(:math.sin(tick * speed / 5_000)) * base_color.v)
    color = HSV.new(base_color.h, base_color.s, value)

    colors = Enum.map(1..led_count, fn _ -> color end)

    {colors, @delay_ms, %{state | tick: tick + 1}}
  end

  @impl true
  def key_pressed(state, _config, _led) do
    {:ignore, state}
  end
end
