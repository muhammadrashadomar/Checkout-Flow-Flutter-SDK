/// Pins the PaymentBridge contracts the pay button depends on: `submit()`
/// resolves with this submission's token or none (a Remember Me card), and
/// fails instead of waiting forever when native reports an error or never
/// answers. Also pins that card height reports reach only their own view.
library;

import 'dart:async';

import 'package:checkout_flow_flutter_sdk/checkout_flow_flutter_sdk.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const _channel = MethodChannel('checkout_bridge');

/// Delivers a call from "native" to the bridge, as the platform views do.
Future<void> _nativeSends(String method, [Object? arguments]) {
  final message = const StandardMethodCodec().encodeMethodCall(
    MethodCall(method, arguments),
  );
  return TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .handlePlatformMessage(_channel.name, message, (_) {});
}

/// Answers `getSessionData` the way the native card view does: it returns at
/// once and replies later through callbacks.
void _onGetSessionData(List<(String, Object?)> replies) {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(_channel, (call) async {
        if (call.method == 'getSessionData') {
          scheduleMicrotask(() async {
            for (final (method, arguments) in replies) {
              await _nativeSends(method, arguments);
            }
          });
        }
        return {'status': 'processing'};
      });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final bridge = PaymentBridge();

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, null);
    bridge.clearCallbacks();
  });

  group('submit(card)', () {
    test('returns the token sent before the session data', () async {
      _onGetSessionData([
        (
          'cardTokenized',
          {
            'tokenDetails': {
              'token': 'tok_1',
              'last4': '4242',
              'bin': '424242',
            },
          },
        ),
        ('sessionDataReady', {'sessionData': 'session-1'}),
      ]);

      final result = await bridge.submit(CurrentPaymentType.card);

      expect(result.sessionData, 'session-1');
      expect(result.token?.token, 'tok_1');
    });

    test('returns no token for a card without one (Remember Me)', () async {
      _onGetSessionData([
        ('sessionDataReady', {'sessionData': 'session-rm'}),
      ]);

      final result = await bridge.submit(CurrentPaymentType.card);

      expect(result.sessionData, 'session-rm');
      expect(result.token, isNull);
    });

    test('fails with the native error instead of waiting', () async {
      _onGetSessionData([
        (
          'paymentError',
          {'errorCode': 'CHECKOUT_ERROR', 'errorMessage': 'componentInvalid'},
        ),
      ]);

      await expectLater(
        bridge.submit(CurrentPaymentType.card),
        throwsA(
          isA<PlatformException>().having(
            (e) => e.code,
            'code',
            'CHECKOUT_ERROR',
          ),
        ),
      );
    });

    test('fails with TIMEOUT when native never answers', () {
      fakeAsync((async) {
        _onGetSessionData([]);
        Object? error;
        bridge.submit(CurrentPaymentType.card).catchError((Object e) {
          error = e;
          return SessionResult(token: null, sessionData: '');
        });

        async.elapse(
          PaymentBridge.nativeCallbackTimeout + const Duration(seconds: 1),
        );

        expect(
          error,
          isA<PlatformException>().having((e) => e.code, 'code', 'TIMEOUT'),
        );
      });
    });

    test('handles an error that arrives before the native call returns, '
        'and reports it once', () async {
      // Android answers getSessionData only after Checkout's submit()
      // returns, so its callbacks can come first.
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(_channel, (call) async {
            await _nativeSends('paymentError', {
              'errorCode': 'CHECKOUT_ERROR',
              'errorMessage': 'componentInvalid',
            });
            return {'status': 'processing'};
          });
      final reportedErrors = <PaymentErrorResult>[];
      bridge.onPaymentError = reportedErrors.add;

      await expectLater(
        bridge.submit(CurrentPaymentType.card),
        throwsA(isA<PlatformException>()),
      );
      expect(reportedErrors, hasLength(1));
    });

    test('fails with TIMEOUT when the native call itself never returns', () {
      fakeAsync((async) {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(
              _channel,
              (call) => Completer<Object?>().future,
            );
        Object? error;
        bridge.submit(CurrentPaymentType.card).catchError((Object e) {
          error = e;
          return SessionResult(token: null, sessionData: '');
        });

        async.elapse(
          PaymentBridge.nativeCallbackTimeout + const Duration(seconds: 1),
        );

        expect(
          error,
          isA<PlatformException>().having((e) => e.code, 'code', 'TIMEOUT'),
        );
      });
    });

    test('restores the callbacks it borrowed', () async {
      void sessionListener(String _) {}
      void errorListener(PaymentErrorResult _) {}
      bridge
        ..onSessionData = sessionListener
        ..onPaymentError = errorListener;
      _onGetSessionData([
        ('sessionDataReady', {'sessionData': 'session-2'}),
      ]);

      await bridge.submit(CurrentPaymentType.card);

      expect(bridge.onSessionData, same(sessionListener));
      expect(bridge.onPaymentError, same(errorListener));
    });
  });

  group('card height', () {
    test('reaches only the listener of the view that reported it', () async {
      final heightsA = <double>[];
      final heightsB = <double>[];
      bridge
        ..setCardHeightListener(1, heightsA.add)
        ..setCardHeightListener(2, heightsB.add);

      await _nativeSends('heightChanged', {'height': 180.0, 'viewId': 1});

      expect(heightsA, [180.0]);
      expect(heightsB, isEmpty);

      bridge
        ..setCardHeightListener(1, null)
        ..setCardHeightListener(2, null);
    });

    test('gives a late listener the last reported height', () async {
      await _nativeSends('heightChanged', {'height': 240.0, 'viewId': 3});

      final heights = <double>[];
      bridge.setCardHeightListener(3, heights.add);

      expect(heights, [240.0]);
      bridge.setCardHeightListener(3, null);
    });
  });
}
