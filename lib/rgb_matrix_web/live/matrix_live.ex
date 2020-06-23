defmodule RGBMatrixWeb.MatrixLive do
  use RGBMatrixWeb, :live_view

  alias RGBMatrix.Effect
  alias RGBMatrix.Layout.{Full, TKL, Xebow}

  import RGBMatrix.Utils, only: [mod: 2]

  defmodule State do
    defstruct [:effect, :keys_with_leds, :timer]
  end

  @impl true
  def mount(_params, _session, socket) do
    [initial_effect_type | _] = Effect.types()

    {:ok,
     socket
     |> assign(state: %State{})
     |> set_keys(Full.keys())
     |> set_effect(initial_effect_type)}
  end

  defp set_keys(%{assigns: %{state: state}} = socket, keys) do
    count = length(keys)

    keys_with_leds =
      Enum.zip(1..count, keys)
      |> Map.new()

    assign(socket,
      state: %State{state | keys_with_leds: keys_with_leds},
      leds: make_view_leds(keys_with_leds)
    )
  end

  defp make_view_leds(keys_with_leds) do
    Enum.map(keys_with_leds, fn {id, key_with_led} ->
      make_view_led(id, key_with_led, "000")
    end)
  end

  defp make_view_leds(keys_with_leds, colors) do
    Enum.zip(keys_with_leds, colors)
    |> Enum.map(fn {{id, key_with_led}, color} ->
      color = Chameleon.convert(color, Chameleon.Hex).hex

      make_view_led(id, key_with_led, color)
    end)
  end

  defp make_view_led(id, key_with_led, color) do
    width = key_with_led.key.width * 50
    height = key_with_led.key.height * 50
    x = key_with_led.key.x * 50 - width / 2
    y = key_with_led.key.y * 50 - height / 2

    %{
      id: id,
      x: x,
      y: y,
      width: width,
      height: height,
      color: "#" <> color
    }
  end

  defp set_effect(%{assigns: %{state: state}} = socket, effect_type) do
    {render_in, effect} = Effect.new(effect_type, leds(state.keys_with_leds))
    %config_module{} = config = effect.config

    state = schedule_next_render(state, render_in)

    assign(socket,
      state: %State{state | effect: effect},
      config: config,
      config_schema: config_module.schema()
    )
  end

  defp schedule_next_render(state, :ignore) do
    state
  end

  defp schedule_next_render(state, :never) do
    cancel_timer(state)
  end

  defp schedule_next_render(state, 0) do
    send(self(), :render)
    cancel_timer(state)
  end

  defp schedule_next_render(state, ms) when is_integer(ms) and ms > 0 do
    state = cancel_timer(state)
    %{state | timer: Process.send_after(self(), :render, ms)}
  end

  defp cancel_timer(%{timer: nil} = state), do: state

  defp cancel_timer(state) do
    Process.cancel_timer(state.timer)
    %{state | timer: nil}
  end

  defp leds(keys_with_leds) do
    keys_with_leds
    |> Map.values()
    |> Enum.map(& &1.led)
  end

  @impl true
  def handle_info(:render, socket) do
    state = socket.assigns.state
    {led_colors, render_in, effect} = Effect.render(state.effect)

    view_leds = make_view_leds(state.keys_with_leds, led_colors)

    state = schedule_next_render(state, render_in)

    state = %State{state | effect: effect}

    {:noreply, assign(socket, state: state, leds: view_leds)}
  end

  @impl true
  def handle_event("next_effect", %{}, socket) do
    effect_types = Effect.types()
    num = Enum.count(effect_types)
    current = Enum.find_index(effect_types, &(&1 == socket.assigns.state.effect.type))
    next = mod(current + 1, num)
    effect_type = Enum.at(effect_types, next)

    {:noreply, set_effect(socket, effect_type)}
  end

  def handle_event("previous_effect", %{}, socket) do
    effect_types = Effect.types()
    num = Enum.count(effect_types)
    current = Enum.find_index(effect_types, &(&1 == socket.assigns.state.effect.type))
    previous = mod(current - 1, num)
    effect_type = Enum.at(effect_types, previous)

    {:noreply, set_effect(socket, effect_type)}
  end

  def handle_event("set_layout", %{"layout" => layout}, socket) do
    keys =
      case layout do
        "xebow" -> Xebow.keys()
        "tkl" -> TKL.keys()
        "full" -> Full.keys()
      end

    {:noreply,
     socket
     |> set_keys(keys)
     |> set_effect(socket.assigns.state.effect.type)}
  end

  def handle_event("key_pressed", %{"key-id" => id_str}, socket) do
    {id, _} = Integer.parse(id_str)
    led = Map.fetch!(socket.assigns.state.keys_with_leds, id).led

    state = socket.assigns.state
    {render_in, effect} = Effect.key_pressed(state.effect, led)
    state = schedule_next_render(state, render_in)
    state = %State{state | effect: effect}

    {:noreply, assign(socket, state: state)}
  end

  def handle_event("update_config", %{"_target" => [field_str]} = params, socket) do
    field = String.to_existing_atom(field_str)
    %config_mod{} = config = socket.assigns.state.effect.config
    %type_mod{} = type = Keyword.fetch!(config_mod.schema(), field)
    value = Map.fetch!(params, field_str)
    {:ok, value} = type_mod.cast(type, value)

    new_config = config_mod.update(config, %{field => value})

    effect = socket.assigns.state.effect
    new_effect = %{effect | config: new_config}
    new_state = %{socket.assigns.state | effect: new_effect}

    {:noreply, assign(socket, state: new_state, config: new_config)}
  end
end
