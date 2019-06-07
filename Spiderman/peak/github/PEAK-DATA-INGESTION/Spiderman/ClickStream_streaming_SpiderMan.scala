// Databricks notebook source
// MAGIC %python
// MAGIC ###initialize logging module##############
// MAGIC 
// MAGIC import logging
// MAGIC logger = logging.getLogger("ClickStream_streaming_SpiderMan")
// MAGIC logger.handlers.clear()
// MAGIC logger.setLevel(logging.DEBUG)
// MAGIC console = logging.StreamHandler()
// MAGIC formatter = logging.Formatter('%(asctime)s %(name)-12s %(levelname)-8s %(message)s')
// MAGIC console.setFormatter(formatter)
// MAGIC logger.addHandler(console)
// MAGIC 
// MAGIC def is_blank(s):
// MAGIC   return not bool(s and s.strip())

// COMMAND ----------

// MAGIC %python
// MAGIC 
// MAGIC ####Prepare the notebook input parameters###########
// MAGIC 
// MAGIC dbutils.widgets.removeAll()
// MAGIC ##define the job group input parameters
// MAGIC ##it's only one group for streaming
// MAGIC job_group_options = ["0"]
// MAGIC dbutils.widgets.dropdown("jobGroup", "0", [str(x) for x in job_group_options], "Job Group Name")
// MAGIC ##define the Environment input parameters
// MAGIC env_options = ["dev","UAT","UAT1","UAT2","PRE","PROD"]
// MAGIC dbutils.widgets.dropdown("env", "UAT", [str(x) for x in env_options], "Environment")
// MAGIC 
// MAGIC ##define the Config Number input parameters
// MAGIC dbutils.widgets.text("confId","","Config ID")

// COMMAND ----------

// MAGIC %python
// MAGIC 
// MAGIC ####Read parameter and verify ###########
// MAGIC 
// MAGIC job_group=dbutils.widgets.get("jobGroup")
// MAGIC config_id = dbutils.widgets.get("confId")
// MAGIC env = dbutils.widgets.get("env")
// MAGIC 
// MAGIC if job_group not in job_group_options :
// MAGIC     logger.error('Invalid job group name - %s', job_group)
// MAGIC     logger.info('Support job group is - %s', job_group_options)
// MAGIC     raise Exception("Not supported job group name!")
// MAGIC   
// MAGIC if not config_id.isdigit():
// MAGIC   logger.error('Invalid ConfigId - %s', config_id)
// MAGIC   raise Exception("Not supported config ID!")
// MAGIC   
// MAGIC if env not in env_options :
// MAGIC   logger.error('Invalid environment - %s', env)
// MAGIC   logger.info('Support environment is - %s', env_options)
// MAGIC   raise Exception("Not supported evnironment!")
// MAGIC 
// MAGIC 
// MAGIC logger.info('>>>>>>>>>>>Processing job group: %s', job_group)
// MAGIC logger.info('>>>>>>>>>>>Processing environment: %s', env)
// MAGIC logger.info('>>>>>>>>>>>Processing config ID: %s', config_id)

// COMMAND ----------

// DBTITLE 1,Invoke process auditing
// MAGIC %run ../Utility/udl_process_auditing_events_v02_Lik

// COMMAND ----------

// DBTITLE 1,Invoke connect config processing
// MAGIC %run ../Utility/load_connect_config

// COMMAND ----------

// MAGIC %python
// MAGIC 
// MAGIC # Get keyvault scope and secrect key
// MAGIC 
// MAGIC connect_info = load_connect_config(config_id)
// MAGIC kv_scope=connect_info.get_kv_scope()
// MAGIC sas_key_name=connect_info.get_secret_key()
// MAGIC 
// MAGIC logger.info('>>>>>>>>>>>Key vault scope: %s', kv_scope)
// MAGIC logger.info('>>>>>>>>>>>SAS Key: %s', sas_key_name)

// COMMAND ----------

