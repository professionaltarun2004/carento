import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../domain/models/car_model.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class CarDetailsScreen extends StatefulWidget {
  final CarModel car;
  const CarDetailsScreen({Key? key, required this.car}) : super(key: key);

  @override
  State<CarDetailsScreen> createState() => _CarDetailsScreenState();
}

class _CarDetailsScreenState extends State<CarDetailsScreen> {
  DateTime? _pickupDate;
  DateTime? _dropoffDate;
  String? _pickupLocationText;
  String? _dropoffLocationText;
  LatLng? _pickupLocation;
  LatLng? _dropoffLocation;
  bool _isBooking = false;
  Razorpay? _razorpay;
  final MapController _mapController = MapController();

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
    if (_pickupDate == null || _dropoffDate == null || _pickupLocationText == null || _pickupLocationText!.isEmpty || _dropoffLocationText == null || _dropoffLocationText!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select pickup and drop-off dates and locations.')));
      return;
    }
    if (_dropoffDate!.isBefore(_pickupDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Drop-off date must be after pickup date.')));
      return;
    }
    final days = _dropoffDate!.difference(_pickupDate!).inDays + 1;
    final amount = (widget.car.price ?? 0) * days;
    
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid booking amount. Please try again.')));
      return;
    }
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundImage: widget.car.imageUrls != null && widget.car.imageUrls!.isNotEmpty
                          ? NetworkImage(widget.car.imageUrls!.first)
                          : AssetImage('assets/images/car1.jpg') as ImageProvider,
                      radius: 32,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.car.name ?? 'Car Name', style: Theme.of(context).textTheme.titleLarge),
                          const SizedBox(height: 4),
                          Text(widget.car.brand ?? '', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Card(
                  color: Theme.of(context).colorScheme.surfaceVariant,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Booking Summary', style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Pickup:'),
                            Text(_pickupDate!.toLocal().toString().split(' ')[0]),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Drop-off:'),
                            Text(_dropoffDate!.toLocal().toString().split(' ')[0]),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Total days:'),
                            Text('$days'),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Total amount:'),
                            Text('₹${amount.toStringAsFixed(0)}', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.blue)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text('Pay with', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.payment),
                        label: const Text('Razorpay'),
                        onPressed: () {
                          Navigator.pop(context, true);
                        },
                        style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.qr_code),
                        label: const Text('GPay QR'),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => Dialog(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              child: Padding(
                                padding: const EdgeInsets.all(24.0),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text('Scan to Pay with GPay', style: Theme.of(context).textTheme.titleMedium),
                                    const SizedBox(height: 16),
                                    Image.asset('assets/images/gpay_qr_placeholder.png', height: 180),
                                    const SizedBox(height: 16),
                                    Text('After payment, enter your transaction ID below.'),
                                    const SizedBox(height: 8),
                                    TextField(
                                      decoration: const InputDecoration(
                                        labelText: 'Transaction ID',
                                        border: OutlineInputBorder(),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    ElevatedButton(
                                      onPressed: () {
                                        Navigator.pop(context);
                                        Navigator.pop(context, true);
                                      },
                                      child: const Text('Confirm Payment'),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel'),
                  ),
                ),
              ],
            ),
          ),
        ),
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
    } on Exception catch (e) {
      setState(() => _isBooking = false);
      String errorMessage = 'Payment failed';
      if (e.toString().contains('network')) {
        errorMessage = 'Network error. Please check your internet connection';
      } else if (e.toString().contains('invalid')) {
        errorMessage = 'Invalid payment configuration';
      } else if (e.toString().contains('cancelled')) {
        errorMessage = 'Payment was cancelled';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    }
  }

  Future<void> _saveBooking(String? paymentId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User not authenticated')),
        );
      }
      return;
    }
    if (_pickupDate == null || _dropoffDate == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid booking dates')),
        );
      }
      return;
    }
    try {
      final booking = {
        'userId': user.uid,
        'carId': widget.car.id,
        'carName': widget.car.name ?? '',
        'carImageUrls': widget.car.imageUrls ?? [],
        'carBrand': widget.car.brand ?? '',
        'carType': widget.car.type ?? '',
        'carSpecifications': widget.car.specifications ?? {},
        'pickupDate': _pickupDate,
        'dropoffDate': _dropoffDate,
        'pickupLocation': _pickupLocationText,
        'dropoffLocation': _dropoffLocationText,
        'pickupCoordinates': _pickupLocation != null ? GeoPoint(_pickupLocation!.latitude, _pickupLocation!.longitude) : null,
        'dropoffCoordinates': _dropoffLocation != null ? GeoPoint(_dropoffLocation!.latitude, _dropoffLocation!.longitude) : null,
        'totalAmount': ((widget.car.price ?? 0) * (_dropoffDate!.difference(_pickupDate!).inDays + 1)),
        'status': 'confirmed',
        'paymentStatus': 'paid',
        'paymentId': paymentId,
        'createdAt': DateTime.now(),
      };
      await FirebaseFirestore.instance.collection('bookings').add(booking);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Booking successful!')),
        );
        Navigator.pop(context);
      }
    } on FirebaseException catch (e) {
      String errorMessage = 'Could not save your booking';
      if (e.code == 'permission-denied') {
        errorMessage = 'You do not have permission to create bookings';
      } else if (e.code == 'unavailable') {
        errorMessage = 'Service is temporarily unavailable';
      }
      if (mounted) {
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Booking Failed'),
            content: Text('$errorMessage. Please contact support or try again.\nError: ${e.message}'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      }
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
    }
  }

  Future<LatLng?> _getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permission denied');
        }
      }
      
      Position position = await Geolocator.getCurrentPosition();
      return LatLng(position.latitude, position.longitude);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error getting location: $e')),
      );
      return null;
    }
  }

  Future<void> _selectLocation(BuildContext context, bool isPickup) async {
    final currentLocation = await _getCurrentLocation();
    if (currentLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not get current location')),
      );
      return;
    }

    final result = await showDialog<LatLng>(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          height: MediaQuery.of(context).size.height * 0.7,
          width: MediaQuery.of(context).size.width * 0.9,
          child: Column(
            children: [
              Expanded(
                child: FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: currentLocation,
                    initialZoom: 15,
                    onTap: (_, point) {
                      Navigator.pop(context, point);
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.carento',
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: currentLocation,
                          width: 40,
                          height: 40,
                          child: Icon(Icons.location_on, color: Colors.red, size: 40),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text('Tap on the map to select location'),
              ),
            ],
          ),
        ),
      ),
    );

    if (result != null) {
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          result.latitude,
          result.longitude,
        );
        
        if (placemarks.isNotEmpty) {
          Placemark place = placemarks[0];
          String address = '${place.street}, ${place.locality}, ${place.administrativeArea}';
          
          setState(() {
            if (isPickup) {
              _pickupLocation = result;
              _pickupLocationText = address;
            } else {
              _dropoffLocation = result;
              _dropoffLocationText = address;
            }
          });
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error getting address: $e')),
        );
      }
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
                const SizedBox(height: 24),
                Card(
                  color: Theme.of(context).colorScheme.surfaceVariant,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Select Booking Dates & Locations', style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                icon: const Icon(Icons.calendar_today),
                                label: Text(_pickupDate == null
                                    ? 'Select Pickup Date'
                                    : 'Pickup: ${_pickupDate!.toLocal().toString().split(' ')[0]}'),
                                onPressed: () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: _pickupDate ?? DateTime.now(),
                                    firstDate: DateTime.now(),
                                    lastDate: DateTime.now().add(const Duration(days: 365)),
                                  );
                                  if (picked != null) {
                                    setState(() => _pickupDate = picked);
                                    if (_dropoffDate != null && _dropoffDate!.isBefore(picked)) {
                                      setState(() => _dropoffDate = null);
                                    }
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton.icon(
                                icon: const Icon(Icons.calendar_today),
                                label: Text(_dropoffDate == null
                                    ? 'Select Drop-off Date'
                                    : 'Drop-off: ${_dropoffDate!.toLocal().toString().split(' ')[0]}'),
                                onPressed: _pickupDate == null
                                    ? null
                                    : () async {
                                        final picked = await showDatePicker(
                                          context: context,
                                          initialDate: _dropoffDate ?? _pickupDate!.add(const Duration(days: 1)),
                                          firstDate: _pickupDate!.add(const Duration(days: 1)),
                                          lastDate: DateTime.now().add(const Duration(days: 366)),
                                        );
                                        if (picked != null) {
                                          setState(() => _dropoffDate = picked);
                                        }
                                      },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        InkWell(
                          onTap: () => _selectLocation(context, true),
                          child: TextField(
                            enabled: false,
                            decoration: InputDecoration(
                              labelText: 'Pickup Location',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.location_on),
                              suffixIcon: Icon(Icons.map),
                            ),
                            controller: TextEditingController(text: _pickupLocationText),
                          ),
                        ),
                        const SizedBox(height: 12),
                        InkWell(
                          onTap: () => _selectLocation(context, false),
                          child: TextField(
                            enabled: false,
                            decoration: InputDecoration(
                              labelText: 'Drop-off Location',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.location_on),
                              suffixIcon: Icon(Icons.map),
                            ),
                            controller: TextEditingController(text: _dropoffLocationText),
                          ),
                        ),
                        if (_pickupDate != null && _dropoffDate != null && _pickupLocationText != null && _pickupLocationText!.isNotEmpty && _dropoffLocationText != null && _dropoffLocationText!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Row(
                              children: [
                                Icon(Icons.check_circle, color: Colors.green),
                                const SizedBox(width: 8),
                                Text('Booking from ${_pickupDate!.toLocal().toString().split(' ')[0]} to ${_dropoffDate!.toLocal().toString().split(' ')[0]}'),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: (_pickupDate != null && _dropoffDate != null && _pickupLocationText != null && _pickupLocationText!.isNotEmpty && _dropoffLocationText != null && _dropoffLocationText!.isNotEmpty && !_isBooking)
                      ? _bookNow
                      : null,
                  child: _isBooking
                      ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Book Now'),
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
    int assetIndex = 1;
    if (widget.car.id != null && widget.car.id!.isNotEmpty) {
      assetIndex = (widget.car.id!.hashCode.abs() % 7) + 1;
    }
    String assetPath = 'assets/images/car$assetIndex.jpg';
    if (images.isEmpty) {
      return Image.asset(
        assetPath,
        height: 220,
        width: double.infinity,
        fit: BoxFit.cover,
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
          errorWidget: (context, url, error) => Image.asset(
            assetPath,
            fit: BoxFit.cover,
            height: 220,
            width: double.infinity,
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