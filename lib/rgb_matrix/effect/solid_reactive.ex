defmodule RGBMatrix.Effect.SolidReactive do
  @moduledoc """
  Static single hue, pulses keys hit to shifted hue then fades to current hue.
  """

  alias Chameleon.HSV
  alias RGBMatrix.Effect

  use Effect

  import RGBMatrix.Utils, only: [mod: 2]

  defmodule State do
    defstruct [:tick, :speed, :color, :leds, :hits]
  end

  @delay_ms 17

  @impl true
  def new(leds) do
    # TODO: configurable base color
    color = HSV.new(190, 100, 100)
    {0, %State{tick: 0, speed: 100, color: color, leds: leds, hits: %{}}}
  end

  @impl true
  def render(state) do
    %{tick: tick, speed: _speed, color: color, leds: leds, hits: hits} = state

    {colors, hits} =
      Enum.map_reduce(leds, hits, fn led, hits ->
        case hits do
          %{^led => {hit_tick, direction}} ->
            if tick - hit_tick >= 180 do
              {color, Map.delete(hits, led)}
            else
              hue = mod(color.h + (tick - hit_tick - 180) * direction, 360)
              {HSV.new(hue, color.s, color.v), hits}
            end

          _else ->
            {color, hits}
        end
      end)

    {colors, @delay_ms, %{state | tick: tick + 1, hits: hits}}
  end

  @impl true
  def key_pressed(state, led) do
    direction = Enum.random([-1, 1])
    {:ignore, %{state | hits: Map.put(state.hits, led, {state.tick, direction})}}
  end
end
