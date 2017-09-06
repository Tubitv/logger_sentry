defmodule LoggerBackends do

  @moduledoc """
  A simple behaviour module for implementing the backend of Logger.

  A LoggerBackends is one backend for Logger and it can handle the event message
  from the Logger event server. The advantage of using a LoggerBackends implemented
  using this module is that it will have a standard set of interface functions:

    * get/set the backend log level
    * get the backend log format
    * get/set the backend log metadata

  ## Example

  The LoggerBackends behaviour abstracts the common Logger backend.
  Developers are only required to implement the callbacks and functionality they are
  interested in.

  Let's start with a code example and then explore the available callbacks.
  Imagine we want a LoggerBackends that write the log into files:

      defmodule Logger.Backends.File do
        use LoggerBackends

        def init(_args) do
          config = Application.get_env(:logger, :file, [])
          {:ok, init(config, %__MODULE__{})}
        end

        def log_event(level, _metadata, output, state) do
          filename = :filename.join(["./logger/", Atom.to_string(level), ".log"])
          :file.write_file(filename, [output], [:append])
          state
        end

        defp init(config, state) do
          level = Keyword.get(config, :level, :info)
          format = Logger.Formatter.compile Keyword.get(config, :format)
          metadata = Keyword.get(config, :metadata, []) |> configure_metadata()
          %{state | format: format, metadata: metadata, level: level}
        end

      end

      # Set `logger` Application's config
      config :logger,
        backends: [:console, Logger.Backends.File],
        sentry: [level: :error,
                 format: "$message",
                 metadata: []
                ]

      # execute Logger.`level` functions
      Logger.error("some log message")

  We set the Application configure of `logger`, and add it to `backends` list,
  then set log level as needed. So we could execute Logger interface functions
  as usual, and the file backend will write the log into the files.

  There are 2 callbacks required to be implemented in a `LoggerBackends`. And
  this behaviour will not define any callbacks for you, you have to define 2
  callbacks by yourself.

  """

  @doc """
  Initial for Logger backend.

  `args` is the module name which using the LoggerBackends behaviour, as example
  above in `Logger.Backends.File` module, the `_args` in `init/1` is
  `Logger.Backends.File`.

  Returning `{:ok, state}` will cause the Logger backend to enter its loop and
  wait for log event message.
  """
  @callback init(args :: term) ::
  {:ok, state} when state: any


  @doc """
  Invoked to log the event message as needed.

  `output` is the argument after parse of `format_event` in the `LoggerBackends`
  module.

  Returning `new_state` continues the loop with new state `new_state`.
  """
  @callback log_event(level :: atom, metadata :: list, output :: bitstring, state :: any) ::
  state when state: any

  defmacro __using__(_) do
    quote do

      @behaviour LoggerBackends
      @level_list [:debug, :info, :warn, :error]
      @metadata_list [:application, :module, :function, :file, :line, :pid]

      defstruct [format: nil, metadata: nil, level: nil, other_config: nil]

      @doc """
      Get the backend log level.
      """
      @spec level :: :debug | :info | :warn | :error
      def level, do: :gen_event.call(Logger, __MODULE__, :level)

      @doc """
      Set the backend log level.
      """
      @spec level(:debug | :info | :warn | :error) :: :ok | :error_level
      def level(level) when level in @level_list do
        :gen_event.call(Logger, __MODULE__, {:level, level})
      end
      def level(_), do: :error_level

      @doc """
      Get the backend log format.
      """
      @spec format :: list()
      def format, do: :gen_event.call(Logger, __MODULE__, :format)

      @doc """
      Get the backend log metadata.
      """
      @spec metadata :: :all | list()
      def metadata, do: :gen_event.call(Logger, __MODULE__, :metadata)

      @doc """
      Set the backend log metadata.
      """
      @spec metadata(:all | list()) :: :error_metadata | :ok
      def metadata(:all) do
        :gen_event.call(Logger, __MODULE__, {:metadata, :all})
      end
      def metadata(metadata) when is_list(metadata) do
        case Enum.all?(metadata, fn i -> Enum.member?(@metadata_list, i) end) do
          true ->
            :gen_event.call(Logger, __MODULE__, {:metadata, metadata})
          false ->
            :error_metadata
        end
      end
      def metadata(_), do: :error_metadata

      @doc false
      def handle_call(:level, state) do
        {:ok, state.level, state}
      end

      def handle_call({:level, level}, state) do
        {:ok, :ok, %{state | level: level}}
      end

      def handle_call(:format, state) do
        {:ok, state.format, state}
      end

      def handle_call(:metadata, state) do
        {:ok, state.metadata, state}
      end

      def handle_call({:metadata, metadata}, state) do
        {:ok, :ok, %{state | metadata: metadata}}
      end

      @doc false
      def handle_event({_level, gl, _event}, state) when node(gl) != node() do
        {:ok, state}
      end

      def handle_event({level, _gl, {Logger, msg, ts, md}},
                       %{level: log_level} = state) do
        case meet_level?(level, log_level) do
          true ->
            {:ok, log_event(level, md, format_event(level, msg, ts, md, state), state)}
          _ ->
            {:ok, state}
        end
      end

      def handle_event(_, state) do
        {:ok, state}
      end

      @doc false
      def handle_info(_, state) do
        {:ok, state}
      end

      @doc false
      def code_change(_old_vsn, state, _extra) do
        {:ok, state}
      end

      @doc false
      def terminate(_reason, _state) do
        :ok
      end

      defp format_event(level, msg, ts, md, state) do
        %{metadata: keys, format: format} = state
        format
        |> Logger.Formatter.format(level, msg, ts, take_metadata(md, keys))
        |> :erlang.iolist_to_binary
      end

      defp take_metadata(_, []), do: []
      defp take_metadata(metadata, :all), do: metadata
      defp take_metadata(metadata, keys), do: Keyword.take(metadata, keys)

      defp meet_level?(_lvl, nil), do: true
      defp meet_level?(lvl, min) do
        Logger.compare_levels(lvl, min) != :lt
      end

    end
  end

end
