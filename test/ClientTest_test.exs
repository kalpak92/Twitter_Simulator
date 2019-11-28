defmodule ClientTest do
  use ExUnit.Case, async: true

  test "Hashtag parsing pass" do
    hashTags = [
      "#love",
      "#iphone",
      "#beatmaker",
      "#trap",
    ]
    teststring = "I am on a rock and roll. #iphone #beatmaker #trap #love @user1 @user2"
    teststringwords = String.split(teststring," ")
    hashtag_list = Client.search_hashtags(teststringwords,[])
    parsedhashtags = Client.search_hashtags(hashTags,[])
    assert(Enum.reduce(hashtag_list, true, fn hashtag,
    acc -> acc && Enum.find(parsedhashtags, false, fn u -> u == hashtag end)
    end))
  end

  test "Hashtag parsing fail" do
    hashTags = [
      "#love",
      "#beatmaker",
      "#trap",
    ]
    teststring = "I am on a rock and roll. #iphone #beatmaker #trap #love @user1 @user2"
    teststringwords = String.split(teststring," ")
    hashtag_list = Client.search_hashtags(teststringwords,[])
    parsedhashtags = Client.search_hashtags(hashTags,[])
    assert(!Enum.reduce(hashtag_list, true, fn hashtag,
    acc -> acc && Enum.find(parsedhashtags, false, fn u -> u == hashtag end)
    end))
  end

  test "Mention parsing pass" do
    mentions = [
      "@user1",
      "@user2",
      "@user3"
    ]
    teststring = "I am on a rock and roll. #iphone #beatmaker #trap #love @user1 @user2"
    teststringwords = String.split(teststring," ")
    mention_list = Client.search_mentions(teststringwords,[])
    parsedmentions = Client.search_mentions(mentions,[])
    assert(Enum.reduce(mention_list, true, fn mention,
    acc -> acc && Enum.find(parsedmentions, false, fn u -> u == mention end)
    end))
  end

  test "Mention parsing fail" do
    mentions = [
      "@user1",
    ]
    teststring = "I am on a rock and roll. #iphone #beatmaker #trap #love @user1 @user2"
    teststringwords = String.split(teststring," ")
    mention_list = Client.search_mentions(teststringwords,[])
    parsedmentions = Client.search_mentions(mentions,[])
    assert(!Enum.reduce(mention_list, true, fn mention,
    acc -> acc && Enum.find(parsedmentions, false, fn u -> u == mention end)
    end))
  end
end
