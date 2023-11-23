# Shelf Interoperability

Before jumping into building Pharaoh, I realized there was already a large pool of `shelf` middlewares that could do most of the things I thought I'd have needed to write so i wrote an adapter to allow you use them directly with `Pharaoh`.

Here's a list of libraries that I personally have tested and confirmed to work with `Pharaoh` through the `useShelfMiddleware` hook.

- [Shelf Cors Headers](https://pub.dev/packages/shelf_cors_headers) -> [see example](https://github.com/codekeyz/pharaoh/tree/main/pharaoh_examples/lib/shelf_middleware/cors.dart)

- [Shelf Static](https://pub.dev/packages/shelf_static) -> [see example](https://github.com/codekeyz/pharaoh/tree/main/pharaoh_examples/lib/serve_files_2/index.dart)

- [Shelf Helmet](https://pub.dev/packages/shelf_helmet) -> [see example](https://github.com/codekeyz/pharaoh/tree/main/pharaoh_examples/lib/shelf_middleware/helmet.dart)

## Contributors ✨

You can try out other shelf libraries and verify that they work and send in a PR to update this doc. If you do find any that doesn't work too, please raise an issue and I might look into that.
