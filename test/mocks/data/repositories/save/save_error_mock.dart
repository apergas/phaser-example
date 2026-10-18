abstract final class SaveErrorMock {
  static const FormatException brokenJson = FormatException('Unexpected end of input');

  static final StateError storageFailure = StateError('storage failure');
}
