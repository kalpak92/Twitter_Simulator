defmodule Server do
  use GenServer

  @doc """
  Setup the Twitter Engine
  """
  def setup_server() do
    # start the node
    IO.inspect get_ip_address(0)

    Node.start(String.to_atom("TwitterServer_Main@"<>get_ip_address(0)))

    cookie = String.to_atom("Twitter")
    Node.set_cookie(cookie)
    start_link()

  end

  @doc """
  Start Link.
  Initialise the tables .

  # TODO : change the fields
  """
  def start_link() do
    :ets.new(:map_of_hashtag, [:set, :public, :named_table])
    :ets.new(:map_of_mentions, [:set, :public, :named_table])
    :ets.new(:table_of_followers, [:set, :public, :named_table])
    :ets.new(:table_of_follows, [:set, :public, :named_table])
    :ets.new(:tweet_database, [:set, :public, :named_table])
    :ets.new(:map_of_user_to_ip, [:set, :public, :named_table])

    GenServer.start_link(__MODULE__, :ok, name: :server_main)
  end

  def init(:ok) do
    {:ok, 0}
  end

  @doc """
  Register Me
  """
  def handle_cast({:register_twitteratti_self, twitteratti_name, ip_user}, state) do
    id_next = state
    status_of_registration = :ets.insert_new(:map_of_user_to_ip, {twitteratti_name, ip_user})

    if status_of_registration == false do
      spawn(fn ->
              GenServer.cast({String.to_atom(twitteratti_name), ip_user},
              {:query_tweets_self})
            end)
    end
    {:noreply,id_next}
  end

  @doc """
  subscribe to
  """
  def handle_cast({:follower_subscription, id_self, twitteratti_name}, state) do
    id_next = state

    map_set =
              if :ets.lookup(:table_of_followers, twitteratti_name) == [] do
                MapSet.new
              else
                [{_, set}] = :ets.lookup(:table_of_followers, twitteratti_name)
                set
              end

    map_set = MapSet.put(map_set, id_self)

    spawn(fn -> :ets.insert(:table_of_followers, {twitteratti_name, map_set}) end)

    map_set_2 =
              if :ets.lookup(:table_of_follows, id_self) == [] do
                MapSet.new
              else
                [{_, set}] = :ets.lookup(:table_of_follows, id_self)
                set
              end

    map_set_2 = MapSet.put(map_set_2, twitteratti_name)

    spawn(fn -> :ets.insert(:table_of_follows, {id_self, map_set_2}) end)

    {:noreply, id_next}
  end

  @doc """
  Tweet
  """

  def handle_cast({:tweet, twitteratti_name, body_tweet}, state) do
    id_next = state

    {tweet_content, tweet_hashtag, tweet_mention} = body_tweet

    Runner.logging("Tweet_id: #{id_next} => #{twitteratti_name} posted a new tweet : #{tweet_content}")

    spawn(fn -> :ets.insert(:tweet_database, {id_next, twitteratti_name, tweet_content}) end)

    spawn(fn -> update_map_of_mentions(tweet_mention, id_next) end)
    spawn(fn -> update_map_of_hashtags(tweet_hashtag, id_next) end)

    # broadcast
    spawn(fn ->
      broadcast_to_followers(MapSet.to_list(elem(List.first(:ets.lookup(:table_of_followers, twitteratti_name)), 1)), id_next, twitteratti_name, tweet_content)
    end)

    spawn(fn ->
      broadcast_to_followers(tweet_mention, id_next, twitteratti_name, tweet_content)
    end)

    {:noreply, id_next + 1}
  end

  @doc """
  updateMentionsMap
  """
  def update_map_of_mentions([tweet_mention | tweet_mentions], idx) do
    elements =
        if :ets.lookup(:map_of_mentions, tweet_mention) == [] do
          element = MapSet.new
          MapSet.put(element, idx)
        else
          [{_, element}] = :ets.lookup(:map_of_mentions, tweet_mention)
          MapSet.put(element, idx)
        end

        :ets.insert(:map_of_mentions, {tweet_mention, elements})
        update_map_of_mentions(tweet_mentions, idx)
  end

  def update_map_of_mentions([], _) do

  end

  @doc """
  updateHashtagMap
  """
  def update_map_of_hashtags([tweet_hashtag| tweet_hashtags], idx) do
    elements =
        if :ets.lookup(:map_of_hashtag, tweet_hashtag) == [] do
          element = MapSet.new
          MapSet.put(element, idx)
        else
          [{_, element}] = :ets.lookup(:map_of_hashtag, tweet_hashtag)
          MapSet.put(element, idx)
        end

        :ets.insert(:map_of_hashtag, {tweet_hashtag, elements})
        update_map_of_hashtags(tweet_hashtags, idx)
  end

  def update_map_of_hashtags([], _) do

  end

  @doc """
  Send to followers
  """
  def broadcast_to_followers([first | followers_list], idx, twitteratti_name, tweet_content) do
    spawn(fn  ->
      GenServer.cast({String.to_atom(first), elem(List.first(:ets.lookup(:map_of_user_to_ip, first)), 1)},
                      {:receive_tweet, idx, twitteratti_name, tweet_content})
          end)

    broadcast_to_followers(followers_list, idx, twitteratti_name, tweet_content)
  end

  def broadcast_to_followers([], _, _, _) do

  end


  @doc """
  retweet
  """
  def handle_cast({:retweet, twitteratti_name, tweet_idx}, state) do
    id_next = state

    [{_, twitteratti_name_original, tweet_content}] = :ets.lookup(:tweet_database, tweet_idx)

    Runner.logging("Tweet_id: #{id_next} => #{twitteratti_name} posted a retweet of tweet #{tweet_idx}")

    {original_twitteratti, final_content} =
                  if is_tuple(tweet_content) do
                    {original_tweet, original_content} = tweet_content
                    {original_tweet, original_content}
                  else
                    {twitteratti_name_original, tweet_content}
                  end

    :ets.insert_new(:tweet_database, {id_next, twitteratti_name, {original_twitteratti, final_content}})

    spawn(fn ->
      broadcast_to_followers(MapSet.to_list(elem(List.first(:ets.lookup(:table_of_followers, twitteratti_name)), 1)),
                              id_next, twitteratti_name, {twitteratti_name_original, tweet_content})
                            end)

    {:noreply, id_next + 1}
  end

  @doc """
  myMentions
  """
  def handle_cast({:mentions_self, twitteratti_name}, state) do
    mention_list =
        if :ets.lookup(:map_of_mentions, twitteratti_name) == [] do
          MapSet.new
        else
          [{_, set}] = :ets.lookup(:map_of_mentions, twitteratti_name)
          set
        end

        tweets_mention = get_mentions_tweet(MapSet.to_list(mention_list), [])

        spawn(fn -> GenServer.cast({String.to_atom(twitteratti_name),
                                  elem(List.first(:ets.lookup(:map_of_user_to_ip, twitteratti_name)), 1)},
                                  {:receive_mentions_self, tweets_mention}) end)
        {:noreply, state}
  end



  @doc """
  tweets with hashtag
  """
  def handle_cast({:tweets_with_hashtag, hashtag, twitteratti_name}, state) do
    tweet_set =
                if :ets.lookup(:map_of_hashtag, hashtag) == [] do
                  MapSet.new
                else
                  [{_, set}] = :ets.lookup(:map_of_hashtag, hashtag)
                  set
                end

    tweets_with_hashtag  = get_hashtag_tweets(MapSet.to_list(tweet_set), [])

    spawn(fn -> GenServer.cast({String.to_atom(twitteratti_name),
                elem(List.first(:ets.lookup(:map_of_user_to_ip, twitteratti_name)), 1)},
                {:get_hashtag_results, tweets_with_hashtag})
              end)

    {:noreply, state}
  end

  @doc """
  getHashtags
  """
  def get_hashtag_tweets([head|last], tweets_with_hashtag) do
    [{idx, twitteratti_name, tweet_content}] = :ets.lookup(:tweet_database, head)
    tweets_with_hashtags = List.insert_at(tweets_with_hashtag, 0, {head, {twitteratti_name, tweet_content}})
    get_hashtag_tweets(last, tweets_with_hashtag)
  end

  def get_hashtag_tweets([], tweets_with_hashtag) do
    tweets_with_hashtag
  end

  @doc """
  queryTweets
  """
  def handle_cast({:query_tweets, twitteratti_name}, state) do
    map_set =
              if :ets.lookup(:table_of_follows, twitteratti_name) == [] do
                MapSet.new
              else
                [{_, set}] = :ets.lookup(:table_of_follows, twitteratti_name)
                set
              end

    tweets_relevant = get_relevant_tweets(map_set)

    mention_list =
                if :ets.lookup(:map_of_mentions, twitteratti_name) == [] do
                  MapSet.new
                else
                  [{_, set}] = :ets.lookup(:map_of_mentions, twitteratti_name)
                  set
                end

    mention_tweet_list = get_mentions_tweet(MapSet.to_list(mention_list), [])
    spawn(fn -> GenServer.cast({String.to_atom(twitteratti_name), elem(List.first(:ets.lookup(:map_of_user_to_ip, twitteratti_name)), 1)},
              {:receive_query_tweets_results, tweets_relevant, mention_tweet_list})
              end)

    {:noreply, state}
  end

  @doc """
  fetch Relevant Tweets
  """
  def get_relevant_tweets(mapSet) do
    result =
            for f_user <- MapSet.to_list(mapSet) do
              tweet_list = List.flatten(:ets.match(:tweet_database, {:_, f_user, :"$1"}))
              Enum.map(tweet_list, fn t -> {f_user, t} end)
            end
    List.flatten(result)
  end


  @doc """
  getMentions
  """
  def get_mentions_tweet([head | last], tweets_with_mention) do
    [{head, twitteratti_name, tweet_content}] = :ets.lookup(:tweet_database, head)
    tweets_with_mention = List.insert_at(tweets_with_mention, 0, {head, {twitteratti_name, tweet_content}})
    get_mentions_tweet(last, tweets_with_mention)
  end

  def get_mentions_tweet(_, [], tweets_with_mention) do
    tweets_with_mention
  end

  @doc """
  find IP
  """
  def get_ip_address(iterator) do
    ip_list = Enum.at(:inet.getif() |> Tuple.to_list(), 1)

    if elem(Enum.at(ip_list, iterator), 0) == {127, 0, 0, 1} do
      get_ip_address(iterator + 1)
    else
      elem(Enum.at(ip_list, iterator), 0) |> Tuple.to_list() |> Enum.join(".")
    end
  end

end
