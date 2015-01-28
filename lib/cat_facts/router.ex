require Logger

defmodule CatFacts.Router do
  use Plug.Router

  plug Plug.Parsers, parsers: [:urlencoded]
  plug :match
  plug :dispatch

  post "/" do

    case HTTPoison.get "http://catfacts-api.appspot.com/api/facts" do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        {:ok, parsed} = JSON.decode body
        slack_params = Map.get(conn, :params)
        url = "https://#{slack_params["team_domain"]}.slack.com/services/hooks/incoming-webhook?token=#{slack_params["token"]}"
        data = [
          username: "cat-facts",
          icon_emoji: ":cat:",
          channel: "##{slack_params["channel"]}",
          username: slack_params["user_name"],
          text: hd parsed["facts"]
        ]
        IO.inspect url
        IO.inspect data
        case HTTPoison.post url, {:form, data}, %{"Content-type" => "application/x-www-form-urlencoded"} do
          {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
            send_resp(conn, 200, hd parsed["facts"])
          err ->
            Logger.error "Error from slack API", [err: err]
            IO.inspect err
            send_resp(conn, 500, "Sorry! Cat facts are unavailable, try again later!")
        end
      err ->
        Logger.error "Error from cat facts API", [err: err]
        IO.inspect err
        send_resp(conn, 500, "Sorry! Cat facts are unavailable, try again later!")
    end
  end

  match _ do
    send_resp(conn, 404, "404 Not Found")
  end
end
