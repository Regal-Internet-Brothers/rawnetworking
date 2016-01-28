# transport

## Description

A low-level networking module meant to abstract internet transport behavior, but not protocol behavior. This is in contrast to '[regal.networking](https://github.com/Regal-Internet-Brothers/networking)', which handles higher-level concepts like clients, connections and disconnections, and packet reliability to name a few.

The '[regal.networking](https://github.com/Regal-Internet-Brothers/networking)' module is tightly connected to the rest of [the 'regal' modules](https://github.com/Regal-Internet-Brothers/regal-modules), this is not. Everything supplied here is based on the 'brl' modules, and related technologies.

## Usage Notes

* When communicating, please realize that data is as-is, meaning byte-order and other details are not accounted for.

* The 'Packet' type defined in this module does not reflect '[regal.networking](https://github.com/Regal-Internet-Brothers/networking)' and its expected behavior. **A packet that has been sent asynchronously cannot be used while in transit**. This means you can't write one message, then send it to multiple places asynchronously. However, if sent synchronously ('Send'), this limitation does not affect transfer.

* Multi-target requirements are met internally, but must be upheld by users. Everything asynchronous in 'brl.socket' is used when possible. This means there's no implied discrepancies in this module.

* Connected "users" are handled internally, but only for minimum behavior. They are not referenced directly, only through asynchronous bootstrapping. This means the 'NetUser' objects given to you are created on the spot, and should be managed by the programmer using this module.
