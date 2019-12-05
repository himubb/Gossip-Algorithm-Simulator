defmodule Project2 do
  def main(args) do
  [numnodes, topology, algorithm] = args
  #extracted arguments from commandline

  numnodes = String.to_integer(numnodes)
  Registry.start_link(keys: :unique, name: :reg_name)


  #check for algorithm gossip or pushsum and redirect aaccordingly
  if algorithm=="gossip" or algorithm == "Gossip" do
    Gossip_main.start(numnodes, topology)
  else
    if algorithm=="pushsum" or algorithm == "Pushsum" do
      Pushsum.start(numnodes, topology)
    else
      IO.puts("Enter correct algorithm name")
    end
  end

  end
end
