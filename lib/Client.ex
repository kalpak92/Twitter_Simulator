defmodule Client do
  use GenServer

  @doc """
  generate multiple tweets
  """
  def generate_tweets_multiple(twitteratti_name, latency, count) do
    for _ <- 1..count do
      spawn(fn -> tweet_generator(twitteratti_name, latency) end)
    end
  end

  @doc """
  createMultipleRetweets
  """
  def multiple_retweet_create(twitteratti_name, count) do
    for _ <- 1..count do
      spawn(fn  -> retweet_create(twitteratti_name) end)
    end
  end

  @doc """
  generateTweets
  """
  def tweet_generator(twitteratti_name, latency) do

    # fetch the content of the tweet
    tweet_content = Runner.get_details_of_tweet(twitteratti_name)

    GenServer.cast(String.to_atom(twitteratti_name), {:tweet, tweet_content})

    Process.sleep(latency)

    tweet_generator(twitteratti_name, latency)
  end

  @doc """
  createRetweets
  """
  def retweet_create(twitteratti_name) do
    Process.sleep(5000)

    index = GenServer.call(String.to_atom(twitteratti_name), {:getRetweetIndex})

    if index != nil do
      GenServer.cast(String.to_atom(twitteratti_name), {:retweet, twitteratti_name, index})
    end

    retweet_create(twitteratti_name)
  end

  def start_link(twitteratti_name, ip_server) do
    GenServer.start_link(__MODULE__, [twitteratti_name, ip_server, MapSet.new, [], [], [], []], name: String.to_atom(twitteratti_name))
  end

  def init(init_arg) do
    {:ok, init_arg}
  end
  def init(twitteratti_name, ip_server, tweets_seen, list_of_hashtags, list_of_mentions, list_of_relevant_tweets, tweets_mentioned) do
    {:ok, {twitteratti_name, ip_server, tweets_seen, list_of_hashtags, list_of_mentions, list_of_relevant_tweets, tweets_mentioned}}
  end

  def handle_cast({:kill_client_self}, state) do
    {:stop, :normal, state}
  end

  def handle_cast({:receive_tweet, index, tweet, content_tweet}, state) do
    [twitteratti_name, ip_server, tweets_seen, list_of_hashtags, list_of_mentions, list_of_relevant_tweets, tweets_mentioned] = state

    tweets_seen = MapSet.put(tweets_seen, index)

    if is_tuple(content_tweet) do
      {twitteratti_org, content} =content_tweet
      Runner.logging(" #{twitteratti_name} sees #{tweet} which has been a Re-Tweeted post of #{twitteratti_org} : #{content}")
    else
      Runner.logging(" #{twitteratti_name} sees #{tweet} post a New Tweet: #{content_tweet}")
    end
    {:noreply, [twitteratti_name, ip_server, tweets_seen, list_of_hashtags, list_of_mentions, list_of_relevant_tweets, tweets_mentioned]}
  end

  def handle_cast({:fetch_mentions}, state) do
    [twitteratti_name, ip_server, tweets_seen, list_of_hashtags, list_of_mentions, list_of_relevant_tweets, tweets_mentioned] = state
    GenServer.cast({:server_main, String.to_atom("TwitterServer_Main@"<>ip_server)}, {:mentions_self, twitteratti_name})
    {:noreply, [twitteratti_name, ip_server, tweets_seen, list_of_hashtags, list_of_mentions, list_of_relevant_tweets, tweets_mentioned]}
  end

  def handle_cast({:user_registration, _twitteratti_name}, state) do
    [twitteratti_name, ip_server, tweets_seen, list_of_hashtags, list_of_mentions, list_of_relevant_tweets, tweets_mentioned] = state
    GenServer.cast({:server_main, String.to_atom("TwitterServer_Main@"<>ip_server)}, {:register_twitteratti_self, twitteratti_name, Node.self()})
    {:noreply, [twitteratti_name, ip_server, tweets_seen, list_of_hashtags, list_of_mentions, list_of_relevant_tweets, tweets_mentioned]}
  end

  def handle_cast({:retweet, self_id, tweet_index}, state) do
    [twitteratti_name, ip_server, tweets_seen, list_of_hashtags, list_of_mentions, list_of_relevant_tweets, tweets_mentioned] = state
    GenServer.cast({:server_main, String.to_atom("TwitterServer_Main@"<>ip_server)}, {:retweet, self_id, tweet_index})
    {:noreply, [twitteratti_name, ip_server, tweets_seen, list_of_hashtags, list_of_mentions, list_of_relevant_tweets, tweets_mentioned]}
  end

  def handle_cast({:follower_subscription, self_id, _twitteratti_name}, state) do
    [twitteratti_name, ip_server, tweets_seen, list_of_hashtags, list_of_mentions, list_of_relevant_tweets, tweets_mentioned] = state
    GenServer.cast({:server_main, String.to_atom("TwitterServer_Main@"<>ip_server)}, {:follower_subscription, self_id, twitteratti_name})
    {:noreply, [twitteratti_name, ip_server, tweets_seen, list_of_hashtags, list_of_mentions, list_of_relevant_tweets, tweets_mentioned]}
  end

  def handle_cast({:search_by_hashtag, hashtag}, state) do
    [twitteratti_name, ip_server, tweets_seen, list_of_hashtags, list_of_mentions, list_of_relevant_tweets, tweets_mentioned] = state
    GenServer.cast({:server_main, String.to_atom("TwitterServer_Main@"<>ip_server)}, {:tweets_with_hashtag, hashtag, twitteratti_name})
    {:noreply, [twitteratti_name, ip_server, tweets_seen, list_of_hashtags, list_of_mentions, list_of_relevant_tweets, tweets_mentioned]}
  end

  def handle_cast({:get_hashtag_results, _list_of_hashtags}, state) do
    [twitteratti_name, ip_server, tweets_seen, list_of_hashtags, list_of_mentions, list_of_relevant_tweets, tweets_mentioned] = state
    {:noreply, [twitteratti_name, ip_server, tweets_seen, list_of_hashtags, list_of_mentions, list_of_relevant_tweets, tweets_mentioned]}
  end

  def handle_cast({:query_tweets_self}, state) do
    [twitteratti_name, ip_server, tweets_seen, list_of_hashtags, list_of_mentions, list_of_relevant_tweets, tweets_mentioned] = state
    GenServer.cast({:server_main, String.to_atom("TwitterServer_Main@"<>ip_server)}, {:query_tweets, twitteratti_name})
    {:noreply, [twitteratti_name, ip_server, tweets_seen, list_of_hashtags, list_of_mentions, list_of_relevant_tweets, tweets_mentioned]}
  end

  def handle_cast({:receive_query_tweets_results, _list_of_relevant_tweets}, state) do
    [twitteratti_name, ip_server, tweets_seen, list_of_hashtags, list_of_mentions, list_of_relevant_tweets, tweets_mentioned] = state
    {:noreply, [twitteratti_name, ip_server, tweets_seen, list_of_hashtags, list_of_mentions, list_of_relevant_tweets, tweets_mentioned]}
  end

  def handle_cast({:tweet, content_tweet}, state) do
    [twitteratti_name, ip_server, tweets_seen, list_of_hashtags, list_of_mentions, list_of_relevant_tweets, tweets_mentioned] = state

    content = content_tweet
    words_separated = String.split(content, " ")
    hashtag_list = search_hashtags(words_separated, [])
    mention_list = search_mentions(words_separated, [])

    body_of_tweet = {content, hashtag_list, mention_list}

    GenServer.cast({:server_main, String.to_atom("TwitterServer_Main@"<>ip_server)}, {:tweet, twitteratti_name, body_of_tweet})

    {:noreply, [twitteratti_name, ip_server, tweets_seen, list_of_hashtags, list_of_mentions, list_of_relevant_tweets, tweets_mentioned]}
  end

  def handle_call({:getRetweetIndex}, _from, state) do
    [twitteratti_name, ip_server, tweets_seen, list_of_hashtags, list_of_mentions, list_of_relevant_tweets, tweets_mentioned] = state
    tweet_list = MapSet.to_list(tweets_seen)

    random_index = Enum.random(1..Enum.count(tweet_list))

    tweet_selected = Enum.at(tweet_list, random_index - 1)

    {:reply, tweet_selected, [twitteratti_name, ip_server, tweets_seen, list_of_hashtags, list_of_mentions, list_of_relevant_tweets, tweets_mentioned]}
  end

  def user_registration(twitteratti_name, ip_server) do
    GenServer.cast({:server_main, String.to_atom("TwitterServer_Main@"<>ip_server)}, {:register_twitteratti_self, twitteratti_name, Node.self()})
  end

  def follower_subscription(self_id, twitteratti_name, ip_server) do
    GenServer.cast({:server_main, String.to_atom("TwitterServer_Main@"<>ip_server)}, {:follower_subscription, self_id, twitteratti_name})
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

  # def handle_cast({:fetch_mentions_self, list_of_mentions}, state) do
  #   [twitteratti_name, ip_server, tweets_seen, list_of_hashtags, list_of_mentions, list_of_relevant_tweets, tweets_mentioned] = state
  #   {:noreply, [twitteratti_name, ip_server, tweets_seen, list_of_hashtags, list_of_mentions, list_of_relevant_tweets, tweets_mentioned]}
  # end

  def search_hashtags([first|last], hashtag_list) do
    if (String.first(first)=="#") do
      [_, _element] = String.split(first, "#")
      search_hashtags(last, List.insert_at(hashtag_list, 0, first))
    else
      search_hashtags(last, hashtag_list)
    end
  end

  def search_hashtags([], hashtag_list) do
    hashtag_list
  end

  def search_mentions([first|last], mention_list) do
    if(String.first(first)=="@") do
      [_, element] = String.split(first, "@")
      search_mentions(last, List.insert_at(mention_list, 0, element))
    else
      search_mentions(last, mention_list)
    end
  end

  def search_mentions([], mentions_list) do
    mentions_list
  end

  def unsubscribe(self_id, twitteratti_name) do
    GenServer.cast(:server_main, {:unsubscribe, self_id, twitteratti_name})
  end

end
