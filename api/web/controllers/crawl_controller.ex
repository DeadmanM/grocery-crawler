defmodule Api.CrawlController do
	use Api.Web, :controller
	alias Api.DownloadHelper
	require Logger

	# Inspired by https://github.com/sergiotapia/magnetissimo
	@headers [{"Accept", "text/html,application/xhtml+xml"}]
  	@options [follow_redirect: false]

	def index(conn, _) do
  		body = DownloadHelper.download("https://github.com/sergiotapia/magnetissimo/blob/master/lib/crawler/helper.ex")

  		json conn, body
  	end
end