// MAGIC %python
// MAGIC 
// MAGIC #### Read configuration from process_metadata_events ###########
// MAGIC 
// MAGIC run_executor=process_executor()
// MAGIC # run_executor.get_next_config_bau(p_group_id = jobGroup, p_env = env, p_config_id = confId)
// MAGIC try :
// MAGIC   table_conf=run_executor.get_next_config_bau(p_group_id = job_group, p_env = env, p_config_id = config_id)
// MAGIC   table_conf
// MAGIC except ValueError:
// MAGIC   logger.error('Return value error!')
// MAGIC   raise ValueError
// MAGIC except Exception as e:
// MAGIC   logger.error('Some error when calling configuration!')
// MAGIC   raise e
// MAGIC   
// MAGIC else:
// MAGIC   
// MAGIC   if table_conf[0] != '0' :
// MAGIC     logger.error('Error happened when getting the pending tables. Error message is %s', table_conf[1])
// MAGIC     raise Exception(table_conf[1])
// MAGIC   
// MAGIC   run_id=table_conf[2]
// MAGIC   config_id=table_conf[3]
// MAGIC   namespace_name = table_conf[4]
// MAGIC   eventhub_name = table_conf[5]
// MAGIC   event_struct_layout = table_conf[6]
// MAGIC #   key_name = namespace_name + "--" + eventhub_name
// MAGIC #   sas_key_name="ReadOnly"
// MAGIC #   sas_key=dbutils.secrets.get(kv_scope,key_name)
// MAGIC   consumer_group = table_conf[10]
// MAGIC   target_table = table_conf[13]
// MAGIC 
// MAGIC #   try:
// MAGIC #     sas_key=dbutils.secrets.get(kv_scope,sas_key_name)
// MAGIC 
// MAGIC #   except Exception as e:
// MAGIC #     raise e
// MAGIC 
// MAGIC   logger.info('>>>>>>>>>>>Processing run ID: %s', run_id)
// MAGIC   logger.info('>>>>>>>>>>>Processing config ID: %s', config_id)
// MAGIC   logger.info('>>>>>>>>>>>Processing namespace name: %s', namespace_name)
// MAGIC   logger.info('>>>>>>>>>>>Processing eventhub name: %s', eventhub_name)
// MAGIC   logger.info('>>>>>>>>>>>Processing consumer group: %s', consumer_group)
// MAGIC   logger.info('>>>>>>>>>>>Processing target table: %s', target_table)
// MAGIC   logger.info('>>>>>>>>>>>Processing event structure: %s', event_struct_layout)

// COMMAND ----------

// MAGIC %python
// MAGIC # Build dataframe for parameter
// MAGIC 
// MAGIC from pyspark.sql import *
// MAGIC 
// MAGIC parmRow = Row(namespace_name=namespace_name, eventhub_name=eventhub_name,consumer_group=consumer_group,target_table=target_table,event_struct_layout=event_struct_layout,kv_scope=kv_scope,sas_key_name=sas_key_name)
// MAGIC parmSeq = [parmRow]
// MAGIC parmdf = spark.createDataFrame(parmSeq)
// MAGIC parmdf.show()
// MAGIC 
// MAGIC parmdf.registerTempTable("parm_table")

// COMMAND ----------

// MAGIC %scala
// MAGIC // Get parameters from dataframe
// MAGIC val scalaDF = table("parm_table")
// MAGIC // display(scalaDF)
// MAGIC 
// MAGIC val consumerGroup=scalaDF.select($"consumer_group").first.get(0).asInstanceOf[String]
// MAGIC val eventStructLayout=scalaDF.select($"event_struct_layout").first.get(0).asInstanceOf[String]
// MAGIC val eventhubName=scalaDF.select($"eventhub_name").first.get(0).asInstanceOf[String]
// MAGIC val kvScope = scalaDF.select($"kv_scope").first.get(0).asInstanceOf[String]
// MAGIC val nameSpaceName=scalaDF.select($"namespace_name").first.get(0).asInstanceOf[String]
// MAGIC val sasKeyName = scalaDF.select($"sas_key_name").first.get(0).asInstanceOf[String]
// MAGIC val targetTable=scalaDF.select($"target_table").first.get(0).asInstanceOf[String]
// MAGIC 
// MAGIC //Get SAS key from Key vault
// MAGIC 
// MAGIC val  sasKey= try{
// MAGIC     dbutils.secrets.get(kvScope,sasKeyName)
// MAGIC }catch{
// MAGIC   case ex: Exception =>{
// MAGIC             println("Get secrect error!")
// MAGIC             throw ex
// MAGIC          }
// MAGIC }
// MAGIC 
// MAGIC // println(sasKey)

// COMMAND ----------

