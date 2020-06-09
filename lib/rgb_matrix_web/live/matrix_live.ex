defmodule RGBMatrixWeb.MatrixLive do
  use RGBMatrixWeb, :live_view

  alias RGBMatrix.{Animation, LED, KeyWithLED}
  alias RGBMatrix.Layout.{Full, TKL, Xebow}

  import RGBMatrix.Utils, only: [mod: 2]

  defmodule State do
    defstruct [:animation, :pixels]
  end

  @impl true
  def mount(_params, _session, socket) do
    send(self(), :get_next_state)

    [initial_animation_type | _] = Animation.types()

    state =
      %State{}
      |> set_pixels(Full.keys())
      |> set_animation(initial_animation_type)

    {:ok, assign(socket, state: state, pixels: [])}
  end

  defp set_animation(state, animation_type) do
    %State{state | animation: Animation.init_state(animation_type, led_locations(state.pixels))}
  end

  defp led_locations(pixels) do
    Enum.map(pixels, fn
      %KeyWithLED{led: %LED{x: x, y: y}} -> {x, y}
    end)
  end

  defp set_pixels(state, pixels) do
    %State{state | pixels: pixels}
  end

  @impl true
  def handle_info(:get_next_state, socket) do
    state = socket.assigns.state
    new_animation_state = Animation.next_state(state.animation)

    pixels = make_pixels_list(state.pixels, new_animation_state.pixel_colors)

    Process.send_after(self(), :get_next_state, new_animation_state.delay_ms)

    new_state = %State{state | animation: new_animation_state}

    {:noreply, assign(socket, state: new_state, pixels: pixels)}
  end

  defp make_pixels_list(pixels, colors) do
    Enum.zip(pixels, colors)
    |> Enum.map(fn {pixel, color} ->
      color = Chameleon.convert(color, Chameleon.Hex).hex

      width = pixel.key.width * 50
      height = pixel.key.height * 50
      x = pixel.key.x * 50 - width / 2
      y = pixel.key.y * 50 - height / 2

      %{
        x: x,
        y: y,
        width: width,
        height: height,
        color: "#" <> color
      }
    end)
  end

  @impl true
  def handle_event("next_animation", %{}, socket) do
    state = socket.assigns.state
    animation_types = Animation.types()
    num = Enum.count(animation_types)
    current = Enum.find_index(animation_types, &(&1 == state.animation.type))
    next = mod(current + 1, num)
    animation_type = Enum.at(animation_types, next)
    new_state = set_animation(state, animation_type)

    {:noreply, assign(socket, state: new_state)}
  end

  def handle_event("previous_animation", %{}, socket) do
    state = socket.assigns.state
    animation_types = Animation.types()
    num = Enum.count(animation_types)
    current = Enum.find_index(animation_types, &(&1 == state.animation.type))
    previous = mod(current - 1, num)
    animation_type = Enum.at(animation_types, previous)
    new_state = set_animation(state, animation_type)

    {:noreply, assign(socket, state: new_state)}
  end

  def handle_event("set_xebow", %{}, socket) do
    state =
      socket.assigns.state
      |> set_pixels(Xebow.keys())
      |> set_animation(socket.assigns.state.animation.type)

    {:noreply, assign(socket, state: state)}
  end

  def handle_event("set_tkl", %{}, socket) do
    state =
      socket.assigns.state
      |> set_pixels(TKL.keys())
      |> set_animation(socket.assigns.state.animation.type)

    {:noreply, assign(socket, state: state)}
  end

  def handle_event("set_full", %{}, socket) do
    state =
      socket.assigns.state
      |> set_pixels(Full.keys())
      |> set_animation(socket.assigns.state.animation.type)

    {:noreply, assign(socket, state: state)}
  end
end
