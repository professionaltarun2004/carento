import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../domain/models/car_model.dart';

class CarCard extends StatelessWidget {
  final CarModel car;

  const CarCard({Key? key, required this.car}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final price = car.price != null ? '₹${car.price!.toStringAsFixed(0)}' : 'N/A';
    final name = car.name ?? 'Car Name';
    final seats = car.specifications?['seats']?.toString() ?? '0';
    final fuel = car.specifications?['fuelType']?.toString() ?? 'N/A';
    final transmission = car.specifications?['transmission']?.toString() ?? 'N/A';
    final location = car.location != null ? '(${car.location!.latitude}, ${car.location!.longitude})' : 'Location not available';
    final imageUrl = (car.imageUrls != null && car.imageUrls!.isNotEmpty) ? car.imageUrls!.first : '';
    final status = car.isAvailable == true ? 'Available' : 'Booked';
    final statusColor = car.isAvailable == true
        ? Colors.green
        : Colors.red;
    final lastUpdated = 'Just now';

    int assetIndex = 1;
    if (car.id != null && car.id!.isNotEmpty) {
      assetIndex = (car.id!.hashCode.abs() % 7) + 1;
    }
    String assetPath = 'assets/images/car$assetIndex.jpg';

    return Card(
      margin: EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          imageUrl.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.cover,
                  errorWidget: (context, url, error) => Image.asset(
                    assetPath,
                    fit: BoxFit.cover,
                    height: 180,
                    width: double.infinity,
                  ),
                  placeholder: (context, url) => Container(
                    height: 180,
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  height: 180,
                  width: double.infinity,
                )
              : Image.asset(
                  assetPath,
                  fit: BoxFit.cover,
                  height: 180,
                  width: double.infinity,
                ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: Theme.of(context).textTheme.titleMedium,
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
                    Text(
                      '₹$price',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.access_time, size: 14, color: Colors.grey),
                    Text(
                      lastUpdated,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
                    ),
                  ],
                ),
                Row(
                  children: [
                    _infoChip(Icons.local_gas_station, fuel),
                    SizedBox(width: 4),
                    _infoChip(Icons.settings, transmission),
                    SizedBox(width: 4),
                    _infoChip(Icons.event_seat, '$seats seats'),
                  ],
                ),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 16, color: Colors.grey),
                    SizedBox(width: 4),
                    Text(location, style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoChip(IconData icon, String label) {
    return Chip(
      avatar: Icon(icon, size: 16, color: Colors.white),
      label: Text(label, style: TextStyle(color: Colors.white)),
      backgroundColor: Colors.blue,
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 0),
    );
  }
} 