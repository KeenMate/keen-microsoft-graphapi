defmodule GraphApi.CalendarTest do
  use ExUnit.Case, async: true

  alias GraphApi.Calendar
  alias GraphApi.Test.Fixtures

  setup do
    stub_name = :"calendar_test_#{System.unique_integer([:positive])}"

    Req.Test.stub(stub_name, fn conn ->
      case {conn.method, conn.request_path} do
        {"GET", "/users/user-1/events"} ->
          Req.Test.json(conn, Fixtures.load("calendar/list_events.json"))

        {"GET", "/users/user-1/events/event-1"} ->
          Req.Test.json(conn, %{
            "id" => "event-1",
            "subject" => "Team Meeting"
          })

        {"POST", "/users/user-1/events"} ->
          conn
          |> Plug.Conn.put_status(201)
          |> Req.Test.json(%{"id" => "new-event-id", "subject" => "New Event"})

        {"PATCH", "/users/user-1/events/event-1"} ->
          Req.Test.json(conn, %{"id" => "event-1", "subject" => "Updated"})

        {"DELETE", "/users/user-1/events/event-1"} ->
          Plug.Conn.send_resp(conn, 204, "")

        {"GET", "/users/user-1/calendarView"} ->
          Req.Test.json(conn, Fixtures.load("calendar/list_events.json"))

        {"GET", "/users/user-1/calendars"} ->
          Req.Test.json(conn, Fixtures.load("calendar/calendars.json"))

        _ ->
          Plug.Conn.send_resp(conn, 404, "")
      end
    end)

    client = Req.new(plug: {Req.Test, stub_name})
    %{client: client}
  end

  describe "list_events/2" do
    test "returns events", %{client: client} do
      assert {:ok, %{"value" => events}} = Calendar.list_events("user-1", client: client)
      assert length(events) == 1
      assert hd(events)["subject"] == "Team Meeting"
    end
  end

  describe "get_event/3" do
    test "returns an event", %{client: client} do
      assert {:ok, event} = Calendar.get_event("user-1", "event-1", client: client)
      assert event["subject"] == "Team Meeting"
    end
  end

  describe "create_event/3" do
    test "creates an event", %{client: client} do
      attrs = %{"subject" => "New Event"}
      assert {:ok, event} = Calendar.create_event("user-1", attrs, client: client)
      assert event["id"] == "new-event-id"
    end
  end

  describe "update_event/4" do
    test "updates an event", %{client: client} do
      assert {:ok, event} =
               Calendar.update_event("user-1", "event-1", %{"subject" => "Updated"},
                 client: client
               )

      assert event["subject"] == "Updated"
    end
  end

  describe "delete_event/3" do
    test "deletes an event", %{client: client} do
      assert :ok = Calendar.delete_event("user-1", "event-1", client: client)
    end
  end

  describe "calendar_view/2" do
    test "returns calendar view events", %{client: client} do
      assert {:ok, %{"value" => events}} =
               Calendar.calendar_view("user-1",
                 start_date_time: "2024-01-01T00:00:00",
                 end_date_time: "2024-01-31T23:59:59",
                 client: client
               )

      assert length(events) == 1
    end
  end

  describe "list_calendars/2" do
    test "returns calendars", %{client: client} do
      assert {:ok, %{"value" => calendars}} = Calendar.list_calendars("user-1", client: client)
      assert length(calendars) == 1
      assert hd(calendars)["name"] == "Calendar"
    end
  end
end
