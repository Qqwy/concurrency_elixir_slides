defmodule HighScoresTable do
  use GenServer
  @moduledoc "A process that stores a table of high scores."

  @doc "A table is list of scores and its max. length"
  defstruct scores: [], max_players: nil

  defmodule Score do
    @doc "A single score"
    defstruct name: "", score: 0, time: nil
  end


  # Outward API

  @doc "Starts the process, internally calls `init`."
  def start_link(max_players) do
    GenServer.start_link(__MODULE__, max_players)
  end

  @doc "Adds a new `score` for `name` to the table."
  def add_score(pid, name, score) do
    time = :erlang.time |> Time.from_erl!
    score = %Score{name: name, score: score, time: time}
    GenServer.call(pid, {:add_score, score})
  end

  @doc "Lists current scores"
  def current_scores(pid) do
    GenServer.call(pid, :current_scores)
  end


  # internal GenServer callbacks

  @doc "Initializes the GenServer"
  def init(max_players) do
    initial_state = %HighScoresTable{max_players: max_players}
    {:ok, initial_state}
  end

  @doc "Adds a score to the table, updating the internal state."
  def handle_call({:add_score, score = %Score{}}, _from, state) do
    {response, new_scores} = maybe_add_score(state.scores, state.max_players, score)
    new_state = %HighScoresTable{state | scores: new_scores}
    {:reply, response, new_state}
  end

  @doc "Lists the current scores"
  def handle_call(:current_scores, _from, state) do
    {:reply, state.scores, state}
  end

  defp maybe_add_score(scores, max_players, new_score) do
    split_scores = Enum.split_while(scores, fn score -> score.score >= new_score.score end)
    case split_scores do
      {all, []} when length(all) >= max_players -> 
        {:unfortunate, scores}
      {higher, lower} -> 
        new_scores = (higher ++ [new_score] ++ lower) |> Enum.take(max_players) 
        {{:congrats, length(higher)+1}, new_scores}
    end
  end
end
