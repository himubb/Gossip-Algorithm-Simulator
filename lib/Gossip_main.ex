defmodule Gossip_main do
  def start(numnodes, topology) do

    #fetch correct numnodes value according to topology
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
    #create actors equal to numnodes
    spawn_processes(numnodes, topology)


    t1 = System.system_time(:millisecond)
    #convergence task
    c_task = Task.async(fn -> convergence_confirmation(numnodes) end)
    :global.register_name(:c_pid, c_task.pid)
    message = :gossip
    send_initial_message(numnodes, message)
    Task.await(c_task, :infinity)

    time_taken = System.system_time(:millisecond) - t1
    IO.puts("Convergence time is : #{time_taken} milliseconds")

  end


  def convergence_confirmation(numnodes) do
      if numnodes > 0 do
        receive do
          {:converged_success, pid} ->
            IO.puts("#{inspect(pid)} node has been converged, remaining nodes are #{numnodes}")
            convergence_confirmation(numnodes - 1)
        after
        1000 ->
          IO.puts("Convergence failed, remaining nodes are #{numnodes}")
          convergence_confirmation(numnodes - 1)
        end
      end
  end


  def send_initial_message(numnodes, message) do
    random_node_id = Enum.random(1..numnodes)
    n_pid=
    case Registry.lookup(:reg_name, random_node_id) do
      [{pid, _}] -> pid
      [] -> nil
    end

    if n_pid != nil do
      send(n_pid, message)
    else
      send_initial_message(numnodes, message)
    end
  end

  defp spawn_processes(numnodes, topology) do
    range_of_nodes = 1..numnodes
    rand_generated_Grid = Enum.shuffle(1..numnodes) |> Enum.with_index(1)

    for t <- range_of_nodes do
      spawn(fn  -> GossipNode.start_link(t, get_neighbor(t, numnodes, topology, rand_generated_Grid)) end) |> Process.monitor()
    end
  end

  #get neighbors as per topology and node arrangement
  def get_neighbor(t, numnodes, topology, rand_generated_Grid) do
    
    n = []
    n = 
    if topology == "full" do
      Enum.filter(1..numnodes, fn x -> x != t end)
    else
      n
    end
    n=
    if topology == "line" do
      Enum.filter(1..numnodes, fn x-> x==t+1 || x==t-1 end)
    else
      n
    end


    n=
    if topology=="rand2D" do
    
    grid_length =  :math.sqrt(numnodes)
    grid_length = round(grid_length)

    top_index = t + grid_length
    top_index = if top_index <= numnodes do
      [top_index]
    else
      []
    end
    bottom_index = t - grid_length
    bottom_index = if bottom_index > 0 do
      [bottom_index]
    else
      []
    end
    right_index =
      if rem(t, grid_length) != 0 do
        if t != numnodes do
          [t+1]  
        else 
          []
        end
      else
        []
      end
    left_index =
      if rem(t, grid_length) != 1 do
        [t-1]
      else
        []
      end

    neighbor_final_list = top_index ++ bottom_index ++ right_index ++ left_index

    Enum.filter(rand_generated_Grid, fn x -> Enum.member?(neighbor_final_list, elem(x, 1)) end) 
    |> Enum.map(fn x -> elem(x, 0) end)
  else
    n
    end
    n=
    if topology=="3Dtorus" do
      # cuberoot = 1/3
      # c = :math.pow(numnodes, cuberoot)
      # neighbor_array = [ t - 1, t + 1, t - :math.pow(c,2), t + :math.pow(c,2), t - c, t + c]
      # Enum.filter(neighbor_array, fn x -> x <= numnodes and x >= 1 end)


    cubeLength = numnodes |> :math.pow(1 / 3) |> trunc()
    divison_criteria = rem(t, cubeLength) |> trunc()
    left_node = if divison_criteria == 1 do
      [t + cubeLength-1]
    else
      [t-1]
    end
    right_node = if divison_criteria == 0 do
      [t - (cubeLength-1)]
    else
      [t+1]
    end
    top_node = if trunc(rem(ceil(t/cubeLength), cubeLength)) == 1 do
      [t + (cubeLength-1)*cubeLength]
    else
      [t-cubeLength]
    end

    bottom_node = if trunc(rem(ceil(t/cubeLength), cubeLength)) == 0 do
      [t - (cubeLength-1)*cubeLength]
    else
      [t+cubeLength]
    end

    front_node = if t <= cubeLength*cubeLength do
      [t + (cubeLength-1)*cubeLength*cubeLength]
    else
      [t - cubeLength*cubeLength]
    end
    back_node = if t >= (numnodes - cubeLength*cubeLength) do
      [t - (cubeLength-1)*cubeLength*cubeLength]
    else
      [t + cubeLength*cubeLength]
    end


    list = left_node ++ right_node ++ top_node ++ bottom_node ++ front_node ++ back_node
    

    l2 = Enum.filter(list, fn x -> x >= 1 and x <= numnodes end) |> Enum.map(fn x-> trunc(x) end)
    l2


    else
      n
    end
    n=
    if topology == "honeycomb" do
      rowcnt = :math.sqrt(numnodes) |> trunc()
      colnum = rem(t, rowcnt) |> trunc()
      colnum = if colnum==0 do
        rowcnt
      else
        colnum
      end
      rownum = ceil(t/rowcnt) |> trunc()
      n = [t+rowcnt, t-rowcnt]
      n = if (rem(rownum, 2)==1 and rem(colnum,2)==1) or (rem(rownum, 2)==0 and rem(colnum,2)==0) do
        n=if colnum !=rowcnt do
          n++[t+1]
        else
          n
        end
        n
      else
        n
      end
      n = if (rem(rownum, 2)==0 and rem(colnum,2)==1) or (rem(rownum, 2)==1 and rem(colnum,2)==0) do
        n=if colnum !=1 do
          n++[t-1]
        else
          n
        end
        n
      else
        n
      end

      Enum.map(n,fn x-> trunc(x) end) |> Enum.filter(fn x -> x >= 1 and x <= numnodes end)

    else
      n
    end
    n=
    if topology == "randhoneycomb" do
      n = get_neighbor(t, numnodes, "honeycomb", rand_generated_Grid)
      
      random_neighbor_list = Enum.reject(1..numnodes, fn x -> x == t end)
      random_neighbor = get_random_neighbor(numnodes, t, n, random_neighbor_list)
      
      n++[random_neighbor]
    else
      n
    end
    n
  end



  def get_random_neighbor(numnodes, t, n, random_neighbor_list) do
    
    random_neighbor = Enum.random(random_neighbor_list)
    if Enum.member?(n, random_neighbor) do
      get_random_neighbor(numnodes, t, n, random_neighbor_list)
    else
      random_neighbor
    end

  end
end 