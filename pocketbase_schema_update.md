# Cập nhật Schema PocketBase cho Musify

## Thêm trường musicPreferences vào bảng user_backups

Để lưu trữ thể loại nhạc ưa thích của người dùng, cần thêm một trường mới vào bảng `user_backups` trong PocketBase:

```js
{
  "id": "user_backups",
  "name": "user_backups",
  "type": "base",
  "schema": [
    // Các trường hiện có
    {
      "id": "musicPreferences",
      "name": "musicPreferences",
      "type": "json",
      "system": false,
      "required": false,
      "options": {}
    }
  ]
}
```

## Cấu trúc dữ liệu JSON của trường musicPreferences

Trường `musicPreferences` sẽ lưu trữ dữ liệu dưới dạng JSON với cấu trúc sau:

```json
{
  "favoriteGenres": [
    {
      "id": "pop",
      "name": "Pop",
      "description": "Nhạc đại chúng, phổ biến toàn cầu",
      "iconUrl": "https://example.com/icons/pop.png",
      "isSelected": true
    },
    {
      "id": "rock",
      "name": "Rock",
      "description": "Nhạc rock với guitar và trống nổi bật",
      "iconUrl": "https://example.com/icons/rock.png",
      "isSelected": true
    }
  ],
  "lastUpdated": "2025-09-27T10:30:00.000Z"
}
```

## Quan hệ với bảng users

Bảng `user_backups` nên có một trường liên kết đến bảng `users` để xác định dữ liệu thuộc về người dùng nào:

```js
{
  "id": "user",
  "name": "user",
  "type": "relation",
  "system": false,
  "required": true,
  "options": {
    "collectionId": "users",
    "cascadeDelete": true,
    "minSelect": 1,
    "maxSelect": 1,
    "displayFields": ["username", "email"]
  }
}
```

## Hướng dẫn cập nhật schema

1. Đăng nhập vào Admin UI của PocketBase
2. Chọn bảng "user_backups" từ menu bên trái (hoặc tạo mới nếu chưa có)
3. Chọn tab "Schema"
4. Nhấn nút "New field"
5. Điền thông tin:
   - Name: musicPreferences
   - Type: JSON
   - Required: No
6. Nhấn "Create" để tạo trường mới
7. Nếu chưa có trường user, tạo thêm trường relation đến bảng users

## Kiểm tra API

Sau khi cập nhật schema, có thể kiểm tra API bằng cách gửi request:

```bash
# Lấy thông tin backup của người dùng
curl -X GET \
  'http://localhost:8090/api/collections/user_backups/records?filter=(user="USER_ID")' \
  -H 'Authorization: Bearer YOUR_AUTH_TOKEN'
```

Hoặc tạo/cập nhật thông tin backup:

```bash
# Tạo mới
curl -X POST \
  'http://localhost:8090/api/collections/user_backups/records' \
  -H 'Authorization: Bearer YOUR_AUTH_TOKEN' \
  -H 'Content-Type: application/json' \
  -d '{
    "user": "USER_ID",
    "musicPreferences": {
      "favoriteGenres": [
        {
          "id": "pop",
          "name": "Pop",
          "isSelected": true
        },
        {
          "id": "rock",
          "name": "Rock",
          "isSelected": true
        }
      ],
      "lastUpdated": "2025-09-27T10:30:00.000Z"
    }
  }'

# Cập nhật
curl -X PATCH \
  'http://localhost:8090/api/collections/user_backups/records/RECORD_ID' \
  -H 'Authorization: Bearer YOUR_AUTH_TOKEN' \
  -H 'Content-Type: application/json' \
  -d '{
    "musicPreferences": {
      "favoriteGenres": [
        {
          "id": "pop",
          "name": "Pop",
          "isSelected": true
        },
        {
          "id": "rock",
          "name": "Rock",
          "isSelected": true
        }
      ],
      "lastUpdated": "2025-09-27T10:30:00.000Z"
    }
  }'
```