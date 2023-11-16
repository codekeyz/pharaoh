# Examples

### API Service

API service with a database access, secured with `:api-key` using a Middleware on PATH: `/api` and 3 has routes.

- GET: `/api/users`
- GET: `/api/repos`
- GET: `/api/user/:name/repos`

[Jump to Source](https://github.com/codekeyz/pharaoh/tree/main/pharaoh_examples/lib/api_service/index.dart)

### Route Groups

API service with two route groups `/guest` and `/admin`.

- Group: `/admin`
- Group: `/guest`

[Jump to Source](https://github.com/codekeyz/pharaoh/tree/main/pharaoh_examples/lib/route_groups/index.dart)

### Middleware

API service with Logger Middleware that logs every request that hits our server.

[Jump to Source](https://github.com/codekeyz/pharaoh/tree/main/pharaoh_examples/lib/middleware/index.dart)

### Shelf Middleware with Pharaoh

Add CORS to our Pharaoah server using [shelf_cors_headers](https://pub.dev/packages/shelf_cors_headers)

[Jump to Source](https://github.com/codekeyz/pharaoh/tree/main/pharaoh_examples/lib/shelf_middleware/index.dart)

### Serve Webpages and Files

[Jump to Source](https://github.com/codekeyz/pharaoh/tree/main/pharaoh_examples/lib/serve_files/index.dart)
