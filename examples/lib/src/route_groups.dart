import 'package:pharaoh/pharaoh.dart';

/// these two objects will serve as our faux database
final repos = [
  {"name": 'express', "url": 'https://github.com/expressjs/express'},
  {"name": 'stylus', "url": 'https://github.com/learnboost/stylus'},
  {"name": 'cluster', "url": 'https://github.com/learnboost/cluster'}
];

final app = Pharaoh();

void main() async {
  final repoRouter = app.router()
    ..get('/repos', (req, res) => res.json(repos))
    ..post('/create', (req, res) async {
      // do some fake loading
      await Future.delayed(const Duration(seconds: 1));

      repos.add(repos.last);

      return res.json(repos);
    })
    ..delete('/delete/:index', (req, res) async {
      final index = int.tryParse(req.params['index']);
      if (index == null) {
        return res.status(422).json('Index is either invalid or not provided');
      }

      // do some fake loading
      await Future.delayed(const Duration(seconds: 1));

      repos.removeAt(index);

      return res.json(repos);
    });

  app.group('/github', repoRouter);

  app.get('/version', (req, res) => res.ok('1.0.0'));

  await app.listen();
}
