require Logger

defmodule CatFacts.Router do
  use Plug.Router

  plug Plug.Parsers, parsers: [:urlencoded]
  plug :match
  plug :dispatch

  post "/" do

    slack_params = Map.get(conn, :params)
    if slack_params["channel_name"] == System.get_env("SLACK_CHANNEL") do
      case HTTPoison.get "http://catfacts-api.appspot.com/api/facts" do
        {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
          {:ok, parsed} = JSON.decode body
          #url = "https://#{slack_params["team_domain"]}.slack.com/services/hooks/incoming-webhook?token=#{slack_params["token"]}"
          url = System.get_env "SLACK_URL"
          data = [
            username: "cat-facts",
            icon_emoji: ":cat:",
            #channel: "##{slack_params["channel_name"]}",
            text: if System.get_env("SLACK_SHOW_USERNAME") == "true" do "#{slack_params["user_name"]}: #{hd parsed["facts"]}" else hd parsed["facts"] end
          ]
          #IO.inspect slack_params
          #IO.inspect url
          #IO.inspect data
          {:ok, data} = JSON.encode data
          case HTTPoison.post url, data, %{"Content-type" => "application/json"} do
            {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
              #send_resp(conn, 200, hd parsed["facts"])
              send_resp(conn, 200, "")
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
    else
      send_resp(conn, 500, "Sorry! Cat facts are only available in #{System.get_env "SLACK_CHANNEL"}.")
    end
  end

  match _ do
    send_resp(conn, 404, "404 Not Found")
  end
end
