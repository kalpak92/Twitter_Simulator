defmodule ServerTest do
  use ExUnit.Case, async: true

  setup_all do
    Server.initializetables()
    :ok
  end

  test "Get tweet with hashtag" do
   tweetId = 100
   tweet_content = "what's up whatttsss uppp whattttttssssss uuuuuuuuppppppp"
   tweet_hashtag = ["#sampletweet", "#help"]
   tweet_mention = ["@kan"]
   twitteratti = "user5"
   Server.inserttweetintodatabase(tweetId, twitteratti, {tweet_content, tweet_hashtag, tweet_mention})
   {tweetID,{twitteratti,tweet_contentfetch}} = Enum.at(Server.findtweetwithhashtag("#help"),0);
   assert(tweet_content == tweet_contentfetch)
  end

  test "Mention Query" do
    tweetId = 1
    tweet_content = "The name's Bond. James Bond."
    tweet_hashtag = ["#beatmaker", "#beat"]
    tweet_mention = ["@user1"]
    twitteratti = "user2"
    Server.inserttweetintodatabase(tweetId, twitteratti, {tweet_content, tweet_hashtag, tweet_mention})
    {tweetID,{twitteratti,tweet_contentfetch}} = Enum.at(Server.findtweetwithmention("@user1"),0);
    assert(tweet_content == tweet_contentfetch)
  end

  test "Test subscribe" do
    user = "Kalpak"
    followuser = "Amit"
    Server.addFollower(user,followuser)
    assert(Enum.find(Server.getfollowlist(followuser), false, fn u -> u == user end))
  end

  test "Test subscriber" do
    user = "Sagnik"
    followuser = "Kalpak"
    Server.addFollower(user, followuser)
    followuser = "Amit"
    Server.addFollower(user,followuser)
    assert(Enum.find(Server.getfollowerlist(user), false, fn u -> u == followuser end))
  end

end
