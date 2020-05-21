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

  def handle_call({:resign, player_id}, _from, state) do
    new_state = ChessApp.Game.resign(player_id, state)
    {:reply, :ok, new_state}
  end

  @impl true
  def handle_call({:get_other_player_id, player_id}, _from, state) do
    other_player_id = ChessApp.Game.get_other_player_id(player_id, state)
    {:reply, other_player_id, state}
  end

  @impl true
  def handle_call({:make_move, player_id, move}, _from, state) do
    new_state = ChessApp.Game.make_move(player_id, move, state)
    {:reply, new_state, new_state}
  end

  @impl true
  def handle_call({:get_board_state}, _from, state) do
    {:reply, ChessApp.Game.get_board_state(state), state}
  end
  @impl true
  def handle_call({:get_game_state, player_id}, _from, state) do
    {:reply, ChessApp.Game.get_game_state(player_id, state), state}
  end

end