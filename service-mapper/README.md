# T-NOVA WP3

##  UniMi Service Mapper

### Requirements

This code has been run on Ruby 2.1.
Additional include files for the mapper binary application are included in bin/include/ directory.
This package requires GLPK libraries! ( http://www.gnu.org/software/glpk/ )
This package uses jsoncons library (http://github.com/danielaparker/jsoncons) redistributed under the Boost license.


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

```
bundle install
```
Which will install all the gems.


GLPK library is required for the binary applications and it is NOT distributed within this package.
On Linux environment:

```
wget http://ftp.gnu.org/gnu/glpk/glpk-4.55.tar.gz

tar xf glpk-4.55.tar.gz

cd glpk-4.55

mkdir build

cd build

../configure

make

sudo make install
```

By default, the installer script copies the service into the /home/<username>/TeNOR-Mapper directory.
It is possible to manual install the service and compile the binary applications: a makefile is available
in the TeNOR-Mapper/bin directory.

### Tests

TODO

### API Documentation

The API is documented with yardoc and can be built with a rake task:

```
rake yard
```

from here you can use the yard server to browse the docs from the source root:

```
yard server
```

and they can be viewed from http://localhost:8808/

### Run Server

The following shows how to start the API server:

```
rake start
```

### Testing the service

The service mapper can be invoked with the following curl example:
```
curl -X POST localhost:4042/vnsd -H 'Content-Type: application/json' -d '{"NS_id":"demo1"}'
```
or by using the included html page:
test_sm.html is used in conjunction with the localhost server

### Developed by Unimi.it in 2015-2016
Alessandro Petrini (alessandro.petrini@unimi.it)
Marco Trubian
Alberto Ceselli
