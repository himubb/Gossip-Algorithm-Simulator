defmodule PushNode do
	def start_link(id, list_of_neighbors) do
		GenServer.start_link(__MODULE__, [id, list_of_neighbors], name: fetch_name(id))
	end


	def init([id, list_of_neighbors]) do
		receive do
			{_, sum, weight} -> start_pushsum_process(id, list_of_neighbors, sum, weight)
		end	
		{:ok, id}
	end


	def start_pushsum_process(id, list_of_neighbors, sum, weight) do
		{:ok, c_pid} = Task.start(fn -> call_neighbor(list_of_neighbors, id) end)
		p_listen(0, sum + id, weight+1, id,c_pid)
	end


	def p_listen(count, sum, weight, prev_ratio, c_pid) do
		new_ratio = sum / weight
		change = abs(new_ratio - prev_ratio)
		threshold = :math.pow(10, -10)
		count = 
		if change <= threshold do
			count + 1
		else
			0
		end


		if count < 3 do
			sum = sum/2
			weight = weight/2
			send(c_pid, {:neighbor_call, sum, weight})

		receive do
			{:updated_value, new_sum, new_weight} -> p_listen(count, new_sum+sum, new_weight+weight, new_ratio,c_pid)
		after
			100 -> p_listen(count, sum, weight, new_ratio, c_pid)
		end
		else
			send(:global.whereis_name(:c_pid), {:converged_success, self()})
    		Task.shutdown(c_pid, :kill)
		end
	end




	def call_neighbor(list_of_neighbors, id) do
		receive do
			{:neighbor_call, sum, weight} ->
				neighbour = Enum.random(list_of_neighbors)
				n_pid = case Registry.lookup(:reg_name, neighbour) do
		      	[{pid, _}] -> pid
		      	[] -> nil
		    	end

		    	if n_pid != nil do
		    		send(n_pid,{:updated_value, sum, weight})
		    		
					call_neighbor(list_of_neighbors, id)
				else
					call_neighbor(list_of_neighbors, id)
		    	end
		end

	end


	def fetch_name(id) do
		{:via, Registry, {:reg_name, id}}
	end

end