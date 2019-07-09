import sys
import logging
import datetime
import time
import os
import random
import time

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
    
    
    message1 ='{"schema":"iglu:com.snowplowanalytics.snowplow\/payload_data\/jsonschema\/1-0-3","data":[{"vp":"750x1334","se_la":"Verify","res":"750x1334","p":"mob","uid":"1b5acb24-76c8-404a-838e-d6708731bc07","co":"{\\"schema\\":\\\"iglu:com.snowplowanalytics.snowplow\\\/contexts\\\/jsonschema\\\/1-0-1\\",\\"data\\":[{\\"schema\\":\\"iglu:com.hsbc\\\/payme_globaldata\\\/jsonschema\\\/1-0-0\\",\\"data\\":{\\"page_category\\":\\"onb\\",\\"page_business_line\\":\\"cmb\\",\\"page_type\\":\\"verification\\",\\"page_security_level\\":\\"0\\",\\"page_customer_group\\":\\"svf\\"}},{\\"schema\\":\\"iglu:com.snowplowanalytics.snowplow\\\/mobile_context\\\/jsonschema\\\/1-0-1\\",\\"data\\":{\\"osType\\":\\"ios\\",\\"networkType\\":\\"wifi\\",\\"osVersion\\":\\"11.3.1\\",\\"appleIdfv\\":\\"095679CF-4921-4215-8890-3D5A999FB4BA\\",\\"carrier\\":\\"CMHK\\",\\"deviceManufacturer\\":\\"Apple Inc.\\",\\"appleIdfa\\":\\"B73CFCA5-20B7-4C6B-B0F7-78BB4FD13EA1\\",\\"deviceModel\\":\\"iPhone\\"}},{\\"schema\\":\\"iglu:com.snowplowanalytics.snowplow\\\/client_session\\\/jsonschema\\\/1-0-1\\",\\"data\\":{\\"previousSessionId\\":null,\\"firstEventId\\":\\"3ec033f6-c504-4fca-b34d-b0a057dd09a3\\",\\"sessionId\\":\\"5ced1f1a-e4ed-464d-882c-e8dc3b812ebd\\",\\"userId\\":\\"6a0a2ba6-9e5e-42b9-933a-6f83ef80a4dd\\",\\"sessionIndex\\":1,\\"storageMechanism\\":\\"SQLITE\\"}}]}","stm":"1548642167092","se_pr":"content","dtm":"1548642166530","tv":"ios-0.8.0","tna":"EventHubTracker_UAT","se_ca":"mobile:payme:b:onb:verify_BIB:landing_withoutVerify","se_va":"0","e":"se","lang":"en-US","se_ac":"button click","duid":"74b91465-4100-4bde-8eca-5703f5629d07","aid":"PM4B","eid":"d63c095b-dcc6-4bd4-8615-f53c9ba3c9b6"}]}'

    message2='{"schema":"iglu:com.snowplowanalytics.snowplow/payload_data/jsonschema/1-0-4","data":[{"se_la":"28D","eid":"7ac02907-c077-4629-aa80-1d0fab00adfe","tv":"andr-0.7.0","duid":"2e0d206b-f8e6-4c24-a523-e49caefb98af","e":"se","tna":"EventHubTracker_UAT","tz":"Asia/Hong_Kong","se_ca":"mobile:payme:b:pay:tran_bank:transac_hist_bank","se_ac":"button click","se_pr":"content","co":"{\"schema\":\"iglu:com.snowplowanalytics.snowplow/contexts/jsonschema/1-0-1\",\"data\":[{\"schema\":\"iglu:com.hsbc/payme_globaldata/jsonschema/1-0-0\",\"data\":{\"page_customer_group\":\"svf\",\"page_type\":\"transaction\",\"page_category\":\"pay\",\"page_security_level\":\"30\",\"page_business_line\":\"cmb\"}},{\"schema\":\"iglu:com.snowplowanalytics.snowplow/client_session/jsonschema/1-0-1\",\"data\":{\"sessionIndex\":4,\"storageMechanism\":\"SQLITE\",\"firstEventId\":\"c9168f71-86c0-4e99-9585-5eed64e5f87e\",\"sessionId\":\"225a9364-c399-4694-a021-09c26bcd9c0a\",\"previousSessionId\":\"e37d9ed4-c694-4326-907c-47b86a1ebdb8\",\"userId\":\"21e47fde-a2ee-484b-b569-00e5c88ff73b\"}},{\"schema\":\"iglu:com.snowplowanalytics.snowplow/mobile_context/jsonschema/1-0-1\",\"data\":{\"osVersion\":\"8.0.0\",\"osType\":\"android\",\"androidIdfa\":\"fe680b52-bf06-4feb-ace5-128d93dd0e43\",\"deviceModel\":\"SM-G9650\",\"deviceManufacturer\":\"samsung\",\"networkType\":\"wifi\"}}]}","stm":"1545190901404","p":"mob","uid":"d0b95748-9c2b-44c4-902e-d46d973c62bf","dtm":"1545190900547","lang":"zh-Hant-HK","aid":"PM4B"}]}'

    # message_err="""{""schema"":""iglu:com.snowplowanalytics.snowplow\/payload_data\/jsonschema\/1-0-3"",""data"":[{""ue_pr"":""{\""schema\"":\""iglu:com.snowplowanalytics.snowplow\\\/unstruct_event\\\/jsonschema\\\/1-0-0\"",\""data\"":{\""schema\"":\""iglu:com.com.hsbc\\\/payme_globaldata\\\/jsonschema\\\/1-0-0\"",\""data\"":{\""tag\"":\""mobile:payme:c:pay:pay_scan:scanner_disabled\"",\""values\"":{\""page_customer_group\"":\""svf\"",\""page_name\"":\""mobile:payme:c:pay:pay_scan:scanner_disabled\"",\""page_business_line\"":\""rbwm\"",\""page_category\"":\""pay\"",\""site_section\"":\""mobile\"",\""page_security_level\"":\""30\"",\""page_type\"":\""transaction\""}}}}"",""vp"":""1125x2436"",""eid"":""a0bd77e3-946c-4901-95b3-53c991238905"",""p"":""mob"",""co"":""{\""schema\"":\""iglu:com.snowplowanalytics.snowplow\\\/contexts\\\/jsonschema\\\/1-0-1\"",\""data\"":[{\""schema\"":\""iglu:com.snowplowanalytics.snowplow\\\/mobile_context\\\/jsonschema\\\/1-0-1\"",\""data\"":{\""osType\"":\""ios\"",\""osVersion\"":\""12.2\"",\""appleIdfv\"":\""AC138160-FBCE-4556-8AC6-47CF65536370\"",\""carrier\"":\""CMHK\"",\""deviceManufacturer\"":\""Apple Inc.\"",\""networkType\"":\""wifi\"",\""deviceModel\"":\""iPhone\""}},{\""schema\"":\""iglu:com.snowplowanalytics.snowplow\\\/client_session\\\/jsonschema\\\/1-0-1\"",\""data\"":{\""previousSessionId\"":\""3d52bc8d-b93a-4a48-b18f-6fe39da4e45d\"",\""firstEventId\"":\""7944cd75-5404-4edf-a1e6-b0af467c8cb8\"",\""sessionId\"":\""c626ad36-51a4-4792-95b4-a228bd722c36\"",\""userId\"":\""2620450a-8900-43dc-aedb-be5098d73652\"",\""sessionIndex\"":2,\""storageMechanism\"":\""SQLITE\""}}]}"",""stm"":""1559100469001"",""dtm"":""1559100468992"",""tv"":""ios-0.8.0"",""tna"":""EventHubTracker_"",""e"":""ue"",""lang"":""en-HK"",""aid"":""PM4C"",""res"":""1125x2436""}]}"""

    # message_err2="""{""schema"":""iglu:com.snowplowanalytics.snowplow\/payload_data\/jsonschema\/1-0-3"",""data"":[{""ue_pr"":""{\""schema\"":\""iglu:com.snowplowanalytics.snowplow\\\/unstruct_event\\\/jsonschema\\\/1-0-0\"",\""data\"":{\""schema\"":\""iglu:com.acme_company\\\/demo_ios_event\\\/jsonschema\\\/1-0-0\"",\""data\"":{\""tag\"":\""mobile:payme:c:mai:notifications:pending\"",\""values\"":{\""page_customer_group\"":\""svf\"",\""page_type\"":\""transaction\"",\""site_section\"":\""mobile\"",\""page_name\"":\""mobile:payme:c:mai:notifications:pending\"",\""page_category\"":\""pay\"",\""page_business_line\"":\""rbwm\"",\""page_security_level\"":\""30\""}}}}"",""vp"":""1242x2208"",""eid"":""ec70027d-6adb-470b-98f8-200763aed8fb"",""p"":""mob"",""co"":""{\""schema\"":\""iglu:com.snowplowanalytics.snowplow\\\/contexts\\\/jsonschema\\\/1-0-1\"",\""data\"":[{\""schema\"":\""iglu:com.snowplowanalytics.snowplow\\\/mobile_context\\\/jsonschema\\\/1-0-1\"",\""data\"":{\""osType\"":\""ios\"",\""osVersion\"":\""12.2\"",\""appleIdfv\"":\""150A4927-8C66-4AA0-B8A8-A6DD594857AB\"",\""carrier\"":\""1O1O \\\/ csl\"",\""deviceManufacturer\"":\""Apple Inc.\"",\""networkType\"":\""wifi\"",\""deviceModel\"":\""iPhone\""}},{\""schema\"":\""iglu:com.snowplowanalytics.snowplow\\\/client_session\\\/jsonschema\\\/1-0-1\"",\""data\"":{\""previousSessionId\"":\""365551cc-3077-4a9a-936e-1799c80e10c3\"",\""firstEventId\"":\""ec70027d-6adb-470b-98f8-200763aed8fb\"",\""sessionId\"":\""a1f1f8f8-a82a-41ad-a30d-f89bcae17828\"",\""userId\"":\""165774d4-6cc5-4e32-b30d-507f2afd913d\"",\""sessionIndex\"":38,\""storageMechanism\"":\""SQLITE\""}}]}"",""stm"":""1558593758831"",""dtm"":""1558593758818"",""tv"":""ios-0.8.0"",""tna"":""EventHubTracker_"",""e"":""ue"",""lang"":""en"",""aid"":""PM4C"",""res"":""1242x2208""}]}"""        
    
    # message_pm4b="""{"schema":"iglu:com.snowplowanalytics.snowplow\/payload_data\/jsonschema\/1-0-3","data":[{"vp":"1242x2208","se_la":"1D","res":"1242x2208","p":"mob","uid":"7a88f763-6214-4d23-a995-f41e260d802d","co":"{\"schema\":\"iglu:com.snowplowanalytics.snowplow\\\/contexts\\\/jsonschema\\\/1-0-1\",\"data\":[{\"schema\":\"iglu:com.hsbc\\\/payme_globaldata\\\/jsonschema\\\/1-0-0\",\"data\":{\"page_category\":\"pay\",\"page_business_line\":\"cmb\",\"page_type\":\"transaction\",\"page_security_level\":\"30\",\"page_customer_group\":\"svf\"}},{\"schema\":\"iglu:com.snowplowanalytics.snowplow\\\/mobile_context\\\/jsonschema\\\/1-0-1\",\"data\":{\"osType\":\"ios\",\"osVersion\":\"12.3.1\",\"networkTechnology\":\"CTRadioAccessTechnologyLTE\",\"appleIdfv\":\"BFE0861D-A255-4BA5-B0B9-7288C3109020\",\"carrier\":\"3\",\"deviceManufacturer\":\"Apple Inc.\",\"networkType\":\"wifi\",\"deviceModel\":\"iPhone\"}},{\"schema\":\"iglu:com.snowplowanalytics.snowplow\\\/client_session\\\/jsonschema\\\/1-0-1\",\"data\":{\"previousSessionId\":\"55677fdb-341e-428b-a489-2f2049d4560c\",\"firstEventId\":\"ff514540-8fb8-4581-b97b-cac297ae1754\",\"sessionId\":\"8de38280-5835-4329-98ad-df48375b8ddd\",\"userId\":\"2d2572cb-24ac-4c23-bd0a-0f55df4ef1d8\",\"sessionIndex\":3,\"storageMechanism\":\"SQLITE\"}}]}","stm":"1559916325388","se_pr":"content","dtm":"1559916325381","tv":"ios-0.8.0","tna":"EventHubTracker_PREPROD","se_ca":"mobile:payme:b:pay:tran_bank:transac_hist_bank","se_va":"0","e":"se","lang":"en-US","se_ac":"button click","duid":"ee7e00ba-a85d-45b3-a1be-f6fc512b5633","aid":"PM4B","eid":"00b49267-37d7-4d77-a023-acace6fe3e8f"}]}"""

    # message_pm4b2="""{"schema":"iglu:com.snowplowanalytics.snowplow\/payload_data\/jsonschema\/1-0-3","data":[{"ue_pr":"{\"schema\":\"iglu:com.snowplowanalytics.snowplow\\\/unstruct_event\\\/jsonschema\\\/1-0-0\",\"data\":{\"schema\":\"iglu:com.snowplowanalytics.snowplow\\\/screen_view\\\/jsonschema\\\/1-0-0\",\"data\":{\"id\":\"mobile:payme:b:pay:tran_bank:home_keypad\",\"name\":\"mobile:payme:b:pay:tran_bank:home_keypad\"}}}","vp":"1242x2208","eid":"c90b1a55-dd44-4543-b4d0-d65cc251e0b8","p":"mob","uid":"7a88f763-6214-4d23-a995-f41e260d802d","co":"{\"schema\":\"iglu:com.snowplowanalytics.snowplow\\\/contexts\\\/jsonschema\\\/1-0-1\",\"data\":[{\"schema\":\"iglu:com.hsbc\\\/payme_globaldata\\\/jsonschema\\\/1-0-0\",\"data\":{\"page_category\":\"pay\",\"page_business_line\":\"cmb\",\"page_type\":\"transaction\",\"page_security_level\":\"30\",\"page_customer_group\":\"svf\"}},{\"schema\":\"iglu:com.snowplowanalytics.snowplow\\\/mobile_context\\\/jsonschema\\\/1-0-1\",\"data\":{\"osType\":\"ios\",\"osVersion\":\"12.3.1\",\"networkTechnology\":\"CTRadioAccessTechnologyLTE\",\"appleIdfv\":\"BFE0861D-A255-4BA5-B0B9-7288C3109020\",\"carrier\":\"3\",\"deviceManufacturer\":\"Apple Inc.\",\"networkType\":\"wifi\",\"deviceModel\":\"iPhone\"}},{\"schema\":\"iglu:com.snowplowanalytics.snowplow\\\/client_session\\\/jsonschema\\\/1-0-1\",\"data\":{\"previousSessionId\":\"55677fdb-341e-428b-a489-2f2049d4560c\",\"firstEventId\":\"ff514540-8fb8-4581-b97b-cac297ae1754\",\"sessionId\":\"8de38280-5835-4329-98ad-df48375b8ddd\",\"userId\":\"2d2572cb-24ac-4c23-bd0a-0f55df4ef1d8\",\"sessionIndex\":3,\"storageMechanism\":\"SQLITE\"}}]}","stm":"1559916323206","dtm":"1559916323197","tv":"ios-0.8.0","tna":"EventHubTracker_PREPROD","e":"ue","lang":"en-US","duid":"ee7e00ba-a85d-45b3-a1be-f6fc512b5633","aid":"PM4B","res":"1242x2208"}]}"""

    # message_pm4b3="""{"schema":"iglu:com.snowplowanalytics.snowplow\/payload_data\/jsonschema\/1-0-3","data":[{"vp":"1242x2208","se_la":"Back","res":"1242x2208","p":"mob","uid":"7a88f763-6214-4d23-a995-f41e260d802d","co":"{\"schema\":\"iglu:com.snowplowanalytics.snowplow\\\/contexts\\\/jsonschema\\\/1-0-1\",\"data\":[{\"schema\":\"iglu:com.hsbc\\\/payme_globaldata\\\/jsonschema\\\/1-0-0\",\"data\":{\"page_category\":\"pay\",\"page_business_line\":\"cmb\",\"page_type\":\"transaction\",\"page_security_level\":\"30\",\"page_customer_group\":\"svf\"}},{\"schema\":\"iglu:com.snowplowanalytics.snowplow\\\/mobile_context\\\/jsonschema\\\/1-0-1\",\"data\":{\"osType\":\"ios\",\"osVersion\":\"12.3.1\",\"networkTechnology\":\"CTRadioAccessTechnologyLTE\",\"appleIdfv\":\"BFE0861D-A255-4BA5-B0B9-7288C3109020\",\"carrier\":\"3\",\"deviceManufacturer\":\"Apple Inc.\",\"networkType\":\"wifi\",\"deviceModel\":\"iPhone\"}},{\"schema\":\"iglu:com.snowplowanalytics.snowplow\\\/client_session\\\/jsonschema\\\/1-0-1\",\"data\":{\"previousSessionId\":\"55677fdb-341e-428b-a489-2f2049d4560c\",\"firstEventId\":\"ff514540-8fb8-4581-b97b-cac297ae1754\",\"sessionId\":\"8de38280-5835-4329-98ad-df48375b8ddd\",\"userId\":\"2d2572cb-24ac-4c23-bd0a-0f55df4ef1d8\",\"sessionIndex\":3,\"storageMechanism\":\"SQLITE\"}}]}","stm":"1559916463113","se_pr":"content","dtm":"1559916463102","tv":"ios-0.8.0","tna":"EventHubTracker_PREPROD","se_ca":"mobile:payme:b:pay:dyn_qr:transac_detail_payment","se_va":"0","e":"se","lang":"en-US","se_ac":"button click","duid":"ee7e00ba-a85d-45b3-a1be-f6fc512b5633","aid":"PM4B","eid":"fa07a434-b9bc-4a01-a2c0-93b121e385a5"}]}"""
    
    # message_pm4b4="""{"schema":"iglu:com.snowplowanalytics.snowplow\/payload_data\/jsonschema\/1-0-3","data":[{"vp":"1242x2208","se_la":"Swipe on reporting screen","res":"1242x2208","p":"mob","uid":"7a88f763-6214-4d23-a995-f41e260d802d","co":"{\"schema\":\"iglu:com.snowplowanalytics.snowplow\\\/contexts\\\/jsonschema\\\/1-0-1\",\"data\":[{\"schema\":\"iglu:com.hsbc\\\/payme_globaldata\\\/jsonschema\\\/1-0-0\",\"data\":{\"page_category\":\"pay\",\"page_business_line\":\"cmb\",\"page_type\":\"transaction\",\"page_security_level\":\"30\",\"page_customer_group\":\"svf\"}},{\"schema\":\"iglu:com.snowplowanalytics.snowplow\\\/mobile_context\\\/jsonschema\\\/1-0-1\",\"data\":{\"osType\":\"ios\",\"osVersion\":\"12.3.1\",\"networkTechnology\":\"CTRadioAccessTechnologyLTE\",\"appleIdfv\":\"BFE0861D-A255-4BA5-B0B9-7288C3109020\",\"carrier\":\"3\",\"deviceManufacturer\":\"Apple Inc.\",\"networkType\":\"wifi\",\"deviceModel\":\"iPhone\"}},{\"schema\":\"iglu:com.snowplowanalytics.snowplow\\\/client_session\\\/jsonschema\\\/1-0-1\",\"data\":{\"previousSessionId\":\"55677fdb-341e-428b-a489-2f2049d4560c\",\"firstEventId\":\"ff514540-8fb8-4581-b97b-cac297ae1754\",\"sessionId\":\"8de38280-5835-4329-98ad-df48375b8ddd\",\"userId\":\"2d2572cb-24ac-4c23-bd0a-0f55df4ef1d8\",\"sessionIndex\":3,\"storageMechanism\":\"SQLITE\"}}]}","stm":"1559916480852","se_pr":"content","dtm":"1559916480841","tv":"ios-0.8.0","tna":"EventHubTracker_PREPROD","se_ca":"mobile:payme:b:pay:tran_bank:transac_hist_bank","se_va":"0","e":"se","lang":"en-US","se_ac":"swipe","duid":"ee7e00ba-a85d-45b3-a1be-f6fc512b5633","aid":"PM4B","eid":"171e644e-f81c-4589-a9c0-3a2ce508800d"}]}"""
    
    # message_pm4c_andr="""{"schema":"iglu:com.snowplowanalytics.snowplow\/payload_data\/jsonschema\/1-0-4","data":[{"eid":"fad179c9-322f-483c-b48b-999f1b0bb76b","tv":"andr-0.7.0","duid":"","e":"ue","tna":"EventHubTracker_uat","tz":"Asia\/Hong_Kong","co":"{\"schema\":\"iglu:com.snowplowanalytics.snowplow\\\/contexts\\\/jsonschema\\\/1-0-1\",\"data\":[{\"schema\":\"iglu:com.snowplowanalytics.snowplow\\\/client_session\\\/jsonschema\\\/1-0-1\",\"data\":{\"sessionIndex\":2,\"storageMechanism\":\"SQLITE\",\"firstEventId\":\"fad179c9-322f-483c-b48b-999f1b0bb76b\",\"sessionId\":\"34e0264f-339d-48a5-8cde-897d9d1f9fa1\",\"previousSessionId\":\"d0b70a67-2ad2-4f2c-8fcc-e24a4537eb3c\",\"userId\":\"9b53cbc8-8f93-479e-87ed-d59391c90431\"}},{\"schema\":\"iglu:com.snowplowanalytics.snowplow\\\/mobile_context\\\/jsonschema\\\/1-0-1\",\"data\":{\"osVersion\":\"8.0.0\",\"osType\":\"android\",\"androidIdfa\":\"5ba8cd3e-e9e5-46a1-a102-bec99095d97b\",\"deviceModel\":\"SM-G9500\",\"deviceManufacturer\":\"samsung\",\"networkType\":\"wifi\"}}]}","stm":"1559909267335","p":"mob","ue_pr":"{\"schema\":\"iglu:com.snowplowanalytics.snowplow\\\/unstruct_event\\\/jsonschema\\\/1-0-0\",\"data\":{\"schema\":\"iglu:com.snowplowanalytics.snowplow\\\/application_background\\\/jsonschema\\\/1-0-0\",\"data\":{\"backgroundIndex\":1}}}","uid":"","dtm":"1559909267281","lang":"en_US","aid":"PM4C"}]}"""

    # message_pm4c_ue="""{"schema":"iglu:com.snowplowanalytics.snowplow\/payload_data\/jsonschema\/1-0-3","data":[{"ue_pr":"{\"schema\":\"iglu:com.snowplowanalytics.snowplow\\\/unstruct_event\\\/jsonschema\\\/1-0-0\",\"data\":{\"schema\":\"iglu:com.hsbc\\\/payme_globaldata\\\/jsonschema\\\/1-0-0\",\"data\":{\"tag\":\"mobile:payme:c:dis:discover:landing\",\"values\":{\"page_customer_group\":\"svf\",\"page_name\":\"mobile:payme:c:dis:discover:landing\",\"page_business_line\":\"rbwm\",\"page_security_level\":\"30\",\"page_type\":\"transaction\",\"page_category\":\"dis\",\"site_section\":\"mobile\"}}}}","vp":"640x1136","eid":"a7118121-3c6e-40cc-9ff9-ba70453c03db","p":"mob","co":"{\"schema\":\"iglu:com.snowplowanalytics.snowplow\\\/contexts\\\/jsonschema\\\/1-0-1\",\"data\":[{\"schema\":\"iglu:com.snowplowanalytics.snowplow\\\/mobile_context\\\/jsonschema\\\/1-0-1\",\"data\":{\"deviceManufacturer\":\"Apple Inc.\",\"osVersion\":\"12.1\",\"osType\":\"ios\",\"deviceModel\":\"iPhone\",\"networkType\":\"wifi\",\"appleIdfv\":\"D2B8FD98-4E19-4D64-B6E8-F05F4B47A386\"}},{\"schema\":\"iglu:com.snowplowanalytics.snowplow\\\/client_session\\\/jsonschema\\\/1-0-1\",\"data\":{\"previousSessionId\":\"45d0cca2-7b52-488c-833c-7584f3764cfa\",\"firstEventId\":\"a7118121-3c6e-40cc-9ff9-ba70453c03db\",\"sessionId\":\"fbc85933-13c6-45e9-b952-4ee752cdace3\",\"userId\":\"7680fcd4-1020-4f4e-ab96-5fc87344fe88\",\"sessionIndex\":90,\"storageMechanism\":\"SQLITE\"}}]}","stm":"1559913172785","dtm":"1559913172779","tv":"ios-0.8.0","tna":"EventHubTracker_uat3","e":"ue","lang":"zh-Hant","aid":"PM4C","res":"640x1136"}]}""" 


    # message_pm4c_se="""{"schema":"iglu:com.snowplowanalytics.snowplow\/payload_data\/jsonschema\/1-0-4","data":[{"se_la":"Me","eid":"19173011-7eaf-4f65-bdd6-a84b0011dcc3","tv":"andr-0.7.0","duid":"","e":"se","tna":"EventHubTracker_uat","tz":"Asia\/Hong_Kong","se_ca":"mobile:payme:c:dis:dis:discover:landing","se_ac":"button click","se_pr":"content","co":"{\"schema\":\"iglu:com.snowplowanalytics.snowplow\\\/contexts\\\/jsonschema\\\/1-0-1\",\"data\":[{\"schema\":\"iglu:com.hsbc\\\/payme_globaldata\\\/jsonschema\\\/1-0-0\",\"data\":{\"page_customer_group\":\"svf\",\"page_type\":\"transaction\",\"page_category\":\"dis\",\"page_security_level\":\"30\",\"page_business_line\":\"rbwm\"}},{\"schema\":\"iglu:com.snowplowanalytics.snowplow\\\/client_session\\\/jsonschema\\\/1-0-1\",\"data\":{\"sessionIndex\":10,\"storageMechanism\":\"SQLITE\",\"firstEventId\":\"2caab7ad-2cef-42a9-8c22-538c47a6044c\",\"sessionId\":\"a38c59ad-58e2-42af-b634-5fbd3e17c523\",\"previousSessionId\":\"b3e98dd8-dccd-489d-b03f-ccd7325a2914\",\"userId\":\"010cafe3-a6ee-43ba-a0c7-5362d01a289d\"}},{\"schema\":\"iglu:com.snowplowanalytics.snowplow\\\/mobile_context\\\/jsonschema\\\/1-0-1\",\"data\":{\"carrier\":\"CMHK\",\"osVersion\":\"8.0.0\",\"osType\":\"android\",\"androidIdfa\":\"0cb0a1ba-d020-48a2-a251-5b9f73ba76c2\",\"deviceModel\":\"BND-AL10\",\"deviceManufacturer\":\"HUAWEI\",\"networkType\":\"wifi\"}}]}","stm":"1559979982137","p":"mob","uid":"","dtm":"1559979981479","lang":"en_US","aid":"PM4C"}]}"""

    message_list = []
    message_list.append(message1)
    message_list.append(message2)
    # message_list.append(message_err)
    # message_list.append(message_err2)
    # message_list.append(message_pm4b)
    # message_list.append(message_pm4b2)
    # message_list.append(message_pm4b3)
    # message_list.append(message_pm4b4)
    # message_list.append(message_pm4c_andr)
    # message_list.append(message_pm4c_se)
    # message_list.append(message_pm4c_ue)

    interval=random.randint(1,5)
    
    try:
        start_time = time.time()
        for i in range(100):
            message_send =random.choice(message_list)
            print("Sending message: {}".format(message_send))
            sender.send(EventData(message_send))
            time.sleep(interval)
            
    except:
        raise
    finally:
        end_time = time.time()
        client.stop()
        run_time = end_time - start_time
        logger.info("Runtime: {} seconds".format(run_time))

except KeyboardInterrupt:
    pass