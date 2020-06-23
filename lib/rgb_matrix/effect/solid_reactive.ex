defmodule RGBMatrix.Effect.SolidReactive do
  @moduledoc """
  Static single hue, pulses keys hit to shifted hue then fades to current hue.
  """

  alias Chameleon.HSV
  alias RGBMatrix.Effect

  use Effect

  import RGBMatrix.Utils, only: [mod: 2]

  defmodule Config do
    use RGBMatrix.Effect.Config

    @doc name: "Speed",
         description: """
         The speed at which the hue shifts back to base.
         """
    field :speed, :integer, default: 4, min: 0, max: 32

    @doc name: "Distance",
         description: """
         The distance that the hue shifts on key-press.
         """
    field :distance, :integer, default: 180, min: 0, max: 360, step: 10

    @doc name: "Direction",
         description: """
         The direction (through the color wheel) that the hue shifts on key-press.
         """
    field :direction, :option,
      default: :random,
      options: [
        :random,
        :negative,
        :positive
      ]
  end

  defmodule State do
    defstruct [:tick, :color, :leds, :hits]
  end

  @delay_ms 17

  @impl true
  def new(leds, _config) do
    # TODO: configurable base color
    color = HSV.new(190, 100, 100)
    {0, %State{tick: 0, color: color, leds: leds, hits: %{}}}
  end

  @impl true
  def render(state, config) do
    %{tick: tick, color: color, leds: leds, hits: hits} = state
    %{speed: _speed, distance: distance} = config

    {colors, hits} =
      Enum.map_reduce(leds, hits, fn led, hits ->
        case hits do
          %{^led => {hit_tick, direction_modifier}} ->
            # TODO: take speed into account
            if tick - hit_tick >= distance do
              {color, Map.delete(hits, led)}
            else
              hue = mod(color.h + (tick - hit_tick - distance) * direction_modifier, 360)
              {HSV.new(hue, color.s, color.v), hits}
            end

          _else ->
            {color, hits}
        end
      end)

    {colors, @delay_ms, %{state | tick: tick + 1, hits: hits}}
  end

  @impl true
  def key_pressed(state, config, led) do
    direction = direction_modifier(config.direction)
    {:ignore, %{state | hits: Map.put(state.hits, led, {state.tick, direction})}}
  end

  defp direction_modifier(:random), do: Enum.random([-1, 1])
  defp direction_modifier(:negative), do: -1
  defp direction_modifier(:positive), do: 1
end
