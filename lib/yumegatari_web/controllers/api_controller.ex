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
end
