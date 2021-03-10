defmodule Dataloader.Ecto.HasManyWhereTest do
  use ExUnit.Case, async: true

  alias Dataloader.{User, Post, Like}
  import Ecto.Query
  alias Dataloader.TestRepo, as: Repo

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)

    test_pid = self()

    source =
      Dataloader.Ecto.new(
        Repo,
        query: &query(&1, &2, test_pid)
      )

    loader =
      Dataloader.new()
      |> Dataloader.add_source(Test, source)

    {:ok, loader: loader}
  end

  defp query(schema, %{limit: limit}, test_pid) do
    send(test_pid, :querying)

    schema
    |> limit(^limit)
  end

  describe "where in has-many associations" do
    test "simple filtered has_many", %{loader: loader} do
      user1 = %User{username: "Ben Wilson"} |> Repo.insert!()

      post1 = %Post{user_id: user1.id, title: "foo", status: "published"} |> Repo.insert!()
      _post2 = %Post{user_id: user1.id, title: "bar", status: "unpublished"} |> Repo.insert!()

      args = {:published_posts, %{limit: 10}}

      loader =
        loader
        |> Dataloader.load(Test, args, user1)
        |> Dataloader.run()

      assert [post1] == Dataloader.get(loader, Test, args, user1)
    end

    test "simple filtered has_many in has_many through in first position", %{loader: loader} do
      user1 = %User{username: "Ben Wilson"} |> Repo.insert!()

      post1 = %Post{user_id: user1.id, title: "foo", status: "published"} |> Repo.insert!()
      post2 = %Post{user_id: user1.id, title: "bar", status: "unpublished"} |> Repo.insert!()

      like1 = %Like{user_id: user1.id, post_id: post1.id} |> Repo.insert!()
      _like2 = %Like{user_id: user1.id, post_id: post2.id} |> Repo.insert!()

      args = {:published_posts_likes, %{limit: 10}}

      loader =
        loader
        |> Dataloader.load(Test, args, user1)
        |> Dataloader.run()

      assert [like1] == Dataloader.get(loader, Test, args, user1)
    end
  end
end
