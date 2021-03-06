# Puppet Module for Razor

## Overview

This module installs and sets up Razor.

[![Puppet Forge](http://img.shields.io/puppetforge/v/Lavaburn/razor.svg)](https://forge.puppetlabs.com/Lavaburn/razor)
[![Travis CI](http://img.shields.io/travis/Lavaburn/puppet-razor.svg)](http://travis-ci.org/Lavaburn/puppet-razor)

## Table of Contents

1. [Dependencies](#dependencies)
2. [Usage](#usage)
3. [Reference](#reference)
4. [Compatibility](#compatibility)
5. [Testing](#testing)
6. [Copyright](#copyright)


## Dependencies

The Database should be postgres >= 9.1

Modules:
- reidmv/yamlfile (REQUIRED)
  * voxpupuli/puppet-filemapper 1.1.3 - Future versions not supported at present.
- puppetlabs/stdlib (REQUIRED)
- puppetlabs/postgresql (Optional)
  * puppetlabs/apt (postgresql)
  * puppetlabs/concat (postgresql)
- puppetlabs/vcsrepo (Optional)
- puppetlabs/tftp (Optional)
  * puppetlabs/xinetd (tftp)
- maestrodev/wget (Optional/tftp)
- puppet/archive (Optional)

* If you want to set up PostgreSQL config:
  	- `include 'posgresql::server'`	[puppetlabs/postgresql]
* If you want to compile the Microkernel (on Fedora/CentOS/RHEL)
	- puppetlabs/vcsrepo module 
* If you want to set up TFTP boot files
	- `include 'wget'`
	- `class { '::tftp': }`		[puppetlabs/tftp]
* If you want to download/extract a microkernel, 
	- Do not set microkernel_url to undef. (Default : puppetlabs precompiled)
	- puppet/archive module	

## Notes

The dependency on reidmv/yamlfile is causing issues in Puppet 6. This will require a different solution.

Shiro Authentication is not fully tested. See notes in lib/puppet/provider/razo_rest.rb ?

SSL/TLS is not fully tested.


## Usage
     
It is highly recommended to put secret keys in Hiera-eyaml and use automatic parameter lookup
* [hiera-eyaml](https://github.com/TomPoulton/hiera-eyaml)
* [automatic-parameter-lookup](https://docs.puppetlabs.com/hiera/1/puppet.html#automatic-parameter-lookup)

Make sure to include all dependencies as per above.

Also see the examples/profile.pp file for an example on how to set up dependencies.   
     
```
  class { 'razor':
    db_hostname => '127.0.0.1',
    db_password => 'notasecretpassword',
    server_http_port => '8150',
  } 
```

Unfortunately Puppet does not support autorequire for classes. Hence a dependency for each of the custom types must be set to Class['razor'].
`Class['razor'] -> razor_broker...`
```
razor_broker { 'name':
  require => Class['razor'],
  ...
}
``` 
```
Razor_repo { 
  require => Class['razor'],
  ...
}
``` 

Note: you will probably need to run it twice anyway as the razor server service is very slow to start.
API calls will only start working a few minutes after the service starting.
[suggestions welcome to fix that]


## Reference

### Classes

#### razor
```
class { '::razor':
    compile_microkernel   => false,
    db_hostname           => $::fqdn,
    db_database           => 'razor',
    db_user               => 'razor',
    db_password           => 'notsecret',
}
```
This is the main class that can install client, server, database and tftp server (with microkernel download).
Additionally, on CentOS, this class can also compile the microkernel.

### Razor API
```
class { '::razor::api':
    
}
```
This class will set up configuration for the defined types.
These use the REST API provided by the Razor Server.

### Task
```
razor::task { 'task1':
  module => 'mymodule1'
}
```

### Hook Type
```
razor::hook_type { 'type1':
  module => 'mymodule1'
}
```

### Broker
```
razor::broker { 'broker1':
  module => 'mymodule1'
}
```

### Types

#### razor_broker
```
razor_broker { 'puppet-dev':
  ensure        => 'present',
  broker_type   => 'puppet',
  configuration => {
    'server'      => 'puppet',
    'environment' => 'dev'
  },
}
```
- name: The broker name
- ensure: The basic property that the resource should be in.
          Valid values are `present`, `absent`.
- broker_type: The broker type
- configuration: The broker configuration (Hash)
- provider: The specific backend to use for this `razor_broker` resource. 
            You will seldom need to specify this --- Puppet will usually
            discover the appropriate provider for your platform.
            Available providers are:
  * rest: REST provider for Razor broker

#### razor_policy
```
razor_policy { 'install_ubuntu_on_hypervisor':
  ensure        => 'present',
  repo          => 'ubuntu-14.04.1',
  task          => 'ubuntu',
  broker        => 'puppet-dev',
  hostname      => 'host${id}.test.com',
  root_password => 't3mporary',
  max_count     =>  undef,
  before_policy => 'policy0',
  node_metadata => {},
  tags          => ['small'],
}
```
- name: The policy name
- ensure: The basic property that the resource should be in.
          Valid values are `present`, `absent`.
- repo: The repository to install from
- task: The task to use to install the repo
- broker: The broker to use after installation
- hostname: The hostname to set up (use ${id} inside)
- root_password: The root password to install with
- max_count: The maximum hosts to configure (set nil for unlimited)
- after_policy: The policy after this one
- before_policy: The policy before this one
- node_metadata: The node metadata [Hash]
- tags: The tags to look for [Array]
- provider: The specific backend to use for this `razor_policy` resource. 
            You will seldom need to specify this --- Puppet will usually
            discover the appropriate provider for your platform.
            Available providers are:
  * rest: REST provider for Razor broker

#### razor_repo
```
razor_repo { 'ubuntu-14.04.1':
  ensure  => 'present',
  iso_url => 'http://releases.ubuntu.com/14.04.1/ubuntu-14.04.1-server-amd64.iso',
  task    => 'ubuntu',
}
```
- name: The repository name
- ensure: The basic property that the resource should be in.
          Valid values are `present`, `absent`.
- iso_url: The URL of the ISO to download
- url: The URL of a mirror (no downloads)
- task: The default task to perform to install the OS
- provider: The specific backend to use for this `razor_repo` resource. 
            You will seldom need to specify this --- Puppet will usually
            discover the appropriate provider for your platform.
            Available providers are:
  * rest: REST provider for Razor broker

#### razor_tag
```
razor_tag { 'small':
  ensure => 'present',
  rule   => ['=', ['fact', 'processorcount'], '1']
}
```
- name: The tag name
- ensure: The basic property that the resource should be in.
          Valid values are `present`, `absent`.
- rule: The tag rule (Array)   
- provider: The specific backend to use for this `razor_tag` resource. 
            You will seldom need to specify this --- Puppet will usually
            discover the appropriate provider for your platform.
            Available providers are:
  * rest: REST provider for Razor broker

#### razor_hook
```
razor_hook { 'a':
  ensure        => 'present',
  hook_type     => '',
  configuration => {}
}
```
- name: The hook name
- ensure: The basic property that the resource should be in.
          Valid values are `present`, `absent`.
- hook_type: The hook type (as defined with razor::hook_type)   
- configuration: A hash with hook configuration.
  
## Compatibility
* compile_microkernel only works on RHEL/CentOS/Fedora (Razor Microkernel constraint)
* enable_server requires Postgres >= 9.1

This module has been tested using Beaker with Puppet 4.3.2 (Ruby 2.1.8) on:
* Ubuntu 12.04 (complete without microkernel compilation) - Razor Server 1.0.0 to 1.5.0
* Ubuntu 14.04 (complete without microkernel compilation) - Razor Server 1.0.0 to 1.5.0
* CentOS 6.6   (complete without microkernel compilation) - Razor Server 1.0.0 to 1.5.0
* CentOS 7.2   (complete with microkernel compilation) - Razor Server 1.4.0 (!) to 1.5.0

## Testing

The use of rvm is encouraged to simulate different Ruby environments.

Setup: gem install bundler && bundle install --binstubs

### Spec test

	 rake test
	 
### Acceptance Testing

This requires some work... helpers are no longer compatible with Puppet APT repository

PREVIOUSLY - Confirmed working on Ruby 2.4.5

	rake beaker:ubuntu-12-04

Notes:
 * Possible issues with bundler: gem uninstall bundler && gem install bundler -v 1.10.6 [Vagrant 1.8.1]
 * Possible issue with vagrant "unable to mount VirtualBox shared folders": plugin install vagrant-vbguest

## Copyright

   Copyright 2017 Nicolas Truyens

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.
