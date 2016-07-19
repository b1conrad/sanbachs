ruleset manageChildren {
  meta {
    name "Manage Children"
    description <<
A ruleset using Wrangler to manage children
>>
    logging on
    use module v1_wrangler alias wrangler
    author "Bruce Conrad"
    sharing on
    provides children
  }
  global {
    children = function() {
      wrangler:children();
    }
  }
  rule createAChild {
    select when pico_systems child_requested
    pre{
      random_name = "Test_Child_" + math:random(999);
      name = event:attr("name").defaultsTo(random_name);
    }
    {
      wrangler:createChild(name);
      send_directive("ack") with
        name = name;
    }
    always{
      log("created child named " + name);
    }
  }
}
