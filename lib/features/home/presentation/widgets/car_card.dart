import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carento/features/cars/domain/models/car_model.dart';

class CarCard extends StatelessWidget {
  final CarModel car;
  final VoidCallback onTap;

  const CarCard({
    super.key,
    required this.car,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    int assetIndex = 1;
    if (car.id != null && car.id!.isNotEmpty) {
      assetIndex = (car.id!.hashCode.abs() % 7) + 1;
    }
    String assetPath = 'assets/images/car$assetIndex.jpg';
    
    final status = car.isAvailable == true ? 'Available' : 'Booked';
    final statusColor = car.isAvailable == true
        ? Colors.green
        : Colors.red;
    final lastUpdated = 'Just now';
    
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
              child: (car.imageUrls != null && car.imageUrls!.isNotEmpty && car.imageUrls!.first.isNotEmpty)
                  ? CachedNetworkImage(
                      imageUrl: car.imageUrls!.first,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: Colors.grey[300],
                        child: const Center(
                          child: CircularProgressIndicator(),
                        ),
                      ),
                      errorWidget: (context, url, error) => Image.asset(
                        assetPath,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                      ),
                    )
                  : Image.asset(
                      assetPath,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
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
                          car.name ?? 'Car Name',
                          style: Theme.of(context).textTheme.titleLarge,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '₹${car.price?.toStringAsFixed(0) ?? 'N/A'}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.circle,
                              color: statusColor,
                              size: 10,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              status,
                              style: TextStyle(
                                color: statusColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.access_time, size: 14, color: Colors.grey),
                      Text(
                        lastUpdated,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildFeatureChip(
                        context,
                        Icons.local_gas_station,
                        car.specifications?['fuelType'] ?? 'N/A',
                      ),
                      const SizedBox(width: 8),
                      _buildFeatureChip(
                        context,
                        Icons.settings,
                        car.specifications?['transmission'] ?? 'N/A',
                      ),
                      const SizedBox(width: 8),
                      _buildFeatureChip(
                        context,
                        Icons.event_seat,
                        '${car.specifications?['seats'] ?? 0} seats',
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 16,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          car.location != null ? '(${car.location!.latitude}, ${car.location!.longitude})' : 'Location not available',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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

  Widget _buildFeatureChip(BuildContext context, IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimaryContainer,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
} 