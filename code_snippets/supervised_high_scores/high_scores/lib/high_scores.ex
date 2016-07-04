defmodule HighScores do
  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    # Define workers and child supervisors to be supervised
    children = [
      supervisor(HighScoresTableSupervisor, []),
      worker(HighScoresRegistry, [])
    ]

    opts = [strategy: :one_for_all, name: HighScores.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
