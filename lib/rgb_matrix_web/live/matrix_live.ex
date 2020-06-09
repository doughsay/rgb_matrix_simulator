defmodule RGBMatrixWeb.MatrixLive do
  use RGBMatrixWeb, :live_view

  alias RGBMatrix.Effect
  alias RGBMatrix.Layout.{Full, TKL, Xebow}

  import RGBMatrix.Utils, only: [mod: 2]

  defmodule State do
    defstruct [:effect, :keys_with_leds]
  end

  @impl true
  def mount(_params, _session, socket) do
    send(self(), :get_next_state)

    [initial_effect_type | _] = Effect.types()

    state =
      %State{}
      |> set_keys(Full.keys())
      |> set_effect(initial_effect_type)

    {:ok, assign(socket, state: state, leds: [])}
  end

  defp set_effect(state, effect_type) do
    %State{state | effect: Effect.init_state(effect_type, leds(state.keys_with_leds))}
  end

  defp leds(keys_with_leds) do
    Enum.map(keys_with_leds, & &1.led)
  end

  defp set_keys(state, keys) do
    %State{state | keys_with_leds: keys}
  end

  @impl true
  def handle_info(:get_next_state, socket) do
    state = socket.assigns.state
    effect = Effect.next_state(state.effect)

    view_leds = make_view_leds(state.keys_with_leds, effect.led_colors)

    # TODO: handle infinity
    Process.send_after(self(), :get_next_state, effect.next_call)

    state = %State{state | effect: effect}

    {:noreply, assign(socket, state: state, leds: view_leds)}
  end

  defp make_view_leds(keys_with_leds, colors) do
    Enum.zip(keys_with_leds, colors)
    |> Enum.map(fn {key_with_led, color} ->
      color = Chameleon.convert(color, Chameleon.Hex).hex

      width = key_with_led.key.width * 50
      height = key_with_led.key.height * 50
      x = key_with_led.key.x * 50 - width / 2
      y = key_with_led.key.y * 50 - height / 2

      %{
        logical_x: key_with_led.key.x,
        logical_y: key_with_led.key.y,
        x: x,
        y: y,
        width: width,
        height: height,
        color: "#" <> color
      }
    end)
  end

  @impl true
  def handle_event("next_effect", %{}, socket) do
    state = socket.assigns.state
    effect_types = Effect.types()
    num = Enum.count(effect_types)
    current = Enum.find_index(effect_types, &(&1 == state.effect.type))
    next = mod(current + 1, num)
    effect_type = Enum.at(effect_types, next)
    new_state = set_effect(state, effect_type)

    {:noreply, assign(socket, state: new_state)}
  end

  def handle_event("previous_effect", %{}, socket) do
    state = socket.assigns.state
    effect_types = Effect.types()
    num = Enum.count(effect_types)
    current = Enum.find_index(effect_types, &(&1 == state.effect.type))
    previous = mod(current - 1, num)
    effect_type = Enum.at(effect_types, previous)
    new_state = set_effect(state, effect_type)

    {:noreply, assign(socket, state: new_state)}
  end

  def handle_event("set_layout", %{"layout" => layout}, socket) do
    keys =
      case layout do
        "xebow" -> Xebow.keys()
        "tkl" -> TKL.keys()
        "full" -> Full.keys()
      end

    state =
      socket.assigns.state
      |> set_keys(keys)
      |> set_effect(socket.assigns.state.effect.type)

    {:noreply, assign(socket, state: state)}
  end

  def handle_event("key_pressed", %{"key-x" => x_str, "key-y" => y_str}, socket) do
    {x, _} = Float.parse(x_str)
    {y, _} = Float.parse(y_str)

    state = socket.assigns.state
    effect = Effect.key_pressed(state.effect, {x, y})
    state = %State{state | effect: effect}

    {:noreply, assign(socket, state: state)}
  end
end
