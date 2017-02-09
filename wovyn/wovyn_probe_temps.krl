ruleset wovyn_probe_temps {
  meta {
    shares __testing, temps
  }
  global {
    __testing = { "queries": [ { "name": "__testing" },
                               { "name": "temps" } ],
                  "events": [ ] }
    temps = function() {
      ent:probeTemps
    }
  }

  // catch and record temperature
  rule record_temperature {
    select when wovyn new_temperature_reading
    pre {
      temperatureData = event:attr("readings")
      timestamp = event:attr("timestamp")
      new_entry = { "timestamp": timestamp,
                    "temperatureF": temperatureData[0]{"temperatureF"} }
      updated_temps = ent:probeTemps.defaultsTo([]).append(new_entry)
    }
    always {
     ent:probeTemps := updated_temps
    }
  }

}
