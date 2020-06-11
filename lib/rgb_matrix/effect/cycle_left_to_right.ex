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

  @max_speed 16
  @min_speed 0

  @max_width 100
  @min_width 10

  @impl true
  def new(leds) do
    width = 20
    steps = 360 / width
    {0, %State{tick: 0, speed: 5, leds: leds, width: width, steps: steps}}
  end

  @impl true
  def render(state) do
    %{tick: tick, speed: speed, leds: leds, steps: steps} = state

    time = div(tick * speed, 5)

    colors =
      for %LED{x: x} <- leds do
        hue = mod(trunc(x * steps) - time, 360)
        HSV.new(hue, 100, 100)
      end

    {colors, @delay_ms, %{state | tick: tick + 1}}
  end

  @impl true
  def key_pressed(state, _led) do
    {:ignore, state}
  end

  @impl true
  def inc(%{speed: speed} = state, :speed) do
    speed = if speed == @max_speed, do: speed, else: speed + 1
    {:ignore, %{state | speed: speed}}
  end

  def inc(%{width: width} = state, :width) do
    width = if width == @max_width, do: width, else: width + 10
    steps = 360 / width
    {:ignore, %{state | width: width, steps: steps}}
  end

  def inc(state, _property) do
    {:ignore, state}
  end

  @impl true
  def dec(%{speed: speed} = state, :speed) do
    speed = if speed == @min_speed, do: speed, else: speed - 1
    {:ignore, %{state | speed: speed}}
  end

  def dec(%{width: width} = state, :width) do
    width = if width == @min_width, do: width, else: width - 10
    steps = 360 / width
    {:ignore, %{state | width: width, steps: steps}}
  end

  def dec(state, _property) do
    {:ignore, state}
  end
end
