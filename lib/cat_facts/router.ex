require Logger

defmodule CatFacts.Router do
  use Plug.Router

  plug :match
  plug :dispatch

  get "/" do
    case HTTPoison.get "http://catfacts-api.appspot.com/api/facts" do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        {:ok, parsed} = JSON.decode body
        send_resp(conn, 200, hd parsed["facts"])
      err ->
        Logger.error "Error from cat facts API", err
        send_resp(conn, 500, "Sorry! Cat facts are unavailable, try again later!")
    end
  end

  match _ do
    send_resp(conn, 404, "404 Not Found")
  end
end
