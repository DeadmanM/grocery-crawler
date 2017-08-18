defmodule Api.DownloadHelper do
	require Logger
	@doc """
		This helper returns the HTML body associated with its argument.
		It does not directly download the page. Instead, it first checks the MIME type
		of the page with `check_content/1`. Then according to the result of this function,
		either the HTML body is returned, or `nil`, with an error message printed on the console.
	"""
	@spec download(String.t) :: String.t | nil
	def download(url) do
		with {:ok, url} <- check_content(url),
	     	 {:ok, %HTTPoison.Response{status_code: 200, body: body, headers: _}} <- fetch(url) do 
	    		body
		else
		  	 :error -> 	
		  	 	{:error, :bad_url}
		    	Logger.warn "Bad URL!"
		    	nil

		  	 {:ok, %HTTPoison.Response{status_code: 502, body: _, headers: _}} -> 
		  	 	Logger.warn "502 Bad Gateway on #{url}"
		    	nil

		  	 {:ok, %HTTPoison.Response{status_code: 404, body: _, headers: _}} ->
		    	Logger.warn "404 Page not Found on #{url}"
		    	nil

		  	 {:error, error} ->
		    	Logger.error inspect(error.reason)
		    	nil
		end
	end

	@spec fetch(String.t) :: {:ok, %HTTPoison.Response{}} | {:error, %HTTPoison.Response{}}
	defp fetch(url) do
		HTTPoison.get(url, @headers, [recv_timeout: :infinity] ++ @options)
	end

	
	@doc """
		This helper checks the MIME type of the page. It first sends a `HEAD` request, and according to
		the HTTP Code (301 or 302, for instance), decides to probe the new location of the page,
		or just return the url in an :ok-tuple
	"""
	@spec check_content(String.t) :: {:ok, String.t} | {:error, term()}
	def check_content(url) do
		response = HTTPoison.head(url, @headers, @options)
		           |> check_response

		result = with {:ok, headers} <- response,
		              {{"Content-Type", types}, _rest} <- List.keytake(headers, "Content-Type", 0),
		              :ok <-  verify_mime(types) do
		              	{:ok, url}
		         else
		          	  {:moved, location} -> check_content(location)
		              {:error, err}      -> {:error, err}
		         end
		result
	end

	@doc """
		Checks if the requested page has been moved
	"""
	@spec check_response({:error, String.t} | {:ok, %HTTPoison.Response{}}) :: {:error, String.t} | {:moved, String.t} | {:ok, list}
  	defp check_response({:error, err}), do: {:error, err}
  	defp check_response({:ok, %HTTPoison.Response{status_code: code, body: _data, headers: headers}}) do
    	case code do

      	c when c in [301,302] ->
        	{{"Location", location}, _rest} = List.keytake(headers, "Location", 0)
        	{:moved, location}

      	_ -> {:ok, headers}

    	end
  	end

  
  	@doc """
		Checks if the mimetype is valid
  	"""
  	@spec verify_mime(String.t) :: :ok | {:error, :wrong_headers}
  	defp verify_mime(types) do
    	case Regex.run(~r/^text\/html.*/iu, types, capture: :all_but_first) do    	
      		nil -> {:error, :wrong_headers}
      		_ -> :ok
    	end
  	end
end