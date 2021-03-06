defmodule Bonfire.Common.URIs do

  alias Bonfire.Common.Utils
  alias Bonfire.Me.Characters
  alias Plug.Conn.Query
  require Logger

  def path(view_module_or_path_name_or_object, args \\ [])

  def path(view_module_or_path_name_or_object, %{id: id} = args) when not is_struct(args), do: path(view_module_or_path_name_or_object, [id])

  def path(view_module_or_path_name_or_object, args) when not is_list(args), do: path(view_module_or_path_name_or_object, [args])

  def path(view_module_or_path_name_or_object, args) when is_atom(view_module_or_path_name_or_object) and not is_nil(view_module_or_path_name_or_object) do
    apply(Bonfire.Web.Router.Reverse, :path, [Bonfire.Common.Config.get(:endpoint_module, Bonfire.Web.Endpoint), view_module_or_path_name_or_object] ++ args)
  end

  def path(%{id: _} = object, args) do
    args_with_id = [path_id(object)] ++ args

    case Bonfire.Common.Types.object_type(object) do
      type when is_atom(type) ->
        Logger.debug("path: resolving with type: #{inspect type}")
        path(type, args_with_id)

      none ->
        Logger.info("path: could not figure out the type of this object: #{inspect none}")
        path(Bonfire.Social.Web.DiscussionLive, args_with_id)
    end

  rescue
    error in FunctionClauseError ->
      Logger.info("path: could not find a matching route: #{inspect error} for object #{inspect object}")
      path(Bonfire.Social.Web.DiscussionLive, [path_id(object)] ++ args)
  end

  def path(id, args) when is_binary(id) do
    if Utils.is_ulid?(id) do
      Bonfire.Common.Pointers.get!(id)
      |> path(args)
    else
      Logger.error("path: could not find a matching route for #{id}")
      "#unrecognised-"<>id
    end
  end

  def path(other, _) do
    Logger.error("path: could not find a matching route for #{inspect other}")
    "#unrecognised-#{inspect other}"
  end

  defp path_id(%{username: username}), do: username
  defp path_id(%{character: %{username: username}}), do: username
  defp path_id(%{id: id}), do: id

  def url(view_module_or_path_name_or_object, args \\ []) do
    base_url()<>path(view_module_or_path_name_or_object, args)
  end

  def canonical_url(%{canonical_uri: canonical_url}) when not is_nil(canonical_url) do
    # TODO preload new Peered.canonical_uri
    canonical_url
  end
  def canonical_url(%{peered: %{canonical_uri: canonical_url}}) when not is_nil(canonical_url) do
    canonical_url
  end
  def canonical_url(%{canonical_url: canonical_url}) when not is_nil(canonical_url) do
    canonical_url
  end
  def canonical_url(%{peered: _not_loaded} = object) do
    Bonfire.Repo.maybe_preload(object, :peered)
    |> Utils.e(:peered, :canonical_uri, generate_canonical_url(object))
  end
  def canonical_url(object) do # fallback, only works for local objects
      generate_canonical_url(object)
  end

  defp generate_canonical_url(%{id: id} = thing) when is_binary(id) do
    if Utils.module_enabled?(Characters) do
      # check if object is a Character (in which case use actor URL)
      case Characters.character_url(thing) do
        nil -> generate_canonical_url(id)
        character_url -> character_url
      end
    else
      generate_canonical_url(id)
    end
  end

  defp generate_canonical_url(id) when is_binary(id) do
    ap_base_path = Bonfire.Common.Config.get(:ap_base_path, "/pub")
    prefix = if Utils.is_ulid?(id), do: "/objects/", else: "/actors/"
    base_url() <> ap_base_path <> prefix <> id
  end


  def base_url(conn \\ nil)
  def base_url(%{scheme: scheme, host: host, port: 80}) when scheme in [:http, "http"], do: "http://"<>host
  def base_url(%{scheme: scheme, host: host, port: 443}) when scheme in [:https, "https"], do: "https://"<>host
  def base_url(%{host: host, port: 443}), do: "https://"<>host
  def base_url(%{scheme: scheme, host: host, port: port}), do: "#{scheme}://#{host}:#{port}"
  def base_url(%{host: host}), do: "http://#{host}"
  def base_url(endpoint) when not is_nil(endpoint) and is_atom(endpoint) do
    if Code.ensure_loaded?(endpoint) do
      endpoint.struct_url() |> base_url()
    else
      Logger.info("base_url: endpoint module not found: #{inspect endpoint}")
      ""
    end
  rescue e ->
    Logger.info("base_url: #{inspect e}")
    ""
  end
  def base_url(_) do
    case Bonfire.Common.Config.get(:endpoint_module, Bonfire.Web.Endpoint) do
      endpoint when is_atom(endpoint) -> base_url(endpoint)
      _ ->
        Logger.info("base_url: requires an endpoint module")
        ""
    end
  end


  # copies the 'go' part of the query string, if any
  def copy_go(%{go: go}), do: "?" <> Query.encode(go: go)
  def copy_go(%{"go" => go}), do: "?" <> Query.encode(go: go)
  def copy_go(_), do: ""

  # TODO: should we preserve query strings?
  def go_query(conn), do: "?" <> Query.encode(go: conn.request_path)

  # TODO: we should validate this a bit harder. Phoenix will prevent
  # us from sending the user to an external URL, but it'll do so by
  # means of a 500 error.
  def valid_go_path?("/" <> _), do: true
  def valid_go_path?(_), do: false

  def go_where?(_conn, %Ecto.Changeset{}, default) do
    default
  end

  def go_where?(_conn, params, default) do
    go = params[:go] || params["go"]
    if valid_go_path?(go), do: go, else: default
  end
end
