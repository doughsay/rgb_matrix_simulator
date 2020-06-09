defmodule RGBMatrix.Effect.CycleAll do
  @moduledoc """
  Cycles the hue of all LEDs at the same time.
  """

  alias Chameleon.HSV
  alias RGBMatrix.Effect

  use Effect

  import RGBMatrix.Utils, only: [mod: 2]

  defmodule State do
    defstruct [:tick, :speed]
  end

  @delay_ms 17

  @impl true
  def init_state(leds) do
    %Effect{
      type: __MODULE__,
      state: %State{tick: 0, speed: 100},
      leds: leds,
      led_colors: nil,
      next_call: @delay_ms
    }
  end

  @impl true
  def next_state(effect) do
    %{state: %{tick: tick, speed: speed} = state, leds: leds} = effect

    time = div(tick * speed, 100)
    hue = mod(time, 360)
    color = HSV.new(hue, 100, 100)

    colors = Enum.map(leds, fn _led -> color end)

    %{
      effect
      | led_colors: colors,
        state: %{state | tick: tick + 1}
    }
  end
end
