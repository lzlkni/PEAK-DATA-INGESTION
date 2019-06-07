import sys
import logging
import datetime
import time
import os
import random

from azure.eventhub import EventHubClient, Sender, EventData

logger = logging.getLogger("azure")

# Address can be in either of these formats:
# "amqps://<URL-encoded-SAS-policy>:<URL-encoded-SAS-key>@<mynamespace>.servicebus.windows.net/myeventhub"
# "amqps://<mynamespace>.servicebus.windows.net/myeventhub"
# For example:
ADDRESS = "amqps://ehubns-uat-hk-peak-di.servicebus.windows.net/clickstreamperformancetesting"

# SAS policy and key are not required if they are encoded in the URL
USER = "send"
KEY = "cJffnCOjNePr6igC5F/56hhC5NZjF93RSv8QTVf2zSc="

try:
    if not ADDRESS:
        raise ValueError("No EventHubs URL supplied.")

    # Create Event Hubs client
    client = EventHubClient(ADDRESS, debug=False, username=USER, password=KEY)
    sender = client.add_sender()
    client.run()
    
    message1 ="""{"schema":"iglu:com.snowplowanalytics.snowplow\/payload_data\/jsonschema\/1-0-3","data":[{"vp":"750x1334","se_la":"Verify","res":"750x1334","p":"mob","uid":"1b5acb24-76c8-404a-838e-d6708731bc07","co":"{\"schema\":\"iglu:com.snowplowanalytics.snowplow\\\/contexts\\\/jsonschema\\\/1-0-1\",\"data\":[{\"schema\":\"iglu:com.hsbc\\\/payme_globaldata\\\/jsonschema\\\/1-0-0\",\"data\":{\"page_category\":\"onb\",\"page_business_line\":\"cmb\",\"page_type\":\"verification\",\"page_security_level\":\"0\",\"page_customer_group\":\"svf\"}},{\"schema\":\"iglu:com.snowplowanalytics.snowplow\\\/mobile_context\\\/jsonschema\\\/1-0-1\",\"data\":{\"osType\":\"ios\",\"networkType\":\"wifi\",\"osVersion\":\"11.3.1\",\"appleIdfv\":\"095679CF-4921-4215-8890-3D5A999FB4BA\",\"carrier\":\"CMHK\",\"deviceManufacturer\":\"Apple Inc.\",\"appleIdfa\":\"B73CFCA5-20B7-4C6B-B0F7-78BB4FD13EA1\",\"deviceModel\":\"iPhone\"}},{\"schema\":\"iglu:com.snowplowanalytics.snowplow\\\/client_session\\\/jsonschema\\\/1-0-1\",\"data\":{\"previousSessionId\":null,\"firstEventId\":\"3ec033f6-c504-4fca-b34d-b0a057dd09a3\",\"sessionId\":\"5ced1f1a-e4ed-464d-882c-e8dc3b812ebd\",\"userId\":\"6a0a2ba6-9e5e-42b9-933a-6f83ef80a4dd\",\"sessionIndex\":1,\"storageMechanism\":\"SQLITE\"}}]}","stm":"1548642167092","se_pr":"content","dtm":"1548642166530","tv":"ios-0.8.0","tna":"EventHubTracker_UAT","se_ca":"mobile:payme:b:onb:verify_BIB:landing_withoutVerify","se_va":"0","e":"se","lang":"en-US","se_ac":"button click","duid":"74b91465-4100-4bde-8eca-5703f5629d07","aid":"PM4B","eid":"d63c095b-dcc6-4bd4-8615-f53c9ba3c9b6"}]}"""
    
    message_list = []
    message_list.append(message1)

    message_send =random.choice(message_list)
    try:
        start_time = time.time()
        for i in range(10):
            print("Sending message: {}".format(message_send))
            sender.send(EventData(message_send))
    except:
        raise
    finally:
        end_time = time.time()
        client.stop()
        run_time = end_time - start_time
        logger.info("Runtime: {} seconds".format(run_time))

except KeyboardInterrupt:
    pass