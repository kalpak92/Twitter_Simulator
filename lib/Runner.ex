defmodule Runner do
  def main(args) do
    try do
      [ip_address, number_of_users] = args

      total_users = String.to_integer(number_of_users)

      # Generate Content
      generate_content(total_users, ip_address)

      # Initiate the Clients
      client_initiate(ip_address)
      Process.sleep(5000)

      # Start the Driver
      run_simulate(ip_address)    # simulate
      Process.sleep(15000)

      spawn(fn -> fetch_mentions() end)
      Process.sleep(4800)

      spawn(fn -> hashtag_lookup() end)
      Process.sleep(4000)

      spawn(fn -> clients_kill(ip_address) end)

    rescue
      MatchError -> Server.setup_server()
    end

    :timer.sleep(:infinity)
  end


  @doc """
  Log
  """
  def logging(string) do
    IO.puts(string)
  end

  @doc """
  setupStaticData
  """
  def generate_content(total_users, ip_address) do
    name_client = String.to_atom("clientname" <> "@" <> get_ip_address(0))

    Node.start(name_client)
    Node.set_cookie(String.to_atom("Twitter"))

    :ets.new(:fields_static, [:named_table])
    :ets.insert(:fields_static, {"total_number_of_nodes", total_users})

    # TODO : Static Content Table
    :ets.insert(
      :fields_static,
      {"tweet_sample",[
        "i love my new Macbook",
        "My Purdue Cal friends are awesome",
        "i liked MIT though esp their little info book",
        "Desperate times, Desperate measures",
        "Catch me if u can",
        "Now you See Me",
        "Ocean 13",
        "I think Angelina Jolie is so much more beautiful than Jennifer Anniston who by the way is majorly OVERRATED",
        "Call me by your name",
        "Who let the Dog's out ... ",
        "Ideas are Bulletproof",
        "Hello Friends, Chai pee lo",
        "Mithun Daaaaaaaaaaaa, Baapi Daaaaaa",
        "Mota Bhaaaai",
        "Toh Kaar naaa",
        "This is Anton. Son of Anton. ",
        "Son of Sardar",
        "The name's Bond. James Bond."
      ]}
      )

    :ets.insert(
      :fields_static,
      {"hashtags",[
        "#sample ",
        "#hiphop ",
        "#rap ",
        "#beats ",
        "#producer ",
        "#music ",
        "#samp ",
        "#sampling ",
        "#iphone ",
        "#beatmaker ",
        "#beat ",
        "#instrumental ",
        "#trap ",
        "#freestuff ",
        "#rnb ",
        "#flstudio ",
        "#samsunggalaxys ",
        "#love ",
        "#beatmaking ",
        "#contactinfo ",
        "#whatsapp ",
        "#cellphonewholesale ",
        "#free ",
        "#samples ",
        "#wholesale ",
        "#boombap ",
        "#drums ",
        "#happy ",
        "#sampi ",
        "#bhfyp "
        ]}
    )

    Node.connect(String.to_atom("TwitterServer_Main@" <> ip_address))
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

  @doc """
  start_client
  """
  def client_initiate(ip_address) do
    [{_, num_of_clients}] = :ets.lookup(:fields_static, "total_number_of_nodes")

    for client <- 1..num_of_clients do
      Client.start_link("twitteratti" <> Integer.to_string(client), ip_address)
      Client.user_registration("twitteratti" <> Integer.to_string(client), ip_address)
    end
  end

  @doc """
  Get Mentions of Clients

  getMyMentions
  """
  def fetch_mentions() do
    [{_, num_of_clients}] = :ets.lookup(:fields_static, "total_number_of_nodes")
    IO.inspect("check mentions - self")

    # kill 5 random ids and save them to a list
    client_id = for i <- 1..5 do
      client = Enum.random(1..num_of_clients)
    end

    for i <- client_id do
      spawn(fn -> GenServer.cast(String.to_atom("twitteratti" <> Integer.to_string(i)), {:fetch_mentions}) end)
    end
  end

  @doc """
  Search on the basis of hashtags
  searchByHashtag
  """
  def hashtag_lookup() do
    [{_, hashtags}] = :ets.lookup(:fields_static, "hashtags")
    IO.inspect("search on the basis of hashtags.")

    for i <- 1..5  do
      hashtag = Enum.random(hashtags)
      IO.inspect(hashtag)

      spawn(fn -> GenServer.cast(String.to_atom("twitteratti" <> Integer.to_string(i)), {:search_by_hashtag, String.trim(hashtag)})end)
    end
  end

  @doc """
  killClients
  """

  def clients_kill(ip_address) do
    [{_, num_of_clients}] = :ets.lookup(:fields_static, "total_number_of_nodes")

    client_id_list =
      for i <- 1..5  do
        client  = Enum.random(1..num_of_clients)
      end

    IO.inspect(client_id_list)

    for j <- client_id_list do
      spawn(fn -> GenServer.cast(String.to_atom("twitteratti" <> Integer.to_string(j)), {:kill_client_self}) end)
    end

    # sleep
    Process.sleep(8000)

    # start the GenServer again
    IO.inspect("STARTING AGAIN")

    for j <- client_id_list do
      spawn(fn ->
        Client.start_link("twitteratti" <> Integer.to_string(j), ip_address)
      end)

      spawn(fn ->
        Client.user_registration("twitteratti" <> Integer.to_string(j), ip_address)
      end)
    end

    IO.inspect("Are we reaching here.")
  end

  @doc """
  Method : simulate
  """
  def run_simulate(ip_address) do
    [{_, num_of_clients}] = :ets.lookup(:fields_static, "total_number_of_nodes")

    fanfollowers_assignment(num_of_clients, ip_address)
    Process.sleep(5000)

    latency  = compute_frequency(num_of_clients)

    thread_count =
      if 100_000 / num_of_clients > 1 do
        round(100_000 / num_of_clients)
      else
        1
      end

    frequency_list =
      for client <- 1..num_of_clients do
        spawn(fn ->
          Client.generate_tweets_multiple(
            "twitteratti" <> Integer.to_string(client), latency * client, thread_count
          )
        end)

        spawn(fn -> Client.multiple_retweet_create("twitteratti" <> Integer.to_string(client), thread_count)
              end)

        {"twitteratti" <> Integer.to_string(client), thread_count * 1000 / (latency * client)}
      end

      IO.inspect(frequency_list)

  end

  @doc """
  getSum
  """
  def compute_addition([], value) do
    value
  end

  def compute_addition([first | last], addition) do
    addition = addition + first
    compute_addition(last, addition)
  end

  @doc """
  calculateFrequency
  """
  def compute_frequency(num_of_clients) do
    2890
  end

  def fanfollowers_assignment(num_of_clients, ip_address) do
    h_list =
      for j <- 1..num_of_clients do
        round(1 / j)
      end

    constant  = 100 / compute_addition(h_list, 0)

    for t <- 1..num_of_clients, i <- 1..round(Float.floor(constant / t))  do
      fan_followers = "twitteratti" <> Integer.to_string(Enum.random(1..num_of_clients))
      being_followed = "twitteratti" <> Integer.to_string(t)

      spawn(fn -> Client.follower_subscription(fan_followers, being_followed, ip_address) end)
    end

    count_number_of_followers =
      for t <- 1..num_of_clients  do
        {"twitteratti" <> Integer.to_string(t), round(Float.floor(constant / t))}
      end

    IO.inspect(count_number_of_followers)
  end

  @doc """
  Get the content of the tweet based on the username
  """
  def get_details_of_tweet(user_name) do
    [{_, tweet_sample}] = :ets.lookup(:fields_static, "tweet_sample")

    select_random_index = Enum.random(1..Enum.count(tweet_sample))

    picked_tweet = Enum.at(tweet_sample, select_random_index - 1)

    [{_, hashtags}] = :ets.lookup(:fields_static, "hashtags")

    number_tags = Enum.random(0..5)

    hashtags_list =
      if number_tags > 0 do
        for i <- Enum.to_list(1..number_tags) do
          Enum.at(hashtags, i - 1)
        end
      else
        []
      end

    [{_, number_of_clients}] = :ets.lookup(:fields_static, "total_number_of_nodes")
    number_of_mentions = Enum.random(0..5)

    mention_list =
      if number_of_mentions > 0 do
        for i <- Enum.to_list(1..number_of_mentions) do
          "@twitteratti" <> Integer.to_string(Enum.random(1..number_of_clients)) <> " "
        end
      else
        []
      end

    picked_tweet <> compress(hashtags_list, "") <> compress(mention_list, "")
  end


  @doc """
  condense
  """
  def compress([first | last], sentence) do
    sentence = sentence <> first
    compress(last, sentence)
  end

  def compress([], sentence) do
    sentence
  end

end


