ruleset wovyn_router {
  meta {
    shares __testing, lastHeartbeat, lastHumidity, lastTemperature, lastPressure
  }
  global {
    __testing = { "queries": [ { "name": "__testing" } ],
                  "events": [ ] }

    // configuration
    healthy_battery_level = 20

    // internal functions
    sensorData = function(path) {
     gtd = event:attr("genericThing")
  	     .defaultsTo({})
	     .klog("Sensor Data: ");
     path.isnull() => gtd | gtd{path}
	     
    }

    // API functions
    lastHeartbeat = function() {
      ent:lastHeartbeat.klog("Return value ")
    }

    lastHumidity = function() {
      ent:lastHumidity
    }
    
    lastTemperature = function() {
      ent:lastProbeTemperature
    }
    
    lastPressure = function() {
      ent:lastPressure
    }
    
  }

  // mostly for debugging; see all data from last heartbeat
  rule receive_heartbeat {
    select when wovyn heartbeat
    pre {
      sensor_data = event:attrs()

    }
    always {
      ent:lastHeartbeat := sensor_data;
      ent:lastTimestamp := time:now()
    }
  }

  // check battery level
  rule check_battery {
    select when wovyn heartbeat
    pre {
      sensor_data = sensorData()
      sensor_id = event:attr("emitterGUID")
      sensor_properties = event:attr("property")
    }
    if (sensor_data{"healthPercent"}) < healthy_battery_level then noop()
    fired {
      "Battery is low".klog("");
      raise wovyn event "battery_level_low"
        with sensor_id = sensor_id
	     properties = sensor_properties
	     health_percent = sensor_data{"healthPercent"}
	     timestamp = time:now()
    } else {
      "Battery is fine".klog("")    
    }
  }

  // route all readings from the sensor array
  rule route_readings {
    select when wovyn heartbeat
    foreach sensorData(["data"]) setting (sensor_readings , sensor_type)
      pre {
	event_name = ("new_" + sensor_type + "_reading").klog("Event ")
      }
      always {
	raise wovyn event event_name attributes
	  {"readings":  sensor_readings,
	   "sensor_id": event:attr("emitterGUID"),
  	   "timestamp": time:now()
	  }
      }
  }

  // catch and store humidity
  rule catch_humidity {
    select when wovyn new_humidity_reading
    pre {
      humidityData = event:attr("readings")
      not_used = event:attrs().klog("humidity event attributes")
    }
    always {
     ent:lastHumidity := humidityData[0]
    }
  }

  // catch and store temperature
  rule catch_temperature {
    select when wovyn new_temperature_reading
    pre {
      temperatureData = event:attr("readings")
    }
    always {
     ent:lastAmbientTemperature := temperatureData[1];
     ent:lastProbeTemperature := temperatureData[0]
    }
  }

  // catch and store pressure
  rule catch_pressure {
    select when wovyn new_pressure_reading
    pre {
      pressureData = event:attr("readings")
    }
    always {
     ent:lastPressure := pressureData[0]
    }
  }
}
