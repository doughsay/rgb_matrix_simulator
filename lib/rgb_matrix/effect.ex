defmodule RGBMatrix.Effect do
  alias RGBMatrix.LED

  @callback init_state(leds :: list(LED.t())) :: t
  @callback next_state(effect :: t) :: t

  @type t :: %__MODULE__{
          type: type,
          state: any,
          leds: list(LED.t()),
          led_colors: list(RGBMatrix.any_color_model()),
          next_call: integer | :infinity
        }
  defstruct [:type, :state, :leds, :led_colors, :next_call]

  defmacro __using__(_) do
    quote do
      @behaviour RGBMatrix.Effect
    end
  end

  @type type ::
          __MODULE__.CycleAll
          | __MODULE__.CycleLeftToRight
          | __MODULE__.Pinwheel

  @doc """
  Returns a list of the available types of animations.
  """
  @spec types :: list(type)
  def types do
    [
      __MODULE__.CycleAll,
      __MODULE__.CycleLeftToRight,
      __MODULE__.Pinwheel
    ]
  end

  @doc """
  Returns an effect's initial state.
  """
  @spec init_state(effect_type :: type, leds :: list(LED.t())) :: any
  def init_state(effect_type, leds) do
    effect_type.init_state(leds)
  end

  @doc """
  Returns the next state of an effect based on its current state.
  """
  @spec next_state(effect :: t) :: t
  def next_state(effect) do
    effect.type.next_state(effect)
  end
end
