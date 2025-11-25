# Documentation Updates for Advanced Filtering Feature

## Summary

Updated all documentation to reflect the new advanced JSON filtering capabilities added in PGMQ v1.9.0.

## Files Updated

### 1. `docs/api/sql/functions.md`
- **Updated `read()` function documentation:**
  - Added detailed explanation of two filter formats (simple containment vs advanced filtering)
  - Documented all supported operators: `>`, `>=`, `<`, `<=`, `=`, `!=`, `<>`, `exists`
  - Added examples for each operator type
  - Documented nested field access using dot notation
  - Removed "experimental" warning (feature is now stable)

- **Updated `read_with_poll()` function documentation:**
  - Added reference to advanced filtering capabilities
  - Added example with advanced filter
  - Removed "experimental" warning

### 2. `pgmq-extension/README.md` (and main `README.md` via symlink)
- **Added new section: "Read messages with advanced filtering"**
  - Examples of simple containment (backward compatible)
  - Examples of advanced filtering with comparison operators
  - List of supported operators
  - Nested field access examples
  - Multiple practical examples

- **Updated Features section:**
  - Added bullet point about advanced JSON filtering

## Documentation Structure

### Filter Formats

1. **Simple Containment** (backward compatible):
   ```json
   {"field": "value"}
   ```
   Uses JSONB `@>` operator for containment matching.

2. **Advanced Filtering**:
   ```json
   {"field": "field_name", "operator": ">", "value": 4}
   ```
   Supports comparison operators and nested fields.

### Supported Operators

| Operator | Description | Example |
|----------|-------------|---------|
| `>` | Greater than (numeric) | `{"field": "age", "operator": ">", "value": 20}` |
| `>=` | Greater than or equal (numeric) | `{"field": "score", "operator": ">=", "value": 85}` |
| `<` | Less than (numeric) | `{"field": "age", "operator": "<", "value": 30}` |
| `<=` | Less than or equal (numeric) | `{"field": "price", "operator": "<=", "value": 100}` |
| `=` | Equal (numeric or text) | `{"field": "status", "operator": "=", "value": "active"}` |
| `!=` or `<>` | Not equal (numeric or text) | `{"field": "status", "operator": "!=", "value": "deleted"}` |
| `exists` | Field exists check | `{"field": "priority", "operator": "exists"}` |

### Nested Fields

Nested JSON fields can be accessed using dot notation:
- `"user.age"` accesses `message->'user'->>'age'`
- `"user.address.city"` accesses nested paths

Example:
```sql
SELECT * FROM pgmq.read('queue', 30, 10, 
  '{"field": "user.age", "operator": ">", "value": 30}');
```

## Examples Added

### Basic Filtering
- Simple containment: `{"status": "active"}`
- Numeric comparison: `{"field": "age", "operator": ">", "value": 20}`
- String comparison: `{"field": "status", "operator": "=", "value": "pending"}`
- Field existence: `{"field": "priority", "operator": "exists"}`

### Advanced Use Cases
- Nested field filtering: `{"field": "user.age", "operator": ">", "value": 30}`
- Score-based filtering: `{"field": "score", "operator": ">=", "value": 85}`
- Status filtering: `{"field": "status", "operator": "=", "value": "active"}`

## Backward Compatibility

All documentation emphasizes that:
- Simple containment format (`{"field": "value"}`) remains fully supported
- Existing code using simple containment will continue to work
- Advanced filtering is an optional enhancement

## Verification

To verify documentation is complete:
1. ✅ Function signatures documented
2. ✅ All operators listed with examples
3. ✅ Nested field access explained
4. ✅ Backward compatibility noted
5. ✅ Examples for common use cases
6. ✅ README updated with feature highlight
7. ✅ API documentation updated

## Next Steps

The documentation is now complete and ready for the v1.9.0 release. Users can:
- Understand the new filtering capabilities
- See practical examples for each operator
- Learn about nested field access
- Know that existing code remains compatible

