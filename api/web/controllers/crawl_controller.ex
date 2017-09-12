defmodule Api.CrawlController do
	use Api.Web, :controller
	alias Api.DownloadHelper
	require Logger


	@elastic_url "http://127.0.0.1:9200"

	def main(conn, _) do
		Elastix.Index.create(@elastic_url, "grocery", %{})
		# TO DO : Retrieve page count
		# BUG? : index count
		index(1 .. 100)
		index(101 .. 200)
		index(201 .. 300)
		index(301 .. 368)
		
  		json conn, []
  	end

  	def index(pageCount) do
  		value = Enum.to_list(pageCount)
				|> Enum.map(fn(x) -> handle_page(x) end)
				|> Enum.concat
		
		error = Elastix.Bulk.post @elastic_url, value, index: "grocery", type: "iga"
  		IO.inspect(error)
  	end

  	def handle_page(x) do
  		src = "https://www.iga.net/en/search?t=%7BD9CE4CBE-C8C3-4203-A58B-7CF7B830880E%7D&page=#{x}"
  		body = DownloadHelper.download(src)
  		
  		value = Floki.find(body, ".js-product")
  				|> Floki.attribute("data-product")
  				|> Enum.map(fn(x) -> parse_info(x) end)
  				|> Enum.concat
  	end

  	#@spec parse_info(String.t, ) :: %{}
  	def parse_info(node) do
  		%{	"BrandName" => brand_name,
  			"FullDisplayName" => full_display_name,
  			"HasNewPrice" => has_new_price,
  			"IsAgeRequired" => is_age_required,
  			"ProductId" => product_id,
  			"ProductImageUrl" => product_image_url,
  			"ProductUrl" => product_url,
  			"PromotionName" => promotion_name,
  			"RegularPrice" => regular_price,
  			"SalesPrice" => sales_price,
  			"Size" => size,
  			"SizeLabel" => size_label
  		} = node
  			|> String.replace("'", "\"")
  			|> Poison.decode!

  		line = [
  					%{index: %{_id: "iga_#{product_id}"}},
  					%{fields: 
  						%{	"BrandName" => brand_name,
  							"full_display_name" => full_display_name,
  							"has_new_price" => has_new_price,
  							"is_age_required" => is_age_required,
  							"product_id" => product_id,
  							"product_image_url" => product_image_url,
  							"product_url" => product_url,
  							"promotion_name" => promotion_name,
  							"regular_price" => regular_price,
  							"sales_price" => sales_price,
  							"size" => size,
  							"size_label" => size_label
  						}
  					}
  				]  		
  	end
end