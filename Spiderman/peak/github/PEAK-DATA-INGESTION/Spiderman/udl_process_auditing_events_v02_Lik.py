# Databricks notebook source
class ParmError(Exception):
    def __init__(self, msg):
        self.msg = msg

# COMMAND ----------

from datetime import datetime, timedelta, date
class process_executor:

  #Function that returns the final result set that provides the next Event Hub batch to be loaded from the Group for Normal execution.
  #Takes the Group ID and Environment as inputs.
  def get_next_config_bau(self, p_group_id, p_env, p_config_id):
    #     Verify the input parameters
    valify_parm_query = "select count(1) from de_barney.test_process_metadata_events_v4 pm where group_id=%s  and environment_name = '%s' " %(p_group_id,p_env)
#     print(valify_parm_query)
    valify_parm_rc = spark.sql(valify_parm_query).rdd.first()[0]
    
    if valify_parm_rc == 0:
      raise ParmError("Error parameter group_id:%s and environment_name:%s" %(p_group_id,p_env))

    #Get the next Event Hub batch from the Group to be extracted from the Storage. If the past run for the date loaded is either failed or success, it ignores that load and gives you the date from the last successful attemnpt. If there is a cluster failure, the last known status will be 'running'; and it will re-run the job again. 
    if p_config_id == None:
      get_next_config_query = "select \
      min(pm.config_id) config_id \
      from de_barney.test_process_metadata_events_v4 pm \
      left join (select config_id from de_barney.test_process_execution_events where end_run_timestamp = date_trunc('DD', current_timestamp()) and last_known_status IN ('failed', 'success')) pe on pe.config_id = pm.config_id \
      where pm.group_id = %s and pm.active_flag = 'y' and pm.run_mode = 'batch' and pe.config_id is null and environment_name = '%s'" %(p_group_id, p_env)
      print(get_next_config_query)
      r_config_id = spark.sql(get_next_config_query).rdd.first()[0]
    else:
      r_config_id = p_config_id
    #print(r_config_id)
    if r_config_id != None:
      print(">>>>> Loading for the Config_id: %s in Evironment: %s" %(r_config_id, p_env))
      set_run_detail_return_list = self.set_run_detail(p_env=p_env, p_config_id=r_config_id, p_start_timestamp='', p_end_timestamp='', p_target_table_name='')
      get_execution_detail_return_list = self.get_execution_detail(r_config_id, set_run_detail_return_list[1], set_run_detail_return_list[2])
      r_status = ['0', 'success']
      
      #Return a list with the following details: return code, return message, run id, Config id, Event Namespace, Evemnt Hub, Strat & End Timestamp, Target Table Name
      final_return_list = r_status + [set_run_detail_return_list[0]] + get_execution_detail_return_list + set_run_detail_return_list[1:4]
      return final_return_list
    else:
      print(">>>>> Completed the loads for load Group# %s in Evironment: %s" %(p_group_id, p_env))
      r_status = ['-99', 'Nothing more to process']
      return r_status

    
  #Function that returns the final result set that provides the next Event Namespace to be loaded from the Group for Adhoc execution.
  #Takes the Environment, Event Namespace, Evemnt Hub, start/end timestamp as inputs.  
  def get_next_config_adhoc(self, p_env, p_event_namespace, p_event_hub, p_start_timestamp, p_end_timestamp, p_target_table_name):
    
  #get_next_config_query = "select min(config_id) config_id from de_barney.test_process_metadata_events_v4 where event_namespace = '%s' and event_hub = '%s' and environment_name = '%s' and run_mode = 'batch'" %(p_event_namespace, p_event_hub, p_env)
    get_next_config_query = "select min(config_id) config_id from de_barney.test_process_metadata_events_v4 pm \
     inner join de_barney.conn_config conn\
      on \
      pm.environment_name = conn.env and pm.conn_name = conn.db_name \
      where conn.event_namespace = '%s' and conn.event_hub = '%s' and pm.environment_name = '%s' and pm.run_mode = 'batch'"  %(p_event_namespace, p_event_hub, p_env)   
    
        
    #print(get_next_config_query)
    r_config_id = spark.sql(get_next_config_query).rdd.first()[0]
    if r_config_id != None:
      print(">>>>> Loading for the Config_id: %s in Evironment: %s" %(r_config_id, p_env))
      set_run_detail_return_list = self.set_run_detail(p_env=p_env, p_config_id=r_config_id, p_start_timestamp=p_start_timestamp, p_end_timestamp=p_end_timestamp, p_target_table_name=p_target_table_name)
      get_execution_detail_return_list = self.get_execution_detail(r_config_id, p_start_timestamp, p_end_timestamp)
      r_status = ['0', 'success']
      
      #Return a list with the following details: return code, return message, run id, Config id, Event Namespace, Evemnt Hub,Start/End timestamp, Target Table Name
      final_return_list = r_status + [set_run_detail_return_list[0]] + get_execution_detail_return_list + set_run_detail_return_list[1:4]
      return final_return_list
    else:
      print(">>>>> Stop Kidding. Combinaiton of the Evironment: %s - Event Namespace: %s - Event Hub: %s for batch mode doesn't exist in the configuration." %(p_env, p_event_namespace, p_event_hub))
      r_status = ['-98', 'Incorrect input combination']
      return r_status

    
  #Function that returns the run id, start/end timestamp and target table name back to the main funtction. 
  #Takes the Environment, config id as input. In case of adhoc run, it takes the start/end timestamp and target table name as inputs as well.
  def set_run_detail(self, p_env, p_config_id, p_start_timestamp, p_end_timestamp, p_target_table_name):
    #Get the run id, start/end timestamp and target table. End timestamp is determined by the last successful run.
    run_set_query = "select \
    (nvl(pe_run.max_run_id, 0) +1) run_id, \
    pm.config_id, '%s' environment_name, \
    case when '%s' != '' then to_timestamp('%s') when pm.run_frequency = 'daily' then to_timestamp(nvl(pe.end_run_timestamp, date_add(current_date(), -1))) else null end start_run_timestamp, \
    case when '%s' != '' then to_timestamp('%s') when pm.run_frequency = 'daily' then to_timestamp(current_date()) else null end end_run_timestamp, \
    case when '%s' != '' then '%s' else pm.target_table_name end target_table_name, \
    'running' last_known_status, \
    null first_processed_record_timestamp, \
    null last_processed_record_timestamp, \
    null final_records_processed, \
    current_timestamp() create_timestamp, \
    current_timestamp() update_timestamp \
    from \
    de_barney.test_process_metadata_events_v4 pm \
    left outer join (select max(run_id) run_id, max(config_id) config_id, max(end_run_timestamp) end_run_timestamp, max(environment_name) environment_name from de_barney.test_process_execution_events where last_known_status = 'success' and config_id = %s and environment_name = '%s') pe on (pm.config_id = pe.config_id and pm.environment_name = pe.environment_name)\
    left outer join (select max(run_id) max_run_id, max(config_id) config_id, max(environment_name) environment_name from de_barney.test_process_execution_events where config_id = %s and environment_name = '%s') pe_run on (pm.config_id = pe_run.config_id and pm.environment_name = pe_run.environment_name) \
    where pm.config_id = %s" %(p_env, p_start_timestamp, p_start_timestamp, p_end_timestamp, p_end_timestamp, p_target_table_name, p_target_table_name, p_config_id, p_env, p_config_id, p_env, p_config_id)
    #print(run_set_query)
    run_set_query_sqldf = spark.sql(run_set_query)
    run_set_query_sqldf.show()
    r_run_id = str(run_set_query_sqldf.rdd.first()[0])
    r_config_id = str(run_set_query_sqldf.rdd.first()[1])
    r_start_timestamp = str(run_set_query_sqldf.rdd.first()[3])
    r_end_timestamp = str(run_set_query_sqldf.rdd.first()[4])
    r_target_table_name = str(run_set_query_sqldf.rdd.first()[5])
    run_set_query_sqldf.write.format("delta").mode("append").saveAsTable("de_barney.test_process_execution_events")
    return [r_run_id, r_start_timestamp, r_end_timestamp, r_target_table_name]

  
  #Function that returns the Event metadata to connect to the read replica to extract the table content. This has the table/database name, parallel threads and where clasue predicate. 
  #Takes the Environment, config id as input. In case of adhoc run, it takes the start/end timestamp and target table name as inputs as well.
  def get_execution_detail(self, p_config_id,p_start_timestamp, p_end_timestamp):
