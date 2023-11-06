defmodule GameOfLifeWeb.GameOfLifeLive do
  use GameOfLifeWeb, :live_view

  alias GameOfLife.Rules

  @max_refresh_rate_ms 5_000
  @min_refresh_rate_ms 100
  @refresh_rate_diff 200

  @impl true
  def render(assigns) do
    ~H"""
    <.button phx-click="pause">
      <%= if @pause do %>
        Continue
      <% else %>
        Pause
      <% end %>
    </.button>
    <.button phx-click="clear">Clear</.button>
    <.button class="disabled:opacity-25" phx-click="faster" disabled={@refresh_rate_ms == @min_rate}>
      Faster
    </.button>
    <.button class="disabled:opacity-25" phx-click="slower" disabled={@refresh_rate_ms == @max_rate}>
      Slower
    </.button>
    <svg width={@canvas_size} height={@canvas_size}>
      <%= for {{x, y}, alive} <- @grid do %>
        <rect
          phx-click="toggle"
          phx-value-x={x}
          phx-value-y={y}
          x={x * @cell_size}
          y={y * @cell_size}
          width={@cell_size}
          height={@cell_size}
          style={"fill:rgb#{cell_color(alive)};stroke-width:1;stroke:rgb(128,128,128)"}
        />
      <% end %>
    </svg>
    """
  end

  @impl true
  def mount(%{"size" => size}, _session, socket) do
    socket =
      socket
      |> assign(size: String.to_integer(size))
      |> assign_grid()
      |> assign_sizes()
      |> assign(:pause, false)
      |> assign(:refresh_rate_ms, 300)
      |> assign(:min_rate, @min_refresh_rate_ms)
      |> assign(:max_rate, @max_refresh_rate_ms)

    Process.send_after(self(), "update", socket.assigns.refresh_rate_ms)

    {:ok, socket}
  end

  @impl true
  def handle_event("pause", _, %{assigns: %{pause: pause}} = socket) do
    {:noreply, assign(socket, :pause, not pause)}
  end

  @impl true
  def handle_event("clear", _, %{assigns: %{size: size}} = socket) do
    {:noreply, assign(socket, :grid, Rules.grid(size))}
  end

  @impl true
  def handle_event("toggle", %{"x" => x, "y" => y}, %{assigns: %{grid: grid}} = socket) do
    x = String.to_integer(x)
    y = String.to_integer(y)

    {:noreply, assign(socket, :grid, Rules.toggle(grid, {x, y}))}
  end

  @impl true
  def handle_event("faster", _, %{assigns: %{refresh_rate_ms: rate}} = socket) do
    {:noreply,
     assign(socket, :refresh_rate_ms, max(rate - @refresh_rate_diff, @min_refresh_rate_ms))}
  end

  @impl true
  def handle_event("slower", _, %{assigns: %{refresh_rate_ms: rate}} = socket) do
    {:noreply,
     assign(socket, :refresh_rate_ms, min(rate + @refresh_rate_diff, @max_refresh_rate_ms))}
  end

  @impl true
  def handle_info("update", %{assigns: %{grid: grid, pause: pause}} = socket) do
    Process.send_after(self(), "update", socket.assigns.refresh_rate_ms)
    new_grid = if(pause, do: grid, else: Rules.step(grid))
    {:noreply, assign(socket, :grid, new_grid)}
  end

  defp assign_sizes(%{assigns: %{size: size}} = socket) do
    canvas_size = max(15 * size, 400)

    socket
    |> assign(:canvas_size, canvas_size)
    |> assign(:cell_size, max(15, div(canvas_size, size)))
  end

  defp assign_grid(%{assigns: %{size: size}} = socket) do
    assign(socket, :grid, Rules.random(size))
  end

  # alive -> black
  defp cell_color(1), do: "(0,0,0)"
  # dead -> white
  defp cell_color(0), do: "(255, 255, 255)"
end
