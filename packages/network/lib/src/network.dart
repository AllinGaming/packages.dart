import 'dart:convert' show Encoding;
import 'package:http/http.dart' as http show Client, Request, Response;
import 'package:meta/meta.dart';
import 'package:network/src/interceptor.dart';
import 'package:network/src/request.dart';

import 'package:network/src/response.dart';
import 'package:network/src/settings.dart';
import 'package:network/src/utils/helpers.dart';
import 'package:network/src/utils/serialize_query_params.dart';

import 'methods.dart';

class Network {
  Network([http.Client client]) : client = client ?? http.Client();
  final http.Client client;

  Set<Interceptor> _interceptors = {};

  Set<Interceptor> get interceptors => _interceptors;

  Future<Response> head(
    url, {
    Map<String, String> headers,
    Map<String, dynamic> queryParameters = const {},
  }) {
    return send(
      url,
      method: HttpMethod.head,
      headers: headers,
      queryParameters: queryParameters,
    );
  }

  Future<Response> delete(
    url, {
    Map<String, String> headers,
    Map<String, dynamic> queryParameters = const {},
  }) {
    return send(
      url,
      method: HttpMethod.delete,
      headers: headers,
      queryParameters: queryParameters,
    );
  }

  Future<Response> get(
    url, {
    Map<String, String> headers,
    Map<String, dynamic> queryParameters = const {},
  }) {
    return send(
      url,
      method: HttpMethod.get,
      headers: headers,
      queryParameters: queryParameters,
    );
  }

  Future<Response> patch(
    url, {
    Map<String, String> headers,
    Object body,
    Encoding encoding,
    Map<String, dynamic> queryParameters = const {},
  }) {
    return send(
      url,
      method: HttpMethod.path,
      headers: headers,
      body: body,
      encoding: encoding,
      queryParameters: queryParameters,
    );
  }

  Future<Response> post(
    url, {
    Map<String, String> headers,
    Object body,
    Encoding encoding,
    Map<String, dynamic> queryParameters = const {},
  }) {
    return send(
      url,
      method: HttpMethod.post,
      headers: headers,
      body: body,
      encoding: encoding,
      queryParameters: queryParameters,
    );
  }

  Future<Response> put(
    url, {
    Map<String, String> headers,
    Object body,
    Encoding encoding,
    Map<String, dynamic> queryParameters = const {},
  }) {
    return send(
      url,
      method: HttpMethod.put,
      headers: headers,
      body: body,
      encoding: encoding,
      queryParameters: queryParameters,
    );
  }

  Future<Response> send(
    url, {
    @required HttpMethod method,
    Map<String, String> headers,
    Object body,
    Encoding encoding,
    Map<String, dynamic> queryParameters = const {},
  }) async {
    assert(url is Uri || url is String);
    final settings = NetworkSettings();
    final Map<String, String> allHeaders = settings.defaultHeaders;
    if (headers != null) {
      allHeaders.addAll(headers);
    }

    try {
      final request = eachInterceptorRequests(
        {...settings.interceptors, ..._interceptors},
        Request(
          headers: allHeaders,
          method: method,
          queryParameters: queryParameters,
          url: url is String ? Uri.parse(url) : url,
          encoding: encoding,
          body: body,
        ),
      );

      final http.Response httpResponse = await _sendUnstreamed(
        httpMethodString(method),
        request.url.toString() +
            serializeQueryParameters(request.queryParameters),
        body: request.body,
        headers: request.headers,
        encoding: request.encoding,
      );

      Response response = eachInterceptorResponses(
        {...settings.interceptors, ..._interceptors},
        Response(
          statusCode: httpResponse.statusCode,
          bytes: httpResponse.bodyBytes,
          request: request,
        ),
      );
      return response;
    } catch (error) {
      throw eachInterceptorErrors(
        {...settings.interceptors, ..._interceptors},
        error,
        on: method,
      );
    }
  }

  /// Sends a non-streaming [Request] and returns a non-streaming [Response].
  Future<http.Response> _sendUnstreamed(
    String method,
    url, {
    Map<String, String> headers,
    body,
    Encoding encoding,
  }) async {
    if (url is String) url = Uri.parse(url);
    http.Request request = new http.Request(method, url);

    if (headers != null) request.headers.addAll(headers);
    if (encoding != null) request.encoding = encoding;
    if (body != null) {
      if (body is String) {
        request.body = body;
      } else if (body is List) {
        request.bodyBytes = body.cast<int>();
      } else if (body is Map) {
        request.bodyFields = body.cast<String, String>();
      } else {
        throw new ArgumentError('Invalid request body "$body".');
      }
    }

    return http.Response.fromStream(await client.send(request));
  }

  void close() {
    client.close();
  }
}
