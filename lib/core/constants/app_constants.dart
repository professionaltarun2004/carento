class AppConstants {
  static const String appName = 'Drivana';
  static const String appVersion = '1.0.0';
  
  // Firebase Collections
  static const String usersCollection = 'users';
  static const String carsCollection = 'cars';
  static const String bookingsCollection = 'bookings';
  static const String chatCollection = 'chats';
  
  // User Roles
  static const String roleUser = 'user';
  static const String roleAdmin = 'admin';
  
  // Booking Status
  static const String bookingPending = 'pending';
  static const String bookingConfirmed = 'confirmed';
  static const String bookingCompleted = 'completed';
  static const String bookingCancelled = 'cancelled';
  
  // Storage Paths
  static const String carImagesPath = 'car_images';
  static const String userProfileImagesPath = 'profile_images';
  
  // API Keys (to be replaced with actual keys)
  static const String razorpayKeyId = 'YOUR_RAZORPAY_KEY_ID';
  static const String geminiApiKey = 'YOUR_GEMINI_API_KEY';
} 