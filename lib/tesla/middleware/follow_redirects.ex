defmodule Tesla.Middleware.FollowRedirects do
  @moduledoc """
  Follow 301/302 redirects

  Example:
      defmodule MyClient do
        use Tesla

        plug Tesla.Middleware.FollowRedirects, max_redirects: 3 # defaults to 5
      end
  """
  @max_redirects 5
  @redirect_statuses [301, 302, 307, 308]

  def call(env, next, opts \\ []) do
    max = Keyword.get(opts || [], :max_redirects, @max_redirects)

    redirect(env, next, max)
  end

  defp redirect(env, next, left) when left == 0 do
    case Tesla.run(env, next) do
      %{status: status} = env when not status in @redirect_statuses ->
        env
      _ ->
        raise Tesla.Error, "too many redirects"
    end
  end

  defp redirect(env, next, left) do
    case Tesla.run(env, next) do
      %{status: status, headers: %{"location" => location}} when status in @redirect_statuses ->
        location = parse_location(location, env)
        redirect(%{env | url: location}, next, left - 1)
      env ->
        env
    end
  end

  defp parse_location("/" <> rest = location, env) do
    if String.ends_with?(env.url, "/") do
      env.url <> rest
    else
      env.url <> location
    end
  end
  defp parse_location(location, _env), do: location
end
