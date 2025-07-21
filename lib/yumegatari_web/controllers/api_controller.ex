defmodule YumegatariWeb.ApiController do
  use YumegatariWeb, :controller

  def index(conn, _params) do
    json(conn, %{
      message: "Welcome to Yumegatari API!",
      version: "1.0.0",
      timestamp: DateTime.utc_now()
    })
  end

  def health(conn, _params) do
    json(conn, %{
      status: "ok",
      service: "yumegatari",
      timestamp: DateTime.utc_now()
    })
  end

  def test(conn, params) do
    json(conn, %{
      message: "POST request received",
      data: params,
      timestamp: DateTime.utc_now()
    })
  end

  def proxy(conn, params) do
    endpoint = params["endpoint"]
    headers = Enum.map(params["headers"] || %{}, fn {k, v} -> {to_string(k), to_string(v)} end)

    body =
      if params["body"] && map_size(params["body"]) > 0,
        do: Jason.encode!(params["body"]),
        else: ""

    case HTTPoison.post(endpoint, body, headers) do
      {:ok, response} ->
        json(conn, %{status_code: response.status_code, body: Jason.decode!(response.body)})

      {:error, error} ->
        json(conn, %{error: "#{error.reason}"})
    end
  end
end
