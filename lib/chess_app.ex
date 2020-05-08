defmodule ChessApp do
  @moduledoc """
  Documentation for `ChessApp`.
  """

  use Application


  def start(_type, _arg) do
    children = []
    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
