import com.microsoft.azure.eventhubs.{EventData, EventHubClient}

class SendEvent(message:String,eventHubClient:EventHubClient,numRec:Int) extends  Thread {

  var i = 0
  while (i < numRec) {
    sendEvent()
    i = i + 1
  }

  def sendEvent() = {
    val messageData = EventData.create(message.getBytes("UTF-8"))
    eventHubClient.sendSync(messageData)
    System.out.println(Thread.currentThread().getName + " :Sent event: " + i + message + "\n")

  }
}
