# fluent-plugin-route

[Fluentd](http://fluentd.org) output plugin to rewrite tags to route messages.

## Configuration

### Example 1: Use only tag

    <match worker.**>
      @type route
      remove_tag_prefix worker
      <route **>
        add_tag_prefix metrics.event
        copy # For fall-through. Without copy, routing is stopped here. 
      </route>
      <route **>
        add_tag_prefix backup
        copy
      </route>
    </match>

    <match metrics.event.**>
      @type stdout
    </match>

    <match backup.**>
      @type file
      path /var/log/fluent/bakcup
    </match>

### Example 2: Use label

    <match worker.**>
      @type route
      remove_tag_prefix worker
      add_tag_prefix metrics.event
      <route **>
        copy
      </route>
      <route **>
        copy
        @label @BACKUP
      </route>
    </match>

    <match metrics.event.**>
      @type stdout
    </match>

    <label @BACKUP>
      <match metrics.event.**>
        @type file
        path /var/log/fluent/bakcup
      </match>
    </label>

## TODO

* tests

## Copyright

* Copyright
  * The original version of `out_route` is written by @frsyuki.
  * TAGOMORI Satoshi (tagomoris)
* License
  * Apache License, Version 2.0
