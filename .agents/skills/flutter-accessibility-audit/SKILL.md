---
name: flutter-accessibility-audit
description: Triggers an accessibility scan through the widget_inspector and automatically adds Semantics widgets or missing labels to the source code.
metadata:
  model: models/gemini-3.1-pro-preview
  last_modified: Tue, 21 Apr 2026 21:57:55 GMT
---
# Implementing Flutter Accessibility

## Contents
- [Managing Semantics](#managing-semantics)
- [Auditing Accessibility](#auditing-accessibility)
- [Debugging the Semantics Tree](#debugging-the-semantics-tree)
- [Examples](#examples)

## Managing Semantics

Rely on Flutter's standard widgets (e.g., `TabBar`, `MenuAnchor`) for automatic semantic role assignment whenever possible. When building custom components or overriding default behaviors, explicitly define the UI element's purpose using the `Semantics` widget.

*   Wrap custom UI components in a `Semantics` widget.
*   Assign the appropriate `SemanticsRole` enum value to the `role` property to define the element's purpose (e.g., button, list, heading).
*   If building for Flutter Web, note that Flutter translates these roles into corresponding ARIA roles in the HTML DOM.
*   Enable web accessibility explicitly. It is disabled by default for performance. Either instruct users to press the invisible `aria-label="Enable accessibility"` button, or force it programmatically in your `main()` function.

## Auditing Accessibility

Implement the following workflows to verify that your application meets accessibility standards. 

### Task Progress: Platform-Specific Scanning
Copy this checklist to track your manual auditing progress across target platforms:

- [ ] **If testing on Android:** 
  1. Install the Accessibility Scanner from Google Play.
  2. Enable it via **Settings > Accessibility > Accessibility Scanner > On**.
  3. Tap the Accessibility Scanner checkmark icon over your running app to initiate the scan.
- [ ] **If testing on iOS:** 
  1. Open the `ios` folder in Xcode and run the app on a Simulator.
  2. Navigate to **Xcode > Open Developer Tools > Accessibility Inspector**.
  3. Select **Inspection > Enable Point to Inspect** and click UI elements to verify attributes.
  4. Select **Audit > Run Audit** to generate an issue report.
- [ ] **If testing on Web:** 
  1. Open Chrome DevTools.
  2. Inspect the HTML tree under the `semantics host` node.
  3. Navigate to the **Elements** tab and open the **Accessibility** sub-tab to inspect exported ARIA data.
  4. Visualize semantic nodes by running the app with: `flutter run -d chrome --profile --dart-define=FLUTTER_WEB_DEBUG_SHOW_SEMANTICS=true`.

### Task Progress: Automated Testing
Integrate Flutter's Accessibility Guideline API into your widget tests to catch contrast, target size, and labeling issues automatically.

- [ ] Create a dedicated test file (e.g., `test/a11y_test.dart`).
- [ ] Initialize the semantics handle using `tester.ensureSemantics()`.
- [ ] Assert against `androidTapTargetGuideline` (48x48px minimum).
- [ ] Assert against `iOSTapTargetGuideline` (44x44px minimum).
- [ ] Assert against `labeledTapTargetGuideline`.
- [ ] Assert against `textContrastGuideline` (3:1 minimum for large text).
- [ ] Dispose of the semantics handle at the end of the test.

## Debugging the Semantics Tree

When semantic nodes are incorrectly placed or missing, execute the following feedback loop to identify and resolve the discrepancies.

1. **Run validator:** Trigger a dump of the Semantics tree to the console.
   * Enable accessibility via a system tool or `SemanticsDebugger`.
   * Invoke `debugDumpSemanticsTree()` (e.g., bind it to a `GestureDetector`'s `onTap` callback for easy triggering during debugging).
2. **Review errors:** Analyze the console output to locate missing labels, incorrect roles, or improperly nested semantic nodes.
3. **Fix:** Wrap the offending widgets in `Semantics` or `MergeSemantics` widgets, apply the correct `SemanticsRole`, and repeat step 1 until the tree accurately reflects the visual UI.

## Examples

### Programmatically Enabling Web Accessibility
Force the Semantics tree to build immediately on Flutter Web.

```dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

void main() {
  runApp(const MyApp());
  if (kIsWeb) {
    SemanticsBinding.instance.ensureSemantics();
  }
}
```

### Explicitly Defining Semantic Roles
Assign explicit list and list-item roles to a custom layout.

```dart
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

class MyCustomListWidget extends StatelessWidget {
  const MyCustomListWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Semantics(
      role: SemanticsRole.list,
      explicitChildNodes: true,
      child: Column(
        children: <Widget>[
          Semantics(
            role: SemanticsRole.listItem,
            child: const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text('Content of the first custom list item.'),
            ),
          ),
          Semantics(
            role: SemanticsRole.listItem,
            child: const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text('Content of the second custom list item.'),
            ),
          ),
        ],
      ),
    );
  }
}
```

### Automated Accessibility Testing
Implement the Accessibility Guideline API in a widget test.

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:your_accessible_app/main.dart';

void main() {
  testWidgets('Follows a11y guidelines', (tester) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    await tester.pumpWidget(const AccessibleApp());

    // Check tap target sizes
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));

    // Check labels and contrast
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
    
    handle.dispose();
  });
}
```