// DBTITLE 1,Configuration
import org.apache.commons.codec.binary.Base64
//Configuration
object Constent {
  val igluConfig=
    """
      |{
      |  "schema": "iglu:com.snowplowanalytics.iglu/resolver-config/jsonschema/1-0-1",
      |  "data": {
      |    "cacheSize": 500,
      |    "repositories": [
      |      {
      |        "name": "Iglu Central",
      |        "priority": 0,
      |        "vendorPrefixes": [ "com.snowplowanalytics" ],
      |        "connection": {
      |          "http": {
      |            "uri": "http://iglucentral.com"
      |          }
      |        }
      |      },
      |      {
      |        "name": "Local Central",
      |        "priority": 1,
      |        "vendorPrefixes": [ "com.hsbc" ],
      |        "connection": {
      |          "http": {
      |            "uri": "https://sacctuatkpeakdics.z7.web.core.windows.net"
      |          }
      |        }
      |      },
      |      {
      |        "name": "Acme Iglu Repo (Embedded)",
      |        "priority": 2,
      |        "vendorPrefixes": [ "com.hsbc" ],
      |        "connection": {
      |          "embedded": {
      |            "path": "/myRepo"
      |          }
      |        }
      |      }
      |    ]
      |  }
      |}
      |
    """.stripMargin

  val enrichments=
    """
      |{
      |	"schema": "iglu:com.snowplowanalytics.snowplow/enrichments/jsonschema/1-0-0",
      |	"data": [
      |			{
      |			"schema": "iglu:com.snowplowanalytics.snowplow/referer_parser/jsonschema/1-0-0",
      |
      |			"data": {
      |
      |				"name": "referer_parser",
      |				"vendor": "com.snowplowanalytics.snowplow",
      |				"enabled": true,
      |				"parameters": {
      |					"internalDomains": []
      |				}
      |			}
      |   	}
      |	]
      |
      |}
    """.stripMargin

  val enrichmentsEmpty=
    """
      |{
      |	"schema": "iglu:com.snowplowanalytics.snowplow/enrichments/jsonschema/1-0-0",
      |	"data":[]
      |
      |}
    """.stripMargin

  val encodedIgluConfig=Base64.encodeBase64String(igluConfig.getBytes())
  val encodedenrichments=Base64.encodeBase64String(enrichments.getBytes())
  val encodedenrichmentsEmpty=Base64.encodeBase64String(enrichmentsEmpty.getBytes())
}

// COMMAND ----------

// DBTITLE 1,BuildCollectorPayLoad
import com.snowplowanalytics.snowplow.CollectorPayload.thrift.model1.CollectorPayload
import org.apache.http.HttpRequest
//Build CollectorPayLoad for erich function. The CollectorPayLoad should be generated by collector, as we replace it by Eventhub, so the fields are hardcoded or insert the reasonable value


object BuildCollectorPayLoad extends java.io.Serializable{
  val collector="EventHub"
  val path="/com.snowplowanalytics.snowplow/tp2"
  val contentType=Some("""application/json""")
  def buildEvent(
                  queryString: Option[String],
                  body: Option[String],
                  path: String,
                  userAgent: Option[String],
                  refererUri: Option[String],
                  hostname: String,
                  ipAddress: String,
                  request: HttpRequest,
                  networkUserId: String,
                  contentType: Option[String],
                  enqueuedTime:Long
                ): CollectorPayload = {
    val e = new CollectorPayload(
      "iglu:com.snowplowanalytics.snowplow/CollectorPayload/thrift/1-0-0",
      ipAddress,
      enqueuedTime,
      "UTF-8",
      collector
    )
    e.querystring = null
    body.foreach(e.body = _)
    e.path = path
    e.userAgent = null
    e.refererUri=null
    e.hostname = hostname
    e.networkUserId = networkUserId
    e.headers = null
    contentType.foreach(e.contentType = _)
    e
  }
    def buildEventFromEmpty(input:String): CollectorPayload ={

      val inputList=input.split("\u0001").toList
      val body=inputList.lift(1)
        val enqueuedTime=inputList.lift(0).getOrElse("0").toLong * 1000
      buildEvent(null,body,path,null,null,null,null,null,null,contentType,enqueuedTime)
    }

}


// COMMAND ----------

// DBTITLE 1,Singleton
import com.fasterxml.jackson.databind.JsonNode
import com.snowplowanalytics.iglu
import com.snowplowanalytics.snowplow.enrich.common.enrichments.EnrichmentRegistry
import com.snowplowanalytics.snowplow.enrich.common.utils.{ConversionUtils, JsonUtils}

// Json4s
import org.json4s.jackson.JsonMethods.fromJsonNode

// Snowplow
import com.snowplowanalytics.snowplow.enrich.common._


// Iglu
import iglu.client.Resolver
import iglu.client.validation.ProcessingMessageMethods._

/** Singletons needed for unserializable classes. */
object singleton {

