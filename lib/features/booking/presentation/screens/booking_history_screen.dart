import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:carento/core/constants/app_constants.dart';
import 'package:carento/features/booking/presentation/widgets/booking_card.dart';
import 'package:carento/features/booking/domain/models/booking_model.dart';

class BookingHistoryScreen extends StatelessWidget {
  const BookingHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text('Please sign in to view bookings'));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking History'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection(AppConstants.bookingsCollection)
            .where('userId', isEqualTo: user.uid)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            final errorMsg = snapshot.error.toString();
            if (errorMsg.contains('failed-precondition') && errorMsg.contains('index')) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 48),
                      const SizedBox(height: 16),
                      Text(
                        'A Firestore index is required for this query.',
                        style: Theme.of(context).textTheme.titleMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Please ask the admin to create the required index in the Firebase Console.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }
            return Center(child: Text('Error loading bookings: $errorMsg'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final bookings = snapshot.data?.docs ?? [];

          if (bookings.isEmpty) {
            return const Center(child: Text('No bookings found.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              final booking = BookingModel.fromFirestore(bookings[index]);
              return BookingCard(
                booking: booking.toMap(),
                onTap: () => _showBookingDetails(context, booking),
              );
            },
          );
        },
      ),
    );
  }

  void _showBookingDetails(BuildContext context, BookingModel booking) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Booking Details',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _buildDetailRow(
              context,
              'Status',
              booking.status,
              showStatusChip: true,
            ),
            _buildDetailRow(
              context,
              'Car',
              booking.carName,
            ),
            _buildDetailRow(
              context,
              'Pickup Date',
              _formatDate(booking.pickupDate),
            ),
            _buildDetailRow(
              context,
              'Drop-off Date',
              _formatDate(booking.dropoffDate),
            ),
            _buildDetailRow(
              context,
              'Total Amount',
              '₹${booking.totalAmount}',
            ),
            if (booking.cancelledAt != null) ...[
              const SizedBox(height: 8),
              _buildDetailRow(
                context,
                'Cancelled On',
                _formatDate(booking.cancelledAt!),
              ),
              if (booking.cancellationFee != null)
                _buildDetailRow(
                  context,
                  'Cancellation Fee',
                  '₹${booking.cancellationFee}',
                ),
              if (booking.cancellationReason != null)
                _buildDetailRow(
                  context,
                  'Cancellation Reason',
                  booking.cancellationReason!,
                ),
            ],
            const SizedBox(height: 16),
            if (booking.canBeCancelled())
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Cancellation Policy',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• Free cancellation up to ${AppConstants.cancellationWindowHours} hours before pickup\n'
                    '• ${(AppConstants.cancellationFeePercentage * 100).toInt()}% fee if cancelled within ${AppConstants.cancellationWindowHours} hours\n'
                    '• ${(AppConstants.lateCancellationFeePercentage * 100).toInt()}% fee for late cancellations',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => _showCancellationDialog(context, booking),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Cancel Booking'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _showCancellationDialog(BuildContext context, BookingModel booking) async {
    final reasonController = TextEditingController();
    final cancellationFee = booking.calculateCancellationFee();
    
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Booking'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to cancel this booking?',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            Text(
              'Cancellation Fee: ₹$cancellationFee',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason for cancellation',
                hintText: 'Please provide a reason for cancellation',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No, Keep Booking'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (reasonController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please provide a reason for cancellation'),
                  ),
                );
                return;
              }

              try {
                await FirebaseFirestore.instance
                    .collection(AppConstants.bookingsCollection)
                    .doc(booking.id)
                    .update({
                  'status': AppConstants.bookingCancelled,
                  'cancelledAt': FieldValue.serverTimestamp(),
                  'cancellationFee': cancellationFee,
                  'cancellationReason': reasonController.text.trim(),
                  'updatedAt': FieldValue.serverTimestamp(),
                });

                if (context.mounted) {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Close bottom sheet
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Booking cancelled successfully'),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error cancelling booking: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Yes, Cancel Booking'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    String label,
    String value, {
    bool showStatusChip = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey,
            ),
          ),
          if (showStatusChip)
            _getStatusChip(context, value)
          else
            Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
        ],
      ),
    );
  }

  Widget _getStatusChip(BuildContext context, String status) {
    Color color;
    switch (status) {
      case AppConstants.bookingPending:
        color = Colors.orange;
        break;
      case AppConstants.bookingConfirmed:
        color = Colors.green;
        break;
      case AppConstants.bookingCompleted:
        color = Colors.blue;
        break;
      case AppConstants.bookingCancelled:
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
} 