defmodule Rumbl.AuthTest do
  use Rumbl.ConnCase
  alias Rumbl.Auth

  setup %{conn: conn} do
    conn =
      conn
      |> bypass_through(Rumbl.Router, :browser)
      |> get("/")

      {:ok, %{conn: conn}}
  end

  test "authenticate_user halts when no current user exists", %{conn: conn} do
    # conn = Auth.authenticate_user(conn, [])
    conn =
      conn
      |> assign(:current_user, nil)
      |> Auth.authenticate_user([])

    assert conn.halted
  end

  test "authenticate_user continues when the current user exists", %{conn: conn} do
    conn =
      conn
      |> assign(:current_user, %Rumbl.User{})
      |> Auth.authenticate_user([])

    refute conn.halted
  end

  test "login puts the user in the session", %{conn: conn} do
    login_conn =
      conn
      |> Auth.login(%Rumbl.User{id: 123})
      |> send_resp(:ok, "")

    next_conn = get login_conn, "/"
    assert get_session(next_conn, "user_id") == 123
  end

  test "logout drops the session", %{conn: conn} do
    logout_conn =
      conn
      |> put_session(:user_id, 123)
      |> Auth.logout()
      |> send_resp(:ok, "")

    next_conn = get logout_conn, "/"
    refute get_session(next_conn, :user_id)
  end

  test "call places user from session into assigns", %{conn: conn} do
    user = insert_user()
    next_conn =
      conn
      |> put_session(:user_id, user.id)
      |> Auth.call(Rumbl.Repo)

    assert next_conn.assigns.current_user.id == user.id
  end
end
