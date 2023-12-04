import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:http/http.dart' as http;

import 'expectation.dart';

typedef HttpFutureResponse = Future<http.Response>;

HttpResponseExpection expectHttp(HttpFutureResponse value) =>
    HttpResponseExpection(value);

typedef GetValueFromResponse<T> = T Function(http.Response response);

typedef MatchCase = ({GetValueFromResponse value, dynamic matcher});

class HttpResponseExpection
    extends ExpectationBase<HttpFutureResponse, http.Response> {
  HttpResponseExpection(super.value);

  final List<MatchCase> _matchcases = [];

  HttpResponseExpection expectHeader(String header, dynamic matcher) {
    final MatchCase test =
        (value: (resp) => resp.headers[header], matcher: matcher);
    _matchcases.add(test);
    return this;
  }

  HttpResponseExpection expectContentType(dynamic matcher) {
    final MatchCase test = (
      value: (resp) => resp.headers[HttpHeaders.contentTypeHeader],
      matcher: matcher
    );
    _matchcases.add(test);
    return this;
  }

  HttpResponseExpection expectHeaders(dynamic matcher) {
    final MatchCase test = (value: (resp) => resp.headers, matcher: matcher);
    _matchcases.add(test);
    return this;
  }

  HttpResponseExpection expectStatus(dynamic matcher) {
    final MatchCase test = (value: (resp) => resp.statusCode, matcher: matcher);
    _matchcases.add(test);
    return this;
  }

  HttpResponseExpection expectBody(dynamic matcher) {
    if (matcher is! Matcher && matcher is! String) {
      matcher = jsonEncode(matcher);
    }

    final MatchCase value = (value: (resp) => resp.body, matcher: matcher);
    _matchcases.add(value);
    return this;
  }

  HttpResponseExpection expectBodyCustom<T>(
    T Function(String body) getValue,
    dynamic matcher,
  ) {
    final MatchCase value = (
      value: (resp) => getValue(resp.body),
      matcher: matcher,
    );
    _matchcases.add(value);
    return this;
  }

  HttpResponseExpection custom(GetValueFromResponse check, Matcher matcher) {
    final MatchCase value = (value: check, matcher: matcher);
    _matchcases.add(value);
    return this;
  }

  @override
  Future<void> test() async {
    final response = await actual;

    // ignore: no_leading_underscores_for_local_identifiers
    for (final _case in _matchcases) {
      expect(_case.value(response), _case.matcher);
    }
  }
}
