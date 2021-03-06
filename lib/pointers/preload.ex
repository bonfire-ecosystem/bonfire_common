defmodule Bonfire.Common.Pointers.Preload do
  import Bonfire.Common.Config, only: [repo: 0]
  alias Bonfire.Common.Utils
  require Logger

  def maybe_preload_pointers(object, keys) when is_list(object) do
    Logger.info("maybe_preload_pointers: iterate list of objects")
    Enum.map(object, &maybe_preload_pointers(&1, keys))
  end

  def maybe_preload_pointers(object, keys) when is_list(keys) and length(keys)==1 do
    # TODO: handle any size list and merge with accelerator?
    key = List.first(keys)
    Logger.info("maybe_preload_pointers: list with one key: #{inspect key}")
    maybe_preload_pointers(object, key)
  end

  def maybe_preload_pointers(object, key) when is_struct(object) and is_map(object) and is_atom(key) do
    Logger.info("maybe_preload_pointers: one field: #{inspect key}")
    case Map.get(object, key) do
      %Pointers.Pointer{} = pointer ->

        object
        |> Map.put(key, maybe_preload_pointer(pointer))

      _ -> object
    end
  end

  def maybe_preload_pointers(object, {key, nested_keys}) when is_struct(object) do

    Logger.info("maybe_preload_pointers: key #{key} with nested keys #{inspect nested_keys}")
    object
    |> maybe_preload_pointer()
    # |> IO.inspect
    |> Map.put(key,
      Map.get(object, key)
      |> maybe_preload_pointers(nested_keys)
    )
  end

  def maybe_preload_pointers(object, keys) do
    Logger.info("maybe_preload_pointers: ignore #{inspect keys}")
    object
  end


  def maybe_preload_nested_pointers(object, keys) when is_list(keys) and length(keys)>0 and is_map(object) do
    Logger.info("maybe_preload_nested_pointers: try object with list of keys: #{inspect keys}")

    do_maybe_preload_nested_pointers(object, nested_keys(keys))
  end

  def maybe_preload_nested_pointers(object, keys) when is_list(keys) and length(keys)>0 and is_list(object) do
    Logger.info("maybe_preload_nested_pointers: try list with list of keys: #{inspect keys}")

    do_maybe_preload_nested_pointers(object, [Access.all()] ++ nested_keys(keys))
  end

  def maybe_preload_nested_pointers(object, _), do: object

  defp nested_keys(keys) do
    # keys |> Ecto.Repo.Preloader.normalize(nil, keys) |> IO.inspect
    keys |> Utils.flatter |> Enum.map(&Access.key!(&1)) # |> IO.inspect(label: "flatten nested keys")
  end

  defp do_maybe_preload_nested_pointers(object, keylist) do

    with {_old, loaded} <- object
    |> get_and_update_in(keylist, &{&1, maybe_preload_pointer(&1)})
    do
      loaded
      # |> IO.inspect(label: "object")
    end
  end


  def maybe_preload_pointer(%Pointers.Pointer{} = pointer) do
    Logger.info("maybe_preload_pointer: follow")

    with {:ok, obj} <- Bonfire.Common.Pointers.get(pointer) do
      obj
    else _e ->
      Logger.info("maybe_preload_pointer: not found")
      pointer
    end
  end

  def maybe_preload_pointer(obj), do: obj #|> IO.inspect(label: "skip")


end
