import java.util.concurrent.{Executor, Executors}

import com.microsoft.azure.eventhubs._
import collection.JavaConversions._
import jdk.nashorn.internal.runtime.regexp.joni.constants.StringType

object ReadTest {

//  val namespaceName: String = "ehubns-uat-hk-peak-di"
//
//  val eventHubName: String = "ehub-uat-hk-peak-di"
//
//  val sasKeyName:String ="ReadOnly"
//  val sasKey :String="yDkDndWfZoW0seW8gBUWy9XoUBRTYwsuW5QCxpXRuKs="

  val namespaceName: String = "ehub-citest-kafka"
  val eventHubName: String = "collector1"
  val sasKeyName:String ="RootManageSharedAccessKey"
  val sasKey :String="JZhlBUZuD0gpx7uuP2TAbPmr7EB+E75/UJQ8o8pyYBk="

  def main(args: Array[String]): Unit = {

    val connStr = new ConnectionStringBuilder()
      .setNamespaceName(namespaceName)
      .setEventHubName(eventHubName)
      .setSasKeyName(sasKeyName)
      .setSasKey(sasKey)
      .toString
    println(connStr)
    val pool = Executors.newScheduledThreadPool(1)
    val eventHubClient = EventHubClient.createSync(connStr, pool)
    val receiver = eventHubClient.createReceiverSync("$Default", "1", EventPosition.fromEndOfStream())
    //    print(eventHubClient.getEventHubName)


//    for (reveiveEvent: EventData <- receivedEvents) {
//
//      println(
//        reveiveEvent.getBytes.map(_.toChar).mkString
//      )
//    }

    while (true){
      val receivedEvents = receiver.receiveSync(1)
      Option(receivedEvents) match {
        case Some(receivedEvents) =>
          for (reveiveEvent: EventData <- receivedEvents) {

            println(
              reveiveEvent.getBytes.map(_.toChar).mkString
            )
          }
        case _ => ()
      }
    }

      eventHubClient.closeSync()


  }


}
