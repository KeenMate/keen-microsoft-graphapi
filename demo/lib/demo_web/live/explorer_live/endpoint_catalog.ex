defmodule DemoWeb.ExplorerLive.EndpointCatalog.Entry do
  @moduledoc false
  defstruct [
    :id,
    :resource,
    :label,
    :method,
    :module,
    :function,
    :schema,
    description: "",
    path_params: [],
    body?: false,
    body_template: nil,
    extra_params: []
  ]
end

defmodule DemoWeb.ExplorerLive.EndpointCatalog do
  @moduledoc """
  Maps every Graph Explorer UI entry to its corresponding library function.
  """

  alias __MODULE__.Entry

  @entries [
    # ── Users ──────────────────────────────────────────
    %Entry{
      id: :users_list,
      resource: "Users",
      label: "list",
      description: "List all users in the organization. Supports OData query parameters.",
      method: :get,
      module: MicrosoftGraph.Users,
      function: :list,
      schema: MicrosoftGraph.Schema.User
    },
    %Entry{
      id: :users_get,
      resource: "Users",
      label: "get",
      description: "Get a user by ID or userPrincipalName (e.g. user@contoso.com).",
      method: :get,
      module: MicrosoftGraph.Users,
      function: :get,
      path_params: [{"user_id", "User ID or UPN"}],
      schema: MicrosoftGraph.Schema.User
    },
    %Entry{
      id: :users_create,
      resource: "Users",
      label: "create",
      description: "Create a new user. Requires User.ReadWrite.All permission.",
      method: :post,
      module: MicrosoftGraph.Users,
      function: :create,
      schema: MicrosoftGraph.Schema.User,
      body?: true,
      body_template: """
      {
        "accountEnabled": true,
        "displayName": "New User",
        "mailNickname": "newuser",
        "userPrincipalName": "newuser@contoso.onmicrosoft.com",
        "passwordProfile": {
          "forceChangePasswordNextSignIn": true,
          "password": "xWwvJ]6NMw+bWH-d"
        }
      }\
      """
    },
    %Entry{
      id: :users_update,
      resource: "Users",
      label: "update",
      description: "Update user properties. Only include fields you want to change.",
      method: :patch,
      module: MicrosoftGraph.Users,
      function: :update,
      path_params: [{"user_id", "User ID or UPN"}],
      schema: MicrosoftGraph.Schema.User,
      body?: true,
      body_template: """
      {
        "jobTitle": "Senior Engineer",
        "department": "Engineering",
        "officeLocation": "Building A"
      }\
      """
    },
    %Entry{
      id: :users_delete,
      resource: "Users",
      label: "delete",
      description: "Delete a user. Moves to deleted items (recoverable for 30 days).",
      method: :delete,
      module: MicrosoftGraph.Users,
      function: :delete,
      path_params: [{"user_id", "User ID or UPN"}]
    },
    %Entry{
      id: :users_list_direct_reports,
      resource: "Users",
      label: "list_direct_reports",
      description: "List users and contacts that report to this user.",
      method: :get,
      module: MicrosoftGraph.Users,
      function: :list_direct_reports,
      path_params: [{"user_id", "User ID or UPN"}]
    },
    %Entry{
      id: :users_list_member_of,
      resource: "Users",
      label: "list_member_of",
      description: "List the groups, directory roles, and administrative units the user is a member of.",
      method: :get,
      module: MicrosoftGraph.Users,
      function: :list_member_of,
      path_params: [{"user_id", "User ID or UPN"}]
    },

    # ── Groups ─────────────────────────────────────────
    %Entry{
      id: :groups_list,
      resource: "Groups",
      label: "list",
      description: "List all groups in the organization. Supports OData query parameters.",
      method: :get,
      module: MicrosoftGraph.Groups,
      function: :list,
      schema: MicrosoftGraph.Schema.Group
    },
    %Entry{
      id: :groups_get,
      resource: "Groups",
      label: "get",
      description: "Get a group by its ID.",
      method: :get,
      module: MicrosoftGraph.Groups,
      function: :get,
      path_params: [{"group_id", "Group ID"}],
      schema: MicrosoftGraph.Schema.Group
    },
    %Entry{
      id: :groups_create,
      resource: "Groups",
      label: "create",
      description: "Create a new Microsoft 365 or security group.",
      method: :post,
      module: MicrosoftGraph.Groups,
      function: :create,
      schema: MicrosoftGraph.Schema.Group,
      body?: true,
      body_template: """
      {
        "displayName": "My New Group",
        "description": "Group created via Graph Explorer",
        "mailEnabled": false,
        "mailNickname": "mynewgroup",
        "securityEnabled": true,
        "groupTypes": []
      }\
      """
    },
    %Entry{
      id: :groups_update,
      resource: "Groups",
      label: "update",
      description: "Update group properties. Only include fields you want to change.",
      method: :patch,
      module: MicrosoftGraph.Groups,
      function: :update,
      path_params: [{"group_id", "Group ID"}],
      schema: MicrosoftGraph.Schema.Group,
      body?: true,
      body_template: """
      {
        "displayName": "Updated Group Name",
        "description": "Updated description"
      }\
      """
    },
    %Entry{
      id: :groups_delete,
      resource: "Groups",
      label: "delete",
      description: "Delete a group. Recoverable for 30 days.",
      method: :delete,
      module: MicrosoftGraph.Groups,
      function: :delete,
      path_params: [{"group_id", "Group ID"}]
    },
    %Entry{
      id: :groups_list_members,
      resource: "Groups",
      label: "list_members",
      description: "List the members of a group (users, service principals, groups, devices).",
      method: :get,
      module: MicrosoftGraph.Groups,
      function: :list_members,
      path_params: [{"group_id", "Group ID"}]
    },
    %Entry{
      id: :groups_add_member,
      resource: "Groups",
      label: "add_member",
      description: "Add a user or service principal to a group by their directory object ID.",
      method: :post,
      module: MicrosoftGraph.Groups,
      function: :add_member,
      path_params: [{"group_id", "Group ID"}, {"member_id", "Member ID (directory object ID)"}]
    },
    %Entry{
      id: :groups_remove_member,
      resource: "Groups",
      label: "remove_member",
      description: "Remove a member from a group.",
      method: :delete,
      module: MicrosoftGraph.Groups,
      function: :remove_member,
      path_params: [{"group_id", "Group ID"}, {"member_id", "Member ID (directory object ID)"}]
    },

    # ── Mail ───────────────────────────────────────────
    %Entry{
      id: :mail_list_messages,
      resource: "Mail",
      label: "list_messages",
      description: "List messages in a user's mailbox (Inbox by default).",
      method: :get,
      module: MicrosoftGraph.Mail,
      function: :list_messages,
      path_params: [{"user_id", "User ID or UPN"}],
      schema: MicrosoftGraph.Schema.Message
    },
    %Entry{
      id: :mail_get_message,
      resource: "Mail",
      label: "get_message",
      description: "Get a specific message by ID.",
      method: :get,
      module: MicrosoftGraph.Mail,
      function: :get_message,
      path_params: [{"user_id", "User ID or UPN"}, {"message_id", "Message ID"}],
      schema: MicrosoftGraph.Schema.Message
    },
    %Entry{
      id: :mail_send_mail,
      resource: "Mail",
      label: "send_mail",
      description: "Send a mail on behalf of a user. Requires Mail.Send permission.",
      method: :post,
      module: MicrosoftGraph.Mail,
      function: :send_mail,
      path_params: [{"user_id", "User ID or UPN"}],
      schema: MicrosoftGraph.Schema.Message,
      body?: true,
      body_template: """
      {
        "subject": "Hello from Graph Explorer",
        "body": {
          "contentType": "Text",
          "content": "This is a test message."
        },
        "toRecipients": [
          {
            "emailAddress": {
              "address": "recipient@contoso.com"
            }
          }
        ]
      }\
      """
    },
    %Entry{
      id: :mail_create_draft,
      resource: "Mail",
      label: "create_draft",
      description: "Create a draft message in the user's Drafts folder.",
      method: :post,
      module: MicrosoftGraph.Mail,
      function: :create_draft,
      path_params: [{"user_id", "User ID or UPN"}],
      schema: MicrosoftGraph.Schema.Message,
      body?: true,
      body_template: """
      {
        "subject": "Draft message",
        "body": {
          "contentType": "Text",
          "content": "Draft content here."
        },
        "toRecipients": [
          {
            "emailAddress": {
              "address": "recipient@contoso.com"
            }
          }
        ]
      }\
      """
    },
    %Entry{
      id: :mail_delete_message,
      resource: "Mail",
      label: "delete_message",
      description: "Delete a message (moves to Deleted Items).",
      method: :delete,
      module: MicrosoftGraph.Mail,
      function: :delete_message,
      path_params: [{"user_id", "User ID or UPN"}, {"message_id", "Message ID"}]
    },
    %Entry{
      id: :mail_list_mail_folders,
      resource: "Mail",
      label: "list_mail_folders",
      description: "List a user's mail folders (Inbox, Sent Items, Drafts, etc.).",
      method: :get,
      module: MicrosoftGraph.Mail,
      function: :list_mail_folders,
      path_params: [{"user_id", "User ID or UPN"}],
      schema: MicrosoftGraph.Schema.MailFolder
    },
    %Entry{
      id: :mail_list_folder_messages,
      resource: "Mail",
      label: "list_folder_messages",
      description: "List messages in a specific mail folder.",
      method: :get,
      module: MicrosoftGraph.Mail,
      function: :list_folder_messages,
      path_params: [{"user_id", "User ID or UPN"}, {"folder_id", "Folder ID"}],
      schema: MicrosoftGraph.Schema.Message
    },

    # ── Calendar ───────────────────────────────────────
    %Entry{
      id: :calendar_list_events,
      resource: "Calendar",
      label: "list_events",
      description: "List events on a user's default calendar.",
      method: :get,
      module: MicrosoftGraph.Calendar,
      function: :list_events,
      path_params: [{"user_id", "User ID or UPN"}],
      schema: MicrosoftGraph.Schema.Event
    },
    %Entry{
      id: :calendar_get_event,
      resource: "Calendar",
      label: "get_event",
      description: "Get a specific calendar event by ID.",
      method: :get,
      module: MicrosoftGraph.Calendar,
      function: :get_event,
      path_params: [{"user_id", "User ID or UPN"}, {"event_id", "Event ID"}],
      schema: MicrosoftGraph.Schema.Event
    },
    %Entry{
      id: :calendar_create_event,
      resource: "Calendar",
      label: "create_event",
      description: "Create a new event on the user's default calendar.",
      method: :post,
      module: MicrosoftGraph.Calendar,
      function: :create_event,
      path_params: [{"user_id", "User ID or UPN"}],
      schema: MicrosoftGraph.Schema.Event,
      body?: true,
      body_template: """
      {
        "subject": "Team Meeting",
        "body": {
          "contentType": "HTML",
          "content": "<p>Let's discuss the project.</p>"
        },
        "start": {
          "dateTime": "2026-03-01T10:00:00",
          "timeZone": "UTC"
        },
        "end": {
          "dateTime": "2026-03-01T11:00:00",
          "timeZone": "UTC"
        },
        "attendees": [
          {
            "emailAddress": {
              "address": "attendee@contoso.com",
              "name": "Attendee Name"
            },
            "type": "required"
          }
        ]
      }\
      """
    },
    %Entry{
      id: :calendar_update_event,
      resource: "Calendar",
      label: "update_event",
      description: "Update a calendar event. Only include fields you want to change.",
      method: :patch,
      module: MicrosoftGraph.Calendar,
      function: :update_event,
      path_params: [{"user_id", "User ID or UPN"}, {"event_id", "Event ID"}],
      schema: MicrosoftGraph.Schema.Event,
      body?: true,
      body_template: """
      {
        "subject": "Updated Meeting Title",
        "location": {
          "displayName": "Conference Room A"
        }
      }\
      """
    },
    %Entry{
      id: :calendar_delete_event,
      resource: "Calendar",
      label: "delete_event",
      description: "Delete a calendar event.",
      method: :delete,
      module: MicrosoftGraph.Calendar,
      function: :delete_event,
      path_params: [{"user_id", "User ID or UPN"}, {"event_id", "Event ID"}]
    },
    %Entry{
      id: :calendar_calendar_view,
      resource: "Calendar",
      label: "calendar_view",
      description: "Get events in a date range. Expands recurring events into individual instances.",
      method: :get,
      module: MicrosoftGraph.Calendar,
      function: :calendar_view,
      path_params: [{"user_id", "User ID or UPN"}],
      schema: MicrosoftGraph.Schema.Event,
      extra_params: [
        {"start_date_time", "Start (ISO 8601, e.g. 2026-01-01T00:00:00)"},
        {"end_date_time", "End (ISO 8601, e.g. 2026-01-31T23:59:59)"}
      ]
    },
    %Entry{
      id: :calendar_list_calendars,
      resource: "Calendar",
      label: "list_calendars",
      description: "List all calendars for a user (default, shared, etc.).",
      method: :get,
      module: MicrosoftGraph.Calendar,
      function: :list_calendars,
      path_params: [{"user_id", "User ID or UPN"}],
      schema: MicrosoftGraph.Schema.Calendar
    },

    # ── Files ──────────────────────────────────────────
    %Entry{
      id: :files_get_drive,
      resource: "Files",
      label: "get_drive",
      description: "Get a user's default OneDrive. Returns drive ID needed for other file operations.",
      method: :get,
      module: MicrosoftGraph.Files,
      function: :get_drive,
      path_params: [{"user_id", "User ID or UPN"}],
      schema: MicrosoftGraph.Schema.Drive
    },
    %Entry{
      id: :files_list_root_children,
      resource: "Files",
      label: "list_root_children",
      description: "List items in the root folder of a drive.",
      method: :get,
      module: MicrosoftGraph.Files,
      function: :list_root_children,
      path_params: [{"drive_id", "Drive ID"}],
      schema: MicrosoftGraph.Schema.DriveItem
    },
    %Entry{
      id: :files_list_children,
      resource: "Files",
      label: "list_children",
      description: "List items inside a specific folder.",
      method: :get,
      module: MicrosoftGraph.Files,
      function: :list_children,
      path_params: [{"drive_id", "Drive ID"}, {"item_id", "Folder Item ID"}],
      schema: MicrosoftGraph.Schema.DriveItem
    },
    %Entry{
      id: :files_get_item,
      resource: "Files",
      label: "get_item",
      description: "Get metadata for a drive item (file or folder) by ID.",
      method: :get,
      module: MicrosoftGraph.Files,
      function: :get_item,
      path_params: [{"drive_id", "Drive ID"}, {"item_id", "Item ID"}],
      schema: MicrosoftGraph.Schema.DriveItem
    },
    %Entry{
      id: :files_get_item_by_path,
      resource: "Files",
      label: "get_item_by_path",
      description: "Get metadata for a drive item by its path (e.g. Documents/report.docx).",
      method: :get,
      module: MicrosoftGraph.Files,
      function: :get_item_by_path,
      path_params: [{"drive_id", "Drive ID"}, {"path", "File path (e.g. Documents/report.docx)"}],
      schema: MicrosoftGraph.Schema.DriveItem
    },
    %Entry{
      id: :files_download_content,
      resource: "Files",
      label: "download_content",
      description: "Download the raw content of a file. Returns binary data.",
      method: :get,
      module: MicrosoftGraph.Files,
      function: :download_content,
      path_params: [{"drive_id", "Drive ID"}, {"item_id", "Item ID"}]
    },
    %Entry{
      id: :files_upload_small,
      resource: "Files",
      label: "upload_small",
      description: "Upload a small file (up to 4 MB). Body is sent as raw content.",
      method: :post,
      module: MicrosoftGraph.Files,
      function: :upload_small,
      path_params: [{"drive_id", "Drive ID"}, {"path", "Destination path (e.g. Documents/test.txt)"}],
      body?: true,
      body_template: "Hello, this is a test file uploaded via Graph Explorer."
    },
    %Entry{
      id: :files_create_upload_session,
      resource: "Files",
      label: "create_upload_session",
      description: "Create an upload session for large files (> 4 MB). Returns an uploadUrl for chunked upload.",
      method: :post,
      module: MicrosoftGraph.Files,
      function: :create_upload_session,
      path_params: [{"drive_id", "Drive ID"}, {"path", "Destination path (e.g. Documents/large.zip)"}],
      body?: true,
      body_template: """
      {
        "@microsoft.graph.conflictBehavior": "rename",
        "name": "large-file.zip"
      }\
      """
    }
  ]

  @doc "Returns all catalog entries."
  def all, do: @entries

  @doc "Finds an entry by its atom ID."
  def find(id) when is_atom(id) do
    Enum.find(@entries, &(&1.id == id))
  end

  @doc "Returns entries grouped by resource name."
  def grouped do
    @entries
    |> Enum.group_by(& &1.resource)
    |> Enum.sort_by(fn {resource, _} ->
      Enum.find_index(~w(Users Groups Mail Calendar Files Subscriptions Batch), &(&1 == resource)) || 99
    end)
  end
end
