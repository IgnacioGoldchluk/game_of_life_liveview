defmodule GameOfLifeWeb.GameOfLifeLive do
  use GameOfLifeWeb, :live_view

  alias GameOfLife.Rules

  @impl true
  def render(assigns) do
    ~H"""
    <svg width={@canvas_size} height={@canvas_size}>
      <%= for {{x, y}, alive} <- @grid do %>
        <rect
          x={x * @cell_size}
          y={y * @cell_size}
          width={@cell_size}
          height={@cell_size}
          style={"fill:rgb#{cell_color(alive)};stroke-width:3;stroke:rgb(128,128,128)"}
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

    Process.send_after(self(), "update", 1_000)

    {:ok, socket}
  end

  @impl true
  def handle_info("update", %{assigns: %{grid: grid}} = socket) do
    Process.send_after(self(), "update", 1_000)
    {:noreply, assign(socket, :grid, Rules.step(grid))}
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
