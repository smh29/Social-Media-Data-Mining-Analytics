'''
Retrieve the most recent Tweets of certain user handles from Twitter using its
API calls.
'''

import sys
import gzip
import time
import tweepy
from datetime import datetime, timedelta

# The consumer and access keys & secrets for the Twitter application
# See https://developer.twitter.com/en/docs/basics/authentication/overview/oauth
# on how to access these credentials
CONSUMER_KEY = '<copy consumer key here from the Twitter dev site>'
CONSUMER_SECRET = '<copy consumer secret here from the Twitter dev site>'
ACCESS_KEY = '<copy access key here from the Twitter dev site>'
ACCESS_SECRET = '<copy access secret here from the Twitter dev site>'

# The maximum number of Tweets we can ask for in one request
# See https://developer.twitter.com/en/docs/tweets/timelines/api-reference/get-statuses-user_timeline.html
MAX_ITEMS_PER_REQUEST = 200

# The file where we store a list of valid Twitter user IDs
USER_LIST = 'data/twitter/user_handles_sample.gz'
# The result file
OUTPUT_FILE = 'data/twitter/tweets_per_user.tsv'

auth = tweepy.OAuthHandler(CONSUMER_KEY, CONSUMER_SECRET)
auth.set_access_token(ACCESS_KEY, ACCESS_SECRET)
api = tweepy.API(auth)

# The start date and time of our data collection; 28 days before now
start_day = datetime.utcnow() - timedelta(days=28)

user_list_file = gzip.open(USER_LIST, 'r')
output_file = open(OUTPUT_FILE, 'w')
for user_id in user_list_file:
    user_id = user_id.rstrip()
    # The ID of the earliest Tweet in the result batch
    earliest_tweet_id = None
    while True:
        try:
            if earliest_tweet_id is None:
                # The first request for the user
                timeline = api.user_timeline(id=user_id, include_rts=True,
                                             count=MAX_ITEMS_PER_REQUEST)
            else:
                # There are possibly more recent Tweets than MAX_ITEMS_PER_REQUEST
                timeline = api.user_timeline(id=user_id, include_rts=True,
                                             count=MAX_ITEMS_PER_REQUEST,
                                             max_id=earliest_tweet_id)
        except Exception as e:
            if e.response.status == 429:
                # If we are rate limited, wait 60 seconds before retrying
                # See https://developer.twitter.com/en/docs/basics/response-codes.html
                time.sleep(60)
                continue
            else:
                # In any other case do not retry to load user data
                # This may be changed to cover other error conditions
                print 'Could not access', user_id
                break
        tweet_count = 0
        found_early_tweets = False
        for tweet in timeline:
            if tweet.created_at >= start_day:
                output_file.write('\t'.join( \
                    [str(f) for f in [user_id, tweet.id, tweet.created_at]]))
                output_file.write('\n')
                output_file.flush()
            else:
                found_early_tweets = True
            if earliest_tweet_id is None or tweet.id < earliest_tweet_id:
                earliest_tweet_id = tweet.id
            tweet_count += 1
        if tweet_count < MAX_ITEMS_PER_REQUEST or found_early_tweets:
            # Finished with this user's Tweets if no more to download or we
            # got back before start_day
            break
user_list_file.close()
output_file.close()
