Kefir = require 'kefir'
KefirBus = require 'kefir-bus'

assign = (old_object, new_object) ->
    for k, v of new_object
        old_object[k] = v
    old_object

sortBy = (key) -> (o1, o2) ->
    o1[key] - o2[key]

mergeArrays = (old_array, new_array, id_key, sort_key) ->
    old_array ||= []
    sort_key ||= id_key
    merged_array = []
    items_by_id = {}
    new_items = []
    for item in old_array
        items_by_id[item[id_key]] = item
    for item in new_array
        if existing_item = items_by_id[item[id_key]]
            assign existing_item, item
        else
            items_by_id[item[id_key]] = item
            new_items.push item
    for item_id, item of items_by_id
        merged_array.push item
    merged_array.sort(sortBy sort_key)
    return [merged_array, new_items]

module.exports = makeCollectionStream = (initial_items=null, options={}) ->
    items = initial_items || []
    {id_key, sort_key} = options
    id_key ||= 'id'

    _collection$ = KefirBus()

    collection$ = _collection$.toProperty()
    collection$.emit = _collection$.emit

    collection$.plug = (items$) ->
        items$.onValue (items) ->
            collection$.setItems items, true

    # Keep last_items on collection$
    collection$.onValue (_items) ->
        collection$.last_items = _items

    collection$.filterItems = (filter) ->
        collection$.map (items) ->
            items.filter filter

    collection$._getItem = (item_id) ->
        items.filter((item) -> item[id_key] == item_id)[0]

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

    collection$.setItems = (items, append=false) ->
        if append
            [all_items, new_items] = mergeArrays collection$.last_items, items, id_key, sort_key
            collection$.emit all_items

            new_items.map (item) ->
                item$ = collection$.setItem(item)

        else
            collection$.emit items

            items.map (item) ->
                item$ = collection$.setItem(item)

    collection$.setItem = (item) ->
        item$ = collection$.getItem item[id_key]
        item$.emit item
        return item$

    # Update an item by finding it in items and emitting on both overall and individual stream
    collection$.updateItem = (item_id, update) ->
        items = collection$.last_items
        item = collection$._getItem item_id

        if !item?
            update[id_key] = item_id
            return collection$.createItem update

        assign item, update
        item$ = collection$.getItem(item_id)
        collection$.emit items
        item$.emit item
        return item$

    # Create an item by adding it to items and creating a stream for it
    collection$.createItem = (new_item) ->
        items = collection$.last_items
        items.push new_item
        collection$.emit items
        return collection$.setItem new_item

    # Remove an item from items
    collection$.removeItem = (item_id) ->
        items = collection$.last_items
        items = items.filter (item) -> item[id_key] != item_id
        collection$.emit items
        return collection$

    # Add initial items and return
    if initial_items?
        collection$.setItems initial_items
    return collection$

