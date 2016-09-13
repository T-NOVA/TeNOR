# T-NOVA WP3

##  UniMi Service Mapper

### Requirements

This code has been tested with Ruby 2.1 on Ubuntu 14.04 LTS.
Additional include files for the mapper binary application are included in bin/include/ directory.
This package requires GLPK libraries! ( http://www.gnu.org/software/glpk/ )
This package uses jsoncons library ( http://github.com/danielaparker/jsoncons ) redistributed under the Boost license.


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

Following up, a guideline on how to install on a freshly deployed VM having Ubuntu 14.04 LTS OS.

Start with:

```
sudo apt-get update

sudo apt-get install -y make g++ ruby bundler zlib1g zlib1g-devp
```

which updates the vm OS and installs the required dependencies.

GLPK library is required for the binary applications and it is NOT distributed within this package. On Linux environment:

``` 
wget http://ftp.gnu.org/gnu/glpk/glpk-4.55.tar.gz

tar xf glpk-4.55.tar.gz 

cd glpk-4.55 

mkdir build

cd build 

../configure 

make

sudo make install

sudo ldconfig
```

After the source has been cloned from the repository (this may require the installation of the git package), you can run

```
./install.sh
```

from the cloned git directory. By default, the installer script copies the service into the ~/TeNOR-Mapper directory.

It is possible to manual install the service and compile the binary applications; the following guidelines, however, assume that the content of the cloned git has been copied into the ~/TeNOR-Mapper directory.

From there, launch: 

```
bundle install
```

for downloading and configuring the required Ruby gems.

Then, from the ~/TeNOR-Mapper/bin directory, compile the binary applications:

```
make jsonconverter

make solver
```

Eventually, for solving any issue with gem dependencies, try running:

```
bundle update
```


### API Documentation
A wiki page will be available shortly.

### Run Server

The following shows how to start the API server:

```
rake start
```

### Testing the service

The service mapper can be invoked with the following curl example:
```
curl -X POST localhost:4042/mapper -H 'Content-Type: application/json' -d '{"NS_id":"demo1", "NS_sla":"gold", "NS_id":"demo1", "NS_sla":"gold", "tenor_api":"http://10.20.30.40:5454", "infr_repo_api":"http://1.2.3.4:5544"}'
```
or by using the included html page:
test_sm.html is used in conjunction with the localhost server

### Developed by Unimi.it in 2015-2016
Alessandro Petrini (alessandro.petrini@unimi.it)

Marco Trubian

Alberto Ceselli