#     table_metadata_query = "select \
#     event_namespace, event_hub, event_struct_layout, event_storage_account, event_container_name, event_folder_location, event_consumer_group\
#     from de_barney.test_process_metadata_events_v4 \
#     where config_id = %s" %(p_config_id)
    
    table_metadata_query = "select \
    conn.event_namespace, conn.event_hub, pm.event_struct_layout, conn.event_storage_account, conn.event_container_name, conn.event_folder_location, conn.event_consumer_group \
    from de_barney.test_process_metadata_events_v4 pm \
    inner join de_barney.conn_config conn\
    on \
    pm.environment_name = conn.env and pm.conn_name = conn.db_name \
    where config_id = %s" %(p_config_id)
    
    #print(table_metadata_query)
    r_config_id = p_config_id
    
    r_metadata_info=spark.sql(table_metadata_query).rdd.first()
    
    if len(r_metadata_info.asDict()) == 0:
      print(">>>>> Getting connection config for config_id: %s and conn_name: %s is failed !" %(p_config_id))
      raise Exception("Get connection information error!")
    else:

      r_event_namespace = r_metadata_info[0]
      r_event_hub = r_metadata_info[1]
      r_event_struct_layout = r_metadata_info[2]
      r_event_storage_account = r_metadata_info[3]
      r_event_container_name = r_metadata_info[4]
      r_event_folder_location = r_metadata_info[5]
      r_event_consumer_group = r_metadata_info[6]
      return [r_config_id, r_event_namespace, r_event_hub, r_event_struct_layout, r_event_storage_account, r_event_container_name, r_event_folder_location, r_event_consumer_group]

  #Function that updates the table with the final execution details. 
  #Takes the run id, status and the # of records processed as inputs.
  def update_execution_status(self, p_run_id, p_config_id, p_last_known_status, p_final_records_processed):
    update_status_query = "UPDATE de_barney.test_process_execution_events SET last_known_status = '%s', final_records_processed = %s, update_timestamp = current_timestamp() WHERE config_id = %s and run_id = %s" %(p_last_known_status, p_final_records_processed, p_config_id, p_run_id)
    #print(update_status_query)
    spark.sql(update_status_query)
    r_status = ['0', 'success']
    return r_status

# COMMAND ----------

#Unit testing for adhoc
# run_executor=process_executor()
# run_executor.get_next_config_adhoc(p_env='dev', p_event_namespace='ehubns-uat-hk-peak-di', p_event_hub='fpstesting', p_start_timestamp='2019-03-19 00:20:33', p_end_timestamp='2019-03-21 00:00:00', p_target_table_name = '/delta/fps_batch_test1')

# COMMAND ----------

# Unit testing get_execution_detail
# run_executor=process_executor()
# # run_executor.get_execution_detail(3)
# run_executor.get_next_config_bau(0, "UAT",3)


# COMMAND ----------

#Unit testing for Batch events 
# run_executor=process_executor()
# run_executor.get_next_config_bau(p_group_id = '0', p_env = 'dev', p_config_id = '3')

# COMMAND ----------

#execution for stream events 
# run_executor=process_executor()
# run_executor.get_next_config_bau(p_group_id = '1', p_env = 'dev', p_config_id = None)

# COMMAND ----------

# run_executor=process_executor()
# run_executor.update_execution_status('12', '4', 'success', 'null', 'null', 'null')
