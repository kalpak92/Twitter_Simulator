# Project4

**Twitter Clone Part 1**

## Group Members
Sagnik Ghosh  UFID 3343-6044 <br />
Kalpak Seal  UFID 8241-7219

## HOW TO RUN
unzip the project <br />
in the directory run epmd -d <br />

for starting the Server <br />
/project4 <br />

for starting the Simulator (clients) <br />
/project4 serverIP numClients <br />

for running the tests <br />
In the project directory enter command 'mix test' <br />

Tweets received at the server will be logged on the console on the engine window along with the tweet ID. <br />
Tweets received by the users will be logged on the console on the simulator window.

## What is working
Twitter Engine : <br />
    Register account and delete account <br />
    Subscribe to other users according to Zipf distribution <br />
    Tweet endlessly <br />
    Retweet the tweets received randomly <br />
    Query Tweets <br />
    Query Tweets by mentions <br />
    Query Tweets by Hashtag <br />
    Receive Live tweets

Simulator : <br />
    Subscribing users according to Zipf Distribution <br />
    Setting the frequency of tweets according to Zipf (more popular tweets more frequently) <br />
    Retweet randomly any of the received tweet. This may include a tweet from someone the user follows, a tweet where the user is mentioned or a tweet queried from a hashtag. <br />
    Period of Live connection and disconnection


