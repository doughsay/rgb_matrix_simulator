defmodule RGBMatrix.Effect do
  alias RGBMatrix.LED

  @callback new(leds :: list(LED.t())) :: t
  @callback render(effect :: t) :: {list(RGBMatrix.any_color_model()), t}
  @callback key_pressed(effect :: t, LED.t()) :: t

  @type t :: %__MODULE__{
          type: type,
          state: any,
          leds: list(LED.t()),
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
  @spec new(effect_type :: type, leds :: list(LED.t())) :: t
  def new(effect_type, leds) do
    effect_type.new(leds)
  end

  @doc """
  Returns the next state of an effect based on its current state.
  """
  @spec render(effect :: t) :: {list(RGBMatrix.any_color_model()), t}
  def render(effect) do
    effect.type.render(effect)
  end

  @doc """
  Sends a key pressed event to an effect.
  """
  @spec key_pressed(effect :: t, led :: LED.t()) :: t
  def key_pressed(effect, led) do
    effect.type.key_pressed(effect, led)
  end

  # TODO: key_down and key_up?
end
