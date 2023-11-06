defmodule GameOfLifeWeb.GameOfLifeLive do
  use GameOfLifeWeb, :live_view

  alias GameOfLife.Rules

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
    <svg width={@canvas_size} height={@canvas_size}>
      <%= for {{x, y}, alive} <- @grid do %>
        <rect
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

    Process.send_after(self(), "update", 1_000)

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
  def handle_info("update", %{assigns: %{grid: grid, pause: pause}} = socket) do
    Process.send_after(self(), "update", 1_000)
    new_grid = if(pause, do: grid, else: Rules.step(grid))
    {:noreply, assign(socket, :grid, new_grid)}
  end

  defp assign_sizes(%{assigns: %{size: size}} = socket) do
    canvas_size = max(10 * size, 400)

    socket
    |> assign(:canvas_size, canvas_size)
    |> assign(:cell_size, max(10, div(canvas_size, size)))
  end

  defp assign_grid(%{assigns: %{size: size}} = socket) do
    assign(socket, :grid, Rules.random(size))
  end

  # alive -> black
  defp cell_color(1), do: "(0,0,0)"
  # dead -> white
  defp cell_color(0), do: "(255, 255, 255)"
end
