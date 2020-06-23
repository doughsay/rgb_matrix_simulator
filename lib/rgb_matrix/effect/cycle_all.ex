defmodule RGBMatrix.Effect.CycleAll do
  @moduledoc """
  Cycles the hue of all LEDs at the same time.
  """

  alias Chameleon.HSV
  alias RGBMatrix.Effect

  use Effect

  import RGBMatrix.Utils, only: [mod: 2]

  defmodule Config do
    use RGBMatrix.Effect.Config
  end

  defmodule State do
    defstruct [:tick, :speed, :led_count]
  end

  @delay_ms 17

  @impl true
  def new(leds, _config) do
    {0, %State{tick: 0, speed: 100, led_count: length(leds)}}
  end

  @impl true
  def render(state, _config) do
    %{tick: tick, speed: speed, led_count: led_count} = state

    time = div(tick * speed, 100)
    hue = mod(time, 360)
    color = HSV.new(hue, 100, 100)

    colors = Enum.map(1..led_count, fn _ -> color end)

    {colors, @delay_ms, %{state | tick: tick + 1}}
  end

  @impl true
  def key_pressed(state, _config, _led) do
    {:ignore, state}
  end
end
