# PocketBase Collections Schema

## Collection: users (System Collection - cập nhật)

### Additional Fields cần thêm:
- `username` (text) - Tên người dùng duy nhất
- `name` (text) - Tên hiển thị
- `avatar` (file) - Ảnh đại diện (optional)
- `lastLogin` (text) - Thời gian đăng nhập cuối
- `emailVisibility` (bool) - Hiển thị email hay không
- `verified` (bool) - Tài khoản đã xác thực chưa

### API Rules cho users collection:
- **View**: `id = @request.auth.id`
- **Update**: `id = @request.auth.id`

## Collection: user_backups

### Fields:
- `id` (text) - Auto-generated ID
- `user_id` (text) - ID của user (relation tới users collection)
- `backup_data` (text) - JSON string chứa dữ liệu backup
- `backup_version` (text) - Phiên bản format backup
- `app_version` (text) - Phiên bản app tại thời điểm backup
- `created_at` (text) - Timestamp tạo backup
- `created` (datetime) - Auto timestamp từ PocketBase
- `updated` (datetime) - Auto timestamp từ PocketBase

### API Rules:
- **List/Search**: `@request.auth.id != "" && user_id = @request.auth.id`
- **View**: `@request.auth.id != "" && user_id = @request.auth.id`
- **Create**: `@request.auth.id != "" && @request.data.user_id = @request.auth.id`
- **Update**: `@request.auth.id != "" && user_id = @request.auth.id`
- **Delete**: `@request.auth.id != "" && user_id = @request.auth.id`

### Indexes:
- `user_id` - để query nhanh backup của từng user
- `created` - để sort theo thời gian

### Sample PocketBase Admin Console Commands:

1. Tạo collection mới tên `user_backups`
2. Thêm các fields như trên
3. Set API rules như trên
4. Tạo indexes

### Migration Script (nếu dùng PocketBase migrations):

```javascript
migrate((db) => {
  const collection = new Collection({
    "id": "user_backups",
    "name": "user_backups",
    "type": "base",
    "system": false,
    "schema": [
      {
        "system": false,
        "id": "user_id",
        "name": "user_id",
        "type": "text",
        "required": true,
        "options": {
          "min": null,
          "max": null,
          "pattern": ""
        }
      },
      {
        "system": false,
        "id": "backup_data",
        "name": "backup_data",
        "type": "text",
        "required": true,
        "options": {
          "min": null,
          "max": null,
          "pattern": ""
        }
      },
      {
        "system": false,
        "id": "backup_version",
        "name": "backup_version",
        "type": "text",
        "required": false,
        "options": {
          "min": null,
          "max": null,
          "pattern": ""
        }
      },
      {
        "system": false,
        "id": "app_version",
        "name": "app_version",
        "type": "text",
        "required": false,
        "options": {
          "min": null,
          "max": null,
          "pattern": ""
        }
      },
      {
        "system": false,
        "id": "created_at",
        "name": "created_at",
        "type": "text",
        "required": false,
        "options": {
          "min": null,
          "max": null,
          "pattern": ""
        }
      }
    ],
    "listRule": "@request.auth.id != \"\" && user_id = @request.auth.id",
    "viewRule": "@request.auth.id != \"\" && user_id = @request.auth.id",
    "createRule": "@request.auth.id != \"\" && @request.data.user_id = @request.auth.id",
    "updateRule": "@request.auth.id != \"\" && user_id = @request.auth.id",
    "deleteRule": "@request.auth.id != \"\" && user_id = @request.auth.id"
  })

  return Dao(db).saveCollection(collection)
})
```

### Cách sử dụng:

1. Start PocketBase server
2. Vào Admin UI (thường là http://127.0.0.1:8090/_/)
3. Tạo collection mới với schema trên
4. Hoặc chạy migration script nếu dùng PocketBase CLI

### Lưu ý:
- Collection này sẽ lưu trữ backup data dưới dạng JSON string
- Mỗi user chỉ có thể truy cập backup của chính họ
- Data được backup bao gồm: settings, user preferences, playlists, v.v.