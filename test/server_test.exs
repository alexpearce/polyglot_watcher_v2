defmodule PolyglotWatcherV2.ServerTest do
  use ExUnit.Case, async: false
  import ExUnit.CaptureIO
  alias PolyglotWatcherV2.{ActionsExecutorFake, ActionsExecutorReal, Server, ServerStateBuilder}

  describe "start_link/2" do
    test "with no command line args given, spawns the server process with default starting state" do
      capture_io(fn ->
        assert {:ok, pid} = Server.start_link([], [])
        assert is_pid(pid)

        assert %{port: port, elixir: elixir} = :sys.get_state(pid)
        assert is_port(port)
        assert %{failures: [], mode: :default} == elixir
      end)
    end

    test "when starting up without any command line args, puts the default startup message" do
      Application.put_env(:polyglot_watcher_v2, :actions_executor_module, ActionsExecutorReal)
      output = capture_io(fn -> Server.start_link([], []) end)

      assert output =~ "Watching for file saves..."
      Application.put_env(:polyglot_watcher_v2, :actions_executor_module, ActionsExecutorFake)
    end
  end

  describe "child_spec/0" do
    test "returns the default genserver options, with the callers pid" do
      assert %{
               id: Server,
               start: {Server, :start_link, [[], [name: :server]]}
             } == Server.child_spec()
    end
  end

  describe "handle_info/2 - file_event" do
    test "regonises file events from FileSystem, & returns a server_state" do
      server_state = ServerStateBuilder.build()

      assert {:noreply, new_server_state} =
               Server.handle_info(
                 {:port, {:data, './test/ CLOSE_WRITE,CLOSE server_test.exs\n'}},
                 server_state
               )

      assert new_server_state == server_state
    end
  end
end
