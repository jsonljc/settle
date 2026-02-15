import 'package:flutter_test/flutter_test.dart';
import 'package:settle/services/safety_compliance_service.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  test('safety compliance checklist is fully mapped', () async {
    final snapshot = await const SafetyComplianceService().loadChecklist();

    expect(snapshot.items, hasLength(4));
    expect(
      snapshot.items.every((item) => item.passed),
      isTrue,
      reason:
          'All v1 safety/compliance controls should map to evidence bindings.',
    );
  });
}
