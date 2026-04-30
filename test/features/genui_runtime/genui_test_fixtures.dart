import 'package:zaoapp/features/genui_runtime/genui_mini_app_package.dart';

const validSurfaceMessages = <Map<String, Object?>>[
  {
    'surfaceUpdate': {
      'surfaceId': 'surface_test',
      'components': [
        {
          'id': 'root',
          'component': {
            'Column': {
              'children': {
                'explicitList': ['title', 'body'],
              },
            },
          },
        },
        {
          'id': 'title',
          'component': {
            'Text': {
              'text': {'literalString': '测试小应用'},
              'usageHint': 'h3',
            },
          },
        },
        {
          'id': 'body',
          'component': {
            'Text': {
              'text': {'literalString': '由 GenUI surface 渲染'},
            },
          },
        },
      ],
    },
  },
  {
    'beginRendering': {'surfaceId': 'surface_test', 'root': 'root'},
  },
];

GenUiMiniAppPackage validPackage({
  String id = 'app_1',
  String name = '测试小应用',
  String prompt = '生成一个测试小应用',
  List<Map<String, Object?>> surfaceJson = validSurfaceMessages,
}) => GenUiMiniAppPackage(
  id: id,
  schemaVersion: 1,
  appVersion: 1,
  name: name,
  prompt: prompt,
  surfaceJson: surfaceJson,
  runtimeData: const {},
  savedAt: DateTime.utc(2026, 4, 30, 1),
  updatedAt: DateTime.utc(2026, 4, 30, 2),
);