  /** Singleton for Iglu's Resolver to maintain one Resolver per node. */
  object ResolverSingleton {
    @volatile private var instance: Resolver = _

    /**
     * Retrieve or build an instance of Iglu's Resolver.
     * @param igluConfig JSON representing the Iglu configuration
     */
    def get(igluConfig: String): Resolver = {
      if (instance == null) {
        synchronized {
          if (instance == null) {
            instance = getIgluResolver(igluConfig)
              .valueOr(e => throw new FatalEtlError(e.toString))
          }
        }
      }
      instance
    }

    /**
     * Build an Iglu resolver from a JSON.
     * @param json JSON representing the Iglu resolver
     * @return A Resolver or one or more error messages boxed in a Scalaz ValidationNel
     */
    private def getIgluResolver(json: String): ValidatedNelMessage[Resolver] =
      for {
        node <- base64ToJsonNode(json, "iglu").toValidationNel: ValidatedNelMessage[JsonNode]
        reso <- Resolver.parse(node)
      } yield reso
  }

  /** Singleton for EnrichmentRegistry. */
  object RegistrySingleton {
    @volatile private var instance: EnrichmentRegistry = _
    @volatile private var enrichments: String          = _

    /**
     * Retrieve or build an instance of EnrichmentRegistry.
     * @param igluConfig JSON representing the Iglu configuration
     * @param enrichments JSON representing the enrichments that need performing
     * @param local Whether to build a registry from local data
     */
    def get(igluConfig: String, enrichments: String, local: Boolean): EnrichmentRegistry = {
      if (instance == null || this.enrichments != enrichments) {
        synchronized {
          if (instance == null || this.enrichments != enrichments) {
            implicit val resolver = ResolverSingleton.get(igluConfig)
            instance = getEnrichmentRegistry(enrichments, local)
              .valueOr(e => throw new FatalEtlError(e.toString))
            this.enrichments = enrichments
          }
        }
      }
      instance
    }

    /**
     * Build an EnrichmentRegistry from the enrichments arg.
     * @param enrichments The JSON of all enrichments constructed by EmrEtlRunner
     * @param local Whether to build a registry from local data
     * @param resolver (implicit) The Iglu resolver used for schema lookup and validation
     * @return An EnrichmentRegistry or one or more error messages boxed in a Scalaz ValidationNel
     */
    private def getEnrichmentRegistry(enrichments: String, local: Boolean)(
      implicit resolver: Resolver): ValidatedNelMessage[EnrichmentRegistry] =
      for {
        node <- base64ToJsonNode(enrichments, "enrichments").toValidationNel: ValidatedNelMessage[JsonNode]
        reg <- EnrichmentRegistry.parse(fromJsonNode(node), local)
      } yield reg
  }

  /** Singleton for Loader. */
  object LoaderSingleton {
    import com.snowplowanalytics.snowplow.enrich.common.loaders.Loader
    @volatile private var instance: Loader[_] = _
    @volatile private var inFormat: String    = _

    /**
     * Retrieve or build an instance of EnrichmentRegistry.
     * @param inFormat Collector format in which the data is coming in
     */
    def get(inFormat: String): Loader[_] = {
      if (instance == null || this.inFormat != inFormat) {
        synchronized {
          if (instance == null || this.inFormat != inFormat) {
            instance = Loader
              .getLoader(inFormat)
              .valueOr(e => throw new FatalEtlError(e.toString))
            this.inFormat = inFormat
          }
        }
      }
      instance
    }
  }

  /**
   * Convert a base64-encoded JSON String into a JsonNode.
   * @param str base64-encoded JSON
   * @param field name of the field to be decoded
   * @return a JsonNode on Success, a NonEmptyList of ProcessingMessages on Failure
   */
  private def base64ToJsonNode(str: String, field: String): ValidatedMessage[JsonNode] =
    (for {
      raw  <- ConversionUtils.decodeBase64Url(field, str)
      node <- JsonUtils.extractJson(field, raw)
    } yield node).toProcessingMessage

}

// COMMAND ----------

