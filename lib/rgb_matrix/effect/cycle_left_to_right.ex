defmodule RGBMatrix.Effect.CycleLeftToRight do
  @moduledoc """
  Cycles the hue of all LEDs in a left-to-right line.
  """

  alias Chameleon.HSV
  alias RGBMatrix.{Effect, LED}

  use Effect

  import RGBMatrix.Utils, only: [mod: 2]

  defmodule State do
    defstruct [:tick, :speed]
  end

  @delay_ms 17

  @impl true
  def new(leds) do
    %Effect{
      type: __MODULE__,
      state: %State{tick: 0, speed: 100},
      leds: leds,
      next_call: @delay_ms
    }
  end

  @impl true
  def render(effect) do
    %{state: %{tick: tick, speed: speed} = state, leds: leds} = effect

    time = div(tick * speed, 100)

    colors =
      for %LED{x: x} <- leds do
        hue = mod(trunc(x * 10) - time, 360)
        HSV.new(hue, 100, 100)
      end

    {colors, %{effect | state: %{state | tick: tick + 1}}}
  end

  @impl true
  def key_pressed(effect, _led) do
    effect
  end
end
