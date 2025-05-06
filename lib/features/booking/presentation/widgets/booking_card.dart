import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carento/core/constants/app_constants.dart';

class BookingCard extends StatelessWidget {
  final Map<String, dynamic> booking;
  final VoidCallback onTap;

  const BookingCard({
    super.key,
    required this.booking,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: (booking['carImageUrl'] != null && booking['carImageUrl'].toString().isNotEmpty)
                  ? CachedNetworkImage(
                      imageUrl: booking['carImageUrl'],
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: Colors.grey[300],
                        child: const Center(
                          child: CircularProgressIndicator(),
                        ),
                      ),
                      errorWidget: (context, url, error) {
                        // Calculate fallback asset index based on carId
                        int assetIndex = 1;
                        if (booking['carId'] != null && booking['carId'].toString().isNotEmpty) {
                          assetIndex = (booking['carId'].toString().hashCode.abs() % 7) + 1;
                        }
                        return Image.asset(
                          'assets/images/car$assetIndex.jpg',
                          fit: BoxFit.cover,
                        );
                      },
                    )
                  : Image.asset(
                      'assets/images/car1.jpg',
                      fit: BoxFit.cover,
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          booking['carName'] ?? 'Car Name',
                          style: Theme.of(context).textTheme.titleLarge,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      _buildStatusChip(context),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${_formatDate(booking['pickupDate'])} - ${_formatDate(booking['dropoffDate'])}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Booking ID: ${booking['id']?.substring(0, 8) ?? 'N/A'}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        '₹${booking['totalAmount']}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(BuildContext context) {
    Color color;
    switch (booking['status']) {
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
        (booking['status'] as String).toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'N/A';
    final date = (timestamp as Timestamp).toDate();
    return '${date.day}/${date.month}/${date.year}';
  }
} 