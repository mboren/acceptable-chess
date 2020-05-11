defmodule ChessTownWeb.PageController do
  use ChessTownWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
