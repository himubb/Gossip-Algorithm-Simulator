defmodule Pushsum do
	def start(numnodes, topology) do
		
	numnodes = if topology=="3Dtorus" do
	    cuberoot = 1/3
	    nodes = :math.pow(numnodes, cuberoot) |> :math.ceil()
	    numnodes = :math.pow(nodes, 3)
	    numnodes
    else
      numnodes
    end 
    numnodes = if topology == "rand2D" or topology == "honeycomb" or topology == "randhoneycomb" do
    sqroot = 1/2
      nodes = :math.pow(numnodes, sqroot) |> :math.ceil()
      numnodes = :math.pow(nodes, 2)
      numnodes
    else
      numnodes
    end
    numnodes = round(numnodes)
    spawn_processes_pushsum(numnodes, topology)

    t1 = System.system_time(:millisecond)
    #convergence task
    c_task = Task.async(fn -> convergence_confirmation_pushsum(numnodes) end)
    :global.register_name(:c_pid, c_task.pid)
    message = {:pushsum, 0, 0}
    initial_pushsum(numnodes, message)
    Task.await(c_task, :infinity)

    time_taken = System.system_time(:millisecond) - t1
    IO.puts("Convergence time is : #{time_taken} milliseconds")

	end

	def convergence_confirmation_pushsum(numnodes) do
      if numnodes > 0 do
        receive do
          {:converged_success, pid} ->
            IO.puts("#{inspect(pid)} node has been converged, remaining nodes are #{numnodes}")
            convergence_confirmation_pushsum(numnodes - 1)
        after
        1000 ->
          IO.puts("Convergence failed, remaining nodes are #{numnodes}")
          convergence_confirmation_pushsum(numnodes - 1)
        end
      end
  	end


  	def initial_pushsum(numnodes, message) do
	    random_node_id = Enum.random(1..numnodes)
	    n_pid=
	    case Registry.lookup(:reg_name, random_node_id) do
	      [{pid, _}] -> pid
	      [] -> nil
	    end

	    if n_pid != nil do
	      send(n_pid, message)
	    else
	      initial_pushsum(numnodes, message)
	    end
  	end


	def spawn_processes_pushsum(numnodes, topology) do
		range_of_nodes = 1..numnodes
    rand_generated_Grid = Enum.shuffle(1..numnodes) |> Enum.with_index(1)
	    for t <- range_of_nodes do
	      spawn(fn  -> PushNode.start_link(t, Gossip_main.get_neighbor(t, numnodes, topology, rand_generated_Grid)) end) |> Process.monitor()
	    end
	end
end