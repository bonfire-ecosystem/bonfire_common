defmodule Bonfire.Web.Gettext do
  @default_locale "en" # TODO: configurable?

  use Gettext,
    otp_app: :bonfire_common,
    default_locale: @default_locale,
    priv: Bonfire.Common.Config.get!(:localisation_path)

  def default_locale, do: @default_locale

end
defmodule Bonfire.Web.Gettext.Helpers do
  @moduledoc """
  A module providing Internationalization with a gettext-based API.

  By using [Gettext](https://hexdocs.pm/gettext),
  your module gains a set of macros for translations, for example:

      import Bonfire.Web.Gettext

      # Simple translation

      usage:
        <%= l("Hello") %>
        <%= l("Hello %{name}", name: "Bookchin") %>
        <%= l("Hi", [], "test context") %>


      output:
        Hello
        Hello Bookchin
        Hi


      # Plural translation

      usage:
        <%= lp("Hi friend", "Hi friends", 2) %>
        <%= lp("Hiya %{user_or_users}", "Hiyas %{user_or_users}", 1, [user_or_users: "Bookchin"], "test context") %>

      output:
        Hi friends
        Hiya Bookchin

  See the [Gettext Docs](https://hexdocs.pm/gettext) for details.
  """

  # alias the gettext macros for ease-of-use

  import Bonfire.Web.Gettext

  defmacro l(original_text_or_id, bindings \\ [], context \\ nil, domain \\ nil)

  defmacro l(msgid, bindings, nil, nil) when is_list(bindings) or is_map(bindings) and is_binary(msgid) do
    # IO.inspect(__CALLER__)
    mod = __CALLER__.module
    case Application.get_application(mod) do

      otp_app when is_atom(otp_app) and not is_nil(otp_app) ->

        # IO.inspect(msgid, label: "domain based on module #{inspect mod}: #{inspect otp_app}")

        quote do: dgettext(unquote(Atom.to_string(otp_app)), unquote(msgid), unquote(bindings))

      _ ->

        # IO.inspect(msgid, label: "no domain or context / #{inspect mod}")

        quote do: gettext(unquote(msgid), unquote(bindings))
    end
  end

  defmacro l(msgid, bindings, context, nil) when is_binary(context) and is_list(bindings) or is_map(bindings) and is_binary(msgid) do
    case Application.get_application(__CALLER__.module) do
      otp_app when is_atom(otp_app) and not is_nil(otp_app) ->

        # IO.inspect(msgid, label: "custom context #{context} + domain based on module #{inspect otp_app}")

        quote do: dpgettext(unquote(Atom.to_string(otp_app)), unquote(context), unquote(msgid), unquote(bindings))

      _ ->

        # IO.inspect(msgid, label: "custom context #{context} - no domain")

        quote do: pgettext(unquote(context), unquote(msgid), unquote(bindings))
    end
  end

  defmacro l(msgid, bindings, nil, domain) when is_binary(domain) and is_list(bindings) or is_map(bindings) and is_binary(msgid) do
    # IO.inspect(msgid, label: "custom domain #{domain}")

    quote do: dgettext(unquote(domain), unquote(msgid), unquote(bindings))
  end

  defmacro l(msgid, bindings, context, domain) when is_binary(domain) and is_binary(context) and is_list(bindings) or is_map(bindings) and is_binary(msgid) do

    # IO.inspect(msgid, label: "custom context #{context} + domain #{domain}")

    quote do: dpgettext(unquote(domain), unquote(context), unquote(msgid), unquote(bindings))
  end


  ### Localisation with pluralisation ###

  defmacro lp(original_text_or_id, msgid_plural, n, bindings \\ [], context \\ nil, domain \\ nil)

  defmacro lp(msgid, msgid_plural, n, bindings, nil, nil) when is_binary(msgid) and is_binary(msgid_plural) and not is_nil(n) and is_list(bindings) or is_map(bindings) do
    # IO.inspect(__CALLER__)
    mod = __CALLER__.module
    case Application.get_application(mod) do

      otp_app when is_atom(otp_app) and not is_nil(otp_app) ->

        # IO.inspect(msgid, label: "plural: domain based on module #{inspect mod}: #{inspect otp_app}")

        quote do: dngettext(unquote(Atom.to_string(otp_app)), unquote(msgid), unquote(msgid_plural), unquote(n), unquote(bindings))

      _ ->

        # IO.inspect(msgid, label: "plural: no domain or context / #{inspect mod}")

        quote do: ngettext(unquote(msgid), unquote(msgid_plural), unquote(n), unquote(bindings))
    end
  end

  defmacro lp(msgid, msgid_plural, n, bindings, context, nil)  when is_binary(msgid) and is_binary(msgid_plural) and not is_nil(n) and is_list(bindings) or is_map(bindings) and is_binary(context) do
    case Application.get_application(__CALLER__.module) do
      otp_app when is_atom(otp_app) and not is_nil(otp_app) ->

        # IO.inspect(msgid, label: "plural: custom context #{context} + domain based on module #{inspect otp_app}")

        quote do: dpngettext(unquote(Atom.to_string(otp_app)), unquote(context), unquote(msgid), unquote(msgid_plural), unquote(n), unquote(bindings))

      _ ->

        # IO.inspect(msgid, label: "plural: custom context #{context} - no domain")

        quote do: pngettext(unquote(context), unquote(msgid), unquote(msgid_plural), unquote(n), unquote(bindings))
    end
  end

  defmacro lp(msgid, msgid_plural, n, bindings, nil, domain) when is_binary(msgid) and is_binary(msgid_plural) and not is_nil(n) and is_list(bindings) or is_map(bindings) and is_binary(domain)  do

    # IO.inspect(msgid, label: "plural: custom domain #{domain}")

    quote do: dngettext(unquote(domain), unquote(msgid), unquote(msgid_plural), unquote(n), unquote(bindings))
  end

  defmacro lp(msgid, msgid_plural, n, bindings, context, domain) when is_binary(msgid) and is_binary(msgid_plural) and not is_nil(n) and is_list(bindings) or is_map(bindings) and is_binary(context) and is_binary(domain)  do

    # IO.inspect(msgid, label: "plural: custom context #{context} + domain #{domain}")

    quote do: dpngettext(unquote(domain), unquote(context), unquote(msgid), unquote(msgid_plural), unquote(n), unquote(bindings))
  end



end
