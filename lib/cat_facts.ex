require Logger

defmodule CatFacts do
  def start(_type, _args) do
    opts  = [port: 4000, compress: true, linger: {true, 10}]
    if port = System.get_env("PORT") do
      opts = Keyword.put(opts, :port, String.to_integer(port))
    end
    Logger.info "Starting Cowboy on port #{opts[:port]}"
    Plug.Adapters.Cowboy.http CatFacts.Router, [], opts
    #CatFacts.Supervisor.start_link
    #{:ok, self()}
  end

  def stop() do
    Plug.Adapters.Cowboy.shutdown CatFacts.Router.HTTP
    :ok
  end
end
