defmodule RGBMatrix.Effect.CycleLeftToRight do
  @moduledoc """
  Cycles the hue of all LEDs in a left-to-right line.
  """

  alias Chameleon.HSV
  alias RGBMatrix.{Effect, LED}

  use Effect

  import RGBMatrix.Utils, only: [mod: 2]

  defmodule State do
    defstruct [:tick, :speed, :leds]
  end

  @delay_ms 17

  @impl true
  def new(leds) do
    {0, %State{tick: 0, speed: 100, leds: leds}}
  end

  @impl true
  def render(state) do
    %{tick: tick, speed: speed, leds: leds} = state

    time = div(tick * speed, 100)

    colors =
      for %LED{x: x} <- leds do
        hue = mod(trunc(x * 10) - time, 360)
        HSV.new(hue, 100, 100)
      end

    {colors, @delay_ms, %{state | tick: tick + 1}}
  end

  @impl true
  def key_pressed(state, _led) do
    {:ignore, state}
  end
end
