# encounter-ruby

Encounter-ruby is lib that provides a common interface for
collecting information from [en.cx](http://en.cx) or [quest.ua](http://quest.ua)
sites.

## Documentation

## Usage examples

### Collect player information

```ruby
require 'encounter'

connection = Encounter::Connection.new(
  domain: 'by.en.cx',
  username: 'user',
  password: 'password'
)

player = Encounter::Player.new(
  connection,
  uid: 1
)
```

### Collect domain announces

```ruby
require 'encounter'

connection = Encounter::Connection.new(
  domain: 'by.en.cx',
  username: 'user',
  password: 'password'
)

domain = Encounter::Domain.new(connection, 'by.en.cx')

announces = domain.announces
```

### Collect game information

```ruby
require 'encounter'

connection = Encounter::Connection.new(
  domain: 'by.en.cx',
  username: 'user',
  password: 'password'
)

domain = Encounter::Game.new(connection, domain: '')
```
