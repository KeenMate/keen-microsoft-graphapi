defmodule GraphApi.ODataTest do
  use ExUnit.Case, async: true

  alias GraphApi.OData

  describe "new/0" do
    test "creates an empty query" do
      query = OData.new()
      assert %OData{} = query
      assert query.select == nil
      assert query.filter == nil
      assert query.expand == nil
      assert query.top == nil
      assert query.skip == nil
      assert query.orderby == nil
      assert query.count == nil
      assert query.search == nil
    end
  end

  describe "select/2" do
    test "sets select fields" do
      query = OData.new() |> OData.select(["displayName", "mail"])
      assert query.select == ["displayName", "mail"]
    end
  end

  describe "filter/2" do
    test "sets filter expression" do
      query = OData.new() |> OData.filter("department eq 'Engineering'")
      assert query.filter == "department eq 'Engineering'"
    end
  end

  describe "expand/2" do
    test "sets expand fields" do
      query = OData.new() |> OData.expand(["manager", "directReports"])
      assert query.expand == ["manager", "directReports"]
    end
  end

  describe "top/2" do
    test "sets top value" do
      query = OData.new() |> OData.top(25)
      assert query.top == 25
    end
  end

  describe "skip/2" do
    test "sets skip value" do
      query = OData.new() |> OData.skip(50)
      assert query.skip == 50
    end

    test "allows zero" do
      query = OData.new() |> OData.skip(0)
      assert query.skip == 0
    end
  end

  describe "orderby/2" do
    test "sets orderby expression" do
      query = OData.new() |> OData.orderby("displayName desc")
      assert query.orderby == "displayName desc"
    end
  end

  describe "count/1" do
    test "sets count to true" do
      query = OData.new() |> OData.count()
      assert query.count == true
    end
  end

  describe "search/2" do
    test "sets search expression" do
      query = OData.new() |> OData.search("\"displayName:John\"")
      assert query.search == "\"displayName:John\""
    end
  end

  describe "to_params/1" do
    test "returns empty map for empty query" do
      params = OData.new() |> OData.to_params()
      assert params == %{}
    end

    test "converts select to comma-separated string" do
      params = OData.new() |> OData.select(["id", "displayName"]) |> OData.to_params()
      assert params["$select"] == "id,displayName"
    end

    test "includes filter as-is" do
      params = OData.new() |> OData.filter("department eq 'Eng'") |> OData.to_params()
      assert params["$filter"] == "department eq 'Eng'"
    end

    test "converts expand to comma-separated string" do
      params = OData.new() |> OData.expand(["manager"]) |> OData.to_params()
      assert params["$expand"] == "manager"
    end

    test "converts top to string" do
      params = OData.new() |> OData.top(10) |> OData.to_params()
      assert params["$top"] == "10"
    end

    test "converts skip to string" do
      params = OData.new() |> OData.skip(20) |> OData.to_params()
      assert params["$skip"] == "20"
    end

    test "includes orderby" do
      params = OData.new() |> OData.orderby("displayName") |> OData.to_params()
      assert params["$orderby"] == "displayName"
    end

    test "converts count to string" do
      params = OData.new() |> OData.count() |> OData.to_params()
      assert params["$count"] == "true"
    end

    test "includes search" do
      params = OData.new() |> OData.search("test") |> OData.to_params()
      assert params["$search"] == "test"
    end

    test "only includes set parameters" do
      params =
        OData.new()
        |> OData.select(["id"])
        |> OData.top(5)
        |> OData.to_params()

      assert Map.keys(params) |> Enum.sort() == ["$select", "$top"]
    end

    test "chaining works correctly" do
      params =
        OData.new()
        |> OData.select(["displayName", "mail", "id"])
        |> OData.filter("department eq 'Engineering'")
        |> OData.top(25)
        |> OData.orderby("displayName")
        |> OData.to_params()

      assert params["$select"] == "displayName,mail,id"
      assert params["$filter"] == "department eq 'Engineering'"
      assert params["$top"] == "25"
      assert params["$orderby"] == "displayName"
      assert map_size(params) == 4
    end
  end
end
