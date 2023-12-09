// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:convert/convert.dart';
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;
import 'package:pharaoh/pharaoh.dart';

import 'utils.dart';

/// The default resolver for MIME types based on file extensions.
final _defaultMimeTypeResolver = MimeTypeResolver();

/// Creates [Middleware] that serves files from the provided
/// [rootdir].
///
/// Accessing a path containing symbolic links will succeed only if the resolved
/// path is within [rootdir]. To allow access to paths outside of
/// [rootdir], set [serveFilesOutsidePath] to `true`.
///
/// When a existing directory is requested and a [defaultDocument] is specified
/// the directory is checked for a file with that name. If it exists, it is
/// served.
///
/// If [useHeaderBytesForContentType] is `true`, the contents of the
/// file will be used along with the file path to determine the content type.
///
/// Specify a custom [contentTypeResolver] to customize automatic content type
/// detection.
Middleware createStaticHandler(
  String rootdir, {
  bool serveFilesOutsidePath = false,
  bool fallthrough = true,
  String? defaultDocument,
  bool useHeaderBytesForContentType = false,
  MimeTypeResolver? contentTypeResolver,
}) {
  final rootDir = Directory(rootdir);
  if (!rootDir.existsSync()) {
    throw PharaohException.value(
        'A directory corresponding to fileSystemPath not found', rootdir);
  }

  rootdir = rootDir.resolveSymbolicLinksSync();

  if (defaultDocument != null) {
    if (defaultDocument != p.basename(defaultDocument)) {
      throw PharaohException('defaultDocument must be a file name.');
    }
  }

  final mimeResolver = contentTypeResolver ?? _defaultMimeTypeResolver;

  return (request, res, next) async {
    if (![HTTPMethod.GET, HTTPMethod.HEAD].contains(request.method)) {
      if (fallthrough) return next();
      return next(res
          .status(HttpStatus.methodNotAllowed)
          .header(HttpHeaders.acceptHeader, 'GET, HEAD')
          .end());
    }

    final uri = request.uri;
    final segs = [rootdir, ...uri.pathSegments];

    final fsPath = p.joinAll(segs);
    final entityType = FileSystemEntity.typeSync(fsPath);

    File? fileFound;

    if (entityType == FileSystemEntityType.file) {
      fileFound = File(fsPath);
    } else if (entityType == FileSystemEntityType.directory) {
      fileFound = _tryDefaultFile(fsPath, defaultDocument);
    }

    if (fileFound == null) {
      return next(res.notFound('File not found on path $uri'));
    }

    final file = fileFound;

    if (!serveFilesOutsidePath) {
      final resolvedPath = file.resolveSymbolicLinksSync();

      // Do not serve a file outside of the original fileSystemPath
      if (!p.isWithin(rootdir, resolvedPath)) {
        return next(res.notFound());
      }
    }

    // when serving the default document for a directory, if the requested
    // path doesn't end with '/', redirect to the path with a trailing '/'
    if (entityType == FileSystemEntityType.directory && !uri.path.endsWith('/')) {
      return next(_redirectToAddTrailingSlash(res, uri));
    }

    Future<String?>? getContentType() async {
      if (useHeaderBytesForContentType) {
        final length = math.min(mimeResolver.magicNumbersMaxLength, file.lengthSync());

        final byteSink = ByteAccumulatorSink();

        await file.openRead(0, length).listen(byteSink.add).asFuture<void>();

        return mimeResolver.lookup(file.path, headerBytes: byteSink.bytes);
      } else {
        return mimeResolver.lookup(file.path);
      }
    }

    final response = await _handleFile((req: request, res: res), file, getContentType);

    next(response);
  };
}

Response _redirectToAddTrailingSlash(Response res, Uri uri) {
  final location = Uri(
      scheme: uri.scheme,
      userInfo: uri.userInfo,
      host: uri.host,
      port: uri.port,
      path: '${uri.path}/',
      query: uri.query);
  return res.movedPermanently(location.toString());
}

File? _tryDefaultFile(String dirPath, String? defaultFile) {
  if (defaultFile == null) return null;

  final filePath = p.join(dirPath, defaultFile);

  final file = File(filePath);

  if (file.existsSync()) {
    return file;
  }

  return null;
}

