defmodule ChessTownWeb.PageController do
  use ChessTownWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end

  def new_game(conn, _params) do
    player_id = ChessApp.get_player_id()
    game_id = ChessApp.create_game()
    ChessApp.join_game(game_id, player_id)

    conn = put_session(conn, :player_id, player_id)

    serialized_game_id = serialize(game_id)

    conn |> redirect(to: "/chess/#{serialized_game_id}/play")
  end

  def play_game(conn, %{"game_id" => game_id}) do
    player_id = get_session(conn, :player_id)
    case ChessApp.get_board_state(deserialize(game_id)) do
      {:ok, fen} ->
        render(conn, "game.html", %{fen: fen, game_id: game_id, player_id: serialize(player_id)})
      {:error, reason} ->
        conn |> redirect(to: "/chess")
    end
  end

  def join_game(conn, %{"game_id" => game_id}) do
    player_id = ChessApp.get_player_id()
    conn = put_session(conn, :player_id, player_id)
    ChessApp.join_game(deserialize(game_id), player_id)

    conn |> redirect(to: "/chess/#{game_id}/play")
  end

  def move(conn, %{"game_id" => game_id, "move" => %{"move_text" => move_text}}) do
    player_id = get_session(conn, :player_id)
    ChessApp.make_move(deserialize(game_id), player_id, move_text)
    {:ok, fen} = ChessApp.get_board_state(deserialize(game_id))

    render(conn, "game.html", %{fen: fen, game_id: game_id, player_id: serialize(player_id)})
  end

  def serialize(term) do
    term
    |> :erlang.term_to_binary()
    |> Base.url_encode64()
  end

  def deserialize(str) when is_binary(str) do
    str
    |> Base.url_decode64!()
    |> :erlang.binary_to_term()
  end

end
