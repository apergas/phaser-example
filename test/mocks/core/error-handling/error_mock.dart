abstract final class ErrorMock {
  static final StateError unexpected = StateError('boom');

  static final StateError diskUnavailable = StateError('disk unavailable');

  static final StateError storageUnavailable = StateError('storage unavailable');
}
