defmodule Demo.Views.UserSummary do
  @moduledoc """
  A view that projects a subset of User fields.

  When passed as the `:as` option to resource calls, the library
  automatically injects the matching `$select` parameter and casts
  the response into this struct.

  ## Example

      {:ok, %{"value" => users}} = MicrosoftGraph.Users.list(as: Demo.Views.UserSummary)
      # users is a list of %Demo.Views.UserSummary{} structs

  """
  use MicrosoftGraph.View,
    schema: MicrosoftGraph.Schema.User,
    fields: [:id, :display_name, :mail, :job_title, :user_principal_name]
end
