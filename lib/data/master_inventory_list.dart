// lib/data/master_inventory_list.dart

class MasterInventoryItem {
  final String name;
  final String unit;

  const MasterInventoryItem({required this.name, required this.unit});
}

// This is the universal list of all possible services/inventory items in the app.
const List<MasterInventoryItem> masterInventoryList = [
  MasterInventoryItem(name: 'ICU Bed', unit: 'beds'),
  MasterInventoryItem(name: 'Ventilator', unit: 'units'),
  MasterInventoryItem(name: 'Oxygen Cylinder', unit: 'cylinders'),
  MasterInventoryItem(name: 'A+ Blood', unit: 'liters'),
  MasterInventoryItem(name: 'A- Blood', unit: 'liters'),
  MasterInventoryItem(name: 'B+ Blood', unit: 'liters'),
  MasterInventoryItem(name: 'B- Blood', unit: 'liters'),
  MasterInventoryItem(name: 'AB+ Blood', unit: 'liters'),
  MasterInventoryItem(name: 'AB- Blood', unit: 'liters'),
  MasterInventoryItem(name: 'O+ Blood', unit: 'liters'),
  MasterInventoryItem(name: 'O- Blood', unit: 'liters'),
  MasterInventoryItem(name: 'Emergency Surgery', unit: 'rooms'),
  MasterInventoryItem(name: 'X-Ray Machine', unit: 'machines'),
  MasterInventoryItem(name: 'CT Scanner', unit: 'scanners'),
  MasterInventoryItem(name: 'MRI Machine', unit: 'machines'),
  MasterInventoryItem(name: 'Dialysis Machine', unit: 'machines'),
  MasterInventoryItem(name: 'Ambulance', unit: 'vehicles'),
  MasterInventoryItem(name: 'Pediatric Care', unit: 'wards'),
  MasterInventoryItem(name: 'Cardiology Dept.', unit: 'wards'),
  MasterInventoryItem(name: 'Neurology Dept.', unit: 'wards'),
];