defmodule RGBMatrix.LED do
  @moduledoc """
  Describes a physical LED location.
  """

  defstruct [:x, :y]

  def new(x, y) do
    struct!(__MODULE__, x: x, y: y)
  end
end
