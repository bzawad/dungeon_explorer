defmodule Dungeon.Services.OllamaClient do
  @moduledoc """
  Client for interacting with local LLM API
  """

  require Logger

  @doc """
  Generate content using the local model
  """
  def generate(prompt) when is_binary(prompt) do
    if System.get_env("OLLAMA_MODEL", "none") == "none" do
      {:error, :ollama_disabled}
    else
      call_ollama_api(prompt)
    end
  end

  @doc """
  Generate content with streaming support for typewriter effect
  """
  def generate_streaming(prompt, callback_pid, message_tag) when is_binary(prompt) do
    if System.get_env("OLLAMA_MODEL", "none") == "none" do
      # Send error message to callback
      send(callback_pid, {message_tag, :error, :ollama_disabled})
      :ok
    else
      call_ollama_api_streaming(prompt, callback_pid, message_tag)
    end
  end

  @doc """
  Generate dungeon-related content with a standardized format
  """
  def generate_dungeon_content(content_type, context \\ %{}) do
    if System.get_env("OLLAMA_MODEL", "none") == "none" do
      {:error, :ollama_disabled}
    else
      prompt = build_dungeon_prompt(content_type, context)
      generate(prompt)
    end
  end

  # Build prompts for different types of dungeon content
  defp build_dungeon_prompt(:encounter_description, %{encounter_label: label, theme: theme}) do
    """
    You are a creative dungeon master. Generate a brief, atmospheric description for an encounter in a #{theme}.

    Encounter: #{label}
    Theme: #{theme}

    Write 1-2 sentences describing what the players might encounter here. Keep it mysterious and engaging.
    Do not include combat mechanics or specific stats.

    Example format: "Ancient skeletal guardians stand motionless in alcoves, their empty eye sockets tracking movement through the chamber."
    """
  end

  defp build_dungeon_prompt(:room_description, %{room_label: label, theme: theme}) do
    """
    You are a creative dungeon master. Generate a brief, atmospheric description for a room in a #{theme}.

    Room: #{label}
    Theme: #{theme}

    Write 1-2 sentences describing the appearance and atmosphere of this room. Focus on sensory details and mood.

    Example format: "Flickering torchlight reveals ancient tapestries hanging in tatters from stone walls, their once-vibrant colors faded to ghostly shadows."
    """
  end

  defp build_dungeon_prompt(:feature_description, %{feature_label: label, theme: theme}) do
    """
    You are a creative dungeon master. Generate a brief, atmospheric description for a special feature in a #{theme}.

    Feature: #{label}
    Theme: #{theme}

    Write 1-2 sentences describing this interesting feature. Make it intriguing and worth investigating.

    Example format: "A mysterious crystalline formation pulses with an inner light, casting dancing shadows across the cavern walls."
    """
  end

  defp build_dungeon_prompt(content_type, context) do
    """
    Generate creative content for a dungeon game.
    Content Type: #{content_type}
    Context: #{inspect(context)}

    Please provide a brief, atmospheric description suitable for a fantasy dungeon setting.
    """
  end

  # Ollama can hang on reused HTTP/1.1 keep-alive connections (second request waits forever
  # for response headers). Force a new TCP connection each time.
  defp ollama_json_headers do
    [
      {"Content-Type", "application/json"},
      {"Connection", "close"}
    ]
  end

  defp call_ollama_api(prompt) do
    model = System.get_env("OLLAMA_MODEL", "none")

    request_body =
      Jason.encode!(%{
        model: model,
        stream: false,
        prompt: prompt,
        temperature: 1.2
      })

    # Send request to Ollama API
    ollama_host = System.get_env("OLLAMA_HOST", "localhost")
    ollama_port = System.get_env("OLLAMA_PORT", "11434")
    ollama_url = "http://#{ollama_host}:#{ollama_port}/api/generate"

    Logger.debug("Sending request to Ollama API: #{ollama_url}")
    Logger.debug("Request model: #{model}")
    # Don't log the full prompt as it could be very large
    Logger.debug("Prompt length: #{String.length(prompt)} characters")

    # Add 30 second timeout to prevent hanging
    case Finch.build(:post, ollama_url, ollama_json_headers(), request_body)
         |> Finch.request(Dungeon.Finch, receive_timeout: 30_000) do
      {:ok, %Finch.Response{status: 200, body: body}} ->
        case Jason.decode(body) do
          {:ok, %{"response" => response}} ->
            Logger.debug(
              "Received response from Ollama API (length: #{String.length(response)} characters)"
            )

            {:ok, response}

          {:ok, response_data} ->
            Logger.error("Unexpected response format from Ollama API: #{inspect(response_data)}")
            {:error, :invalid_response_format}

          {:error, decode_error} ->
            Logger.error(
              "Failed to decode JSON response from Ollama API: #{inspect(decode_error)}"
            )

            {:error, :json_decode_error}
        end

      {:ok, %Finch.Response{status: status, body: body}} ->
        Logger.error("Ollama API returned error status #{status}: #{body}")
        {:error, {:http_error, status, body}}

      {:error, error} ->
        Logger.error("Failed to connect to Ollama API: #{inspect(error)}")
        {:error, :connection_error}
    end
  end

  defp call_ollama_api_streaming(prompt, callback_pid, message_tag) do
    model = System.get_env("OLLAMA_MODEL", "none")

    request_body =
      Jason.encode!(%{
        model: model,
        stream: true,
        prompt: prompt,
        temperature: 1.2
      })

    # Send request to Ollama API
    ollama_host = System.get_env("OLLAMA_HOST", "localhost")
    ollama_port = System.get_env("OLLAMA_PORT", "11434")
    ollama_url = "http://#{ollama_host}:#{ollama_port}/api/generate"

    Logger.debug("Sending streaming request to Ollama API: #{ollama_url}")
    Logger.debug("Request model: #{model}")
    Logger.debug("Prompt length: #{String.length(prompt)} characters")

    # Start a task to handle the streaming response
    Task.start(fn ->
      try do
        # Add 30 second timeout to prevent hanging
        case Finch.build(:post, ollama_url, ollama_json_headers(), request_body)
             |> Finch.request(Dungeon.Finch, receive_timeout: 30_000) do
          {:ok, %Finch.Response{status: 200, body: body}} ->
            handle_streaming_response(body, callback_pid, message_tag)

          {:ok, %Finch.Response{status: status, body: body}} ->
            Logger.error("Ollama API returned error status #{status}: #{body}")
            send(callback_pid, {message_tag, :error, :http_error})

          {:error, error} ->
            Logger.error("Failed to connect to Ollama API: #{inspect(error)}")
            send(callback_pid, {message_tag, :error, :connection_error})
        end
      rescue
        error ->
          Logger.error("Streaming task crashed: #{inspect(error)}")
          send(callback_pid, {message_tag, :error, :task_crash})
      end
    end)

    :ok
  end

  defp handle_streaming_response(body, callback_pid, message_tag) do
    # Split response by newlines since each chunk is a separate JSON object
    lines = String.split(body, "\n", trim: true)
    accumulated_response = ""

    accumulated_response =
      Enum.reduce(lines, accumulated_response, fn line, acc ->
        case Jason.decode(line) do
          {:ok, %{"response" => chunk} = obj} ->
            done? = Map.get(obj, "done", false)

            cond do
              done? and chunk != "" ->
                final_response = acc <> chunk
                send(callback_pid, {message_tag, :complete, final_response})
                final_response

              done? ->
                send(callback_pid, {message_tag, :complete, acc})
                acc

              true ->
                new_acc = acc <> chunk
                send(callback_pid, {message_tag, :partial, new_acc})
                new_acc
            end

          {:ok, %{"done" => true}} ->
            send(callback_pid, {message_tag, :complete, acc})
            acc

          {:error, decode_error} ->
            Logger.warning("Failed to decode streaming JSON line: #{inspect(decode_error)}")
            acc

          unexpected ->
            Logger.warning("Unexpected streaming response format: #{inspect(unexpected)}")
            acc
        end
      end)

    # If we got no response at all, send an error
    if accumulated_response == "" do
      Logger.error("No response content received from streaming API")
      send(callback_pid, {message_tag, :error, :no_response})
    end
  end
end
