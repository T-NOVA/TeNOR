# T-NOVA WP3

## Orchestrator VNFD Validator

### Requirements

This code has been run on Ruby 2.1.

### Gems used

* [Sinatra](http://www.sinatrarb.com/) - Ruby framework
* [Thin](https://github.com/macournoyer/thin/) - Web server
* [json](https://github.com/flori/json) - JSON specification
* [sinatra-contrib](https://github.com/sinatra/sinatra-contrib) - Sinatra extensions
* [Nokogiri](https://github.com/sparklemotion/nokogiri) - XML parser
* [JSON-schema](https://github.com/ruby-json-schema/json-schema) - JSON schema validator
* [Rest-client](https://github.com/rest-client/rest-client) - HTTP and REST client
* [Yard](https://github.com/lsegal/yard) - Documentation generator tool
* [rerun](https://github.com/alexch/rerun) - Restarts the app when a file changes (used in development environment)

### Installation

After you cloned the source from the repository, you can run

```sh
bundle install
```

Which will install all the gems.

### Tests

TODO

### API Documentation

The API is documented with yardoc and can be built with a rake task:

```sh
rake yard
```

from here you can use the yard server to browse the docs from the source root:

```sh
yard server
```

and they can be viewed from http://localhost:8808/

### Run Server

The following shows how to start the API server:

```sh
rake start
```
