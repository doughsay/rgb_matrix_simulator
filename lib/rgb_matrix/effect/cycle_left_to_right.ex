defmodule RGBMatrix.Effect.CycleLeftToRight do
  @moduledoc """
  Cycles the hue of all LEDs in a left-to-right line.
  """

  alias Chameleon.HSV
  alias RGBMatrix.{Effect, LED}

  use Effect

  import RGBMatrix.Utils, only: [mod: 2]

  defmodule State do
    defstruct [:tick, :speed, :leds, :width, :steps]
  end

  @delay_ms 17

  # suggested limits
  # @max_speed 12
  # @min_speed -12

  # @max_width 100
  # @min_width 10

  @impl true
  def new(leds) do
    width = 20
    steps = 360 / width
    {0, %State{tick: 0, speed: -5, leds: leds, width: width, steps: steps}}
  end

  @impl true
  def render(state) do
    %{tick: tick, speed: speed, leds: leds, steps: steps} = state

    time = div(tick * speed, 5)

    colors =
      for %LED{x: x} <- leds do
        hue = mod(trunc(x * steps) + time, 360)
        HSV.new(hue, 100, 100)
      end

    {colors, @delay_ms, %{state | tick: tick + 1}}
  end

  @impl true
  def key_pressed(state, _led) do
    {:ignore, state}
  end
end
