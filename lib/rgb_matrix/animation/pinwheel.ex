defmodule RGBMatrix.Animation.Pinwheel do
  @moduledoc """
  Cycles hue in a pinwheel pattern.
  """

  alias Chameleon.HSV

  alias RGBMatrix.Animation

  import RGBMatrix.Utils, only: [mod: 2]

  use Animation

  @impl true
  def next_state(animation) do
    %Animation{tick: tick, speed: speed, pixels: pixels} = animation
    time = div(tick * speed, 100)

    center = determine_center(pixels)

    pixel_colors =
      for {x, y} <- pixels do
        dx = x - center.x
        dy = y - center.y

        hue = mod(atan2_8(dy, dx) + time, 360)

        HSV.new(hue, 100, 100)
      end

    %Animation{animation | pixel_colors: pixel_colors}
    |> do_tick()
  end

  defp atan2_8(x, y) do
    atan = :math.atan2(x, y)

    trunc((atan + :math.pi()) * 359 / (2 * :math.pi()))
  end

  defp determine_center(pixels) do
    {{min_x, _}, {max_x, _}} = Enum.min_max_by(pixels, &elem(&1, 0))
    {{_, min_y}, {_, max_y}} = Enum.min_max_by(pixels, &elem(&1, 1))

    %{
      x: (max_x - min_x) / 2 + min_x,
      y: (max_y - min_y) / 2 + min_y
    }
  end
end
