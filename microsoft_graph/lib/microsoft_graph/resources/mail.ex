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

  alias MicrosoftGraph.Batch
  alias MicrosoftGraph.Delta
  alias MicrosoftGraph.Resource

  @doc """
  Lists messages in a user's mailbox.
  """
  @spec list_messages(String.t(), keyword()) :: {:ok, map()} | {:error, term()}
  def list_messages(user_id, opts \\ []), do: Resource.execute(list_messages_query(user_id, opts), opts)

  @doc "Batch query variant of `list_messages/2`."
  @spec list_messages_query(String.t(), keyword()) :: Batch.Request.t()
  def list_messages_query(user_id, opts \\ []), do: build_query("GET", "/users/#{user_id}/messages", nil, opts)

  @doc """
  Gets a specific message.
  """
  @spec get_message(String.t(), String.t(), keyword()) :: {:ok, map()} | {:error, term()}
  def get_message(user_id, message_id, opts \\ []), do: Resource.execute(get_message_query(user_id, message_id, opts), opts)

  @doc "Batch query variant of `get_message/3`."
  @spec get_message_query(String.t(), String.t(), keyword()) :: Batch.Request.t()
  def get_message_query(user_id, message_id, opts \\ []) do
    build_query("GET", "/users/#{user_id}/messages/#{message_id}", nil, opts)
  end

  @doc """
  Sends a mail on behalf of a user.

  The `message` map should include `:subject`, `:body`, and `:toRecipients`.
  An optional `save_to_sent_items` boolean can be passed (default: true).
  """
  @spec send_mail(String.t(), map(), keyword()) :: :ok | {:error, term()}
  def send_mail(user_id, message, opts \\ []), do: Resource.execute(send_mail_query(user_id, message, opts), opts)

  @doc "Batch query variant of `send_mail/3`."
  @spec send_mail_query(String.t(), map(), keyword()) :: Batch.Request.t()
  def send_mail_query(user_id, message, opts \\ []) do
    {save, opts} = Keyword.pop(opts, :save_to_sent_items, true)
    body = %{"message" => stringify_keys(message), "saveToSentItems" => save}
    build_query("POST", "/users/#{user_id}/sendMail", body, opts)
  end

  @doc """
  Creates a draft message in the user's Drafts folder.
  """
  @spec create_draft(String.t(), map(), keyword()) :: {:ok, map()} | {:error, term()}
  def create_draft(user_id, message, opts \\ []), do: Resource.execute(create_draft_query(user_id, message, opts), opts)

  @doc "Batch query variant of `create_draft/3`."
  @spec create_draft_query(String.t(), map(), keyword()) :: Batch.Request.t()
  def create_draft_query(user_id, message, opts \\ []) do
    build_query("POST", "/users/#{user_id}/messages", stringify_keys(message), opts)
  end

  @doc """
  Deletes a message.
  """
  @spec delete_message(String.t(), String.t(), keyword()) :: :ok | {:error, term()}
  def delete_message(user_id, message_id, opts \\ []), do: Resource.execute(delete_message_query(user_id, message_id, opts), opts)

  @doc "Batch query variant of `delete_message/3`."
  @spec delete_message_query(String.t(), String.t(), keyword()) :: Batch.Request.t()
  def delete_message_query(user_id, message_id, opts \\ []) do
    build_query("DELETE", "/users/#{user_id}/messages/#{message_id}", nil, opts)
  end

  @doc """
  Lists mail folders for a user.
  """
  @spec list_mail_folders(String.t(), keyword()) :: {:ok, map()} | {:error, term()}
  def list_mail_folders(user_id, opts \\ []), do: Resource.execute(list_mail_folders_query(user_id, opts), opts)

  @doc "Batch query variant of `list_mail_folders/2`."
  @spec list_mail_folders_query(String.t(), keyword()) :: Batch.Request.t()
  def list_mail_folders_query(user_id, opts \\ []), do: build_query("GET", "/users/#{user_id}/mailFolders", nil, opts)

  @doc """
  Lists messages in a specific mail folder.
  """
  @spec list_folder_messages(String.t(), String.t(), keyword()) ::
          {:ok, map()} | {:error, term()}
  def list_folder_messages(user_id, folder_id, opts \\ []), do: Resource.execute(list_folder_messages_query(user_id, folder_id, opts), opts)

  @doc "Batch query variant of `list_folder_messages/3`."
  @spec list_folder_messages_query(String.t(), String.t(), keyword()) :: Batch.Request.t()
  def list_folder_messages_query(user_id, folder_id, opts \\ []) do
    build_query("GET", "/users/#{user_id}/mailFolders/#{folder_id}/messages", nil, opts)
  end

  @doc """
  Delta query for a user's messages. Returns message changes since the last sync.
  """
  @spec messages_delta(String.t(), keyword()) :: {:ok, Delta.delta_page()} | {:error, term()}
  def messages_delta(user_id, opts \\ []), do: Delta.query("/users/#{user_id}/messages/delta", opts)

  @doc "Batch query variant of `messages_delta/2`."
  @spec messages_delta_query(String.t(), keyword()) :: Batch.Request.t()
  def messages_delta_query(user_id, opts \\ []), do: build_query("GET", "/users/#{user_id}/messages/delta", nil, opts)

  @doc """
  Delta query for messages in a specific mail folder.
  """
  @spec folder_messages_delta(String.t(), String.t(), keyword()) :: {:ok, Delta.delta_page()} | {:error, term()}
  def folder_messages_delta(user_id, folder_id, opts \\ []) do
    Delta.query("/users/#{user_id}/mailFolders/#{folder_id}/messages/delta", opts)
  end

  @doc "Batch query variant of `folder_messages_delta/3`."
  @spec folder_messages_delta_query(String.t(), String.t(), keyword()) :: Batch.Request.t()
  def folder_messages_delta_query(user_id, folder_id, opts \\ []) do
    build_query("GET", "/users/#{user_id}/mailFolders/#{folder_id}/messages/delta", nil, opts)
  end

  defp stringify_keys(map) when is_map(map) do
    Map.new(map, fn
      {k, v} when is_atom(k) -> {Atom.to_string(k), stringify_keys(v)}
      {k, v} -> {k, stringify_keys(v)}
    end)
  end

  defp stringify_keys(list) when is_list(list), do: Enum.map(list, &stringify_keys/1)
  defp stringify_keys(value), do: value

  defp build_query(method, url, body, opts) do
    {as, opts} = Keyword.pop(opts, :as)
    {query, _opts} = Keyword.pop(opts, :query)
    %Batch.Request{method: method, url: url, body: body, query: query, as: as}
  end
end