/// Creates a middleware [Middleware] that serves the file at [path].
///
/// This returns a 404 response for any requests whose [Request.url] doesn't
/// match [url]. The [url] defaults to the basename of [path].
///
/// This uses the given [contentType] for the Content-Type header. It defaults
/// to looking up a content type based on [path]'s file extension, and failing
/// that doesn't sent a [contentType] header at all.
Middleware createFileHandler(String path, {String? url, String? contentType}) {
  final file = File(path);
  if (!file.existsSync()) {
    throw PharaohException.value('Path does not exist.', path);
  } else if (url != null && !p.url.isRelative(url)) {
    throw PharaohException.value('Url must be relative.', url);
  }

  final mimeType = contentType ?? _defaultMimeTypeResolver.lookup(path);
  url ??= p.toUri(p.basename(path)).toString();

  return (req, res, next) {
    if (req.uri.path != url) return res.notFound('Not Found');
    return _handleFile((req: req, res: res), file, () => mimeType);
  };
}

/// Serves the contents of [file] in response to [request].
///
/// This handles caching, and sends a 304 Not Modified response if the request
/// indicates that it has the latest version of a file. Otherwise, it calls
/// [getContentType] and uses it to populate the Content-Type header.
Future<Response> _handleFile(
  ReqRes reqRes,
  File file,
  FutureOr<String?> Function() getContentType,
) async {
  final request = reqRes.req;
  final response = reqRes.res;
  final stat = file.statSync();
  final ifModifiedSince = request.ifModifiedSince;

  if (ifModifiedSince != null) {
    final fileChangeAtSecResolution = toSecondResolution(stat.modified);
    if (!fileChangeAtSecResolution.isAfter(ifModifiedSince)) {
      return response.notModified();
    }
  }

  final contentType = await getContentType();

  final headers = {
    HttpHeaders.lastModifiedHeader: formatHttpDate(stat.modified),
    HttpHeaders.acceptRangesHeader: 'bytes',
    if (contentType != null) HttpHeaders.contentTypeHeader: contentType,
  };

  final fileRangeResponse = _fileRangeResponse(
    (req: request, res: response),
    file,
    headers,
  );
  if (fileRangeResponse != null) return fileRangeResponse;

  final body = request.method == HTTPMethod.HEAD ? Body(null) : Body(file.openRead());
  response.body = body;
  return response.header(HttpHeaders.contentLengthHeader, '${stat.size}').end();
}

final _bytesMatcher = RegExp(r'^bytes=(\d*)-(\d*)$');

/// Serves a range of [file], if [request] is valid 'bytes' range request.
///
/// If the request does not specify a range, specifies a range of the wrong
/// type, or has a syntactic error the range is ignored and `null` is returned.
///
/// If the range request is valid but the file is not long enough to include the
/// start of the range a range not satisfiable response is returned.
///
/// Ranges that end past the end of the file are truncated.
Response? _fileRangeResponse(
  ReqRes reqRes,
  File file,
  Map<String, dynamic> headers,
) {
  final request = reqRes.req;
  final response = reqRes.res;
  final range = request.headers[HttpHeaders.rangeHeader];
  if (range == null) return null;
  final matches = _bytesMatcher.firstMatch(range);
  // Ignore ranges other than bytes
  if (matches == null) return null;

  final actualLength = file.lengthSync();
  final startMatch = matches[1]!;
  final endMatch = matches[2]!;
  if (startMatch.isEmpty && endMatch.isEmpty) return null;

  int start; // First byte position - inclusive.
  int end; // Last byte position - inclusive.
  if (startMatch.isEmpty) {
    start = actualLength - int.parse(endMatch);
    if (start < 0) start = 0;
    end = actualLength - 1;
  } else {
    start = int.parse(startMatch);
    end = endMatch.isEmpty ? actualLength - 1 : int.parse(endMatch);
  }

  // If the range is syntactically invalid the Range header
  // MUST be ignored (RFC 2616 section 14.35.1).
  if (start > end) return null;

  if (end >= actualLength) {
    end = actualLength - 1;
  }
  if (start >= actualLength) {
    Response res = response;
    headers.forEach((key, value) => res = response.header(key, value));
    return res.status(HttpStatus.requestedRangeNotSatisfiable).end();
  }

  final headerUpdate = response.headers;
  headerUpdate[HttpHeaders.contentLengthHeader] = (end - start + 1).toString();
  headerUpdate[HttpHeaders.contentRangeHeader] = 'bytes $start-$end/$actualLength';

  final body =
      request.method == HTTPMethod.HEAD ? null : Body(file.openRead(start, end + 1));
  response.body = body;

  Response res = response;
  headers.forEach((key, value) => res = response.header(key, value));

  return res.status(HttpStatus.partialContent).end();
}
