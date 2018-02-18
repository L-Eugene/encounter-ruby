# encounter-ruby

Encounter-ruby is lib that provides a common interface for
collecting information from [en.cx](http://en.cx) or [quest.ua](http://quest.ua)
sites.

## Documentation

## Usage example

```require 'encounter'

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

### Collect player information

### Collect game information