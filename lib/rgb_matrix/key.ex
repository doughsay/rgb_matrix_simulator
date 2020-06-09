defmodule RGBMatrix.Key do
  @moduledoc """
  Describes a physical key and its location.
  """

  defstruct [:x, :y, :width, :height]

  def new(x, y, width \\ 1, height \\ 1) do
    struct!(__MODULE__, x: x, y: y, width: width, height: height)
  end
end
