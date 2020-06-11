defmodule RGBMatrix.Effect do
  alias RGBMatrix.LED

  @callback new(leds :: list(LED.t())) :: {render_in, any}
  @callback render(state :: any) :: {list(RGBMatrix.any_color_model()), render_in, any}
  @callback key_pressed(state :: any, led :: LED.t()) :: {render_in, any}
  @callback inc(state :: any, property :: property) :: {render_in, any}
  @callback dec(state :: any, property :: property) :: {render_in, any}

  @type t :: %__MODULE__{
          type: type,
          state: any
        }
  defstruct [:type, :state]

  defmacro __using__(_) do
    quote do
      @behaviour RGBMatrix.Effect
    end
  end

  @type render_in :: non_neg_integer() | :never | :ignore

  @type property :: :speed

  @type type ::
          __MODULE__.CycleAll
          | __MODULE__.CycleLeftToRight
          | __MODULE__.Pinwheel
          | __MODULE__.RandomSolid
          | __MODULE__.RandomKeypresses

  @doc """
  Returns a list of the available types of animations.
  """
  @spec types :: list(type)
  def types do
    [
      __MODULE__.CycleAll,
      __MODULE__.CycleLeftToRight,
      __MODULE__.Pinwheel,
      __MODULE__.RandomSolid,
      __MODULE__.RandomKeypresses
    ]
  end

  @doc """
  Returns an effect's initial state.
  """
  @spec new(effect_type :: type, leds :: list(LED.t())) :: {render_in, t}
  def new(effect_type, leds) do
    {render_in, effect_state} = effect_type.new(leds)

    effect = %__MODULE__{
      type: effect_type,
      state: effect_state
    }

    {render_in, effect}
  end

  @doc """
  Returns the next state of an effect based on its current state.
  """
  @spec render(effect :: t) :: {list(RGBMatrix.any_color_model()), render_in, t}
  def render(effect) do
    {colors, render_in, effect_state} = effect.type.render(effect.state)
    {colors, render_in, %{effect | state: effect_state}}
  end

  @doc """
  Sends a key pressed event to an effect.
  """
  @spec key_pressed(effect :: t, led :: LED.t()) :: {render_in, t}
  def key_pressed(effect, led) do
    {render_in, effect_state} = effect.type.key_pressed(effect.state, led)
    {render_in, %{effect | state: effect_state}}
  end

  def inc(effect, property) do
    {render_in, effect_state} = effect.type.inc(effect.state, property)
    {render_in, %{effect | state: effect_state}}
  end

  def dec(effect, property) do
    {render_in, effect_state} = effect.type.dec(effect.state, property)
    {render_in, %{effect | state: effect_state}}
  end

  # TODO: key_down and key_up?
end
