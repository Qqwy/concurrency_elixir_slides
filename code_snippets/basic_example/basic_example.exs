other_pid = spawn(fn -> 
  receive do
    {sender, contents} -> 
      send(sender, "You sent me: #{inspect(contents)}")
  end
end)

send(other_pid, {self, "Hello, world!"})

receive do
  message -> IO.puts "Main Process received: #{inspect(message)}"
end