// DBTITLE 1,Pre-define
// Define enrich function
import com.snowplowanalytics.snowplow.enrich.common.loaders.Loader
import com.snowplowanalytics.snowplow.enrich.common.outputs.{BadRow, EnrichedEvent}
import com.snowplowanalytics.snowplow.enrich.common.{EtlPipeline, ValidatedEnrichedEvent}
import org.apache.spark.SparkConf
import org.apache.spark.eventhubs.{ConnectionStringBuilder, EventHubsConf, EventPosition}
import org.apache.spark.sql.types.{LongType, StringType, TimestampType}
import org.apache.spark.sql._
import org.apache.thrift.TSerializer
import org.joda.time.DateTime
import scalaz._
  
  def enrich(line: Any): (Any, List[ValidatedEnrichedEvent]) = {
    import singleton._
    val etlVersion=s"spark-enrich-stream"
    val registry = RegistrySingleton.get(Constent.encodedIgluConfig, Constent.encodedenrichmentsEmpty, false)
    val loader   = LoaderSingleton.get("thrift").asInstanceOf[Loader[Any]]

    val event = EtlPipeline.processEvents(
      registry,
      etlVersion,
      new DateTime(System.currentTimeMillis),
      loader.toCollectorPayload(line))(ResolverSingleton.get(Constent.igluConfig))
    (line, event)
  }

// COMMAND ----------

// DBTITLE 1,Form StructType
// Get schema from paramter and form StructType
import scala.reflect.runtime.universe
import scala.tools.reflect.ToolBox
import org.apache.spark.sql._
import org.apache.spark.sql.types._

object defSchema extends java.io.Serializable{
@transient
 val tb = universe.runtimeMirror(getClass.getClassLoader).mkToolBox()

  val importCode = s"""
  |import org.apache.spark.sql._
  |import org.apache.spark.sql.types._
  """.stripMargin

//   val defSchema = importCode + "val schemaFlatten1 = "+ eventStructLayout

@transient
  val schemaFlatten3 = tb.eval(tb.parse(importCode+eventStructLayout)).asInstanceOf[org.apache.spark.sql.types.StructType]
//   val schemaFlatten3 = tb.eval(tb.parse(eventStructLayout)).asInstanceOf[org.apache.spark.sql.types.StructType]
}

// COMMAND ----------

// DBTITLE 1,Read data from EventHub
// Define the streaming reader for EventHub
import org.apache.spark.eventhubs._
import org.apache.spark.sql.types._
import org.apache.spark.sql.functions._

val connectionString = ConnectionStringBuilder()
  .setNamespaceName(nameSpaceName)
  .setEventHubName(eventhubName)
  .setSasKeyName(sasKeyName)
  .setSasKey(sasKey)
  .build

    val eventHubsConf = EventHubsConf(connectionString)
//       .setStartingPosition(EventPosition.fromStartOfStream)
      .setConsumerGroup(consumerGroup)

    val reader = spark.readStream
      .format("eventhubs")
      .options(eventHubsConf.toMap)
      .load()

val messages =
      reader
      .withColumn("Offset", $"offset".cast(LongType))
      .withColumn("Time (readable)", $"enqueuedTime".cast(TimestampType))
      .withColumn("enqueuedTime", $"enqueuedTime".cast(LongType))
      .withColumn("Body", $"body".cast(StringType))
      .select("enqueuedTime","Body")


// COMMAND ----------

// DBTITLE 1,Enriched and Flatten
// Performthe enrichment and flatten the eriched data with Snowplow SDK

import com.snowplowanalytics.snowplow.analytics.scalasdk.Event

def projectGoods(all: List[ValidatedEnrichedEvent]): List[EnrichedEvent] =
     all.collect { case Success(e) => e }
def projectBads(all: List[ValidatedEnrichedEvent]): List[NonEmptyList[String]] =
    all.collect { case Failure(errs) => errs }

