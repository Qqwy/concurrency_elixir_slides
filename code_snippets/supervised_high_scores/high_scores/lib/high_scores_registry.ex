defmodule HighScoresRegistry do
  use GenServer

  @doc "Starts the HighScoresRegistry, with the module name as process alias so we don't have to pass the pid around"
  def start_link do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    {:ok, %{}}
  end

  # Outward API

  @doc "Adds a new game"
  def add_game(game, max_players \\ 10) do
    GenServer.call(__MODULE__, {:add_game, game, max_players})
  end

  @doc "Adds `name`'s `score` on `game` to that games table"
  def add_score(game, name, score) do
    {:ok, hst_pid} = get_game_pid(game)
    HighScoresTable.add_score(hst_pid, name, score)
  end

  @doc "Lists the current scores for `game`"
  def current_scores(game) do
    {:ok, hst_pid} = get_game_pid(game)
    HighScoresTable.current_scores(hst_pid)
  end

  # Returns the pid of a certain game.
  defp get_game_pid(game) do
    GenServer.call(__MODULE__, {:get_game, game})
  end

  # internal GenServer callbacks

  def handle_call({:add_game, game_name, max_players}, _from, games) do
    if games[game_name] do
      {:reply, {:error, :game_already_exists}, games}
    else
      {:ok, pid} = HighScoresTableSupervisor.start_child([max_players])
      Process.monitor(pid)
      games = Map.put_new(games, game_name, {pid, max_players})
      {:reply, :ok, games}
    end
  end

  def handle_call({:get_game, game}, _from, games) do
    if games[game] do
      {pid, _} = games[game]
      {:reply, {:ok, pid}, games}
    else
      {:reply, {:error, :unknown_game}, games}
    end
  end

  @doc "Remove table processes when they crash, and start a new table for that game."
  def handle_info({:DOWN, ref, :process, crashed_pid, _reason}, games) do
    games = 
      for {game_name, {pid, max_players}} <- games, into: %{} do
        if pid == crashed_pid do
          {:ok, new_pid} = HighScoresTableSupervisor.start_child([max_players])
          {game_name, {new_pid, max_players}}
        else
          {game_name, {pid, max_players}}
        end
      end
    {:noreply, games}
  end
end
