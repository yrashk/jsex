defmodule JSX do
  def encode!(term, opts // []) do
    parser_opts = :jsx_config.extract_config(opts ++ [:escaped_strings])
    :jsx.parser(:jsx_to_json, opts, parser_opts).(List.flatten(JSXEncoder.json(term) ++ [:end_json]))
  end
  
  def encode(term, opts // []) do
    try do
      {:ok, encode!(term, opts)}
    rescue
      ArgumentError -> {:error, :badarg}
    end
  end
  
  def decode!(json, opts // []) do
    :jsx.decoder(JSX.Decoder, [], opts).(json)
  end

  def decode(term, opts // []) do
    try do
      {:ok, decode!(term, opts)}
    rescue
      ArgumentError -> {:error, :badarg}
    end
  end
  
  def format!(json, opts // []) do
    :jsx.format(json, opts)
  end

  def format(json, opts // []) do
    try do
      {:ok, format!(json, opts)}
    rescue
      ArgumentError -> {:error, :badarg}
    end
  end

  def minify!(json) do
    :jsx.minify(json)
  end

  def minify(json) do
    try do
      {:ok, minify! json}
    rescue
      ArgumentError -> {:error, :badarg}
    end
  end
  
  def prettify!(json) do
    :jsx.prettify(json)
  end

  def prettify(json) do
    try do
      {:ok, prettify! json}
    rescue
      ArgumentError -> {:error, :badarg}
    end
  end
  
  def is_json?(json, opts // []) do
    try do
      :jsx.is_json(json, opts)
    catch
      _, _ -> :false
    end
  end
  
  def is_term?(term, opts // []) do
    parser_opts = :jsx_config.extract_config(opts)
    try do
      :jsx.parser(:jsx_verify, opts, parser_opts).(List.flatten(JSXEncoder.json(term) ++ [:end_json]))
    catch
      _, _ -> :false
    end
  end
   
  defmodule Decoder do
    def init(_) do
      :jsx_to_term.init([])
    end

    def handle_event({:key, key}, {terms, config}) do
      {[{:key, format_key(key)}] ++ terms, config}
    end

    def handle_event({:literal, :null}, {[{:key, key}, last|terms], config}) do
      {[[{key, :nil}] ++ last] ++ terms, config}
    end
  
    def handle_event({:literal, :null}, {[last|terms], config}) do
      {[[:nil] ++ last] ++ terms, config}
    end
  
    def handle_event(event, config) do
      :jsx_to_term.handle_event(event, config)
    end
    
    defp format_key(key) do
      :erlang.binary_to_atom(key, :utf8)
    end
  end
end
  
defprotocol JSXEncoder do
  @only [Record, List, Tuple, Atom, Number, BitString, Any]
  def json(term)
end

defimpl JSXEncoder, for: List do
  def json([]), do: [:start_array, :end_array]
  def json([{}]), do: [:start_object, :end_object]
  def json([first|_] = list) when is_tuple(first) do
    [:start_object] ++ List.flatten(Enum.map(list, fn(term) -> JSXEncoder.json(term) end)) ++ [:end_object]
  end
  def json(list) do
    [:start_array] ++ List.flatten(Enum.map(list, fn(term) -> JSXEncoder.json(term) end)) ++ [:end_array]
  end
end

defimpl JSXEncoder, for: Tuple do
  # just assume any two tuples are part of a proplist. one field records are kind of
  # unencodable but those can be overriden while fixing proplists is harder 
  def json({key, value}) when is_atom(key), do: [{:key, key}] ++ JSXEncoder.json(value)
  def json(record) when is_record(record) do
    JSXEncoder.json Enum.map(
      record.__record__(:fields),
      fn({key, _}) ->
        index = record.__index__(key)
        value = elem(record, index)
        {key, value}
      end
    )
  end
  def json(_), do: raise ArgumentError
end

defimpl JSXEncoder, for: Atom do
  def json(:true), do: [:true]
  def json(:false), do: [:false]
  def json(:nil), do: [:null]
  def json(_), do: raise ArgumentError
end

defimpl JSXEncoder, for: Number do
  def json(number), do: [number]
end

defimpl JSXEncoder, for: BitString do
  def json(string), do: [string]
end

defimpl JSXEncoder, for: Any do
  def json(_), do: raise ArgumentError
end
