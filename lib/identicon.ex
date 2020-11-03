defmodule Identicon do
  @moduledoc """
  Identicon image generator.
  """
def main(args) do
  {opts,_,_} = OptionParser.parse(args, strict: [help: :boolean, file: :string, input: :string], aliases: [h: :help, f: :file, i: :input])

  cond do
    opts[:help] -> show_help()
    true ->
      opts[:input]
      |>hash_input
      |>pick_color
      |>build_grid
      |>filter_odd_squares
      |>build_pixel_map
      |>draw_image
      |>save_image(opts[:file])
  end
end

def show_help() do
  IO.puts("Help:")
  IO.puts("identicon -i <input_string> -f <file_to_save.png>")
end


def save_image(image, filename) do
  filename = String.split(filename, ".")|>List.first
  IO.inspect(filename)
  File.write("#{filename}.png", image )
end

def draw_image(%Identicon.Image{color: color, pixel_map: pixel_map}) do
  image = :egd.create(250, 250)
  fill = :egd.color(color)

  Enum.each pixel_map, fn({start, stop}) ->
    :egd.filledRectangle(image, start, stop, fill)
  end

  :egd.render(image)
end

def build_pixel_map(%Identicon.Image{grid: grid} = image) do
  pixel_map=
  Enum.map grid, fn({_code, index}) ->
    horizontal = rem(index, 5)*50
    vertical  = div(index, 5)*50

    top_left = {horizontal, vertical}
    botton_right = {horizontal+50, vertical+50}

    {top_left, botton_right}
  end

  %Identicon.Image{image | pixel_map: pixel_map}
end

def filter_odd_squares(%Identicon.Image{grid: grid} = image) do
  grid = Enum.filter grid, fn({code, _index}) ->
    rem(code, 2) == 0 #if code is even, keep in the list
  end

  %Identicon.Image{image | grid: grid}
end

def build_grid(%Identicon.Image{hex: hex} = image) do
  grid =
    hex
    |> Enum.chunk_every(3, 3, :discard)
    |> Enum.map(&mirror_row/1)
    |> List.flatten
    |>Enum.with_index

  %Identicon.Image{image| grid: grid}
end

def mirror_row (row) do
  [first, second | _] = row
  row ++ [second, first]
end

def pick_color(%Identicon.Image{hex: [r,g,b|_tail]} = image) do
  #elixir allows the pattern matching to get RGB is done on the argument list
  %Identicon.Image{image | color: {r,g,b}} #adding rgb to the record
end

def hash_input(input) do
  hex=:crypto.hash(:md5, input)
  |> :binary.bin_to_list

  %Identicon.Image{hex: hex}
end

end
