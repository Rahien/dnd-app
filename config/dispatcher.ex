defmodule Dispatcher do
  use Plug.Router

  def start(_argv) do
    port = 80
    IO.puts "Starting Plug with Cowboy on port #{port}"
    Plug.Adapters.Cowboy.http __MODULE__, [], port: port
    :timer.sleep(:infinity)
  end

  plug Plug.Logger
  plug :match
  plug :dispatch

	match "/sessions/*path" do
		Proxy.forward conn, path, "http://login/sessions/"
	end

  match "/accounts/*path" do
    Proxy.forward conn, path, "http://registration/accounts/"
  end

  match "/players/*path" do
    Proxy.forward conn, path, "http://resource/players/"
  end

  match "/characters/*path" do
    Proxy.forward conn, path, "http://resource/characters/"
  end

  match "/spells/*path" do
    Proxy.forward conn, path, "http://resource/spells/"
  end

  match "/items/*path" do
    Proxy.forward conn, path, "http://resource/items/"
  end

end
