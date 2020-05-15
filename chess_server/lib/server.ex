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

  @impl true
  def handle_call({:get_player_color, player_id}, _from, state) do
    color = ChessApp.Game.get_player_color(player_id, state)
    {:reply, color, state}
  end

  @impl true
  def handle_call({:make_move, player_id, move}, _from, state) do
    # for now this call does not modify the game's state, it modifies the
    # binbo processes state, so we don't need to update here.
    {:reply, ChessApp.Game.make_move(player_id, move, state), state}
  end

  @impl true
  def handle_call({:get_board_state}, _from, state) do
    {:reply, ChessApp.Game.get_board_state(state), state}
  end
  @impl true
  def handle_call({:get_game_state}, _from, state) do
    {:reply, ChessApp.Game.get_game_state(state), state}
  end

end