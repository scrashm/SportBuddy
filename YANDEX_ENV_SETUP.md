# Yandex Cloud Environment Variables Setup

## Required Environment Variables for Railway

Your server now uses Yandex Object Storage instead of AWS S3. You need to update your Railway environment variables:

### Yandex Object Storage Variables:
```
YANDEX_ACCESS_KEY_ID=your_yandex_access_key_id
YANDEX_SECRET_ACCESS_KEY=your_yandex_secret_access_key
YANDEX_REGION=ru-central1
YANDEX_ENDPOINT=https://storage.yandexcloud.net
YANDEX_BUCKET=your_bucket_name
```

### Existing Variables (keep these):
```
DATABASE_URL=your_postgresql_connection_string
TELEGRAM_BOT_TOKEN=your_telegram_bot_token
PORT=3000
RAILWAY_PUBLIC_DOMAIN=your_railway_domain
```

## How to Get Yandex Cloud Credentials:

1. **Create a Service Account** in Yandex Cloud Console
2. **Generate Static Access Keys** for the service account
3. **Create an Object Storage bucket** 
4. **Set bucket permissions** to public read (for avatar access)

## Steps to Update Railway:

1. Go to your Railway project
2. Navigate to "Variables" tab
3. **Remove** old AWS variables:
   - AWS_ACCESS_KEY_ID
   - AWS_SECRET_ACCESS_KEY
   - AWS_REGION
   - AWS_S3_BUCKET

4. **Add** new Yandex variables (see list above)

## Common Issues:

- **Authentication Error**: Check that your Access Key ID and Secret Key are correct
- **Bucket Access Error**: Ensure bucket exists and has public read permissions
- **Region Error**: Use 'ru-central1' for most Yandex Cloud regions
- **Endpoint Error**: Make sure endpoint is exactly 'https://storage.yandexcloud.net'

## Testing:

After updating variables, test avatar upload by:
1. Restart your Railway deployment
2. Try uploading an avatar through your app
3. Check Railway logs for any errors
