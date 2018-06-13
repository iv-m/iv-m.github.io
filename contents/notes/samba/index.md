---
title: Samba development notes
date: 2018-05-29 12:00
template: article.jade
---

[[toc]]

## Development documentation

Links, 2, 3, 4...

https://wiki.samba.org/index.php/Development_Resources

Protocol documentation from Microsoft, now freely available:
https://msdn.microsoft.com/en-us/openspecifications/dn646763.aspx
Keyword to search in MSDN: WSSP (Workgroup Server Protocol Program)


## TDB file format

In short:

    if TDB_FEATURE_FLAG_MUTEX:
        tdb_mutexes:
            tdb_header
            allrecords_mutex
            allrecord_lock          // the type of the lock, short int
            mutexes[hash_size + 1]  // free list + one for each bucket
    tdb_header                      // repeated if there are mutexes; it's RO anyway
    offsets[hash_size + 1]          // same as mutexes: #0 is for free list, then one for each bucket
    records[...]:
        tdb_record
        key
        data

Records are aligned, so one cannot assume one record follows another.

Records are allocated 25% larger than strictly required, to reduce
the fragmentation. So typically the size of the record is larger
then `sizeof(*rec) + rec->key_size + rec->data_size`. It's never
smaller, obviously.

TDB file format is defined, in addition to the above map, by
the following `struct`s:

* `tdb_header`
* `tdb_mutexes` (not interesting)
* `tdb_record`

These structures are read directly from file into the memory
(`__attribute__((packed))`, where are you?), and, if required,
converted to respect the endianness.
