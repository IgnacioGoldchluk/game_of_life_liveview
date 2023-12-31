defmodule GameOfLifeWeb.GameOfLifeLive do
  use GameOfLifeWeb, :live_view

  alias GameOfLife.Rules

  @max_refresh_rate_ms 5_000
  @min_refresh_rate_ms 100
  @refresh_rate_diff 200

  @impl true
  def render(assigns) do
    ~H"""
    <div class="text-xl">Click on a cell to toggle its alive status</div>
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
    <.button phx-click="reset">Reset</.button>
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
    <div class="max-w-xs">
      <.form :let={_form} for={@steps} phx-submit="advance_steps">
        <.input type="number" name="steps" value={@steps["steps"]} />
        <.button>Advance steps</.button>
      </.form>
    </div>
    <div class="max-w-xs">
      <.form :let={_form} for={@size_form} phx-submit="change_size">
        <.input type="number" name="new_size" value={@size_form["size"]} />
        <.button>Change size</.button>
      </.form>
    </div>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(size: 10)
      |> assign_grid()
      |> assign_sizes()
      |> assign_size_form()
      |> assign(:pause, false)
      |> assign(:refresh_rate_ms, 300)
      |> assign(:min_rate, @min_refresh_rate_ms)
      |> assign(:max_rate, @max_refresh_rate_ms)
      |> assign(:steps, %{"steps" => 0})

    Process.send_after(self(), "update", socket.assigns.refresh_rate_ms)

    {:ok, socket}
  end

  defp assign_size_form(%{assigns: %{size: size}} = socket) do
    assign(socket, :size_form, %{"size" => size})
  end

  @impl true
  def handle_event("change_size", %{"new_size" => new_size}, socket) do
    new_size = String.to_integer(new_size)

    if Enum.member?(1..50, new_size) do
      {:noreply,
       socket
       |> assign(size: new_size)
       |> assign_grid()
       |> assign_sizes()
       |> assign_size_form()}
    else
      {:noreply, socket |> put_flash(:error, "Size must be between 1 and 50")}
    end
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
  def handle_event("advance_steps", %{"steps" => val}, %{assigns: %{grid: grid}} = socket) do
    steps = String.to_integer(val)
    {:noreply, assign(socket, :grid, Rules.steps(grid, steps))}
  end

  @impl true
  def handle_event("reset", _, socket) do
    {:noreply, socket |> assign_grid()}
  end

  @impl true
  def handle_info("update", %{assigns: %{grid: grid, pause: pause}} = socket) do
    Process.send_after(self(), "update", socket.assigns.refresh_rate_ms)
    new_grid = if(pause, do: grid, else: Rules.step(grid))
    {:noreply, assign(socket, :grid, new_grid)}
  end

  defp assign_sizes(%{assigns: %{size: size}} = socket) do
    canvas_size = max(15 * size, 600)

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
