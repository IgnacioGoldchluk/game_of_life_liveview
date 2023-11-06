defmodule GameOfLife.Rules do
  def grid(size) when is_binary(size), do: grid(String.to_integer(size))

  def grid(size) when is_integer(size) and size > 0 do
    for x <- 0..(size - 1), y <- 0..(size - 1), into: Map.new(), do: {{x, y}, 0}
  end

  def random(size) do
    grid(size)
    |> Enum.map(fn {coords, _} -> {coords, :rand.uniform(2) - 1} end)
    |> Enum.into(Map.new())
  end

  def step(grid) when is_map(grid) do
    grid
    |> Enum.map(fn {coords, alive} ->
      alive_neighbors =
        coords
        |> neighbors_indices()
        |> count_alive(grid)

      {coords, next_value(alive, alive_neighbors)}
    end)
    |> Enum.into(Map.new())
  end

  def steps(grid, number) when number <= 0, do: grid
  def steps(grid, number), do: steps(step(grid), number - 1)

  def toggle(grid, coords), do: Map.update!(grid, coords, &toggle_alive/1)

  defp toggle_alive(1), do: 0
  defp toggle_alive(0), do: 1

  defp neighbors_indices({x, y}) do
    [
      {x - 1, y - 1},
      {x - 1, y},
      {x - 1, y + 1},
      {x, y - 1},
      {x, y + 1},
      {x + 1, y - 1},
      {x + 1, y},
      {x + 1, y + 1}
    ]
  end

  defp count_alive(indices, grid) do
    indices
    |> Enum.filter(&alive?(&1, grid))
    |> Enum.count()
  end

  defp alive?(coords, grid), do: Map.get(grid, coords, 0) == 1

  # Rules based on whether the cell is alive (1) or dead (2) and the number of neighbors

  # Live cells with 2 or 3 neighbors survive
  defp next_value(1, 2), do: 1
  defp next_value(1, 3), do: 1
  # Dead cell with 3 neighbors become alive
  defp next_value(0, 3), do: 1
  # Any other case is dead
  defp next_value(_, _), do: 0
end
