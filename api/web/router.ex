defmodule Api.Router do
  use Api.Web, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", Api do
     pipe_through :api

     get "crawl/:groceryId", CrawlController, :index
  end
end
