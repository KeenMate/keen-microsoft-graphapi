defmodule MicrosoftGraph.Mail do
  @moduledoc """
  Operations on mail resources (`/users/{id}/messages`, `/users/{id}/sendMail`, etc.).

  ## Examples

      # List messages
      {:ok, %{"value" => messages}} = MicrosoftGraph.Mail.list_messages("user-id")

      # Send mail
      MicrosoftGraph.Mail.send_mail("user-id", %{
        subject: "Hello",
        body: %{contentType: "Text", content: "Hi there"},
        toRecipients: [%{emailAddress: %{address: "bob@contoso.com"}}]
      })
  """

  alias MicrosoftGraph.Resource

  @doc """
  Lists messages in a user's mailbox.
  """
  @spec list_messages(String.t(), keyword()) :: {:ok, map()} | {:error, term()}
  def list_messages(user_id, opts \\ []) do
    Resource.get("/users/#{user_id}/messages", opts)
  end

  @doc """
  Gets a specific message.
  """
  @spec get_message(String.t(), String.t(), keyword()) :: {:ok, map()} | {:error, term()}
  def get_message(user_id, message_id, opts \\ []) do
    Resource.get("/users/#{user_id}/messages/#{message_id}", opts)
  end

  @doc """
  Sends a mail on behalf of a user.

  The `message` map should include `:subject`, `:body`, and `:toRecipients`.
  An optional `save_to_sent_items` boolean can be passed (default: true).
  """
  @spec send_mail(String.t(), map(), keyword()) :: :ok | {:error, term()}
  def send_mail(user_id, message, opts \\ []) do
    {save, opts} = Keyword.pop(opts, :save_to_sent_items, true)

    body = %{
      "message" => stringify_keys(message),
      "saveToSentItems" => save
    }

    Resource.post("/users/#{user_id}/sendMail", body, opts)
  end

  @doc """
  Creates a draft message in the user's Drafts folder.
  """
  @spec create_draft(String.t(), map(), keyword()) :: {:ok, map()} | {:error, term()}
  def create_draft(user_id, message, opts \\ []) do
    Resource.post("/users/#{user_id}/messages", stringify_keys(message), opts)
  end

  @doc """
  Deletes a message.
  """
  @spec delete_message(String.t(), String.t(), keyword()) :: :ok | {:error, term()}
  def delete_message(user_id, message_id, opts \\ []) do
    Resource.delete("/users/#{user_id}/messages/#{message_id}", opts)
  end

  @doc """
  Lists mail folders for a user.
  """
  @spec list_mail_folders(String.t(), keyword()) :: {:ok, map()} | {:error, term()}
  def list_mail_folders(user_id, opts \\ []) do
    Resource.get("/users/#{user_id}/mailFolders", opts)
  end

  @doc """
  Lists messages in a specific mail folder.
  """
  @spec list_folder_messages(String.t(), String.t(), keyword()) ::
          {:ok, map()} | {:error, term()}
  def list_folder_messages(user_id, folder_id, opts \\ []) do
    Resource.get("/users/#{user_id}/mailFolders/#{folder_id}/messages", opts)
  end

  defp stringify_keys(map) when is_map(map) do
    Map.new(map, fn
      {k, v} when is_atom(k) -> {Atom.to_string(k), stringify_keys(v)}
      {k, v} -> {k, stringify_keys(v)}
    end)
  end

  defp stringify_keys(list) when is_list(list), do: Enum.map(list, &stringify_keys/1)
  defp stringify_keys(value), do: value
end
