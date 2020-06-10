defmodule RGBMatrix.Effect.RandomSolid do
  @moduledoc """
  A random solid color fills the entire matrix and changes every key-press.
  """

  alias Chameleon.HSV
  alias RGBMatrix.Effect

  use Effect

  defmodule State do
    defstruct [:led_count]
  end

  @impl true
  def new(leds) do
    {0, %State{led_count: length(leds)}}
  end

  @impl true
  def render(state) do
    %{led_count: led_count} = state

    color = random_color()

    colors = Enum.map(1..led_count, fn _led -> color end)

    {colors, :never, state}
  end

  @impl true
  def key_pressed(state, _led) do
    {0, state}
  end

  defp random_color do
    HSV.new((:rand.uniform() * 360) |> trunc(), 100, 100)
  end
end
