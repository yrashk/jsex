defmodule JSX do

  def decode(json) do
    :jsx.decoder(JSX, [], []).(json)
  end
  
  
  def init(_) do
    :jsx_to_term.init([])
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
  
end