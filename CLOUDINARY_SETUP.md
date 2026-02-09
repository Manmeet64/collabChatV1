# Cloudinary Setup for File Uploads

## What is Cloudinary?

Cloudinary is a cloud-based media management platform that handles image and video uploads, storage, optimization, and delivery. It provides:

- Free tier with 25 GB storage and 25 GB monthly bandwidth
- Automatic image/video optimization
- CDN delivery for fast file access worldwide
- Secure file storage with URL-based access

## Setup Instructions

### 1. Create a Cloudinary Account

1. Go to [cloudinary.com](https://cloudinary.com)
2. Click "Sign Up For Free"
3. Create account with email or Google/GitHub

### 2. Get Your Credentials

After signing in, you'll see your Dashboard with:

- **Cloud Name**: `your_cloud_name`
- **API Key**: `123456789012345`
- **API Secret**: `abc123def456ghi789`

### 3. Configure Backend

Update `.env` file in `/backend` directory:

```env
CLOUDINARY_CLOUD_NAME=your_cloud_name
CLOUDINARY_API_KEY=your_api_key
CLOUDINARY_API_SECRET=your_api_secret
```

### 4. Test the Upload

**Current Setup:**

- **Endpoint**: `POST /api/v1/chats/upload/:chatId`
- **Method**: multipart/form-data
- **File field name**: `file`
- **Max file size**: 50 MB

**Supported formats:**

- Images: jpg, jpeg, png, gif
- Documents: pdf, doc, docx, txt
- Videos: mp4, mov

## How It Works

### Backend Flow:

1. Frontend sends file as `multipart/form-data` to `/api/v1/chats/upload/:chatId`
2. Multer middleware intercepts the file
3. Multer-Storage-Cloudinary uploads file to Cloudinary
4. Cloudinary returns the file URL
5. Backend saves message with file URL in MongoDB
6. Frontend receives message with `fileUrl` field

### Frontend Update Needed:

Update the file upload in Flutter to use the new endpoint:

```dart
// Change from this:
final formData = FormData.fromMap({
  'message': file.name,
  'fileName': file.name,
  // ...
});

// To this:
final formData = FormData.fromMap({
  'file': MultipartFile.fromBytes(
    file.bytes!,
    filename: file.name,
  ),
  'recipientId': recipientId, // for private chats
});

// Use new endpoint
await api.uploadFileToCloudinary(chatId, formData);
```

## Database Structure

**Message Model with File:**

```javascript
{
  _id: "...",
  senderId: "user_id",
  chatId: "chat_id",
  content: "File: filename.jpg",
  type: "file",
  fileName: "filename.jpg",
  fileSize: 1024567,
  fileType: "image/jpeg",
  fileUrl: "https://res.cloudinary.com/your_cloud/image/upload/v1234567890/collabchat/abc123.jpg",
  createdAt: "2026-02-09T...",
}
```

## Benefits

1. **No Server Storage**: Files stored in cloud, not on your server
2. **CDN Delivery**: Fast file access from anywhere in world
3. **Automatic Optimization**: Images auto-optimized for web
4. **Secure URLs**: Each file gets unique, secure URL
5. **Easy Scaling**: No need to manage file storage infrastructure

## Cost

**Free Tier** (sufficient for development and small apps):

- 25 GB storage
- 25 GB monthly bandwidth
- 2,500 transformations/month

## Next Steps

1. ✅ Sign up for Cloudinary account
2. ✅ Copy credentials to `.env`
3. ✅ Restart backend server
4. ⏳ Update Flutter frontend to use new upload endpoint
5. ⏳ Test file upload
6. ⏳ Update UI to display files using fileUrl

## Frontend Implementation Example

```dart
// In api_service.dart
Future<Message> uploadFileToCloudinary(String chatId, FormData formData) async {
  try {
    final endpoint = '/chats/upload/$chatId';
    final response = await _dio.post(
      endpoint,
      data: formData,
      options: Options(
        headers: {
          'Content-Type': 'multipart/form-data',
        },
      ),
    );
    return Message.fromJson(response.data);
  } catch (e) {
    rethrow;
  }
}

// In chat_screen.dart - Update file upload
Future<void> _shareFile(PlatformFile file) async {
  final formData = FormData.fromMap({
    'file': MultipartFile.fromBytes(
      file.bytes!,
      filename: file.name,
    ),
    'recipientId': widget.userId,
  });

  final message = await api.uploadFileToCloudinary(widget.userId, formData);
  // Message will have fileUrl field populated
}
```

## Displaying Files in UI

```dart
// In chat_bubble.dart
if (message.type == 'file' && message.fileUrl != null) {
  if (message.fileType?.startsWith('image/') == true) {
    // Show image
    Image.network(message.fileUrl!);
  } else {
    // Show file download button
    TextButton.icon(
      icon: Icon(Icons.download),
      label: Text(message.fileName ?? 'Download'),
      onPressed: () => _downloadFile(message.fileUrl!),
    );
  }
}
```
