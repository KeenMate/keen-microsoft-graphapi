defmodule MicrosoftGraph.OData.FilterTest do
  use ExUnit.Case, async: true

  alias MicrosoftGraph.OData
  alias MicrosoftGraph.OData.Filter
  alias MicrosoftGraph.Schema.User

  describe "OData.filter/3 keyword syntax" do
    test "single string equality" do
      query = OData.new() |> OData.filter(User, company_name: "Contoso")
      assert query.filter == "companyName eq 'Contoso'"
    end

    test "single boolean equality" do
      query = OData.new() |> OData.filter(User, account_enabled: true)
      assert query.filter == "accountEnabled eq true"
    end

    test "multiple conditions are AND-ed" do
      query =
        OData.new()
        |> OData.filter(User,
          company_name: "Contoso",
          account_enabled: true,
          employee_type: "Employee"
        )

      assert query.filter ==
               "companyName eq 'Contoso' and accountEnabled eq true and employeeType eq 'Employee'"
    end

    test "integer values" do
      query = OData.new() |> OData.filter(User, age: 30)
      assert query.filter == "age eq 30"
    end

    test "nil values" do
      query = OData.new() |> OData.filter(User, mail: nil)
      assert query.filter == "mail eq null"
    end

    test "raises on unknown field" do
      assert_raise ArgumentError, ~r/unknown field :nonexistent/, fn ->
        OData.new() |> OData.filter(User, nonexistent: "value")
      end
    end

    test "escapes single quotes in strings" do
      query = OData.new() |> OData.filter(User, display_name: "O'Brien")
      assert query.filter == "displayName eq 'O''Brien'"
    end
  end

  describe "OData.filter/2 with Filter struct" do
    test "accepts a Filter builder" do
      filter =
        Filter.new(User)
        |> Filter.where(:display_name, :starts_with, "A")

      query = OData.new() |> OData.filter(filter)
      assert query.filter == "startsWith(displayName,'A')"
    end
  end

  describe "Filter builder" do
    test "single eq condition" do
      result =
        Filter.new(User)
        |> Filter.where(:company_name, :eq, "Contoso")
        |> Filter.to_string()

      assert result == "companyName eq 'Contoso'"
    end

    test "multiple AND conditions" do
      result =
        Filter.new(User)
        |> Filter.where(:company_name, :eq, "Contoso")
        |> Filter.where(:account_enabled, :eq, true)
        |> Filter.to_string()

      assert result == "companyName eq 'Contoso' and accountEnabled eq true"
    end

    test "OR conditions" do
      result =
        Filter.new(User)
        |> Filter.where(:company_name, :eq, "Contoso")
        |> Filter.or_where(:company_name, :eq, "Fabrikam")
        |> Filter.to_string()

      assert result == "companyName eq 'Contoso' or companyName eq 'Fabrikam'"
    end

    test "mixed AND and OR" do
      result =
        Filter.new(User)
        |> Filter.where(:account_enabled, :eq, true)
        |> Filter.where(:company_name, :eq, "Contoso")
        |> Filter.or_where(:company_name, :eq, "Fabrikam")
        |> Filter.to_string()

      assert result == "accountEnabled eq true and companyName eq 'Contoso' or companyName eq 'Fabrikam'"
    end

    test "ne operator" do
      result =
        Filter.new(User)
        |> Filter.where(:job_title, :ne, "Intern")
        |> Filter.to_string()

      assert result == "jobTitle ne 'Intern'"
    end

    test "comparison operators" do
      result =
        Filter.new(User)
        |> Filter.where(:age, :gt, 18)
        |> Filter.where(:age, :le, 65)
        |> Filter.to_string()

      assert result == "age gt 18 and age le 65"
    end

    test "startsWith function" do
      result =
        Filter.new(User)
        |> Filter.where(:display_name, :starts_with, "A")
        |> Filter.to_string()

      assert result == "startsWith(displayName,'A')"
    end

    test "endsWith function" do
      result =
        Filter.new(User)
        |> Filter.where(:mail, :ends_with, "@contoso.com")
        |> Filter.to_string()

      assert result == "endsWith(mail,'@contoso.com')"
    end

    test "contains function" do
      result =
        Filter.new(User)
        |> Filter.where(:display_name, :contains, "john")
        |> Filter.to_string()

      assert result == "contains(displayName,'john')"
    end

    test "in operator" do
      result =
        Filter.new(User)
        |> Filter.where(:employee_type, :in, ["Employee", "Contractor", "Guest"])
        |> Filter.to_string()

      assert result == "employeeType in ('Employee','Contractor','Guest')"
    end

    test "is_nil true (eq null)" do
      result =
        Filter.new(User)
        |> Filter.where(:mail, :is_nil, true)
        |> Filter.to_string()

      assert result == "mail eq null"
    end

    test "is_nil false (ne null)" do
      result =
        Filter.new(User)
        |> Filter.where(:mail, :is_nil, false)
        |> Filter.to_string()

      assert result == "mail ne null"
    end

    test "float values" do
      result =
        Filter.new(User)
        |> Filter.where(:height, :gt, 1.75)
        |> Filter.to_string()

      assert result == "height gt 1.75"
    end

    test "raises on unknown field" do
      assert_raise ArgumentError, ~r/unknown field :nonexistent/, fn ->
        Filter.new(User)
        |> Filter.where(:nonexistent, :eq, "value")
        |> Filter.to_string()
      end
    end
  end

  describe "integration with OData.to_params/1" do
    test "filter is included in params" do
      params =
        OData.new()
        |> OData.filter(User, company_name: "Contoso", account_enabled: true)
        |> OData.select(["id", "displayName"])
        |> OData.top(10)
        |> OData.to_params()

      assert params["$filter"] == "companyName eq 'Contoso' and accountEnabled eq true"
      assert params["$select"] == "id,displayName"
      assert params["$top"] == "10"
    end
  end
end
