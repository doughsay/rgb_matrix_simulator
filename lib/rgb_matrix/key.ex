defmodule RGBMatrix.Key do
  @moduledoc """
  Describes a physical key and its location.
  """

  @type t :: %__MODULE__{
          x: float,
          y: float,
          width: float,
          height: float
        }
  defstruct [:x, :y, :width, :height]

  def new(x, y, width \\ 1, height \\ 1) do
    struct!(__MODULE__, x: x, y: y, width: width, height: height)
  end
end
