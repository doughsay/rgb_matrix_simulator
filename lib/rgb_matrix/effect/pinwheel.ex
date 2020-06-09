defmodule RGBMatrix.Effect.Pinwheel do
  @moduledoc """
  Cycles hue in a pinwheel pattern.
  """

  alias Chameleon.HSV
  alias RGBMatrix.{Effect, LED}

  use Effect

  import RGBMatrix.Utils, only: [mod: 2]

  defmodule State do
    defstruct [:tick, :speed, :center]
  end

  @delay_ms 17

  @impl true
  def init_state(leds) do
    %Effect{
      type: __MODULE__,
      state: %State{tick: 0, speed: 100, center: determine_center(leds)},
      leds: leds,
      led_colors: nil,
      next_call: @delay_ms
    }
  end

  defp determine_center(leds) do
    {%{x: min_x}, %{x: max_x}} = Enum.min_max_by(leds, & &1.x)
    {%{y: min_y}, %{y: max_y}} = Enum.min_max_by(leds, & &1.y)

    %{
      x: (max_x - min_x) / 2 + min_x,
      y: (max_y - min_y) / 2 + min_y
    }
  end

  @impl true
  def next_state(effect) do
    %{state: %{tick: tick, speed: speed, center: center} = state, leds: leds} = effect

    time = div(tick * speed, 100)

    colors =
      for %LED{x: x, y: y} <- leds do
        dx = x - center.x
        dy = y - center.y

        hue = mod(atan2_8(dy, dx) + time, 360)

        HSV.new(hue, 100, 100)
      end

    %{
      effect
      | led_colors: colors,
        state: %{state | tick: tick + 1}
    }
  end

  defp atan2_8(x, y) do
    atan = :math.atan2(x, y)

    trunc((atan + :math.pi()) * 359 / (2 * :math.pi()))
  end

  @impl true
  def key_pressed(effect, {x, y}) do
    %{
      effect
      | state: %{effect.state | center: %{x: x, y: y}}
    }
  end
end
