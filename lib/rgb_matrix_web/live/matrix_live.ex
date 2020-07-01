defmodule RGBMatrixWeb.MatrixLive do
  use RGBMatrixWeb, :live_view

  alias RGBMatrix.{Effect, Layout}
  alias RGBMatrix.Layout.{CTRL, Full, TKL, Xebow}

  import RGBMatrix.Utils, only: [mod: 2]

  defmodule State do
    defstruct [:effect, :layout, :current_colors, :timer]
  end

  @impl true
  def mount(_params, _session, socket) do
    [initial_effect_type | _] = Effect.types()

    {:ok,
     socket
     |> assign(state: %State{})
     |> set_layout(CTRL.new())
     |> set_effect(initial_effect_type)}
  end

  defp set_layout(%{assigns: %{state: state}} = socket, layout) do
    black = Chameleon.HSV.new(0, 0, 0)
    colors = Enum.map(leds(layout), &{&1.id, black})

    assign(socket,
      state: %State{state | layout: layout, current_colors: colors},
      leds: make_view_leds(layout, colors)
    )
  end

  defp make_view_leds(layout, colors) do
    colors_map = Map.new(colors)

    leds_with_maybe_keys =
      layout
      |> Layout.leds()
      |> Enum.map(fn {led_id, led} ->
        color =
          colors_map
          |> Map.fetch!(led_id)
          |> Chameleon.convert(Chameleon.Hex)

        key = Layout.key_for_led(layout, led_id)

        make_view_led(color.hex, led, key)
      end)

    keys_with_no_leds =
      layout
      |> Layout.keys()
      |> Enum.filter(fn {_key_id, key} -> is_nil(key.led) end)
      |> Enum.map(fn {_key_id, key} ->
        make_view_led("000", nil, key)
      end)

    leds_with_maybe_keys ++ keys_with_no_leds
  end

  defp make_view_led(color_hex, led, nil) do
    width = 25
    height = 25
    x = led.x * 50 - width / 2
    y = led.y * 50 - height / 2

    %{
      class: "led",
      id: led.id,
      x: x,
      y: y,
      width: width,
      height: height,
      color: "#" <> color_hex
    }
  end

  defp make_view_led(color_hex, _led, key) do
    width = key.width * 50
    height = key.height * 50
    x = key.x * 50 - width / 2
    y = key.y * 50 - height / 2

    %{
      class: "key",
      id: key.id,
      x: x,
      y: y,
      width: width,
      height: height,
      color: "#" <> color_hex
    }
  end

  defp set_effect(%{assigns: %{state: state}} = socket, effect_type) do
    {render_in, effect} = Effect.new(effect_type, leds(state.layout))
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

  defp leds(layout) do
    Keyword.values(layout.leds)
  end

  @impl true
  def handle_info(:render, socket) do
    state = socket.assigns.state
    {new_colors, render_in, effect} = Effect.render(state.effect)

    colors = combine_colors(state.current_colors, new_colors)
    view_leds = make_view_leds(state.layout, colors)
    state = schedule_next_render(state, render_in)
    state = %State{state | effect: effect, current_colors: colors}

    {:noreply, assign(socket, state: state, leds: view_leds)}
  end

  defp combine_colors(current_colors, new_colors) do
    new_colors_map = Map.new(new_colors)

    Enum.map(current_colors, fn {led_id, color} ->
      case Map.get(new_colors_map, led_id) do
        nil -> {led_id, color}
        new_color -> {led_id, new_color}
      end
    end)
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

  def handle_event("set_layout", %{"layout" => layout_name}, socket) do
    layout =
      case layout_name do
        "xebow" -> Xebow.new()
        "tkl" -> TKL.new()
        "ctrl" -> CTRL.new()
        "full" -> Full.new()
      end

    {:noreply,
     socket
     |> set_layout(layout)
     |> set_effect(socket.assigns.state.effect.type)}
  end

  def handle_event("key_pressed", %{"key-id" => id_str}, socket) do
    key_id = String.to_existing_atom(id_str)

    case Layout.led_for_key(socket.assigns.state.layout, key_id) do
      nil ->
        {:noreply, socket}

      led ->
        state = socket.assigns.state
        {render_in, effect} = Effect.key_pressed(state.effect, led)
        state = schedule_next_render(state, render_in)
        state = %State{state | effect: effect}

        {:noreply, assign(socket, state: state)}
    end
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
