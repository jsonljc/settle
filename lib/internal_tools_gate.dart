class InternalToolsGate {
  const InternalToolsGate._();

  static const String dartDefineKey = 'SETTLE_INTERNAL_TOOLS';

  // Internal tools are opt-in only and stay hidden in normal parent builds.
  static const bool enabled = bool.fromEnvironment(
    dartDefineKey,
    defaultValue: false,
  );
}
