import 'package:pharaoh/pharaoh.dart';

var app = Pharaoh();

void main() async {
  app.use(logRequests);

  // app.get("/", (req, res) => res.ok("Working on context policy"));
  app.get("/here", (req, res) => res.ok("Here Working on context policy"));

//  TODO FIX LOGGER TO LOG ACCEPT MEDIATYPE
  app.get(
    "/get_me",
    (req, res) => res.format({
      'text/plain': (res) => res.ok("Hey, there!"),
      'text/html': (res) => res.send("<h1> Hey, there!</h1>"),
      '_': (res) => res.json("{ message: 'Hey, there!'}"),
    }),
  );

  app.get(
    "/commit",
    (req, res) => res.format({
      'text/plain': (res) => res.ok('hey'),
      'text/html': (res) => res.send('<p>hey</p>'),
      '_': (res) => res.json("{ message: 'hey' }"),
    }),
  );

  await app.listen();
}
