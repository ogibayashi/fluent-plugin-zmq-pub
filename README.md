# fluent-plugin-zmq-pub

## Overview

Fluentd plugin to publish records to ZeroMQ.

## Build & Install

This plugin is not registerd to official rubygems. 

`rake build
fluent-gem zmq
fluent-gem install ./pkg/fluent-plugin-zmq-pub-0.0.1.gem --local
`

## Configuration

`pubkey <%tag%>:<%key1%>
bindaddr tcp://*:5556
`

* 'pubkey' specifies the publish key to ZeroMQ. 
  * '<%tag%>' is replace by fluentd tag. '<%name%>' is replaced by fluentd record['name']. 
  * Actual record to be published is '<pubkey> <reocord.to_msgpack>'.
  * Subscriber can subscribe by '<pubkey>'.

## Copyright

* Copyright (c) 2013- Hironori Ogibayashi
* License
  * Apache License, Version 2.0
