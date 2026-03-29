import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/expense_model.dart';

class ExpenseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Create expense
  Future<String?> createExpense(ExpenseModel expense) async {
    try {
      DocumentReference docRef =
          await _firestore.collection('expenses').add(expense.toMap());
      await docRef.update({'id': docRef.id});
      return docRef.id;
    } catch (e) {
      return null;
    }
  }

  // Get expenses by landlord
  Stream<List<ExpenseModel>> getExpensesByLandlord(String landlordId) {
    return _firestore
        .collection('expenses')
        .where('landlordId', isEqualTo: landlordId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ExpenseModel.fromMap(doc.data()))
            .toList());
  }

  // Get expenses by property
  Stream<List<ExpenseModel>> getExpensesByProperty(String propertyId) {
    return _firestore
        .collection('expenses')
        .where('propertyId', isEqualTo: propertyId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ExpenseModel.fromMap(doc.data()))
            .toList());
  }

  // Get total expenses for landlord
  Future<double> getTotalExpenses(String landlordId, {DateTime? startDate, DateTime? endDate}) async {
    try {
      Query query = _firestore
          .collection('expenses')
          .where('landlordId', isEqualTo: landlordId);

      if (startDate != null) {
        query = query.where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
      }
      if (endDate != null) {
        query = query.where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }

      QuerySnapshot snapshot = await query.get();
      
      double total = 0;
      for (var doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        total += (data['amount'] ?? 0).toDouble();
      }
      return total;
    } catch (e) {
      return 0;
    }
  }

  // Get expenses by category
  Future<Map<String, double>> getExpensesByCategory(String landlordId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('expenses')
          .where('landlordId', isEqualTo: landlordId)
          .get();

      Map<String, double> categoryTotals = {};
      
      for (var doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        String category = data['category'] ?? 'other';
        double amount = (data['amount'] ?? 0).toDouble();
        
        categoryTotals[category] = (categoryTotals[category] ?? 0) + amount;
      }
      
      return categoryTotals;
    } catch (e) {
      return {};
    }
  }

  // Delete expense
  Future<bool> deleteExpense(String expenseId) async {
    try {
      await _firestore.collection('expenses').doc(expenseId).delete();
      return true;
    } catch (e) {
      return false;
    }
  }

  // Update expense
  Future<bool> updateExpense(String expenseId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('expenses').doc(expenseId).update(data);
      return true;
    } catch (e) {
      return false;
    }
  }
}