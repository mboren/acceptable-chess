defmodule ChessTownWeb.Router do
  use ChessTownWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/chess", ChessTownWeb do
    pipe_through :browser

    get "/", PageController, :index
    get "/:game_id/play", PageController, :play_game
    post  "/:game_id/play", PageController, :move
    get  "/:game_id/join", PageController, :join_game

    post "/", PageController, :new_game

    get "/elm", PageController, :elm_index

  end

  # Other scopes may use custom stacks.
  # scope "/api", ChessTownWeb do
  #   pipe_through :api
  # end
end
