import java.text.SimpleDateFormat
import java.util.concurrent.Executors

import com.microsoft.azure.eventhubs._

import scala.concurrent.duration._
import scala.concurrent.{Await, Future,duration}
import scala.concurrent.ExecutionContext.Implicits.global
import util.control.Breaks._


object SendTestParallel {

  def main(args: Array[String]): Unit = {
//    val namespaceName: String = "ehub-citest-kafka"
//    val eventHubName: String = "collector1"
//    val sasKeyName:String ="RootManageSharedAccessKey"
//    val sasKey :String="JZhlBUZuD0gpx7uuP2TAbPmr7EB+E75/UJQ8o8pyYBk="

    val namespaceName: String = "ehubns-uat-hk-peak-di"
    val eventHubName: String = "clickstreamperformancetesting"
    val sasKey :String="cJffnCOjNePr6igC5F/56hhC5NZjF93RSv8QTVf2zSc="
//    val eventHubName: String = "clickstreamperformancetesting2"
//    val sasKey :String="ZfsyQpIXWBlFfaU3X6XG8Z99LEE9iGqlZn8A+/EomOU="
    val sasKeyName:String ="send"


    val connStr = new ConnectionStringBuilder()
      .setNamespaceName(namespaceName)
      .setEventHubName(eventHubName)
      .setSasKeyName(sasKeyName)
      .setSasKey(sasKey)
      .toString
    println(connStr)
    val pool = Executors.newScheduledThreadPool(1)
    val eventHubClient = EventHubClient.createSync(connStr,pool)

    val message ="""{"schema":"iglu:com.snowplowanalytics.snowplow\/payload_data\/jsonschema\/1-0-3","data":[{"vp":"750x1334","se_la":"Verify","res":"750x1334","p":"mob","uid":"1b5acb24-76c8-404a-838e-d6708731bc07","co":"{\"schema\":\"iglu:com.snowplowanalytics.snowplow\\\/contexts\\\/jsonschema\\\/1-0-1\",\"data\":[{\"schema\":\"iglu:com.hsbc\\\/payme_globaldata\\\/jsonschema\\\/1-0-0\",\"data\":{\"page_category\":\"onb\",\"page_business_line\":\"cmb\",\"page_type\":\"verification\",\"page_security_level\":\"0\",\"page_customer_group\":\"svf\"}},{\"schema\":\"iglu:com.snowplowanalytics.snowplow\\\/mobile_context\\\/jsonschema\\\/1-0-1\",\"data\":{\"osType\":\"ios\",\"networkType\":\"wifi\",\"osVersion\":\"11.3.1\",\"appleIdfv\":\"095679CF-4921-4215-8890-3D5A999FB4BA\",\"carrier\":\"CMHK\",\"deviceManufacturer\":\"Apple Inc.\",\"appleIdfa\":\"B73CFCA5-20B7-4C6B-B0F7-78BB4FD13EA1\",\"deviceModel\":\"iPhone\"}},{\"schema\":\"iglu:com.snowplowanalytics.snowplow\\\/client_session\\\/jsonschema\\\/1-0-1\",\"data\":{\"previousSessionId\":null,\"firstEventId\":\"3ec033f6-c504-4fca-b34d-b0a057dd09a3\",\"sessionId\":\"5ced1f1a-e4ed-464d-882c-e8dc3b812ebd\",\"userId\":\"6a0a2ba6-9e5e-42b9-933a-6f83ef80a4dd\",\"sessionIndex\":1,\"storageMechanism\":\"SQLITE\"}}]}","stm":"1548642167092","se_pr":"content","dtm":"1548642166530","tv":"ios-0.8.0","tna":"EventHubTracker_UAT","se_ca":"mobile:payme:b:onb:verify_BIB:landing_withoutVerify","se_va":"0","e":"se","lang":"en-US","se_ac":"button click","duid":"74b91465-4100-4bde-8eca-5703f5629d07","aid":"PM4B","eid":"d63c095b-dcc6-4bd4-8615-f53c9ba3c9b6"}]}"""
//    val message ="""{"schema":"iglu:com.snowplowanalytics.snowplow/payload_data/jsonschema/1-0-4","data":[{"se_la":"28D","eid":"7ac02907-c077-4629-aa80-1d0fab00adfe","tv":"andr-0.7.0","duid":"2e0d206b-f8e6-4c24-a523-e49caefb98af","e":"se","tna":"EventHubTracker_UAT","tz":"Asia/Hong_Kong","se_ca":"mobile:payme:b:pay:tran_bank:transac_hist_bank","se_ac":"button click","se_pr":"content","co":"{\"schema\":\"iglu:com.snowplowanalytics.snowplow/contexts/jsonschema/1-0-1\",\"data\":[{\"schema\":\"iglu:com.hsbc/payme_globaldata/jsonschema/1-0-0\",\"data\":{\"page_customer_group\":\"svf\",\"page_type\":\"transaction\",\"page_category\":\"pay\",\"page_security_level\":\"30\",\"page_business_line\":\"cmb\"}},{\"schema\":\"iglu:com.snowplowanalytics.snowplow/client_session/jsonschema/1-0-1\",\"data\":{\"sessionIndex\":4,\"storageMechanism\":\"SQLITE\",\"firstEventId\":\"c9168f71-86c0-4e99-9585-5eed64e5f87e\",\"sessionId\":\"225a9364-c399-4694-a021-09c26bcd9c0a\",\"previousSessionId\":\"e37d9ed4-c694-4326-907c-47b86a1ebdb8\",\"userId\":\"21e47fde-a2ee-484b-b569-00e5c88ff73b\"}},{\"schema\":\"iglu:com.snowplowanalytics.snowplow/mobile_context/jsonschema/1-0-1\",\"data\":{\"osVersion\":\"8.0.0\",\"osType\":\"android\",\"androidIdfa\":\"fe680b52-bf06-4feb-ace5-128d93dd0e43\",\"deviceModel\":\"SM-G9650\",\"deviceManufacturer\":\"samsung\",\"networkType\":\"wifi\"}}]}","stm":"1545190901404","p":"mob","uid":"d0b95748-9c2b-44c4-902e-d46d973c62bf","dtm":"1545190900547","lang":"zh-Hant-HK","aid":"PM4B"}]}"""

    val numThread = 50
    val fList:Array[Future[Unit]] =new Array[Future[Unit]](numThread)


    val startTime=System.currentTimeMillis()
    val startTimeStamp = new SimpleDateFormat("yyyy.MM.dd.HH.mm.ss").format(startTime)
    
    for ( a <- 0 until numThread){
      fList(a) = Future{
        for (i <- 0 until 10000){
          sendEvent(i)
        }
      }
    }

    def sendEvent(i:Int) = {
      val messageData = EventData.create(message.getBytes("UTF-8"))
      eventHubClient.sendSync(messageData)
      System.out.println(Thread.currentThread().getName + " " + i + " :Sent event: "  + message + "\n")

    }





    for (f <- fList){
      Await.ready(f,10.second)

    }

    eventHubClient.closeSync()
    pool.shutdown()
    val endTime=System.currentTimeMillis()
    val endTimeStamp = new SimpleDateFormat("yyyy.MM.dd.HH.mm.ss").format(endTime)
    println("*** Start time: " + startTimeStamp)
    println("*** End time:" + endTimeStamp)

  }
}
