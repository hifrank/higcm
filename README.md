GCM Ruby wrapper  [![Build Status](https://secure.travis-ci.org/hifrank/higcm.png?branch=master)](http://travis-ci.org/hifrank/higcm)
===
This is Ruby libray for push message to device via [Google Cloud Messaging for Android](http://developer.android.com/guide/google/gcm/index.html)
# Features
## parallel gcm messaging 
it use [Typhoeus](http://typhoeus.github.com/) as http client so it is able to send gcm messges in parallel way.

## handler
it parse gcm response with GCM::Handler according to [GCM Response format](http://developer.android.com/guide/google/gcm/gcm.html#response), 
into serveral kinds of responses, say, success, fails, retry, unregister, you can only handle events you care about.
