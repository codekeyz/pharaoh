# Examples

### API Service

API service with a database access, secured with `:api-key` using a Middleware on PATH: `/api` and 3 has routes.

- GET: `/api/users`
- GET: `/api/repos`
- GET: `/api/user/:name/repos`

[Jump to Source](https://github.com/Pharaoh-Framework/pharaoh/blob/main/pharaoh_examples/lib/api_service/index.dart)

### Route Groups

API service with two route groups `/guest` and `/admin`.

- Group: `/admin`
- Group: `/guest`

[Jump to Source](https://github.com/Pharaoh-Framework/pharaoh/tree/main/pharaoh_examples/lib/route_groups/index.dart)

### Middleware

API service with Logger Middleware that logs every request that hits our server.

[Jump to Source](https://github.com/Pharaoh-Framework/pharaoh/blob/main/pharaoh_examples/lib/middleware/index.dart)

### CORS with Shelf Middleware

Add CORS to our Pharaoah server using [shelf_cors_headers](https://pub.dev/packages/shelf_cors_headers)

[Jump to Source](https://github.com/Pharaoh-Framework/pharaoh/blob/main/pharaoh_examples/lib/shelf_middleware/cors.dart)

### Helmet with Pharaoh (Shelf Middleware)

Use Helmet with Pharaoah [shelf_helmet](https://pub.dev/packages/shelf_helmet)

[Jump to Source](https://github.com/Pharaoh-Framework/pharaoh/blob/main/pharaoh_examples/lib/shelf_middleware/helmet.dart)

### Serve Webpages and Files 1

Serve a Webpage, and files using Pharaoh

[Jump to Source](https://github.com/Pharaoh-Framework/pharaoh/blob/main/pharaoh_examples/lib/serve_files_1/index.dart)

### Serve Webpages and Files 2

Serve a Webpage, favicon and Image using [shelf_static](https://pub.dev/packages/shelf_static)

[Jump to Source](https://github.com/Pharaoh-Framework/pharaoh/blob/main/pharaoh_examples/lib/serve_files_2/index.dart)
