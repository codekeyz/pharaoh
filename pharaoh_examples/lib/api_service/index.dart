import 'package:pharaoh/pharaoh.dart';

/// map of valid api keys, typically mapped to
/// account info with some sort of database like redis.
/// api keys do _not_ serve as authentication, merely to
/// track API usage or help prevent malicious behavior etc.
var apiKeys = ['foo', 'bar', 'baz'];

/// these two objects will serve as our faux database
var repos = [
  {"name": 'express', "url": 'https://github.com/expressjs/express'},
  {"name": 'stylus', "url": 'https://github.com/learnboost/stylus'},
  {"name": 'cluster', "url": 'https://github.com/learnboost/cluster'}
];

var users = [
  {"name": 'tobi'},
  {"name": 'loki'},
  {"name": 'jane'}
];

var userRepos = {
  "tobi": [repos[0], repos[1]],
  "loki": [repos[1]],
  "jane": [repos[2]]
};

final app = Pharaoh();

void main([args]) async {
  final port = List.from(args).isEmpty ? 3000 : args[0];

  /// if we wanted to supply more than JSON, we could
  /// use something similar to the content-negotiation
  /// example.
  /// here we validate the API key,
  /// by mounting this middleware to /api
  /// meaning only paths prefixed with "/api"
  /// will cause this middleware to be invoked
  app.on('/api', (req, res, next) {
    var key = req.query['api-key'];

    /// key isn't present
    if (key == null) {
      next(res.status(400).json('API key required'));
      return;
    }

    /// key is invalid
    if (!apiKeys.contains(key)) {
      next(res.status(401).json('Invalid API key'));
      return;
    }

    req['key'] = key;

    next(req);
  });

  /// we now can assume the api key is valid,
  /// and simply expose the data
  /// example: http://localhost:3000/api/users/?api-key=foo
  app.get('/api/users', (req, res) => res.json(users));

  /// example: http://localhost:3000/api/repos/?api-key=foo
  app.get('/api/repos', (req, res) => res.json(repos));

  /// example: http://localhost:3000/api/user/tobi/repos/?api-key=foo
  app.get('/api/user/<name>/repos', (req, res) {
    var name = req.params['name'];
    var user = userRepos[name];

    if (user != null) {
      return res.json(user);
    }

    return res.notFound();
  });

  await app.listen(port: port);
}
