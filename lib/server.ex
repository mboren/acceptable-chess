defmodule ChessApp.Game.Server do
  use GenServer

  @impl true
  def init(_arg) do
    {:ok, ChessApp.Game.new_game()}
  end

  @impl true
  def handle_call({:join_game, player_id}, _from, state) do
    new_state = ChessApp.Game.add_player_to_game(player_id, state)
    {:reply, :ok, new_state}
  end

  @impl true
  def handle_call({:get_players}, _from, state) do
    {:reply, state, state}
  end
end