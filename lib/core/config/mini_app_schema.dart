const Map<String, Object?> miniAppSchema = {
  r'$schema': 'http://json-schema.org/draft-07/schema#',
  'type': 'object',
  'required': ['id', 'schemaVersion', 'appVersion', 'name', 'type'],
  'additionalProperties': false,
  'properties': {
    'id': {'type': 'string', 'minLength': 1},
    'schemaVersion': {
      'type': 'integer',
      'enum': [1],
    },
    'appVersion': {'type': 'integer', 'minimum': 1},
    'name': {'type': 'string', 'minLength': 1},
    'type': {
      'type': 'string',
      'enum': ['todo_list', 'habit_tracker', 'countdown', 'expense_tracker'],
    },
    'theme': {
      'type': 'object',
      'additionalProperties': false,
      'properties': {
        'color': {'type': 'string', 'minLength': 1},
        'icon': {'type': 'string', 'minLength': 1},
      },
    },
    'fields': {
      'type': 'array',
      'items': {
        'type': 'object',
        'required': ['key', 'label', 'type'],
        'additionalProperties': false,
        'properties': {
          'key': {'type': 'string', 'minLength': 1},
          'label': {'type': 'string', 'minLength': 1},
          'type': {
            'type': 'string',
            'enum': [
              'text',
              'multiline_text',
              'number',
              'date',
              'select',
              'switch',
            ],
          },
          'options': {
            'type': 'array',
            'items': {'type': 'string', 'minLength': 1},
          },
        },
      },
    },
  },
};
