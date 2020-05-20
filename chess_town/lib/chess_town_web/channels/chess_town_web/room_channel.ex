defmodule ChessTownWeb.RoomChannel do
  use Phoenix.Channel

  def join("room:lobby", _message, socket) do
    {:ok, socket}
  end
  def join("room:" <> room_id, _params, socket) do
    # TODO some authentication will go here
    {:ok, socket}
  end

  def handle_in("ready", %{"game_id" => game_id, "player_id" => player_id}, socket) do
    game_state = ChessApp.get_game_state(deserialize(game_id), deserialize(player_id))
    broadcast!(socket, "game_state", %{body: game_state})
    {:noreply, socket}
  end

  def handle_in("move", %{"game_id" => game_id, "player_id" => player_id, "move" => move_text}, socket) do
    ChessApp.make_move(deserialize(game_id), deserialize(player_id), move_text)
    game_state = ChessApp.get_game_state(deserialize(game_id), deserialize(player_id))
    broadcast!(socket, "game_state", %{body: game_state})
    other_player_id = ChessApp.get_other_player_id(deserialize(game_id), deserialize(player_id))
    send_player_updated_state(socket, game_id, serialize(other_player_id))
    {:noreply, socket}
  end

  defp send_player_updated_state(_socket, _game_id, nil) do
  end

  defp send_player_updated_state(socket, game_id, player_id) do
    game_state = ChessApp.get_game_state(deserialize(game_id), deserialize(player_id))
    channel = "room:" <> game_id <> ":" <> player_id
    socket.endpoint.broadcast!(channel, "game_state", %{body: game_state})
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
