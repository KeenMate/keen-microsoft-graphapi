defmodule GraphApi.PaginationTest do
  use ExUnit.Case, async: true

  alias GraphApi.Pagination
  alias GraphApi.Test.Fixtures

  describe "extract_page/1" do
    test "extracts items and next_link from paginated response" do
      page = Fixtures.load("users/list_paginated.json")
      {items, next_link} = Pagination.extract_page(page)

      assert length(items) == 2
      assert next_link == "https://graph.microsoft.com/v1.0/users?$skiptoken=abc123"
    end

    test "extracts items with nil next_link from final page" do
      page = Fixtures.load("users/list.json")
      {items, next_link} = Pagination.extract_page(page)

      assert length(items) == 2
      assert next_link == nil
    end

    test "wraps single object in list with nil next_link" do
      page = Fixtures.load("users/get.json")
      {items, next_link} = Pagination.extract_page(page)

      assert length(items) == 1
      assert hd(items)["displayName"] == "Alice Smith"
      assert next_link == nil
    end
  end

  describe "stream/2" do
    test "streams items from a single page (no next_link)" do
      page = Fixtures.load("users/list.json")

      # For a single page with no nextLink, we don't need a client
      # but the API requires it, so we pass a dummy
      client = Req.new(url: "http://localhost")

      items = Pagination.stream(page, client: client) |> Enum.to_list()
      assert length(items) == 2
      assert hd(items)["displayName"] == "Alice Smith"
    end
  end

  describe "collect_all/2" do
    test "collects all items from a single page" do
      page = Fixtures.load("users/list.json")
      client = Req.new(url: "http://localhost")

      {:ok, items} = Pagination.collect_all(page, client: client)
      assert length(items) == 2
    end
  end
end
