# Databricks notebook source
# Function to call connection config
class load_connect_config():
      
  def __init__(self, p_config_id):
    table_metadata_query = "select \
    conn.kv_scope, conn.secret_url \
    from de_barney.test_process_metadata_events_v4 pm \
    inner join de_barney.conn_config conn\
    on \
    pm.environment_name = conn.env and pm.conn_name = conn.db_name \
    where config_id = %s" %(p_config_id)

    r_conn_info=spark.sql(table_metadata_query).rdd.first()

    self.kv_scope = r_conn_info[0]
    self.secrect_key = r_conn_info[1]
  
  def get_kv_scope(self):    
    return self.kv_scope
  
  def get_secret_key(self):
    return self.secrect_key

# COMMAND ----------

# connect_info = load_connect_config(3)
# connect_info.get_kv_scope()
