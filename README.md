GCM Ruby wrapper  [![Build Status](https://secure.travis-ci.org/hifrank/higcm.png?branch=master)](http://travis-ci.org/hifrank/higcm)
===
This is Ruby libray for push message to device via [Google Cloud Messaging for Android](http://developer.android.com/guide/google/gcm/index.html)
# Features
## parallel gcm messaging 
use [Typhoeus](http://typhoeus.github.com/) as http client so it is able to send gcm messges in parallel way.

## handler
parse gcm response with GCM::Handler according to [GCM Response format](http://developer.android.com/guide/google/gcm/gcm.html#response), 
into serveral kinds of responses, say, success, fails, retry, unregister, you can only handle events you care about.

# Usage

## send a message
<pre>
sender = HiGCM::Sender.new(your_api_key)
registration_ids = [1, 2, 3]
opts = {
  :collapse_key => "test"
  :data         => { :mesg => "hello GCM" }
}
response = sender.send(registration_ids, opts)
...
</pre>

## send a message with handler
<pre>
# prepare handler for retry and unregister event
handler = HiGCM::Handler.new
handler.do_retry do | retry_ids, opts, response |
  retry_ids.each do | reg_id, retry_after |
    # do retry things
  end
end
#prepare for renew registration_ids 
handler.do_renew_token do | renew_ids, response |
  renew_ids.each do | reg_id, new_reg_id |
    # do renew stuff
  end
end

sender  = HiGCM::Sender.new(your_api_key)
registration_ids = [1, 2, 3]
opts = {
  :collapse_key => "test"
  :data         => { :mesg => "hello GCM" }
}
sender.send(registration_ids, opts)
</pre>

## send a muti-messages in parallel way 
<pre>
sender  = HiGCM::Sender.new(your_api_key)

# queue your messages first 
something.each do | registration_id, name |
  # prepare handler for retry and unregister event
  handler = HiGCM::Handler.new
  handler.do_retry do | retry_ids, opts, response |
    retry_ids.each do | reg_id, retry_after |
      # do retry things
    end
  end
  #prepare for renew registration_ids 
  handler.do_renew_token do | renew_ids, response |
    renew_ids.each do | reg_id, new_reg_id |
      # do renew stuff
    end
  end

  opts = {
    :collapse_key => "test"
    :data         => { :mesg => "hello #{name}" }
  }
  sender.send_async(registration_id, opts, handler)
end
# now fire
sender.send_async_run
</pre>