val q = 
messages
.writeStream
  .foreachBatch{
    (batchDF: DataFrame, batchId: Long)=>{
      val rawEvent = batchDF.select($"enqueuedTime",$"Body").map(x => x.mkString("\u0001")).rdd
//       rawEvent.toDF().show(false)
      
// Build collector payload and pass to enrichment      
      val enrichedEvent = 
      rawEvent
//         .map(x => Option(x))
        .map(BuildCollectorPayLoad.buildEventFromEmpty(_))
        .map(new TSerializer().serialize(_))
        .map(x => enrich(x))
      
      val good = enrichedEvent
        .flatMap {case(_,enriched) => projectGoods(enriched)}
      
      val goodDF = spark
        .createDataset(good)(Encoders.bean(classOf[EnrichedEvent]))
      .toDF()
// hack to preserve the order of the fields in the csv, otherwise it's alphabetical
      .select(
      classOf[EnrichedEvent]
        .getDeclaredFields()
        .filterNot(_.getName.equals("pii"))
        .map(f => col(f.getName())): _*)

//Reformat the enriched event line and build tsv     
      val goodRdd=goodDF.na.fill("")
      .map(row => row.mkString("\t").replaceAll(":null",":\"\"").replaceAll("\\bnull\\b",""))
      .rdd

//Pass the enriched even(tsv) to SDK and flatten it      
      val goodFlatten=goodRdd
      .map(line => Event.parse(line))
      .filter(_.isValid)
      .flatMap(_.toOption)
      .map(event => event.toJson(true).noSpaces)
      
      

      val goodFlattenDf = spark.read.schema(defSchema.schemaFlatten3).json(goodFlatten)

// Write to delta table
      goodFlattenDf.write
        .format("delta")
        .mode("append")
        .save("/delta/"+targetTable)

// Writing the bad event from enrichment step      
      val bad = enrichedEvent
      .map { case (line, enriched) => (line, projectBads(enriched)) }
      .flatMap {
        case (line, errors) =>
          val originalLine = line match {
            case bytes: Array[Byte] => new String(Base64.encodeBase64(bytes), "UTF-8")
            case other              => other.toString
          }
          errors.map(e => Row(BadRow(originalLine, e).toCompactJson))
      }
    spark
      .createDataFrame(bad, StructType(StructField("_", StringType, true) :: Nil))
      .write
      .mode(SaveMode.Append)
      .text("/delta/ClickStream_Streaming/BadOut")
    }
  }
      .option("checkpointLocation", "/delta/ClickStream_Streaming/check_point1")
      .start()

// COMMAND ----------

// Create table for Clickstream and streaming status

  val createEvent = 
    """
      |CREATE TABLE IF NOT EXISTS %s
      |USING DELTA
      |LOCATION '/delta/%s'
    """.stripMargin.format(targetTable,targetTable)

println("Creating table:" + targetTable)
spark.sql(createEvent)

// COMMAND ----------

import org.apache.spark.sql.types._
import org.apache.spark.sql.functions._

val statusSchema= new StructType()
.add("batchId", LongType)
.add("durationMs", new StructType()
  .add("addBatch",LongType)
  .add("getBatch",LongType)
  .add("getOffset",LongType)
  .add("queryPlanning",LongType)
  .add("triggerExecution",LongType)
  .add("walCommit",LongType)  
)
.add("id",StringType)
.add("inputRowsPerSecond",DoubleType)
.add("name",StringType)
.add("numInputRows",LongType)
.add("processedRowsPerSecond",DoubleType)
.add("runId",StringType)
.add("sink",new StructType()
    .add("description", StringType)     
    )
.add("sources", 
    new ArrayType(
      new StructType()
        .add("description",StringType)
        .add("endOffset", new StructType()
            .add("ehub-uat-hk-peak-di", new StructType()
                 .add("0",LongType)
                 .add("1",LongType)
                )             
            )
        .add("inputRowsPerSecond",DoubleType)
        .add("numInputRows",LongType)
        .add("processedRowsPerSecond",DoubleType)
        .add("startOffset", new StructType()
            .add("0",LongType)
             .add("1",LongType)
            ),true
      )
    )
.add("stateOperators",new ArrayType(StringType,true)    
    )
.add("timestamp", StringType)



// COMMAND ----------

// Writing the status for streaming jobs. 
// Whenever the query is running, the status will keep update

Thread.sleep(60000)
while (q.isActive){
  val qJson=q.lastProgress.toString

  val queryDF = spark.read.schema(statusSchema).json(Seq(qJson).toDS)
  // queryDF.printSchema

  queryDF.write
          .format("delta")
          .mode("append")
          .save("/delta/clickstream_status")

  // Create table for Clickstream and streaming status
  val createStatus=
      """
        |CREATE TABLE IF NOT EXISTS clickstream_status
        |USING DELTA
        |LOCATION '/delta/clickstream_status'
      """.stripMargin

//   println("Creating table:clickstream_status")
  spark.sql(createStatus)  

  Thread.sleep(60000)
}


// COMMAND ----------

// MAGIC %python
// MAGIC 
// MAGIC # update job status
// MAGIC # once the stream is stopped, update the status.
// MAGIC 
// MAGIC run_executor.update_execution_status(run_id, config_id, 'stopped', 0)

// COMMAND ----------

// SDK will not output the error record?
// How to re-process the Bab record?

// Stream Monitoring
// 1. Update start/end information to status table
// 2. have a new table for stream monitoring, record name and batch processing information. Link it to tableau, monitor real time. 
// 3. Report real time to show the page moving
