# fluent-plugin-route

[Fluentd](http://fluentd.org) output plugin to rewrite tags to route messages.

## Configuration

Configuration example:

    <match worker.**>
      type route
      remove_tag_prefix worker
      <route **>
        add_tag_prefix metrics.event
        copy
      </route>
      <route **>
        add_tag_prefix backup
        copy
      </route>
    </match>

    <match metrics.event.**>
      type stdout
    </match>

    <match backup.**>
      type file
      path /var/log/fluent/bakcup
    </match>

## TODO

* tests

## Copyright

* Copyright
  * The original version of `out_route` is written by @frsyuki.
  * TAGOMORI Satoshi (tagomoris)
* License
  * Apache License, Version 2.0
