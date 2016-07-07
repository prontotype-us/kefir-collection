Kefir = require 'kefir'
KefirBus = require 'kefir-bus'
deepAssign = require 'deep-assign'

module.exports = makeCollectionStream = (items) ->
    _collection$ = KefirBus()

    collection$ = _collection$.toProperty()
    collection$.emit = _collection$.emit

    # Keep last_items on collection$
    collection$.onValue (_items) ->
        collection$.last_items = _items

    # Individual streams per item
    collection$.item$s = {}
    collection$.getItem = (item_id) ->
        if !(item$ = collection$.item$s[item_id])
            _item$ = KefirBus()
            item$ = _item$.toProperty()
            item$.emit = _item$.emit
            item$.onValue -> # NOOP to activate property
            collection$.item$s[item_id] = item$
        return item$

    collection$.setItem = (item_id, item) ->
        item$ = collection$.getItem item_id
        item$.emit item
        return item$

    # Update an item by finding it in items and emitting on both overall and individual stream
    collection$.updateItem = (item_id, update) ->
        items = collection$.last_items
        item = items.filter((item) -> item._id == item_id)[0]
        return if !item? # TODO: Handle nonexistent items
        deepAssign item, update
        item$ = collection$.getItem(item_id)
        collection$.emit items
        item$.emit item
        return item$

    # Create an item by adding it to items and creating a stream for it
    collection$.createItem = (new_item) ->
        items = collection$.last_items
        items.push new_item
        collection$.emit items
        return collection$.setItem new_item._id, new_item

    # Remove an item from items
    collection$.removeItem = (item_id) ->
        items = collection$.last_items
        items = items.filter((item) -> item._id != item_id)
        collection$.emit items
        return collection$

    # Add initial items and return
    collection$.emit items
    items.map (item) ->
        item$ = collection$.setItem(item._id, item)
    return collection$

