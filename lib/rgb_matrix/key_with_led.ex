defmodule RGBMatrix.KeyWithLED do
  @moduledoc """
  A key with an LED.
  """

  alias RGBMatrix.{LED, Key}

  defstruct [:key, :led]

  def new(x, y, width \\ 1, height \\ 1) do
    struct!(__MODULE__, key: Key.new(x, y, width, height), led: LED.new(x, y))
  end
end
