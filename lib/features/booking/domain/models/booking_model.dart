import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:carento/core/constants/app_constants.dart';

class BookingModel {
  final String id;
  final String userId;
  final String carId;
  final String carName;
  final DateTime pickupDate;
  final DateTime dropoffDate;
  final double totalAmount;
  final String status;
  final String paymentStatus;
  final String? paymentId;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? cancelledAt;
  final double? cancellationFee;
  final String? cancellationReason;

  BookingModel({
    required this.id,
    required this.userId,
    required this.carId,
    required this.carName,
    required this.pickupDate,
    required this.dropoffDate,
    required this.totalAmount,
    required this.status,
    required this.paymentStatus,
    this.paymentId,
    required this.createdAt,
    this.updatedAt,
    this.cancelledAt,
    this.cancellationFee,
    this.cancellationReason,
  });

  factory BookingModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return BookingModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      carId: data['carId'] ?? '',
      carName: data['carName'] ?? '',
      pickupDate: (data['pickupDate'] as Timestamp).toDate(),
      dropoffDate: (data['dropoffDate'] as Timestamp).toDate(),
      totalAmount: (data['totalAmount'] ?? 0.0).toDouble(),
      status: data['status'] ?? 'pending',
      paymentStatus: data['paymentStatus'] ?? 'pending',
      paymentId: data['paymentId'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null 
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
      cancelledAt: data['cancelledAt'] != null 
          ? (data['cancelledAt'] as Timestamp).toDate()
          : null,
      cancellationFee: data['cancellationFee']?.toDouble(),
      cancellationReason: data['cancellationReason'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'carId': carId,
      'carName': carName,
      'pickupDate': Timestamp.fromDate(pickupDate),
      'dropoffDate': Timestamp.fromDate(dropoffDate),
      'totalAmount': totalAmount,
      'status': status,
      'paymentStatus': paymentStatus,
      'paymentId': paymentId,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'cancelledAt': cancelledAt != null ? Timestamp.fromDate(cancelledAt!) : null,
      'cancellationFee': cancellationFee,
      'cancellationReason': cancellationReason,
    };
  }

  static double calculateTotalAmount(double dailyRate, DateTime pickup, DateTime dropoff) {
    final days = dropoff.difference(pickup).inDays;
    return dailyRate * days;
  }

  bool canBeCancelled() {
    if (status == AppConstants.bookingCancelled || 
        status == AppConstants.bookingCompleted) {
      return false;
    }
    
    final now = DateTime.now();
    final hoursUntilPickup = pickupDate.difference(now).inHours;
    return hoursUntilPickup >= AppConstants.cancellationWindowHours;
  }

  double calculateCancellationFee() {
    final now = DateTime.now();
    final hoursUntilPickup = pickupDate.difference(now).inHours;
    
    if (hoursUntilPickup >= AppConstants.cancellationWindowHours) {
      return totalAmount * AppConstants.cancellationFeePercentage;
    } else {
      return totalAmount * AppConstants.lateCancellationFeePercentage;
    }
  }
} 