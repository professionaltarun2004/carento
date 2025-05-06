import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../domain/models/car_model.dart';

class CarDetailsScreen extends StatefulWidget {
  final CarModel car;
  const CarDetailsScreen({Key? key, required this.car}) : super(key: key);

  @override
  State<CarDetailsScreen> createState() => _CarDetailsScreenState();
}

class _CarDetailsScreenState extends State<CarDetailsScreen> {
  DateTime? _pickupDate;
  DateTime? _dropoffDate;
  bool _isBooking = false;
  Razorpay? _razorpay;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay!.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay!.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay!.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    _razorpay?.clear();
    super.dispose();
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    await _saveBooking(response.paymentId);
    if (mounted) {
      setState(() => _isBooking = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Booking successful!')));
      Navigator.pop(context);
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    setState(() => _isBooking = false);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payment failed. Please try again.')));
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    setState(() => _isBooking = false);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('External wallet selected.')));
  }

  Future<void> _bookNow() async {
    if (_pickupDate == null || _dropoffDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select pickup and drop-off dates.')));
      return;
    }
    if (_dropoffDate!.isBefore(_pickupDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Drop-off date must be after pickup date.')));
      return;
    }
    final days = _dropoffDate!.difference(_pickupDate!).inDays + 1;
    final amount = (widget.car.price ?? 0) * days;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Booking'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Car: ${widget.car.name}'),
            Text('Pickup: ${_pickupDate!.toLocal().toString().split(' ')[0]}'),
            Text('Drop-off: ${_dropoffDate!.toLocal().toString().split(' ')[0]}'),
            Text('Total days: $days'),
            Text('Total amount: ₹${amount.toStringAsFixed(0)}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Proceed to Pay'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _isBooking = true);
    var options = {
      'key': 'rzp_test_1DP5mmOlF5G5ag', // Replace with your Razorpay key
      'amount': (amount * 100).toInt(), // in paise
      'name': widget.car.name ?? 'Car',
      'description': 'Car Booking',
      'prefill': {'contact': '', 'email': ''},
      'currency': 'INR',
    };
    try {
      _razorpay!.open(options);
    } catch (e) {
      setState(() => _isBooking = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _saveBooking(String? paymentId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final booking = {
      'userId': user.uid,
      'carId': widget.car.id,
      'carName': widget.car.name,
      'carImageUrl': (widget.car.imageUrls != null && widget.car.imageUrls!.isNotEmpty) ? widget.car.imageUrls!.first : '',
      'pickupDate': _pickupDate,
      'dropoffDate': _dropoffDate,
      'totalAmount': ((widget.car.price ?? 0) * (_dropoffDate!.difference(_pickupDate!).inDays + 1)),
      'status': 'confirmed',
      'paymentStatus': 'paid',
      'paymentId': paymentId,
      'createdAt': DateTime.now(),
    };
    try {
      await FirebaseFirestore.instance.collection('bookings').add(booking);
    } catch (e) {
      if (mounted) {
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Booking Failed'),
            content: Text('Could not save your booking. Please contact support or try again.\nError: $e'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      }
      return;
    }
    if (mounted) {
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Booking Confirmed!'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Car: ${widget.car.name}'),
              Text('Pickup: ${_pickupDate!.toLocal().toString().split(' ')[0]}'),
              Text('Drop-off: ${_dropoffDate!.toLocal().toString().split(' ')[0]}'),
              Text('Total: ₹${((widget.car.price ?? 0) * (_dropoffDate!.difference(_pickupDate!).inDays + 1)).toStringAsFixed(0)}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context); // Go back to car list
                Navigator.pushNamed(context, '/bookings');
              },
              child: const Text('Go to My Bookings'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.car.name ?? 'Car Details')),
      body: ListView(
        children: [
          _buildImageGallery(),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.car.name ?? 'Car Name', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 8),
                Text(widget.car.description ?? '', style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 16),
                _buildSpecs(context),
                const SizedBox(height: 16),
                Text('Price: ₹${widget.car.price?.toStringAsFixed(0) ?? 'N/A'} / day', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _bookNow,
                  child: const Text('Book Now'),
                  style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageGallery() {
    final images = widget.car.imageUrls ?? [];
    if (images.isEmpty) {
      return Container(
        height: 220,
        color: Colors.grey[200],
        child: const Center(child: Icon(Icons.directions_car, size: 64)),
      );
    }
    return SizedBox(
      height: 220,
      child: PageView.builder(
        itemCount: images.length,
        itemBuilder: (context, index) => CachedNetworkImage(
          imageUrl: images[index],
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            color: Colors.grey[200],
            child: const Center(child: CircularProgressIndicator()),
          ),
          errorWidget: (context, url, error) => Container(
            color: Colors.grey[200],
            child: const Icon(Icons.error),
          ),
        ),
      ),
    );
  }

  Widget _buildSpecs(BuildContext context) {
    final specs = widget.car.specifications ?? {};
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: [
        _specChip(Icons.local_gas_station, specs['fuelType'] ?? 'N/A'),
        _specChip(Icons.settings, specs['transmission'] ?? 'N/A'),
        _specChip(Icons.event_seat, '${specs['seats'] ?? 0} seats'),
        _specChip(Icons.luggage, specs['luggage'] ?? 'N/A'),
        _specChip(Icons.ac_unit, specs['airConditioning'] == true ? 'A/C' : 'No A/C'),
      ],
    );
  }

  Widget _specChip(IconData icon, String label) {
    return Chip(
      avatar: Icon(icon, size: 16, color: Colors.white),
      label: Text(label, style: const TextStyle(color: Colors.white)),
      backgroundColor: Colors.blue,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
    );
  }
} 