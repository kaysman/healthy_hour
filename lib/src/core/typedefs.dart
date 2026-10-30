typedef Json = Map<String, dynamic>;

typedef AsyncCallback = Future<void> Function();

/// Source of the current time. Injected so time-driven code can be tested
/// without waiting in real time.
typedef Clock = DateTime Function();
