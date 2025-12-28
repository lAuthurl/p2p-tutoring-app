import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../common/widgets/texts/section_heading.dart';
import '../../../utils/constants/sizes.dart';
import '../models/address_model.dart';
import '../screens/address/single_address_widget.dart';

class AddressController extends GetxController {
  static AddressController get instance => Get.find();

  final Rx<AddressModel> selectedAddress = AddressModel.empty().obs;

  // Add init to initialize some address by default.
  @override
  void onInit() {
    selectedAddress.value = TDummyData.user.addresses![0];
    super.onInit();
  }

  Future<dynamic> selectNewAddress(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      builder:
          (_) => SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.all(TSizes.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const TSectionHeading(
                    title: 'Select Address',
                    showActionButton: false,
                  ),
                  Column(
                    children:
                        TDummyData.user.addresses!
                            .map(
                              (address) => TSingleAddress(
                                address: address,
                                onTap: () {
                                  selectedAddress.value = address;
                                  Get.back();
                                },
                              ),
                            )
                            .toList(),
                  ),
                  const SizedBox(height: TSizes.defaultSpace * 2),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {},
                      child: const Text('Add new address'),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }
}

class TDummyData {
  static final user = TUser(
    id: '1',
    name: 'John Doe',
    email: 'john.doe@example.com',
    phone: '+1234567890',
    addresses: [
      AddressModel(
        id: '1',
        name: 'Home Address',
        street: '123 Main Street',
        city: 'New York',
        state: 'NY',
        zipCode: '10001',
        country: 'USA',
        phoneNumber: '',
        postalCode: '',
      ),
      AddressModel(
        id: '2',
        name: 'Work Address',
        street: '456 Business Avenue',
        city: 'Los Angeles',
        state: 'CA',
        zipCode: '90001',
        country: 'USA',
        phoneNumber: '',
        postalCode: '',
      ),
    ],
  );
}

class TUser {
  final String id;
  final String name;
  final String email;
  final String phone;
  final List<AddressModel>? addresses;

  TUser({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.addresses,
  });
}
