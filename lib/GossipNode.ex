defmodule GossipNode do
	def start_link(id, list_of_neighbors) do
		GenServer.start_link(__MODULE__, [id, list_of_neighbors], name: fetch_name(id))
	end


	def init([id, list_of_neighbors]) do
		get_message(id, list_of_neighbors)
		{:ok, id}
	end

	defp get_message(id, list_of_neighbors) do
		receive do
			:gossip ->
				
				#create_task has pid
				create_task = Task.start(fn -> start_process(id, list_of_neighbors) end)
				count = 1
				receive_gossip(create_task, count)
		end	
	end

	def receive_gossip(create_task, count) do
		if count < 10 do
			#IO.puts("count is #{count}")
			
			receive do
				:gossip-> receive_gossip(create_task, count+1)
			end
		else
			send(:global.whereis_name(:c_pid), {:converged_success, self()})
    		Task.shutdown(create_task, :kill)
		end
	end


	def start_process(id, list_of_neighbors) do
		neighbor = Enum.random(list_of_neighbors)
		neighbor_pid = 
		case Registry.lookup(:reg_name, neighbor) do
      	[{pid, _}] -> pid
      	[] -> nil
    	end

      	if neighbor_pid != nil do
      		send(neighbor_pid, :gossip)
      		Process.sleep(100)
      		start_process(id, list_of_neighbors)
      	else
      		start_process(id, list_of_neighbors)
      	end

      	
	end

	def fetch_name(id) do
		{:via, Registry, {:reg_name, id}}
	end


end