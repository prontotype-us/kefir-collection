# kefir-collection

Stream helper for managing a collection of items that may be updated, added and removed.

## Install

```
npm install kefir-collection
```

## Usage

Create a collection stream with `KefirCollection(items)`. This stream has a few helper functions for managing items:

* `setItems(item_id, merge=false)` Sets the collection's items, optionally merging with existing items
* `getItem(item_id)` Returns a stream for an individual item
* `updateItem(item_id, update)` Updates the item, returns individual stream for the updated item
* `createItem(new_item)` Creates a new item, returns individual stream for the created item
* `removeItem(item_id)` Removes an item, returns the overall items stream

## Example

```coffee
KefirCollection = require 'kefir-collection'

items$ = KefirCollection [
    {_id: 123, name: "Test"},
    {_id: 425, name: "Jones"},
    {_id: 850, name: "Frank"}
]

items$.onValue (items) ->
    console.log '\n[items]', items

items$.getItem(123).onValue (item) ->
    console.log '\n[item 123]', item

# Run some operations

items$.updateItem 123, name: "Hello"

create$ = items$.createItem {_id: 999, name: "Ok"}

create$.onValue (item) ->
    console.log '\n[new item]', item

items$.removeItem 850
```

```
[items] [ { _id: 123, name: 'Test' },
  { _id: 425, name: 'Jones' },
  { _id: 850, name: 'Frank' } ]

[item 123] { _id: 123, name: 'Test' }

[items] [ { _id: 123, name: 'Hello' },
  { _id: 425, name: 'Jones' },
  { _id: 850, name: 'Frank' } ]

[item 123] { _id: 123, name: 'Hello' }

[items] [ { _id: 123, name: 'Hello' },
  { _id: 425, name: 'Jones' },
  { _id: 850, name: 'Frank' },
  { _id: 999, name: 'Ok' } ]

[new item] { _id: 999, name: 'Ok' }

[items] [ { _id: 123, name: 'Hello' },
  { _id: 425, name: 'Jones' },
  { _id: 999, name: 'Ok' } ]
```

